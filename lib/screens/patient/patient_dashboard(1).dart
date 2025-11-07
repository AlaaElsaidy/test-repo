import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/progress_item.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.tealGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good Morning',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Margaret Smith',
                              style: TextStyle(
                                color: Color(0xFFCFFAFE),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How are you feeling today?',
                    style: TextStyle(
                      color: Color(0xFFCFFAFE),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.psychology,
                    label: 'Activities',
                    value: '12/15',
                    color: AppTheme.teal500,
                    backgroundColor: AppTheme.teal50,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.emoji_events,
                    label: 'Points',
                    value: '890',
                    color: AppTheme.cyan500,
                    backgroundColor: AppTheme.cyan50,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Memory Progress Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Memory Progress',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.teal900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'This Week',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.gray500,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.trending_up,
                          color: AppTheme.teal600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const ProgressItem(
                      label: 'Face Recognition',
                      value: 0.85,
                      color: AppTheme.teal500,
                    ),
                    const SizedBox(height: 12),
                    const ProgressItem(
                      label: 'Photo Matching',
                      value: 0.72,
                      color: AppTheme.cyan500,
                    ),
                    const SizedBox(height: 12),
                    const ProgressItem(
                      label: 'Music Memory',
                      value: 0.90,
                      color: AppTheme.teal500,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Next Appointment
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.teal50, AppTheme.cyan50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.teal500,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Appointment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.teal900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Dr. Sarah Johnson',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.teal600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tomorrow, 10:00 AM',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.teal600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Today's Reminders
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today\'s Reminders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.teal900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ReminderItem(
                      title: 'Take morning medication',
                      time: '9:00 AM',
                      color: AppTheme.teal500,
                    ),
                    const SizedBox(height: 12),
                    _ReminderItem(
                      title: 'Memory game activity',
                      time: '2:00 PM',
                      color: AppTheme.cyan500,
                    ),
                    const SizedBox(height: 12),
                    _ReminderItem(
                      title: 'Evening walk',
                      time: '6:00 PM',
                      color: AppTheme.teal500,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Safety Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        color: Colors.green[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.teal900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Safe - At Home',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderItem extends StatelessWidget {
  final String title;
  final String time;
  final Color color;

  const _ReminderItem({
    required this.title,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.teal900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
