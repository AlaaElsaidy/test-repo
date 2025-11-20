import 'dart:io';

import 'package:alzcare/core/supabase/supabase-config.dart';
import 'package:supabase/supabase.dart';

// ============== User Service ==============
class UserService {
  final _client = SupabaseConfig.client;

  Future<void> addUser({
    required String id,
    required String email,
    required String name,
    required String role,
    String? phone,
  }) async {
    await _client.from('users').insert({
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
    });
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    final response =
        await _client.from('users').select().eq('id', userId).maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final response =
        await _client.from('users').select().eq('email', email).maybeSingle();
    return response;
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _client.from('users').update(data).eq('id', userId);
  }

  Future<void> deleteUser(String userId) async {
    await _client.from('users').delete().eq('id', userId);
  }
}

// ============== Patient Service ==============
class PatientService {
  final _client = SupabaseConfig.client;

  Future<void> addPatient({
    required String patientId,
    required int age,
    required String name,
    required String gender,
    String? stage,
    String? homeAddress,
    String? phoneEmergency,
    double? latitude,
    double? longitude,
    String? photoUrl,
  }) async {
    // Check if patient record already exists
    final existing = await getPatientByUserId(patientId);
    if (existing != null) {
      // Patient record already exists, don't insert again
      return;
    }
    
    await _client.from('patients').insert({
      'user_id': patientId,
      'age': age,
      'gender': gender,
      'alzheimer_stage': stage,
      'home_address': homeAddress,
      'phone_emergency': phoneEmergency,
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'photo_url': photoUrl,
    });
  }

  Future<Map<String, dynamic>?> getPatientByUserId(String userId) async {
    final response = await _client
        .from('patients')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return response;
  }

  Future<void> updatePatient(
      String patientId, Map<String, dynamic> data) async {
    await _client.from('patients').update(data).eq('id', patientId);
  }

  Future<String> uploadPatientPhoto(String patientId, File imageFile) async {
    final fileName = 'patient_$patientId.jpg';
    final bucket = _client.storage.from('patientImg');

    await bucket.remove([fileName]).catchError((e) {});

    final response = await bucket.upload(fileName, imageFile,
        fileOptions: const FileOptions(upsert: true));

    final publicUrl = bucket.getPublicUrl(fileName);

    return publicUrl;
  }
}

//================= FamilyMember Service =============
class FamilyMemberService {
  final _client = SupabaseConfig.client;

  Future<void> addFamily({
    required String familyId,
    required String name,
    required String email,
    String? phone,
    String? photoUrl,
  }) async {
    await _client.from('family_members').insert({
      'id': familyId,
      'name': name,
      'phone': phone,
      'email': email,
      'image_url': photoUrl,
    });
  }

  Future<void> updateFamily(String familyId, Map<String, dynamic> data) async {
    await _client.from('family_members').update(data).eq('id', familyId);
  }
}

// ============== Doctor Service ==============
class DoctorService {
  final _client = SupabaseConfig.client;

  Future<List<Map<String, dynamic>>> getDoctors() async {
    final response = await _client.from('doctors').select();

    return response;
  }
}
