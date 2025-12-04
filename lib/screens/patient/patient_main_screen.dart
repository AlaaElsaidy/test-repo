import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../ai/lobna_voice_controller.dart';
import '../../widgets/lobna_listen_button.dart';
import 'live_tracking_screen.dart';
import 'memory_activities_screen.dart';
import 'patient_dashboard.dart';
import 'patient_profile_screen.dart';
import 'chat_with_doctor_screen.dart';
import 'lobna_chat_screen.dart';

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  int _currentIndex = 0;

  // ADDED: نموذج مريض تجريبي — تقدري تبدّليه بأي بيانات حقيقية أو توصليه بـ Provider/API
  late final Patient _patient;

  // CHANGED: بدل ما تبقى قائمة ثابتة، هنجهّزها في initState بعد بناء المريض
  late final List<Widget> _screens;
  late final LobnaVoiceController _lobnaController;

  @override
  void initState() {
    super.initState();

    // Initialize Lobna controller
      _lobnaController = LobnaVoiceController();
      _lobnaController.initialize();

    // ADDED: بيانات مريض افتراضية
    _patient = const Patient(
      name: 'Margaret Smith',
      age: 72,
      // مش بتظهر في الـ UI
      phone: '+1 (555) 123-4567',
      email: 'margaret.smith@email.com',
      address: '123 Oak Street, Springfield',
      emergencyContact: EmergencyContact(
        name: 'Emily Smith',
        relation: 'Daughter',
        phone: '+1 (555) 987-6543',
      ),
    );

    // ADDED: بناء الشاشات وتمرير المريض للبروفايل
    _screens = [
      const PatientDashboard(),
      const MemoryActivitiesScreen(),
      const LiveTrackingScreen(),
      const ChatWithDoctorScreen(), // الشات القديم مع الدكتور/العيلة
      PatientProfileScreen(patient: _patient), // ADDED: تمرير patient
    ];
  }

  @override
  void dispose() {
    _lobnaController.dispose();
    super.dispose();
  }

  void _openLobnaChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LobnaChatScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.lightGradient,
        ),
        // CHANGED: IndexedStack لحفظ حالة كل تبويب بدل ما يعاد بناؤه كل مرة
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      floatingActionButton: _currentIndex == 3
          ? null
          : LobnaListenButton(
              controller: _lobnaController,
              onTap: _openLobnaChat,
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home, 'Home'),
                _buildNavItem(1, Icons.psychology, 'Activities'),
                _buildNavItem(2, Icons.location_on, 'Tracking'),
                _buildNavItem(3, Icons.chat_bubble, 'Chat'),
                _buildNavItem(4, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.teal50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.teal600 : AppTheme.gray500,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppTheme.teal600 : AppTheme.gray500,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}