import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../config/env/env_config.dart';

class ActivityReminder {
  ActivityReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.time24h,
    this.alertBefore = const Duration(minutes: 10),
  });

  final String id;
  final String title;
  final String body;
  final DateTime date;
  final String time24h;
  final Duration alertBefore;

  factory ActivityReminder.fromActivityMap(Map<String, dynamic> map) {
    final date = map['date'];
    final time24 = map['time24'] as String? ?? '08:00';
    if (date is! DateTime) {
      throw ArgumentError('Activity date is missing');
    }
    return ActivityReminder(
      id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: map['name'] as String? ?? 'نشاط',
      body: map['description'] as String? ?? 'لا تنس تنفيذ نشاطك.',
      date: date,
      time24h: time24,
    );
  }

  tz.TZDateTime scheduledDate(tz.Location location) {
    final parts = time24h.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final scheduled = tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
    final reminderTime = scheduled.subtract(alertBefore);
    if (reminderTime.isBefore(tz.TZDateTime.now(location))) {
      return scheduled;
    }
    return reminderTime;
  }
}

class ActivityReminderService {
  ActivityReminderService._();

  static final ActivityReminderService instance = ActivityReminderService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  tz.Location? _location;
  final _dueController = StreamController<ActivityReminder>.broadcast();
  final Map<String, Timer> _timers = {};

  Stream<ActivityReminder> get onReminderDue => _dueController.stream;

  Future<void> _ensureInitialized() async {
    if (_initialized && _location != null) return;
    tzdata.initializeTimeZones();
    _location = tz.getLocation(EnvConfig.timezone);
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    _initialized = true;
  }

  Future<void> syncReminders(List<ActivityReminder> reminders) async {
    await _ensureInitialized();
    await _notifications.cancelAll();
    _timers.values.forEach((timer) => timer.cancel());
    _timers.clear();
    for (final reminder in reminders) {
      await _scheduleReminder(reminder);
    }
  }

  Future<void> _scheduleReminder(ActivityReminder reminder) async {
    if (_location == null) {
      await _ensureInitialized();
    }
    final location = _location!;
    final when = reminder.scheduledDate(location);
    if (when.isBefore(tz.TZDateTime.now(location))) {
      return;
    }

    final id = reminder.id.hashCode & 0x7fffffff;
    const androidDetails = AndroidNotificationDetails(
      'lobna_activity',
      'Lobna Activity Reminders',
      channelDescription: 'تذكيرات صوتية للأنشطة المجدولة',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _notifications.zonedSchedule(
      id,
      reminder.title,
      reminder.body,
      when,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );

    final now = tz.TZDateTime.now(location);
    final delay = when.difference(now);
    if (!delay.isNegative) {
      _timers[reminder.id]?.cancel();
      _timers[reminder.id] = Timer(delay, () {
        _dueController.add(reminder);
        _timers.remove(reminder.id);
      });
    }
  }
}

