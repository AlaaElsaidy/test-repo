import 'package:alzcare/core/models/patient-family-relation-model.dart';
import 'package:alzcare/core/supabase/supabase-config.dart';

class PatientFamilyService {
  final _client = SupabaseConfig.client;

  /// Link patient to family member
  Future<PatientFamilyRelationModel> linkPatientToFamily({
    required String patientId,
    required String familyMemberId,
    String? relationType,
  }) async {
    final now = DateTime.now();

    // If relation already exists, just return it
    final alreadyExists = await relationExists(
      patientId: patientId,
      familyMemberId: familyMemberId,
    );

    if (alreadyExists) {
      final existing = await _client
          .from('patient_family_relations')
          .select()
          .eq('patient_id', patientId)
          .eq('family_member_id', familyMemberId)
          .single();

      // Try to back-fill family_members.patient_id
      try {
        await _client
            .from('family_members')
            .update({'patient_id': patientId})
            .eq('id', familyMemberId);
      } catch (_) {
        // Ignore any FK/constraint errors – relation itself already exists
      }

      return PatientFamilyRelationModel.fromJson(existing);
    }

    // Insert new relation
    final response = await _client.from('patient_family_relations').insert({
      'patient_id': patientId,
      'family_member_id': familyMemberId,
      if (relationType != null) 'relation_type': relationType,
      'created_at': now.toIso8601String(),
    }).select().single();

    // After creating relation, try to set family_members.patient_id as well
    try {
      await _client
          .from('family_members')
          .update({'patient_id': patientId})
          .eq('id', familyMemberId);
    } catch (_) {
      // Ignore errors here – core relation is stored in patient_family_relations
    }

    return PatientFamilyRelationModel.fromJson(response);
  }

  /// Get all family members for a patient
  Future<List<Map<String, dynamic>>> getFamilyMembersByPatient(
      String patientId) async {
    final response = await _client
        .from('patient_family_relations')
        .select('''
          *,
          family_members (
            id,
            name,
            email,
            phone,
            image_url
          )
        ''')
        .eq('patient_id', patientId);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Get all patients for a family member
  Future<List<Map<String, dynamic>>> getPatientsByFamily(
      String familyMemberId) async {
    final response = await _client
        .from('patient_family_relations')
        .select('''
          *,
          patients (
            id,
            user_id,
            name,
            age,
            gender,
            photo_url
          )
        ''')
        .eq('family_member_id', familyMemberId);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Remove relation between patient and family member
  Future<void> removeRelation({
    required String patientId,
    required String familyMemberId,
  }) async {
    await _client
        .from('patient_family_relations')
        .delete()
        .eq('patient_id', patientId)
        .eq('family_member_id', familyMemberId);
  }

  /// Check if relation exists
  Future<bool> relationExists({
    required String patientId,
    required String familyMemberId,
  }) async {
    final response = await _client
        .from('patient_family_relations')
        .select()
        .eq('patient_id', patientId)
        .eq('family_member_id', familyMemberId)
        .maybeSingle();

    return response != null;
  }
}



