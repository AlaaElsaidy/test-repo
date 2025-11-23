import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/models/tracking_models.dart';
import '../../../../core/repositories/tracking_repository.dart';

part 'family_tracking_state.dart';

enum FamilyTrackingStatus { initial, loading, loaded, error }
enum TrackingTab { live, safeZones, history }

class FamilyTrackingCubit extends Cubit<FamilyTrackingState> {
  final TrackingRepository _trackingRepository;
  final String _patientId;
  
  // Getter للوصول إلى patientId من خارج الـ Cubit
  String get patientId => _patientId;
  
  StreamSubscription? _locationSubscription;
  StreamSubscription? _safeZonesSubscription;
  StreamSubscription? _historySubscription;
  Timer? _refreshTimer;

  FamilyTrackingCubit(
    this._trackingRepository,
    this._patientId,
  ) : super(
    const FamilyTrackingState(
      status: FamilyTrackingStatus.initial,
      selectedTab: TrackingTab.live,
      patientInsideSafeZone: true,
      safeZones: [],
      isCreatingZone: false,
      isEditingZone: false,
      locationHistory: [],
      zoneVisitCounts: {},
      averageDailyDistance: 0.0,
    ),
  );

  /// تهيئة التتبع الكامل للعائلة
  Future<void> initializeTracking() async {
    emit(state.copyWith(status: FamilyTrackingStatus.loading));
    try {
      // 1. جلب آخر موقع معروف للمريض
      final lastLocation = await _trackingRepository.getLastLocation(_patientId);
      
      // 2. جلب المناطق الآمنة
      final safeZones = await _trackingRepository.getSafeZones(_patientId);
      
      // 3. جلب السجل (آخر 14 يوم)
      final history = 
          await _trackingRepository.getLocationHistory(_patientId, days: 14);
      
      // 4. حساب الإحصائيات
      final zoneVisitCounts = _calculateZoneVisitCounts(history, safeZones);
      final avgDistance = _calculateAverageDailyDistance(history);
      
      // 5. التحقق مما إذا كان المريض داخل منطقة آمنة
      bool insideSafeZone = false;
      SafeZone? currentZone;
      if (lastLocation != null) {
        for (final zone in safeZones) {
          if (!zone.isActive) continue;
          if (_isInsideZone(lastLocation.latitude, lastLocation.longitude, zone)) {
            insideSafeZone = true;
            currentZone = zone;
            break;
          }
        }
      }

      emit(state.copyWith(
        status: FamilyTrackingStatus.loaded,
        lastKnownLocation: lastLocation,
        safeZones: safeZones,
        locationHistory: history,
        zoneVisitCounts: zoneVisitCounts,
        averageDailyDistance: avgDistance,
        patientInsideSafeZone: insideSafeZone,
        currentZone: currentZone,
        lastLocationUpdate: lastLocation?.timestamp,
      ));

      // 6. بدء المراقبة الفورية
      _startRealTimeUpdates();
      
      // 7. بدء Timer للتحديثات (كل دقيقة)
      _startRefreshTimer();
    } catch (e) {
      emit(state.copyWith(
        status: FamilyTrackingStatus.error,
        errorMessage: 'فشل التهيئة: $e',
      ));
    }
  }

  /// تبديل التبويب المختار
  void selectTab(TrackingTab tab) {
    emit(state.copyWith(selectedTab: tab));
  }

  /// جلب تحديثات حية للموقع
  void _startRealTimeUpdates() {
    // الاستماع لتحديثات الموقع
    _locationSubscription?.cancel();
    _locationSubscription = _trackingRepository
        .watchLocationUpdates(_patientId)
        .listen(
          (location) {
            // التحقق ما إذا كان المريض داخل منطقة آمنة
            bool insideSafeZone = false;
            SafeZone? currentZone;
            
            for (final zone in state.safeZones) {
              if (!zone.isActive) continue;
              if (_isInsideZone(location.latitude, location.longitude, zone)) {
                insideSafeZone = true;
                currentZone = zone;
                break;
              }
            }

            emit(state.copyWith(
              lastKnownLocation: location,
              lastLocationUpdate: DateTime.now(),
              patientInsideSafeZone: insideSafeZone,
              currentZone: currentZone,
            ));
          },
          onError: (e) {
            emit(state.copyWith(
              errorMessage: 'خطأ في تحديثات الموقع الفورية: $e',
            ));
          },
        );

    // الاستماع لتحديثات المناطق الآمنة
    _safeZonesSubscription?.cancel();
    _safeZonesSubscription = _trackingRepository
        .watchSafeZones(_patientId)
        .listen(
          (zone) {
            final updatedZones = state.safeZones
                .where((z) => z.id != zone.id)
                .toList();
            updatedZones.add(zone);

            emit(state.copyWith(safeZones: updatedZones));
          },
          onError: (e) {
            emit(state.copyWith(
              errorMessage: 'خطأ في تحديثات المناطق: $e',
            ));
          },
        );

    // الاستماع لتحديثات السجل
    _historySubscription?.cancel();
    _historySubscription = _trackingRepository
        .watchLocationHistory(_patientId)
        .listen(
          (entry) {
            final updatedHistory = [entry, ...state.locationHistory]
                .take(500)
                .toList();
            
            // تحديث الإحصائيات
            final newCounts = _calculateZoneVisitCounts(updatedHistory, state.safeZones);
            final newAvgDistance = _calculateAverageDailyDistance(updatedHistory);

            emit(state.copyWith(
              locationHistory: updatedHistory,
              zoneVisitCounts: newCounts,
              averageDailyDistance: newAvgDistance,
            ));
          },
          onError: (e) {
            emit(state.copyWith(
              errorMessage: 'خطأ في تحديثات السجل: $e',
            ));
          },
        );
  }

  /// بدء Timer للتحديثات الدورية
  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    // تحديث كل 10 ثواني بدل دقيقة للحصول على بيانات أحدث
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) async {
        // تحديث الموقع الحالي للمريض
        try {
          final lastLocation = await _trackingRepository.getLastLocation(_patientId);
          if (lastLocation != null) {
            // التحقق ما إذا كان المريض داخل منطقة آمنة
            bool insideSafeZone = false;
            SafeZone? currentZone;
            
            for (final zone in state.safeZones) {
              if (!zone.isActive) continue;
              if (_isInsideZone(lastLocation.latitude, lastLocation.longitude, zone)) {
                insideSafeZone = true;
                currentZone = zone;
                break;
              }
            }

            emit(state.copyWith(
              lastKnownLocation: lastLocation,
              lastLocationUpdate: DateTime.now(),
              patientInsideSafeZone: insideSafeZone,
              currentZone: currentZone,
            ));
          }
        } catch (e) {
          // تجاهل الأخطاء في التحديثات الدورية
        }
      },
    );
  }

  /// إضافة منطقة آمنة جديدة
  Future<void> addSafeZone({
    required String name,
    String? address,
    required double latitude,
    required double longitude,
    required double radiusMeters,
  }) async {
    emit(state.copyWith(isCreatingZone: true));
    try {
      final newZone = await _trackingRepository.createSafeZone(
        patientId: _patientId,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );

      final updatedZones = [...state.safeZones, newZone];
      emit(state.copyWith(
        safeZones: updatedZones,
        isCreatingZone: false,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isCreatingZone: false,
        errorMessage: 'فشل إضافة المنطقة: $e',
      ));
    }
  }

  /// تحديث منطقة آمنة
  Future<void> updateSafeZone(SafeZone zone) async {
    emit(state.copyWith(isEditingZone: true));
    try {
      final updated = await _trackingRepository.updateSafeZone(zone);
      final updatedZones = state.safeZones
          .map((z) => z.id == updated.id ? updated : z)
          .toList();
      
      emit(state.copyWith(
        safeZones: updatedZones,
        isEditingZone: false,
        selectedZone: null,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isEditingZone: false,
        errorMessage: 'فشل التحديث: $e',
      ));
    }
  }

  /// حذف منطقة آمنة
  Future<void> deleteSafeZone(String zoneId) async {
    try {
      await _trackingRepository.deleteSafeZone(zoneId);
      final updatedZones = state.safeZones
          .where((z) => z.id != zoneId)
          .toList();
      
      emit(state.copyWith(
        safeZones: updatedZones,
        selectedZone: null,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'فشل الحذف: $e',
      ));
    }
  }

  /// تشغيل/إيقاف منطقة آمنة
  Future<void> toggleSafeZone(String zoneId, bool isActive) async {
    try {
      await _trackingRepository.toggleSafeZone(zoneId, isActive);
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'فشل التشغيل/الإيقاف: $e',
      ));
    }
  }

  /// اختيار منطقة للتحرير
  void selectZoneForEditing(SafeZone zone) {
    emit(state.copyWith(selectedZone: zone, isEditingZone: true));
  }

  /// إلغاء التحرير
  void cancelEditing() {
    emit(state.copyWith(
      selectedZone: null,
      isEditingZone: false,
      isCreatingZone: false,
    ));
  }

  /// حساب عدد زيارات كل منطقة
  Map<String, int> _calculateZoneVisitCounts(
    List<LocationHistory> history,
    List<SafeZone> zones,
  ) {
    final counts = <String, int>{};
    
    for (final entry in history) {
      final place = entry.placeName ?? 'Unknown';
      if (place.isEmpty) continue;
      counts[place] = (counts[place] ?? 0) + 1;
    }
    
    return counts;
  }

  /// حساب متوسط المسافة اليومية
  double _calculateAverageDailyDistance(List<LocationHistory> history) {
    if (history.isEmpty) return 0.0;
    
    // تجميع التواريخ
    final dailyDistances = <String, double>{};
    
    for (final entry in history) {
      final date = entry.arrivedAt.toString().split(' ')[0];
      // يمكن إضافة حساب المسافة الفعلية بين النقاط
      dailyDistances[date] = (dailyDistances[date] ?? 0) + 
          (entry.duration?.inMinutes.toDouble() ?? 0) * 0.05; // تقريبي
    }
    
    if (dailyDistances.isEmpty) return 0.0;
    return dailyDistances.values.fold(0.0, (a, b) => a + b) / 
        dailyDistances.length;
  }

  /// التحقق ما إذا كانت النقطة داخل المنطقة
  bool _isInsideZone(double lat, double lng, SafeZone zone) {
    final distance = _haversineDistance(
      lat,
      lng,
      zone.latitude,
      zone.longitude,
    );
    return distance <= zone.radiusMeters;
  }

  /// حساب المسافة باستخدام Haversine
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

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _safeZonesSubscription?.cancel();
    _historySubscription?.cancel();
    _refreshTimer?.cancel();
    return super.close();
  }
}
