import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:alzcare/services/lobna/activity_reminder_service.dart';

void main() {
  tzdata.initializeTimeZones();
  final cairo = tz.getLocation('Africa/Cairo');

  test('ActivityReminder subtracts alert duration when possible', () {
    final date = DateTime.now().add(const Duration(days: 1));
    final reminder = ActivityReminder(
      id: 'a1',
      title: 'تمرين ذاكرة',
      body: 'ابدأ التمرين حالاً.',
      date: DateTime(date.year, date.month, date.day),
      time24h: '12:30',
      alertBefore: const Duration(minutes: 15),
    );

    final scheduled = reminder.scheduledDate(cairo);
    expect(scheduled.hour, 12);
    expect(scheduled.minute, 15);
  });

  test('ActivityReminder will not schedule in the past', () {
    final today = DateTime.now();
    final reminder = ActivityReminder(
      id: 'a2',
      title: 'دواء المساء',
      body: 'حان وقت الدواء.',
      date: DateTime(today.year, today.month, today.day),
      time24h: '00:30',
      alertBefore: const Duration(hours: 1),
    );

    final scheduled = reminder.scheduledDate(cairo);
    // Because subtracting ساعة يعطي وقتاً باليوم السابق، يتم استخدام الموعد الأصلي.
    expect(scheduled.hour, 0);
    expect(scheduled.minute, 30);
  });
}

