// lib/screens/doctor/doctor_chat_screen.dart
import 'package:flutter/material.dart';

import '../../screens/family/family_chat_screen.dart';
import '../../screens/patient/chat_with_doctor_screen.dart';
import '../../theme/app_theme.dart';

class DoctorChatScreen extends StatelessWidget {
  const DoctorChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AppTheme.tealGradient,
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
                      Icons.chat,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Messages',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search),
                    color: Colors.white,
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: const TabBar(
                labelColor: AppTheme.teal600,
                unselectedLabelColor: AppTheme.gray500,
                indicatorColor: AppTheme.teal500,
                tabs: [
                  Tab(text: 'Patients'),
                  Tab(text: 'Families'),
                ],
              ),
            ),

            // Chat Lists
            Expanded(
              child: TabBarView(
                children: [
                  _buildPatientList(context),
                  _buildFamilyList(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 1, // مثال
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final name = 'Margaret Smith';
        return _ChatItem(
          name: name,
          subtitle: 'Patient',
          lastMessage: 'Good morning Dr. Johnson!',
          time: '9:30 AM',
          isOnline: true,
          avatar: Icons.person,
          color: AppTheme.teal500,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatWithDoctorScreen(
                  currentSender: 'doctor', // الطبيب بيرد
                  chatTitle: name, // اسم المريض يظهر فوق
                  isOnline: true,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFamilyList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 1, // مثال
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final name = 'Emily Smith';
        return _ChatItem(
          name: name,
          subtitle: 'Family Member',
          lastMessage: 'She\'s doing well, thank you!',
          time: '10:17 AM',
          isOnline: false,
          avatar: Icons.family_restroom,
          color: AppTheme.cyan500,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FamilyChatScreen(
                  currentSender: 'doctor', // الطبيب بيرد
                  chatTitle: name, // اسم فرد العائلة يظهر فوق
                  isOnline: false,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ChatItem extends StatelessWidget {
  final String name;
  final String subtitle;
  final String lastMessage;
  final String time;
  final bool isOnline;
  final IconData avatar;
  final Color color;
  final VoidCallback onTap;

  const _ChatItem({
    required this.name,
    required this.subtitle,
    required this.lastMessage,
    required this.time,
    required this.isOnline,
    required this.avatar,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(avatar, color: color, size: 28),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
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
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.teal900,
                            ),
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
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.gray500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lastMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.gray600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
