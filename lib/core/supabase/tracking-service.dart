import 'dart:math' as math;

import 'package:alzcare/core/supabase/supabase-config.dart';

class TrackingService {
  final _client = SupabaseConfig.client;

  // ============== Patient Locations ==============

  /// Save or update patient's current location
  Future<void> savePatientLocation({
    required String patientId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    // Get patient record id from user_id
    final patientRecord = await _client
        .from('patients')
        .select('id')
        .eq('user_id', patientId)
        .maybeSingle();

    if (patientRecord == null) {
      throw Exception('Patient not found');
    }

    final patientRecordId = patientRecord['id'] as String;

    // Check if location exists for today
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final existing = await _client
        .from('patient_locations')
        .select()
        .eq('patient_id', patientRecordId)
        .gte('created_at', startOfDay.toIso8601String())
        .lt('created_at', endOfDay.toIso8601String())
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      // Update existing location
      await _client
          .from('patient_locations')
          .update({
            'latitude': latitude,
            'longitude': longitude,
            if (address != null) 'address': address,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing['id']);
    } else {
      // Insert new location
      await _client.from('patient_locations').insert({
        'patient_id': patientRecordId,
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
      });
    }
  }

  /// Get patient's current location
  Future<Map<String, dynamic>?> getPatientCurrentLocation(
      String patientId) async {
    final patientRecord = await _client
        .from('patients')
        .select('id')
        .eq('user_id', patientId)
        .maybeSingle();

    if (patientRecord == null) return null;

    final patientRecordId = patientRecord['id'] as String;

    final response = await _client
        .from('patient_locations')
        .select()
        .eq('patient_id', patientRecordId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  }

  /// Get patient's current location by patient record id (for family members)
  Future<Map<String, dynamic>?> getPatientCurrentLocationByRecordId(
      String patientRecordId) async {
    final response = await _client
        .from('patient_locations')
        .select()
        .eq('patient_id', patientRecordId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  }

  // ============== Safe Zones ==============

  /// Create a safe zone
  /// patientId can be either user_id or patient record id
  Future<Map<String, dynamic>> createSafeZone({
    required String patientId,
    String? familyMemberId,
    required String name,
    String? address,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    bool isActive = true,
    bool isPatientRecordId = false, // If true, patientId is already the record id
  }) async {
    String patientRecordId;
    
    if (isPatientRecordId) {
      patientRecordId = patientId;
    } else {
      // Get patient record id from user_id
      final patientRecord = await _client
          .from('patients')
          .select('id')
          .eq('user_id', patientId)
          .maybeSingle();

      if (patientRecord == null) {
        throw Exception('Patient not found');
      }

      patientRecordId = patientRecord['id'] as String;
    }

    final response = await _client.from('safe_zones').insert({
      'patient_id': patientRecordId,
      if (familyMemberId != null) 'family_member_id': familyMemberId,
      'name': name,
      if (address != null) 'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'is_active': isActive,
    }).select().single();

    return response;
  }

  /// Get all safe zones for a patient
  Future<List<Map<String, dynamic>>> getSafeZonesForPatient(
      String patientId) async {
    final patientRecord = await _client
        .from('patients')
        .select('id')
        .eq('user_id', patientId)
        .maybeSingle();

    if (patientRecord == null) return [];

    final patientRecordId = patientRecord['id'] as String;

    final response = await _client
        .from('safe_zones')
        .select()
        .eq('patient_id', patientRecordId)
        .order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Get all safe zones for a patient by patient record id (for family members)
  Future<List<Map<String, dynamic>>> getSafeZonesForPatientByRecordId(
      String patientRecordId) async {
    final response = await _client
        .from('safe_zones')
        .select()
        .eq('patient_id', patientRecordId)
        .order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Update safe zone
  Future<void> updateSafeZone(
    String safeZoneId,
    Map<String, dynamic> updates,
  ) async {
    await _client
        .from('safe_zones')
        .update({
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', safeZoneId);
  }

  /// Delete safe zone
  Future<void> deleteSafeZone(String safeZoneId) async {
    await _client.from('safe_zones').delete().eq('id', safeZoneId);
  }

  /// Check if location is inside any active safe zone
  Future<bool> isLocationInSafeZone({
    required String patientId,
    required double latitude,
    required double longitude,
  }) async {
    final zones = await getSafeZonesForPatient(patientId);
    final activeZones = zones.where((z) => z['is_active'] == true).toList();

    for (final zone in activeZones) {
      final distance = _calculateDistance(
        latitude,
        longitude,
        (zone['latitude'] as num).toDouble(),
        (zone['longitude'] as num).toDouble(),
      );

      final radius = (zone['radius_meters'] as num).toDouble();
      if (distance <= radius) {
        return true;
      }
    }

    return false;
  }

  // ============== Location History ==============

  /// Add location to history
  Future<void> addLocationHistory({
    required String patientId,
    required double latitude,
    required double longitude,
    String? address,
    String? placeName,
    required DateTime arrivedAt,
    DateTime? leftAt,
    int? durationMinutes,
  }) async {
    final patientRecord = await _client
        .from('patients')
        .select('id')
        .eq('user_id', patientId)
        .maybeSingle();

    if (patientRecord == null) {
      throw Exception('Patient not found');
    }

    final patientRecordId = patientRecord['id'] as String;

    await _client.from('location_history').insert({
      'patient_id': patientRecordId,
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
      if (placeName != null) 'place_name': placeName,
      'arrived_at': arrivedAt.toIso8601String(),
      if (leftAt != null) 'left_at': leftAt.toIso8601String(),
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
    });
  }

  /// Get location history for a patient
  Future<List<Map<String, dynamic>>> getLocationHistory(
    String patientId, {
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final patientRecord = await _client
        .from('patients')
        .select('id')
        .eq('user_id', patientId)
        .maybeSingle();

    if (patientRecord == null) return [];

    final patientRecordId = patientRecord['id'] as String;

    dynamic query = _client
        .from('location_history')
        .select()
        .eq('patient_id', patientRecordId);

    if (startDate != null) {
      query = query.gte('arrived_at', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('arrived_at', endDate.toIso8601String());
    }

    query = query.order('arrived_at', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Get location history for a patient by patient record id (for family members)
  Future<List<Map<String, dynamic>>> getLocationHistoryByRecordId(
    String patientRecordId, {
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    dynamic query = _client
        .from('location_history')
        .select()
        .eq('patient_id', patientRecordId);

    if (startDate != null) {
      query = query.gte('arrived_at', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('arrived_at', endDate.toIso8601String());
    }

    query = query.order('arrived_at', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return (response as List).cast<Map<String, dynamic>>();
  }

  // ============== Helper Methods ==============

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}

