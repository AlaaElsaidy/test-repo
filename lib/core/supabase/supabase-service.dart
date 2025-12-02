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
    
    final data = {
      'age': age,
      'gender': gender,
      'name': name,
      if (stage != null) 'alzheimer_stage': stage,
      if (homeAddress != null) 'home_address': homeAddress,
      if (phoneEmergency != null) 'phone_emergency': phoneEmergency,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (photoUrl != null) 'photo_url': photoUrl,
    };
    
    if (existing != null) {
      // Patient record already exists, update it
      final patientRecordId = existing['id'] as String;
      await _client.from('patients').update(data).eq('id', patientRecordId);
    } else {
      // New patient, insert
      await _client.from('patients').insert({
        'user_id': patientId,
        ...data,
      });
    }
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

    try {
      await bucket.remove([fileName]);
    } catch (_) {}

    await bucket.upload(fileName, imageFile,
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

  Future<String> uploadFamilyPhoto(String familyId, File imageFile) async {
    final fileName = 'family_$familyId.jpg';
    // نستخدم نفس الـ bucket الخاص بصور المرضى للأفاتار
    final bucket = _client.storage.from('patientImg');

    try {
      await bucket.remove([fileName]);
    } catch (_) {}

    await bucket.upload(
      fileName,
      imageFile,
      fileOptions: const FileOptions(upsert: true),
    );

    final publicUrl = bucket.getPublicUrl(fileName);
    return publicUrl;
  }

  Future<List<Map<String, dynamic>>> getFamiliesByDoctor(String doctorId) async {
    final response = await _client
        .from('family_members')
        .select()
        .eq('doctor_id', doctorId);

    return (response as List).cast<Map<String, dynamic>>();
  }
}

// ============== Doctor Service ==============
class DoctorService {
  final _client = SupabaseConfig.client;

  Future<Map<String, dynamic>?> getDoctorById(String doctorId) async {
    final response = await _client
        .from('doctors')
        .select()
        .eq('id', doctorId)
        .maybeSingle();
    return response;
  }

  Future<List<Map<String, dynamic>>> getDoctors() async {
    final response = await _client.from('doctors').select();

    return response;
  }

  /// Upload doctor profile photo and return public URL.
  /// Uses same storage bucket as patient avatars for simplicity.
  Future<String> uploadDoctorPhoto(String doctorId, File imageFile) async {
    final fileName = 'doctor_$doctorId.jpg';
    final bucket = _client.storage.from('patientImg');

    try {
      await bucket.remove([fileName]);
    } catch (_) {}

    await bucket.upload(
      fileName,
      imageFile,
      fileOptions: const FileOptions(upsert: true),
    );

    final publicUrl = bucket.getPublicUrl(fileName);

    // حاول نحفظ الرابط فى جدول الأطباء لو العمود موجود (photo)
    try {
      await _client
          .from('doctors')
          .update({'photo': publicUrl}).eq('id', doctorId);
    } catch (_) {
      // لو مفيش عمود photo نتجاهل الخطأ ونرجّع الـ URL على أى حال
    }

    return publicUrl;
  }
}

// ============== Appointments Service ==============
class AppointmentService {
  final _client = SupabaseConfig.client;

  /// Get today's appointments for a doctor from appointments table
  Future<List<Map<String, dynamic>>> getTodayAppointments(String doctorId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('appointments')
        .select()
        .eq('doctor_id', doctorId)
        .gte('date', startOfDay.toIso8601String().substring(0, 10))
        .lt('date', endOfDay.toIso8601String().substring(0, 10))
        .order('date')
        .order('time');

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Count all upcoming appointments for today
  Future<int> countTodayAppointments(String doctorId) async {
    final appointments = await getTodayAppointments(doctorId);
    return appointments.length;
  }
}
