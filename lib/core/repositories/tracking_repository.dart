// lib/core/repositories/tracking_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tracking_models.dart';

class TrackingRepository {
  final SupabaseClient _supabase;

  TrackingRepository(this._supabase);

  // ========== Safe Zones ==========

  /// جلب جميع المناطق الآمنة لمريض معين
  Future<List<SafeZone>> getSafeZones(String patientId) async {
    try {
      final response = await _supabase
          .from('safe_zones')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => SafeZone.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch safe zones: $e');
    }
  }

  /// إضافة منطقة آمنة جديدة
  Future<SafeZone> createSafeZone({
    required String patientId,
    required String name,
    String? address,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    bool isActive = true,
  }) async {
    try {
      final response = await _supabase
          .from('safe_zones')
          .insert({
            'patient_id': patientId,
            'name': name,
            'address': address,
            'latitude': latitude,
            'longitude': longitude,
            'radius_meters': radiusMeters,
            'is_active': isActive,
          })
          .select()
          .single();

      return SafeZone.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create safe zone: $e');
    }
  }

  /// تحديث منطقة آمنة
  Future<SafeZone> updateSafeZone(SafeZone zone) async {
    try {
      final response = await _supabase
          .from('safe_zones')
          .update({
            'name': zone.name,
            'address': zone.address,
            'latitude': zone.latitude,
            'longitude': zone.longitude,
            'radius_meters': zone.radiusMeters,
            'is_active': zone.isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', zone.id)
          .select()
          .single();

      return SafeZone.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update safe zone: $e');
    }
  }

  /// حذف منطقة آمنة
  Future<void> deleteSafeZone(String zoneId) async {
    try {
      await _supabase.from('safe_zones').delete().eq('id', zoneId);
    } catch (e) {
      throw Exception('Failed to delete safe zone: $e');
    }
  }

  /// تشغيل/إيقاف منطقة آمنة
  Future<SafeZone> toggleSafeZone(String zoneId, bool isActive) async {
    try {
      final response = await _supabase
          .from('safe_zones')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', zoneId)
          .select()
          .single();

      return SafeZone.fromJson(response);
    } catch (e) {
      throw Exception('Failed to toggle safe zone: $e');
    }
  }

  // ========== Location Updates ==========

  /// إرسال موقع حالي للـ Database
  Future<PatientLocation> updateLocation({
    required String patientId,
    required double latitude,
    required double longitude,
    String? address,
    double? accuracy,
  }) async {
    try {
      print('📡 Repository: إرسال موقع لـ Supabase...');
      print('   - Patient ID: $patientId');
      print('   - Location: $latitude, $longitude');
      
      final response = await _supabase
          .from('location_updates')
          .insert({
            'patient_id': patientId,
            'latitude': latitude,
            'longitude': longitude,
            'address': address,
            'accuracy': accuracy,
            'timestamp': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      print('✅ Repository: تم الإرسال بنجاح!');
      return PatientLocation.fromJson(response);
    } catch (e) {
      print('❌ Repository: خطأ في الإرسال: $e');
      throw Exception('Failed to update location: $e');
    }
  }

  /// جلب آخر موقع معروف للمريض
  Future<PatientLocation?> getLastLocation(String patientId) async {
    try {
      final response = await _supabase
          .from('location_updates')
          .select()
          .eq('patient_id', patientId)
          .order('timestamp', ascending: false)
          .limit(1);

      if ((response as List).isEmpty) return null;
      return PatientLocation.fromJson(response.first);
    } catch (e) {
      throw Exception('Failed to fetch last location: $e');
    }
  }

  /// جلب آخر X موقع للمريض (لاستخدام الـ Map)
  Future<List<PatientLocation>> getRecentLocations(
    String patientId, {
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('location_updates')
          .select()
          .eq('patient_id', patientId)
          .order('timestamp', ascending: false)
          .limit(limit);

      return (response as List)
          .map((e) => PatientLocation.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recent locations: $e');
    }
  }

  // ========== Location History ==========

  /// جلب سجل الحركة للمريض (آخر X أيام)
  Future<List<LocationHistory>> getLocationHistory(
    String patientId, {
    int days = 7,
  }) async {
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      final response = await _supabase
          .from('location_history')
          .select()
          .eq('patient_id', patientId)
          .gte('arrived_at', since.toIso8601String())
          .order('arrived_at', ascending: false);

      return (response as List)
          .map((e) => LocationHistory.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch location history: $e');
    }
  }

  /// إضافة دخول إلى السجل
  Future<LocationHistory> addHistoryEntry({
    required String patientId,
    String? placeName,
    String? address,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _supabase
          .from('location_history')
          .insert({
            'patient_id': patientId,
            'place_name': placeName,
            'address': address,
            'latitude': latitude,
            'longitude': longitude,
            'arrived_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return LocationHistory.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add history entry: $e');
    }
  }

  /// تحديث مغادرة من منطقة
  Future<LocationHistory> updateHistoryDeparture(
    String historyId, {
    required int durationMinutes,
  }) async {
    try {
      final response = await _supabase
          .from('location_history')
          .update({
            'departed_at': DateTime.now().toIso8601String(),
            'duration_minutes': durationMinutes,
          })
          .eq('id', historyId)
          .select()
          .single();

      return LocationHistory.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update history departure: $e');
    }
  }

  // ========== Emergency Contacts ==========

  /// جلب جهات الاتصال الطوارئ للمريض
  Future<List<EmergencyContact>> getEmergencyContacts(String patientId) async {
    try {
      final response = await _supabase
          .from('emergency_contacts')
          .select()
          .eq('patient_id', patientId)
          .order('is_primary', ascending: false);

      return (response as List)
          .map((e) => EmergencyContact.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch emergency contacts: $e');
    }
  }

  /// جلب جهة الاتصال الأساسية للطوارئ
  Future<EmergencyContact?> getPrimaryEmergencyContact(String patientId) async {
    try {
      final response = await _supabase
          .from('emergency_contacts')
          .select()
          .eq('patient_id', patientId)
          .eq('is_primary', true)
          .limit(1);

      if ((response as List).isEmpty) return null;
      return EmergencyContact.fromJson(response.first);
    } catch (e) {
      throw Exception('Failed to fetch primary emergency contact: $e');
    }
  }

  /// إضافة جهة اتصال طوارئ
  Future<EmergencyContact> addEmergencyContact({
    required String patientId,
    required String name,
    required String phone,
    String? relationship,
    bool isPrimary = false,
  }) async {
    try {
      final response = await _supabase
          .from('emergency_contacts')
          .insert({
            'patient_id': patientId,
            'name': name,
            'phone': phone,
            'relationship': relationship,
            'is_primary': isPrimary,
          })
          .select()
          .single();

      return EmergencyContact.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add emergency contact: $e');
    }
  }

  /// تحديث جهة اتصال طوارئ
  Future<EmergencyContact> updateEmergencyContact(EmergencyContact contact) async {
    try {
      final response = await _supabase
          .from('emergency_contacts')
          .update({
            'name': contact.name,
            'phone': contact.phone,
            'relationship': contact.relationship,
            'is_primary': contact.isPrimary,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contact.id)
          .select()
          .single();

      return EmergencyContact.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update emergency contact: $e');
    }
  }

  /// حذف جهة اتصال طوارئ
  Future<void> deleteEmergencyContact(String contactId) async {
    try {
      await _supabase
          .from('emergency_contacts')
          .delete()
          .eq('id', contactId);
    } catch (e) {
      throw Exception('Failed to delete emergency contact: $e');
    }
  }

  // ========== Real-time Streams ==========

  /// الاستماع للتحديثات الفورية للموقع (WebSocket)
  Stream<PatientLocation> watchLocationUpdates(String patientId) {
    return _supabase
        .from('location_updates')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .asyncMap((event) async {
          final data = event.isNotEmpty ? 
              event.first : 
              <String, dynamic>{};
          return PatientLocation.fromJson(data);
        });
  }

  /// الاستماع لتحديثات Safe Zones (WebSocket)
  Stream<SafeZone> watchSafeZones(String patientId) {
    return _supabase
        .from('safe_zones')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .asyncMap((event) async {
          final data = event.isNotEmpty ? 
              event.first : 
              <String, dynamic>{};
          return SafeZone.fromJson(data);
        });
  }

  /// الاستماع لتحديثات السجل (WebSocket)
  Stream<LocationHistory> watchLocationHistory(String patientId) {
    return _supabase
        .from('location_history')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .asyncMap((event) async {
          final data = event.isNotEmpty ? 
              event.first : 
              <String, dynamic>{};
          return LocationHistory.fromJson(data);
        });
  }
}
