import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import 'chat_with_doctor_screen.dart';
import 'live_tracking_screen.dart';
import 'memory_activities_screen.dart';
import 'patient_dashboard.dart';
import 'patient_profile_screen.dart' show PatientProfileScreen, Patient, EmergencyContact;

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  int _currentIndex = 0;

  late final Patient? _patient;
  late final String _currentPatientId;
  late String _assignedDoctorId = '';
  late String _assignedDoctorName = 'Dr. Sarah Johnson';
  late final List<Widget> _screens;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  void _loadPatientData() async {
    final user = Supabase.instance.client.auth.currentUser;
    
    _patient = const Patient(
      name: 'Margaret Smith',
      age: 72,
      phone: '+1 (555) 123-4567',
      email: 'margaret.smith@email.com',
      address: '123 Oak Street, Springfield',
      emergencyContact: EmergencyContact(
        name: 'Emily Smith',
        relation: 'Daughter',
        phone: '+1 (555) 987-6543',
      ),
    );

    _currentPatientId = user?.id ?? '';

    // جيب الدكتور المعين للمريض من Supabase
    await _fetchAssignedDoctor(_currentPatientId);

    _screens = [
      const PatientDashboard(),
      const MemoryActivitiesScreen(),
      const LiveTrackingScreen(),
      // تمرير الـ parameters للشات
      ChatWithDoctorScreen(
        currentSender: 'patient',
        chatTitle: _assignedDoctorName,
        isOnline: true,
        recipientId: _assignedDoctorId,
        currentUserId: _currentPatientId,
        currentUserName: _patient!.name,
      ),
      PatientProfileScreen(patient: _patient as Patient?),
    ];

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchAssignedDoctor(String patientId) async {
    try {
      print('DEBUG: Fetching doctor for patient: $patientId');
      
      // اجلب بيانات المريض مع الدكتور المعين
      final patientData = await Supabase.instance.client
          .from('patients')
          .select('id, name, doctor_id')
          .eq('id', patientId)
          .single();

      print('DEBUG: Patient data: $patientData');

      final doctorId = patientData['doctor_id'];
      print('DEBUG: Doctor ID from patient: $doctorId');

      if (doctorId != null && doctorId.isNotEmpty) {
        // اجلب بيانات الدكتور
        final doctorData = await Supabase.instance.client
            .from('doctors')
            .select('id, name')
            .eq('id', doctorId)
            .single();

        print('DEBUG: Doctor data: $doctorData');

        _assignedDoctorId = doctorData['id'];
        _assignedDoctorName = doctorData['name'] ?? 'Dr. Sarah Johnson';
        
        print('DEBUG: Assigned doctor ID: $_assignedDoctorId');
        print('DEBUG: Assigned doctor name: $_assignedDoctorName');
      } else {
        print('DEBUG: No doctor assigned to patient');
        _assignedDoctorId = '';
        _assignedDoctorName = 'Dr. Sarah Johnson';
      }
    } catch (e) {
      print('Error fetching assigned doctor: $e');
      // قيم افتراضية في حالة الفشل
      _assignedDoctorId = '';
      _assignedDoctorName = 'Dr. Sarah Johnson';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.lightGradient,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.teal500),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.lightGradient,
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
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