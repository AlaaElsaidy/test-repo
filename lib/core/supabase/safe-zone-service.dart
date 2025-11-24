import 'package:alzcare/core/supabase/supabase-config.dart';

class SafeZone {
  final String? id;
  final String patientId;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SafeZone({
    this.id,
    required this.patientId,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory SafeZone.fromJson(Map<String, dynamic> json) {
    return SafeZone(
      id: json['id'] as String?,
      patientId: json['patient_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: json['radius_meters'] as int,
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patient_id': patientId,
      'name': name,
      if (address != null) 'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'is_active': isActive,
    };
  }
}

class SafeZoneService {
  final _client = SupabaseConfig.client;
  static const String _table = 'safe_zones';
  static const String _patientsTable = 'patients';

  /// Get patient record ID from user_id
  Future<String?> _getPatientRecordId(String userId) async {
    final patient = await _client
        .from(_patientsTable)
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    return patient?['id'] as String?;
  }

  /// Create a new safe zone
  Future<SafeZone> createSafeZone({
    required String patientUserId,
    required String name,
    String? address,
    required double latitude,
    required double longitude,
    required int radiusMeters,
    bool isActive = true,
  }) async {
    try {
      final patientRecordId = await _getPatientRecordId(patientUserId);
      if (patientRecordId == null) {
        throw Exception('Patient not found');
      }

      final response = await _client.from(_table).insert({
        'patient_id': patientRecordId,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'radius_meters': radiusMeters,
        'is_active': isActive,
      }).select().single();

      return SafeZone.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create safe zone: $e');
    }
  }

  /// Get all safe zones for a patient (by user_id)
  Future<List<SafeZone>> getSafeZonesByPatient(String patientUserId) async {
    try {
      final patientRecordId = await _getPatientRecordId(patientUserId);
      if (patientRecordId == null) return [];

      final response = await _client
          .from(_table)
          .select()
          .eq('patient_id', patientRecordId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SafeZone.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get safe zones: $e');
    }
  }

  /// Get safe zones by patient record ID (for family members)
  Future<List<SafeZone>> getSafeZonesByPatientRecordId(
      String patientRecordId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('patient_id', patientRecordId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SafeZone.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get safe zones: $e');
    }
  }

  /// Update a safe zone
  Future<SafeZone> updateSafeZone({
    required String zoneId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (address != null) updates['address'] = address;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (radiusMeters != null) updates['radius_meters'] = radiusMeters;
      if (isActive != null) updates['is_active'] = isActive;

      if (updates.isEmpty) {
        throw Exception('No updates provided');
      }

      final response = await _client
          .from(_table)
          .update(updates)
          .eq('id', zoneId)
          .select()
          .single();

      return SafeZone.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update safe zone: $e');
    }
  }

  /// Delete a safe zone
  Future<void> deleteSafeZone(String zoneId) async {
    try {
      await _client.from(_table).delete().eq('id', zoneId);
    } catch (e) {
      throw Exception('Failed to delete safe zone: $e');
    }
  }

  /// Toggle safe zone active status
  Future<SafeZone> toggleSafeZone(String zoneId, bool isActive) async {
    return await updateSafeZone(zoneId: zoneId, isActive: isActive);
  }
}

