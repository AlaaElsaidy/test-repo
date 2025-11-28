import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../core/supabase/activity-service.dart';
import '../core/supabase/supabase-service.dart';
import '../core/supabase/supabase-config.dart';
import '../core/supabase/notification-service.dart';
import '../core/shared-prefrences/shared-prefrences-helper.dart';
import 'text_to_speech_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for activity reminders
/// Uses Workmanager for background tasks
class ActivityReminderService {
  final ActivityService _activityService = ActivityService();
  final PatientService _patientService = PatientService();
  final NotificationService _notificationService = NotificationService();
  final TextToSpeechService _ttsService = TextToSpeechService();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _taskName = 'activityReminderTask';
  static const Duration _checkInterval = Duration(minutes: 5);
  static const Duration _reminderBeforeActivity = Duration(minutes: 30);
  static const Duration _missedActivityThreshold = Duration(minutes: 15); // إذا فات 15 دقيقة ولم يُنجز

  /// Initialize the service
  Future<void> initialize() async {
    // Initialize TTS
    await _ttsService.initialize();

    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(initSettings);

    // Request notification permissions
    await _requestNotificationPermissions();

    // Initialize Workmanager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    // Register periodic task
    await _registerPeriodicTask();
  }

  /// Register periodic task to check activities
  Future<void> _registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: _checkInterval,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  /// Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// Check for upcoming activities and send reminders
  /// Note: In background isolate, Supabase might not be available
  /// So we use cached data or skip Supabase-dependent operations
  Future<void> checkAndRemind() async {
    try {
      final userId = SharedPrefsHelper.getString("userId") ??
          SharedPrefsHelper.getString("patientUid");

      if (userId == null) {
        debugPrint('User ID not found for activity reminders');
        return;
      }

      // Try to get patient record (might fail in background isolate)
      Map<String, dynamic>? patient;
      String? patientId;
      String patientName = 'عزيزي';
      
      try {
        patient = await _patientService.getPatientByUserId(userId);
        if (patient != null && patient['id'] != null) {
          patientId = patient['id'] as String;
          patientName = patient['name'] as String? ?? 'عزيزي';
        }
      } catch (e) {
        debugPrint('Could not fetch patient in background: $e');
        // Continue with default name
      }

      if (patientId == null) {
        debugPrint('Patient ID not available, skipping Supabase operations');
        // Can still send local notifications if we have cached data
        return;
      }

      // Get all activities (might fail in background isolate)
      List<Map<String, dynamic>> activities = [];
      try {
        activities = await _activityService.getActivitiesByPatient(patientId);
      } catch (e) {
        debugPrint('Could not fetch activities in background: $e');
        return; // Can't proceed without activities
      }
      
      final now = DateTime.now();

      for (final activity in activities) {
        // Skip if already done
        if (activity['is_done'] == true) continue;

        try {
          final dateStr = activity['scheduled_date'] as String?;
          final timeStr = activity['scheduled_time'] as String?;
          if (dateStr == null || timeStr == null) continue;

          final date = DateTime.parse(dateStr);
          final timeParts = timeStr.split(':');
          final scheduledDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );

          final timeUntilActivity = scheduledDateTime.difference(now);
          final activityName = activity['name'] as String? ?? 'نشاط';
          final activityId = activity['id'] as String?;

          // Check if activity is within reminder window (upcoming)
          if (timeUntilActivity <= _reminderBeforeActivity &&
              timeUntilActivity.inMinutes >= 0) {
            await _sendReminder(patientName, activityName, scheduledDateTime);
          }

          // Check if activity was missed (past due and not done)
          if (timeUntilActivity.isNegative &&
              timeUntilActivity.abs() >= _missedActivityThreshold &&
              timeUntilActivity.abs() <= const Duration(hours: 2)) {
            // Activity missed - notify family (only if Supabase is available)
            try {
              await _notifyMissedActivity(
                patientId: patientId,
                activityId: activityId,
                activityName: activityName,
                scheduledTime: scheduledDateTime,
              );
            } catch (e) {
              debugPrint('Could not notify family in background: $e');
              // Continue - local notification was already sent
            }
          }
        } catch (e) {
          debugPrint('Error processing activity reminder: $e');
        }
      }
    } catch (e) {
      debugPrint('Error checking activities: $e');
    }
  }

  /// Notify family when patient misses an activity
  Future<void> _notifyMissedActivity({
    required String patientId,
    String? activityId,
    required String activityName,
    required DateTime scheduledTime,
  }) async {
    try {
      final hour = scheduledTime.hour;
      final minute = scheduledTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'مساءً' : 'صباحاً';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      await _notificationService.sendNotificationToFamily(
        patientId: patientId,
        type: NotificationType.reminderMissed,
        title: 'تنبيه: نشاط فائت',
        message: 'المريض لم يُكمل "$activityName" المحدد الساعة $hour12:$minute $period',
        data: {
          'activity_id': activityId,
          'activity_name': activityName,
          'scheduled_time': scheduledTime.toIso8601String(),
        },
      );
      debugPrint('Missed activity notification sent to family');
    } catch (e) {
      debugPrint('Error notifying missed activity: $e');
    }
  }

  /// Send reminder notification and TTS
  Future<void> _sendReminder(
      String patientName, String activityName, DateTime scheduledTime) async {
    // Format time
    final hour = scheduledTime.hour;
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'مساءً' : 'صباحاً';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    // New message format: "ع المعاد بتاعه" + activity name
    final message = 'ع المعاد بتاعه، عندك $activityName الساعة $hour12:$minute $period';

    // Send notification
    await _showNotification(activityName, message);

    // Speak reminder (if TTS is available)
    try {
      await _ttsService.speak(message);
    } catch (e) {
      debugPrint('Error speaking reminder: $e');
    }
  }

  /// Show local notification
  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'lobna_reminders',
      'Lobna Activity Reminders',
      channelDescription: 'تنبيهات الأنشطة من لبنى',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
    );
  }

  /// Cancel all reminders
  Future<void> cancelAll() async {
    await Workmanager().cancelByUniqueName(_taskName);
  }

  /// Dispose resources
  void dispose() {
    _ttsService.dispose();
    _notificationService.dispose();
  }
}

/// Background callback for Workmanager
/// Note: Supabase might not work in background isolate
/// So we handle errors gracefully
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Background task: $task');
    if (task == 'activityReminderTask') {
      try {
        // Initialize SharedPreferences (works in background)
        await SharedPrefsHelper.init();
        
        final service = ActivityReminderService();
        await service.checkAndRemind();
        return Future.value(true);
      } catch (e) {
        debugPrint('Error in background task: $e');
        // Don't fail the task - background tasks should be resilient
        // The task will be retried later
        return Future.value(false);
      }
    }
    return Future.value(false);
  });
}

