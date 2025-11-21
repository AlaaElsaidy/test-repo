import 'package:alzcare/core/supabase/supabase-config.dart';

class ActivitiesService {
  final _client = SupabaseConfig.client;

  /// Create an activity
  Future<Map<String, dynamic>> createActivity({
    required String patientId,
    String? familyMemberId,
    required String name,
    String? description,
    required DateTime scheduledDate,
    String? scheduledTime,
    String? reminderType,
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

    final response = await _client.from('activities').insert({
      'patient_id': patientRecordId,
      if (familyMemberId != null) 'family_member_id': familyMemberId,
      'name': name,
      if (description != null) 'description': description,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
      if (scheduledTime != null) 'scheduled_time': scheduledTime,
      if (reminderType != null) 'reminder_type': reminderType,
    }).select().single();

    return response;
  }

  /// Get activities for a patient
  Future<List<Map<String, dynamic>>> getActivitiesForPatient(
    String patientId, {
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
  }) async {
    final patientRecord = await _client
        .from('patients')
        .select('id')
        .eq('user_id', patientId)
        .maybeSingle();

    if (patientRecord == null) return [];

    final patientRecordId = patientRecord['id'] as String;

    dynamic query = _client
        .from('activities')
        .select()
        .eq('patient_id', patientRecordId);

    if (startDate != null) {
      query = query.gte('scheduled_date', startDate.toIso8601String().split('T')[0]);
    }

    if (endDate != null) {
      query = query.lte('scheduled_date', endDate.toIso8601String().split('T')[0]);
    }

    if (isCompleted != null) {
      query = query.eq('is_completed', isCompleted);
    }

    query = query
        .order('scheduled_date', ascending: true)
        .order('scheduled_time', ascending: true);

    final response = await query;
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Get activities for a patient by patient record id (for family members)
  Future<List<Map<String, dynamic>>> getActivitiesForPatientByRecordId(
    String patientRecordId, {
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
  }) async {
    dynamic query = _client
        .from('activities')
        .select()
        .eq('patient_id', patientRecordId);

    if (startDate != null) {
      query = query.gte('scheduled_date', startDate.toIso8601String().split('T')[0]);
    }

    if (endDate != null) {
      query = query.lte('scheduled_date', endDate.toIso8601String().split('T')[0]);
    }

    if (isCompleted != null) {
      query = query.eq('is_completed', isCompleted);
    }

    query = query
        .order('scheduled_date', ascending: true)
        .order('scheduled_time', ascending: true);

    final response = await query;
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Update activity
  Future<void> updateActivity(
    String activityId,
    Map<String, dynamic> updates,
  ) async {
    await _client
        .from('activities')
        .update({
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', activityId);
  }

  /// Toggle activity completion status
  Future<void> toggleActivityCompletion(String activityId, bool isCompleted) async {
    await _client
        .from('activities')
        .update({
          'is_completed': isCompleted,
          if (isCompleted)
            'completed_at': DateTime.now().toIso8601String()
          else
            'completed_at': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', activityId);
  }

  /// Delete activity
  Future<void> deleteActivity(String activityId) async {
    await _client.from('activities').delete().eq('id', activityId);
  }
}

