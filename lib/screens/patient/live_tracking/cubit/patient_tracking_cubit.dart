// lib/screens/patient/live_tracking/cubit/patient_tracking_cubit.dart

import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../core/models/tracking_models.dart';
import '../../../../core/repositories/tracking_repository.dart';

part 'patient_tracking_state.dart';

class PatientTrackingCubit extends Cubit<PatientTrackingState> {
  final TrackingRepository _trackingRepository;
  final String _patientId;
  
  StreamSubscription? _locationSubscription;
  StreamSubscription? _safeZonesSubscription;
  StreamSubscription? _historySubscription;
  Timer? _locationUpdateTimer;

  PatientTrackingCubit(
    this._trackingRepository,
    this._patientId,
  ) : super(
    const PatientTrackingState(
      status: TrackingStatus.initial,
      safeZones: [],
      isInsideSafeZone: true,
      locationHistory: [],
      emergencyContacts: [],
    ),
  );

  /// بدء المراقبة الكاملة
  Future<void> initializeTracking() async {
    emit(state.copyWith(status: TrackingStatus.loading));
    try {
      // 0. طلب الـ Permissions
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('لم يتم السماح بالوصول للموقع');
      }

      // 1. جلب Safe Zones
      final zones = await _trackingRepository.getSafeZones(_patientId);
      
      // 2. جلب Emergency Contacts
      final emergencyContacts = 
          await _trackingRepository.getEmergencyContacts(_patientId);
      
      // 3. جلب آخر موقع معروف وإرساله للـ Database
      await _updateLocation();
      
      // 4. جلب السجل
      final history = 
          await _trackingRepository.getLocationHistory(_patientId, days: 7);

      emit(state.copyWith(
        safeZones: zones,
        emergencyContacts: emergencyContacts,
        locationHistory: history,
        status: TrackingStatus.loaded,
      ));

      // 5. بدء المراقبة الفورية
      _startRealTimeUpdates();

      // 6. بدء Timer للتحديثات المستمرة (كل 5 ثواني بدل 30)
      _startLocationUpdateTimer();
    } catch (e) {
      emit(state.copyWith(
        status: TrackingStatus.error,
        errorMessage: 'فشل التهيئة: $e',
      ));
    }
  }

  /// تحديث الموقع يدويًا
  Future<void> refreshLocation() async {
    print('🔄 جاري تحديث الموقع يدويًا...');
    await _updateLocation();
  }

  /// تحديث الموقع الداخلي
  Future<void> _updateLocation() async {
    try {
      print('🌍 بدء تحديث الموقع من GPS...');
      
      // التحقق من الصلاحيات
      final permission = await Geolocator.checkPermission();
      print('📋 حالة الـ Permission: $permission');
      
      if (permission == LocationPermission.denied) {
        print('⚠️ الـ Permission مرفوض، جاري الطلب...');
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied ||
            newPermission == LocationPermission.deniedForever) {
          print('❌ الـ Permission رفضه المستخدم');
          emit(state.copyWith(
            errorMessage: 'لم يتم السماح بالوصول إلى الموقع',
          ));
          return;
        }
      } else if (permission == LocationPermission.deniedForever) {
        print('❌ الـ Permission مرفوض دائماً، فتح Settings...');
        await Geolocator.openLocationSettings();
        return;
      }

      // جلب الموقع
      print('🔍 جاري جلب الموقع من GPS...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      
      print('✅ تم الحصول على الموقع: ${position.latitude}, ${position.longitude}');

      // عكس الجيو-كود (اختياري)
      String? addr;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[];
          if (p.street != null && p.street!.isNotEmpty) {
            parts.add(p.street!);
          }
          if (p.locality != null && p.locality!.isNotEmpty) {
            parts.add(p.locality!);
          }
          addr = parts.join(', ');
          print('📍 العنوان: $addr');
        }
      } catch (_) {
        // تجاهل الأخطاء في الجيو-كود
        print('⚠️ فشل الجيو-كود (لا مشكلة، الموقع موجود)');
      }

      // إرسال للـ Database
      print('📤 جاري إرسال الموقع لـ Supabase (User ID: $_patientId)...');
      final result = await _trackingRepository.updateLocation(
        patientId: _patientId,
        latitude: position.latitude,
        longitude: position.longitude,
        address: addr,
        accuracy: position.accuracy,
      );
      
      print('✅ تم الإرسال بنجاح! ID: ${result.id}');

      // حساب الأمان
      final isInside = _isInsideSafeZone(
        position.latitude,
        position.longitude,
      );

      emit(state.copyWith(
        currentPosition: position,
        address: addr,
        lastUpdated: DateTime.now(),
        isInsideSafeZone: isInside,
      ));
    } catch (e) {
      print('❌ خطأ في تحديث الموقع: $e');
      print('📌 Stack Trace:');
      print(StackTrace.current);
      emit(state.copyWith(
        errorMessage: 'فشل تحديث الموقع: $e',
      ));
    }
  }

  /// بدء المراقبة الفورية
  void _startRealTimeUpdates() {
    // الاستماع لتحديثات Safe Zones
    _safeZonesSubscription?.cancel();
    _safeZonesSubscription = _trackingRepository
        .watchSafeZones(_patientId)
        .listen(
          (zone) {
            final updatedZones = state.safeZones.map((z) {
              return z.id == zone.id ? zone : z;
            }).toList();
            
            // إذا كانت المنطقة جديدة، أضفها
            if (!state.safeZones.any((z) => z.id == zone.id)) {
              updatedZones.add(zone);
            }

            emit(state.copyWith(safeZones: updatedZones));
          },
          onError: (e) {
            emit(state.copyWith(
              errorMessage: 'خطأ في المراقبة الفورية: $e',
            ));
          },
        );

    // الاستماع لتحديثات السجل
    _historySubscription?.cancel();
    _historySubscription = _trackingRepository
        .watchLocationHistory(_patientId)
        .listen(
          (history) {
            final updatedHistory = [history, ...state.locationHistory]
                .take(50)
                .toList();
            emit(state.copyWith(locationHistory: updatedHistory));
          },
          onError: (e) {
            emit(state.copyWith(
              errorMessage: 'خطأ في مراقبة السجل: $e',
            ));
          },
        );
  }

  /// بدء Timer للتحديثات المستمرة
  void _startLocationUpdateTimer() {
    _locationUpdateTimer?.cancel();
    // تحديث كل 5 ثواني بدل 30 لأداء أفضل
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) async => await _updateLocation(),
    );
  }

  /// حساب ما إذا كان المريض داخل منطقة آمنة
  bool _isInsideSafeZone(double lat, double lng) {
    for (final zone in state.safeZones) {
      if (!zone.isActive) continue;
      final distance = _haversineDistance(
        lat,
        lng,
        zone.latitude,
        zone.longitude,
      );
      if (distance <= zone.radiusMeters) return true;
    }
    return false;
  }

  /// حساب المسافة بين نقطتين (Haversine)
  double _haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371000.0; // نصف قطر الأرض بالمتر
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double d) => d * pi / 180.0;

  /// إضافة منطقة آمنة جديدة
  Future<void> addSafeZone({
    required String name,
    String? address,
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) async {
    try {
      final newZone = await _trackingRepository.createSafeZone(
        patientId: _patientId,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );

      emit(state.copyWith(
        safeZones: [...state.safeZones, newZone],
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'فشل إضافة المنطقة الآمنة: $e',
      ));
    }
  }

  /// تحديث منطقة آمنة
  Future<void> updateSafeZone(SafeZone zone) async {
    try {
      final updated = await _trackingRepository.updateSafeZone(zone);
      final updatedZones = state.safeZones.map((z) {
        return z.id == updated.id ? updated : z;
      }).toList();
      emit(state.copyWith(safeZones: updatedZones));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'فشل تحديث المنطقة الآمنة: $e',
      ));
    }
  }

  /// حذف منطقة آمنة
  Future<void> deleteSafeZone(String zoneId) async {
    try {
      await _trackingRepository.deleteSafeZone(zoneId);
      final updatedZones =
          state.safeZones.where((z) => z.id != zoneId).toList();
      emit(state.copyWith(safeZones: updatedZones));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'فشل حذف المنطقة الآمنة: $e',
      ));
    }
  }

  /// تشغيل/إيقاف منطقة آمنة
  Future<void> toggleSafeZone(String zoneId, bool isActive) async {
    try {
      final updated = await _trackingRepository.toggleSafeZone(zoneId, isActive);
      final updatedZones = state.safeZones.map((z) {
        return z.id == updated.id ? updated : z;
      }).toList();
      emit(state.copyWith(safeZones: updatedZones));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'فشل تشغيل/إيقاف المنطقة: $e',
      ));
    }
  }

  /// إضافة جهة اتصال طوارئ
  Future<void> addEmergencyContact({
    required String name,
    required String phone,
    String? relationship,
    bool isPrimary = false,
  }) async {
    try {
      final contact = await _trackingRepository.addEmergencyContact(
        patientId: _patientId,
        name: name,
        phone: phone,
        relationship: relationship,
        isPrimary: isPrimary,
      );

      emit(state.copyWith(
        emergencyContacts: [...state.emergencyContacts, contact],
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'فشل إضافة جهة الاتصال: $e',
      ));
    }
  }

  /// حذف جهة اتصال طوارئ
  Future<void> deleteEmergencyContact(String contactId) async {
    try {
      await _trackingRepository.deleteEmergencyContact(contactId);
      final updatedContacts = state.emergencyContacts
          .where((c) => c.id != contactId)
          .toList();
      emit(state.copyWith(emergencyContacts: updatedContacts));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'فشل حذف جهة الاتصال: $e',
      ));
    }
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _safeZonesSubscription?.cancel();
    _historySubscription?.cancel();
    _locationUpdateTimer?.cancel();
    return super.close();
  }
}
