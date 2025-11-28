import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/supabase/activity-service.dart';
import '../core/supabase/safe-zone-service.dart';
import '../core/supabase/supabase-service.dart';
import '../core/supabase/supabase-config.dart';
import '../core/shared-prefrences/shared-prefrences-helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages context for AI assistant (Lobna)
/// Fetches patient data, activities, and safe zones from Supabase
/// Supports Realtime updates for immediate context refresh
class ContextManager {
  final ActivityService _activityService = ActivityService();
  final SafeZoneService _safeZoneService = SafeZoneService();
  final PatientService _patientService = PatientService();
  final SupabaseClient _supabaseClient = SupabaseConfig.client;

  String? _cachedContext;
  DateTime? _lastUpdate;
  static const Duration _cacheDuration = Duration(minutes: 5);

  StreamSubscription? _activitiesSubscription;
  StreamSubscription? _safeZonesSubscription;
  final StreamController<String> _contextUpdateController =
      StreamController<String>.broadcast();

  /// Stream of context updates (fires when context changes)
  Stream<String> get contextUpdates => _contextUpdateController.stream;

  /// Builds context string for AI model
  /// Includes: patient info, upcoming activities, safe zones
  Future<String> buildContext() async {
    // Return cached context if still valid
    if (_cachedContext != null &&
        _lastUpdate != null &&
        DateTime.now().difference(_lastUpdate!) < _cacheDuration) {
      return _cachedContext!;
    }

    try {
      final userId = SharedPrefsHelper.getString("userId") ??
          SharedPrefsHelper.getString("patientUid");

      if (userId == null) {
        return _getDefaultContext();
      }

      // Get patient data
      final patient = await _patientService.getPatientByUserId(userId);
      final patientName = patient?['name'] as String? ?? 'المريض';
      final patientAge = patient?['age'] as int?;

      // Get patient record ID for activities and safe zones
      String? patientRecordId;
      if (patient != null && patient['id'] != null) {
        patientRecordId = patient['id'] as String;
      }

      // Get upcoming activities (next 24 hours)
      List<Map<String, dynamic>> upcomingActivities = [];
      if (patientRecordId != null) {
        try {
          final allActivities =
              await _activityService.getActivitiesByPatient(patientRecordId);
          final now = DateTime.now();

          upcomingActivities = allActivities.where((activity) {
            if (activity['is_done'] == true) return false;

            try {
              final dateStr = activity['scheduled_date'] as String?;
              final timeStr = activity['scheduled_time'] as String?;
              if (dateStr == null || timeStr == null) return false;

              final date = DateTime.parse(dateStr);
              final timeParts = timeStr.split(':');
              final scheduledDateTime = DateTime(
                date.year,
                date.month,
                date.day,
                int.parse(timeParts[0]),
                int.parse(timeParts[1]),
              );

              // Include activities in next 24 hours
              final diff = scheduledDateTime.difference(now);
              return diff.inHours >= 0 && diff.inHours <= 24;
            } catch (e) {
              debugPrint('Error parsing activity date/time: $e');
              return false;
            }
          }).toList();
        } catch (e) {
          debugPrint('Error fetching activities: $e');
        }
      }

      // Get active safe zones
      List<SafeZone> activeSafeZones = [];
      try {
        final allZones = await _safeZoneService.getSafeZonesByPatient(userId);
        activeSafeZones = allZones.where((zone) => zone.isActive).toList();
      } catch (e) {
        debugPrint('Error fetching safe zones: $e');
      }

      // Build context string
      final buffer = StringBuffer();
      buffer.writeln('=== معلومات المريض ===');
      buffer.writeln('اسم المريض: $patientName${patientAge != null ? '، $patientAge سنة' : ''}');
      buffer.writeln('⚠️ مهم جداً: استخدم هذا الاسم فقط عند التحدث مع المريض - لا تخترع أسماء أخرى');

      // Current date & time (assumed Egypt local time on device)
      final nowForContext = DateTime.now();
      final dayName = _weekdayToArabic(nowForContext.weekday);
      final hour = nowForContext.hour;
      final minute = nowForContext.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'مساءً' : 'صباحاً';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final dayOfMonth = nowForContext.day.toString().padLeft(2, '0');
      final month = nowForContext.month.toString().padLeft(2, '0');
      final year = nowForContext.year;

      buffer.writeln('\n=== اليوم والوقت (توقيت مصر حسب جهاز المريض) ===');
      buffer.writeln('اليوم الحالي في مصر: $dayName');
      buffer.writeln('تاريخ اليوم في مصر: $dayOfMonth / $month / $year');
      buffer.writeln('الوقت الحالي تقريباً في مصر: $hour12:$minute $period');
      buffer.writeln(
          'استخدم هذه المعلومات دائماً عند الإجابة عن أسئلة اليوم أو التاريخ أو الوقت، ولا تحاول تخمين يوم أو وقت مختلف.');

      if (upcomingActivities.isNotEmpty) {
        buffer.writeln('\nالأنشطة القادمة:');
        for (final activity in upcomingActivities.take(5)) {
          final name = activity['name'] as String? ?? 'نشاط';
          final dateStr = activity['scheduled_date'] as String?;
          final timeStr = activity['scheduled_time'] as String?;

          String timeDisplay = '';
          if (dateStr != null && timeStr != null) {
            try {
              final timeParts = timeStr.split(':');
              final hour = int.parse(timeParts[0]);
              final minute = timeParts[1];
              final period = hour >= 12 ? 'مساءً' : 'صباحاً';
              final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
              timeDisplay = 'الساعة $hour12:$minute $period';
            } catch (e) {
              timeDisplay = timeStr;
            }
          }

          buffer.writeln('- $name $timeDisplay');
        }
      } else {
        buffer.writeln('\nلا توجد أنشطة قادمة اليوم');
      }

      if (activeSafeZones.isNotEmpty) {
        buffer.writeln('\n=== المناطق الآمنة المتاحة ===');
        buffer.writeln('⚠️⚠️⚠️ تحذير صارم: استخدم فقط هذه الأماكن بالضبط - ممنوع تماماً ذكر "New Zone" أو أي مكان آخر غير موجود في هذه القائمة');
        for (final zone in activeSafeZones) {
          buffer.writeln('- ${zone.name} (نشط)');
        }
        buffer.writeln('⚠️ القائمة أعلاه هي القائمة الكاملة - لا توجد أماكن أخرى');
      } else {
        buffer.writeln('\n=== المناطق الآمنة ===');
        buffer.writeln('⚠️⚠️⚠️ لا توجد مناطق آمنة محددة حالياً - ممنوع تماماً اختراع أماكن مثل "New Zone"');
      }

      _cachedContext = buffer.toString();
      _lastUpdate = DateTime.now();
      return _cachedContext!;
    } catch (e) {
      debugPrint('Error building context: $e');
      return _getDefaultContext();
    }
  }

  String _getDefaultContext() {
    final now = DateTime.now();
    final dayName = _weekdayToArabic(now.weekday);
    final minute = now.minute.toString().padLeft(2, '0');
    final hour = now.hour;
    final period = hour >= 12 ? 'مساءً' : 'صباحاً';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final dayOfMonth = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year;

    return '=== معلومات المريض ===\n'
        'اسم المريض: المستخدم\n'
        '\n=== اليوم والوقت (تقديري بتوقيت جهاز المريض في مصر) ===\n'
        'اليوم الحالي في مصر: $dayName\n'
        'تاريخ اليوم في مصر: $dayOfMonth / $month / $year\n'
        'الوقت الحالي تقريباً في مصر: $hour12:$minute $period\n'
        '\nلا توجد أنشطة قادمة اليوم';
  }

  String _weekdayToArabic(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'الاثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
      default:
        return 'الأحد';
    }
  }

  /// Clears cached context (call when data changes)
  void clearCache() {
    _cachedContext = null;
    _lastUpdate = null;
  }

  /// Gets patient name for personalization
  Future<String?> getPatientName() async {
    try {
      final userId = SharedPrefsHelper.getString("userId") ??
          SharedPrefsHelper.getString("patientUid");
      if (userId == null) return null;

      final patient = await _patientService.getPatientByUserId(userId);
      return patient?['name'] as String?;
    } catch (e) {
      debugPrint('Error getting patient name: $e');
      return null;
    }
  }

  /// Initialize Realtime subscriptions for automatic context updates
  Future<void> initializeRealtime() async {
    try {
      final userId = SharedPrefsHelper.getString("userId") ??
          SharedPrefsHelper.getString("patientUid");
      if (userId == null) return;

      // Get patient record ID
      final patient = await _patientService.getPatientByUserId(userId);
      if (patient == null || patient['id'] == null) return;

      final patientRecordId = patient['id'] as String;

      // Subscribe to activities changes
      _activitiesSubscription = _supabaseClient
          .from('activities')
          .stream(primaryKey: ['id'])
          .eq('patient_id', patientRecordId)
          .listen((data) {
        debugPrint('Activities updated, refreshing context');
        clearCache();
        buildContext().then((newContext) {
          _contextUpdateController.add(newContext);
        });
      });

      // Subscribe to safe zones changes
      _safeZonesSubscription = _supabaseClient
          .from('safe_zones')
          .stream(primaryKey: ['id'])
          .eq('patient_id', patientRecordId)
          .listen((data) {
        debugPrint('Safe zones updated, refreshing context');
        clearCache();
        buildContext().then((newContext) {
          _contextUpdateController.add(newContext);
        });
      });

      debugPrint('Realtime subscriptions initialized');
    } catch (e) {
      debugPrint('Error initializing Realtime: $e');
    }
  }

  /// Stop Realtime subscriptions
  void stopRealtime() {
    _activitiesSubscription?.cancel();
    _safeZonesSubscription?.cancel();
    _activitiesSubscription = null;
    _safeZonesSubscription = null;
  }

  /// Dispose resources
  void dispose() {
    stopRealtime();
    _contextUpdateController.close();
  }
}

