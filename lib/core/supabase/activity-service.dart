import 'package:flutter/foundation.dart';
import 'package:alzcare/core/supabase/supabase-config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityService {
  static const _table = 'activities';
  final SupabaseClient _client = SupabaseConfig.client;

  /// Add a new activity (Family member creates activity for patient)
  Future<Map<String, dynamic>> addActivity({
    required String patientId,
    required String familyMemberId,
    required String name,
    String? description,
    required DateTime scheduledDate,
    required String scheduledTime, // Format: "HH:mm" or "h:mm a"
    String reminderType = 'alarm',
  }) async {
    // Convert scheduledTime to TIME format (HH:mm)
    String timeFormatted = _formatTimeTo24Hour(scheduledTime);

    final payload = {
      'patient_id': patientId,
      'family_member_id': familyMemberId,
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'scheduled_time': timeFormatted, // HH:mm
      'reminder_type': reminderType,
      'is_done': false,
    };

    final response = await _client.from(_table).insert(payload).select().single();
    return response as Map<String, dynamic>;
  }

  /// Get all activities for a patient (used by Patient screen)
  Future<List<Map<String, dynamic>>> getActivitiesByPatient(String patientId) async {
    final response = await _client
        .from(_table)
        .select('''
          *,
          family_members (
            id,
            name,
            email
          )
        ''')
        .eq('patient_id', patientId)
        .order('scheduled_date', ascending: true)
        .order('scheduled_time', ascending: true);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Get activities for a specific date (used by Patient screen)
  Future<List<Map<String, dynamic>>> getActivitiesByPatientAndDate(
    String patientId,
    DateTime date,
  ) async {
    final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD

    final response = await _client
        .from(_table)
        .select('''
          *,
          family_members (
            id,
            name,
            email
          )
        ''')
        .eq('patient_id', patientId)
        .eq('scheduled_date', dateStr)
        .order('scheduled_time', ascending: true);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Get all activities created by a family member (used by Family screen)
  Future<List<Map<String, dynamic>>> getActivitiesByFamilyMember(
    String familyMemberId,
  ) async {
    final response = await _client
        .from(_table)
        .select('''
          *,
          patients (
            id,
            user_id,
            name,
            photo_url
          )
        ''')
        .eq('family_member_id', familyMemberId)
        .order('scheduled_date', ascending: true)
        .order('scheduled_time', ascending: true);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Get activities for a specific date (used by Family screen)
  Future<List<Map<String, dynamic>>> getActivitiesByFamilyMemberAndDate(
    String familyMemberId,
    DateTime date,
  ) async {
    final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD

    final response = await _client
        .from(_table)
        .select('''
          *,
          patients (
            id,
            user_id,
            name,
            photo_url
          )
        ''')
        .eq('family_member_id', familyMemberId)
        .eq('scheduled_date', dateStr)
        .order('scheduled_time', ascending: true);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Update an activity (Family member can edit)
  Future<Map<String, dynamic>> updateActivity({
    required String activityId,
    String? name,
    String? description,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? reminderType,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (description != null) payload['description'] = description;
    if (scheduledDate != null) {
      payload['scheduled_date'] = scheduledDate.toIso8601String().split('T')[0];
    }
    if (scheduledTime != null) {
      payload['scheduled_time'] = _formatTimeTo24Hour(scheduledTime);
    }
    if (reminderType != null) payload['reminder_type'] = reminderType;

    final response = await _client
        .from(_table)
        .update(payload)
        .eq('id', activityId)
        .select()
        .single();

    return response as Map<String, dynamic>;
  }

  /// Toggle done status (Patient can mark as done/undone)
  Future<Map<String, dynamic>> toggleActivityDone({
    required String activityId,
    required bool isDone,
  }) async {
    final response = await _client
        .from(_table)
        .update({'is_done': isDone})
        .eq('id', activityId)
        .select()
        .single();

    return response as Map<String, dynamic>;
  }

  /// Delete an activity (Family member can delete)
  Future<void> deleteActivity(String activityId) async {
    await _client.from(_table).delete().eq('id', activityId);
  }

  /// Helper: Convert time string to 24-hour format (HH:mm)
  String _formatTimeTo24Hour(String timeStr) {
    // If already in 24-hour format (HH:mm), return as is
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(timeStr)) {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      return '${hour.toString().padLeft(2, '0')}:$minute';
    }

    // If in 12-hour format (h:mm a or hh:mm a), parse it
    try {
      // Try to parse formats like "8:00 AM", "08:00 AM", "1:30 PM"
      final regex = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false);
      final match = regex.firstMatch(timeStr);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final minute = match.group(2)!;
        final period = match.group(3)!.toUpperCase();

        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        return '${hour.toString().padLeft(2, '0')}:$minute';
      }
    } catch (e) {
      // If parsing fails, return default or throw
      debugPrint('Error parsing time: $timeStr');
    }

    // Default fallback
    return '08:00';
  }
}

