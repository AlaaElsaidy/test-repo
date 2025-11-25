import 'dart:io';

import 'package:alzcare/core/models/doctor_advice_model.dart';
import 'package:alzcare/core/supabase/supabase-config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorAdviceService {
  static const _table = 'doctor_advices';
  static const _storageBucket = 'doctor_advice_media';

  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<DoctorAdviceModel>> getAdviceByDoctor(String doctorId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('doctor_id', doctorId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => DoctorAdviceModel.fromJson(row))
        .toList();
  }

  Future<List<DoctorAdviceModel>> getAdviceForFamily(String familyMemberId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('family_member_id', familyMemberId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => DoctorAdviceModel.fromJson(row))
        .toList();
  }

  Future<DoctorAdviceModel> createAdvice({
    required String doctorId,
    required String familyMemberId,
    String? patientId,
    String? title,
    required List<String> tips,
    String? videoUrl,
    String? thumbnailUrl,
    String status = 'sent',
  }) async {
    final payload = {
      'doctor_id': doctorId,
      'family_member_id': familyMemberId,
      'patient_id': patientId,
      'title': title,
      'tips': tips,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'status': status,
    };

    final response =
        await _client.from(_table).insert(payload).select().single();

    return DoctorAdviceModel.fromJson(response);
  }

  Future<String> uploadMedia({
    required File file,
    required String doctorId,
    required String adviceId,
  }) async {
    final bucket = _client.storage.from(_storageBucket);
    final extension = file.path.split('.').last;
    final fileName = '$doctorId/$adviceId.$extension';

    await bucket.upload(fileName, file,
        fileOptions: const FileOptions(upsert: true));

    return bucket.getPublicUrl(fileName);
  }

  Future<void> deleteAdvice(String adviceId) async {
    await _client.from(_table).delete().eq('id', adviceId);
  }
}

