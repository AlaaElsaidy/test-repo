import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

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
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.medical_services,
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
                          'Welcome Back',
                          style: TextStyle(
                            color: Color(0xFFCFFAFE),
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Dr. Sarah Johnson',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined),
                    color: Colors.white,
                    iconSize: 28,
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
                    icon: Icons.people,
                    label: 'Active Patients',
                    value: '24',
                    color: AppTheme.teal500,
                    backgroundColor: AppTheme.teal50,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.calendar_today,
                    label: 'Appointments',
                    value: '8',
                    color: AppTheme.cyan500,
                    backgroundColor: AppTheme.cyan50,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Today's Appointments
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Today\'s Appointments',
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
                    const SizedBox(height: 16),
                    _AppointmentItem(
                      patientName: 'Margaret Smith',
                      time: '10:00 AM',
                      type: 'Regular Checkup',
                      status: 'Upcoming',
                      statusColor: AppTheme.teal500,
                    ),
                    const SizedBox(height: 12),
                    _AppointmentItem(
                      patientName: 'John Davis',
                      time: '11:30 AM',
                      type: 'Progress Review',
                      status: 'Upcoming',
                      statusColor: AppTheme.cyan500,
                    ),
                    const SizedBox(height: 12),
                    _AppointmentItem(
                      patientName: 'Emily Wilson',
                      time: '2:00 PM',
                      type: 'Family Consultation',
                      status: 'Confirmed',
                      statusColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Patients Requiring Attention
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.warning,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Requires Attention',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _AlertItem(
                      patientName: 'Robert Brown',
                      message: 'Missed 2 daily activities',
                      time: '1 hour ago',
                    ),
                    const SizedBox(height: 12),
                    _AlertItem(
                      patientName: 'Mary Taylor',
                      message: 'GPS alert: Outside safe zone',
                      time: '30 mins ago',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recent Activities
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Patient Activities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.teal900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ActivityItem(
                      patientName: 'Margaret Smith',
                      activity: 'Completed memory exercise',
                      time: '2 hours ago',
                      icon: Icons.psychology,
                      color: AppTheme.teal500,
                    ),
                    const SizedBox(height: 12),
                    _ActivityItem(
                      patientName: 'John Davis',
                      activity: 'Started chat conversation',
                      time: '3 hours ago',
                      icon: Icons.chat_bubble,
                      color: AppTheme.cyan500,
                    ),
                    const SizedBox(height: 12),
                    _ActivityItem(
                      patientName: 'Emily Wilson',
                      activity: 'Location updated',
                      time: '5 hours ago',
                      icon: Icons.location_on,
                      color: Colors.green,
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

class _AppointmentItem extends StatelessWidget {
  final String patientName;
  final String time;
  final String type;
  final String status;
  final Color statusColor;

  const _AppointmentItem({
    required this.patientName,
    required this.time,
    required this.type,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.teal900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.gray600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final String patientName;
  final String message;
  final String time;

  const _AlertItem({
    required this.patientName,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patientName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String patientName;
  final String activity;
  final String time;
  final IconData icon;
  final Color color;

  const _ActivityItem({
    required this.patientName,
    required this.activity,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patientName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.teal900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activity,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.gray600,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.gray500,
          ),
        ),
      ],
    );
  }
}
