import 'dart:io';

import 'package:alzcare/core/supabase/supabase-config.dart';
import 'package:supabase/supabase.dart';

class DoctorAdviceService {
  final _client = SupabaseConfig.client;

  /// Create doctor advice
  Future<Map<String, dynamic>> createAdvice({
    required String doctorId,
    String? title,
    List<String>? tips,
    String? videoUrl,
    String? videoStoragePath,
    bool isDraft = false,
  }) async {
    final response = await _client.from('doctor_advice').insert({
      'doctor_id': doctorId,
      if (title != null) 'title': title,
      if (tips != null && tips.isNotEmpty) 'tips': tips,
      if (videoUrl != null) 'video_url': videoUrl,
      if (videoStoragePath != null) 'video_storage_path': videoStoragePath,
      'is_draft': isDraft,
    }).select().single();

    return response;
  }

  /// Upload video to Supabase Storage
  Future<String> uploadVideo(String doctorId, File videoFile) async {
    final fileName = 'advice_${doctorId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final bucket = _client.storage.from('doctor-advice-videos');

    try {
      await bucket.remove([fileName]);
    } catch (e) {
      // Ignore if file doesn't exist
    }

    await bucket.upload(fileName, videoFile,
        fileOptions: const FileOptions(upsert: true));

    final publicUrl = bucket.getPublicUrl(fileName);
    return publicUrl;
  }

  /// Get video storage path
  String getVideoStoragePath(String doctorId, String fileName) {
    return 'advice_${doctorId}_$fileName';
  }

  /// Send advice to family members
  Future<void> sendAdviceToFamilyMembers({
    required String adviceId,
    required List<String> familyMemberIds,
  }) async {
    final recipients = familyMemberIds.map((familyMemberId) => {
      'advice_id': adviceId,
      'family_member_id': familyMemberId,
    }).toList();

    await _client.from('doctor_advice_recipients').insert(recipients);
  }

  /// Get all family members linked to a doctor
  Future<List<Map<String, dynamic>>> getFamilyMembersForDoctor(
      String doctorId) async {
    final response = await _client
        .from('family_members')
        .select()
        .eq('doctor_id', doctorId);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Get all advice for a doctor
  Future<List<Map<String, dynamic>>> getAdviceForDoctor(
    String doctorId, {
    bool? isDraft,
  }) async {
    dynamic query = _client
        .from('doctor_advice')
        .select()
        .eq('doctor_id', doctorId);

    if (isDraft != null) {
      query = query.eq('is_draft', isDraft);
    }

    query = query.order('created_at', ascending: false);

    final response = await query;
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Get advice sent to a family member
  Future<List<Map<String, dynamic>>> getAdviceForFamilyMember(
    String familyMemberId,
  ) async {
    final response = await _client
        .from('doctor_advice_recipients')
        .select('''
          *,
          doctor_advice (
            id,
            doctor_id,
            title,
            tips,
            video_url,
            video_storage_path,
            created_at,
            updated_at,
            users!doctor_advice_doctor_id_fkey (
              id,
              name,
              email
            )
          )
        ''')
        .eq('family_member_id', familyMemberId)
        .order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Mark advice as read
  Future<void> markAdviceAsRead({
    required String adviceId,
    required String familyMemberId,
  }) async {
    await _client
        .from('doctor_advice_recipients')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('advice_id', adviceId)
        .eq('family_member_id', familyMemberId);
  }

  /// Update advice
  Future<void> updateAdvice(
    String adviceId,
    Map<String, dynamic> updates,
  ) async {
    await _client
        .from('doctor_advice')
        .update({
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', adviceId);
  }

  /// Delete advice
  Future<void> deleteAdvice(String adviceId) async {
    // Delete recipients first (cascade should handle this, but being explicit)
    await _client
        .from('doctor_advice_recipients')
        .delete()
        .eq('advice_id', adviceId);

    // Delete advice
    await _client.from('doctor_advice').delete().eq('id', adviceId);
  }
}

