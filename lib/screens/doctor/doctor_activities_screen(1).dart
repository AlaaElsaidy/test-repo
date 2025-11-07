import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DoctorActivitiesScreen extends StatelessWidget {
  const DoctorActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activities Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.teal900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage patient activities and reminders',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.gray600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add_circle),
                  iconSize: 32,
                  color: AppTheme.teal600,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Patient Selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.tealGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Patient',
                          style: TextStyle(
                            color: Color(0xFFCFFAFE),
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Margaret Smith',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.swap_horiz),
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'Active Activities',
                    value: '12',
                    icon: Icons.task_alt,
                    color: AppTheme.teal500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    label: 'Completed Today',
                    value: '8',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Today's Activities
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s Activities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.teal900,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _ActivityCard(
              title: 'Take Morning Medication',
              time: '9:00 AM',
              status: 'Completed',
              statusColor: Colors.green,
              type: 'Medication',
              icon: Icons.medication,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _ActivityCard(
              title: 'Memory Exercise - Face Recognition',
              time: '11:00 AM',
              status: 'Completed',
              statusColor: Colors.green,
              type: 'Memory',
              icon: Icons.psychology,
              color: AppTheme.teal500,
            ),
            const SizedBox(height: 12),
            _ActivityCard(
              title: 'Lunch Reminder',
              time: '12:30 PM',
              status: 'Pending',
              statusColor: Colors.orange,
              type: 'Meal',
              icon: Icons.restaurant,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _ActivityCard(
              title: 'Afternoon Walk',
              time: '3:00 PM',
              status: 'Scheduled',
              statusColor: AppTheme.cyan500,
              type: 'Exercise',
              icon: Icons.directions_walk,
              color: AppTheme.cyan500,
            ),
            const SizedBox(height: 12),
            _ActivityCard(
              title: 'Evening Medication',
              time: '6:00 PM',
              status: 'Scheduled',
              statusColor: AppTheme.cyan500,
              type: 'Medication',
              icon: Icons.medication,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),

            // Activity Templates
            const Text(
              'Activity Templates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.teal900,
              ),
            ),
            const SizedBox(height: 12),

            _TemplateCard(
              title: 'Memory Games',
              description: 'Interactive memory exercises',
              icon: Icons.psychology,
              color: AppTheme.teal500,
            ),
            const SizedBox(height: 12),
            _TemplateCard(
              title: 'Physical Activities',
              description: 'Walking and light exercises',
              icon: Icons.directions_walk,
              color: AppTheme.cyan500,
            ),
            const SizedBox(height: 12),
            _TemplateCard(
              title: 'Social Engagement',
              description: 'Family calls and interactions',
              icon: Icons.people,
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.gray600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String time;
  final String status;
  final Color statusColor;
  final String type;
  final IconData icon;
  final Color color;

  const _ActivityCard({
    required this.title,
    required this.time,
    required this.status,
    required this.statusColor,
    required this.type,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.teal900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.gray500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
              color: AppTheme.gray500,
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _TemplateCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.teal900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.gray600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_circle),
            color: color,
          ),
        ],
      ),
    );
  }
}
