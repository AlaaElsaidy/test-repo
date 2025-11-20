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

    final response = await _client.from('patient_family_relations').insert({
      'patient_id': patientId,
      'family_member_id': familyMemberId,
      if (relationType != null) 'relation_type': relationType,
      'created_at': now.toIso8601String(),
    }).select().single();

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



