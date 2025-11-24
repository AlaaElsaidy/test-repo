import 'package:alzcare/core/supabase/supabase-config.dart';

class LocationTrackingService {
  final _client = SupabaseConfig.client;
  static const String _historyTable = 'location_history';
  static const String _patientsTable = 'patients';
  static const String _usersTable = 'users';

  /// Save patient location to history and update current location in patients table
  Future<void> saveLocation({
    required String patientId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      // Get patient record ID from user_id
      var patientRecord = await _client
          .from(_patientsTable)
          .select('id')
          .eq('user_id', patientId)
          .maybeSingle();

      // If patient record doesn't exist, create it
      if (patientRecord == null) {
        // Get user info to create patient record
        final user = await _client
            .from(_usersTable)
            .select('name, email')
            .eq('id', patientId)
            .maybeSingle();

        if (user == null) {
          throw Exception('User not found');
        }

        // Create patient record with minimal data
        final insertResponse = await _client.from(_patientsTable).insert({
          'user_id': patientId,
          'name': user['name'] ?? 'Patient',
          'age': 0,
          'gender': 'Male', // Default value
        }).select('id').single();

        patientRecord = insertResponse;
      }

      final patientRecordId = patientRecord['id'] as String;

      // Save to location_history
      await _client.from(_historyTable).insert({
        'patient_id': patientRecordId,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      });

      // Update current location in patients table
      await _client.from(_patientsTable).update({
        'latitude': latitude,
        'longitude': longitude,
      }).eq('id', patientRecordId);
    } catch (e) {
      throw Exception('Failed to save location: $e');
    }
  }

  /// Get current location of patient
  Future<Map<String, dynamic>?> getCurrentLocation(String patientId) async {
    try {
      final patient = await _client
          .from(_patientsTable)
          .select('id, latitude, longitude')
          .eq('user_id', patientId)
          .maybeSingle();

      if (patient == null) return null;

      final patientRecordId = patient['id'] as String;

      // Get latest location from history
      final latestHistory = await _client
          .from(_historyTable)
          .select('latitude, longitude, address, created_at')
          .eq('patient_id', patientRecordId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (latestHistory != null) {
        return {
          'latitude': latestHistory['latitude'] as double?,
          'longitude': latestHistory['longitude'] as double?,
          'address': latestHistory['address'] as String?,
          'updated_at': latestHistory['created_at'] as String?,
        };
      }

      // Fallback to patients table
      return {
        'latitude': patient['latitude'] as double?,
        'longitude': patient['longitude'] as double?,
        'address': null,
        'updated_at': null,
      };
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  /// Get location history for a patient
  Future<List<Map<String, dynamic>>> getLocationHistory({
    required String patientId,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get patient record ID from user_id
      final patient = await _client
          .from(_patientsTable)
          .select('id')
          .eq('user_id', patientId)
          .maybeSingle();

      if (patient == null) {
        // Patient record doesn't exist, return empty list
        return [];
      }

      final patientRecordId = patient['id'] as String;

      var query = _client
          .from(_historyTable)
          .select()
          .eq('patient_id', patientRecordId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      
      final result = (response as List).cast<Map<String, dynamic>>();
      return result;
    } catch (e) {
      throw Exception('Failed to get location history: $e');
    }
  }

  /// Get location for patient by record ID (for family members)
  Future<Map<String, dynamic>?> getLocationByPatientRecordId(
      String patientRecordId) async {
    try {
      // Get latest location from history
      final latestHistory = await _client
          .from(_historyTable)
          .select('latitude, longitude, address, created_at')
          .eq('patient_id', patientRecordId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (latestHistory != null) {
        return {
          'latitude': latestHistory['latitude'] as double?,
          'longitude': latestHistory['longitude'] as double?,
          'address': latestHistory['address'] as String?,
          'updated_at': latestHistory['created_at'] as String?,
        };
      }

      // Fallback to patients table
      final patient = await _client
          .from(_patientsTable)
          .select('latitude, longitude')
          .eq('id', patientRecordId)
          .maybeSingle();

      if (patient == null) {
        return null;
      }

      // Check if patient has location data
      final lat = patient['latitude'] as double?;
      final lng = patient['longitude'] as double?;
      
      if (lat == null || lng == null) {
        return null;
      }

      return {
        'latitude': lat,
        'longitude': lng,
        'address': null,
        'updated_at': null,
      };
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }
}

