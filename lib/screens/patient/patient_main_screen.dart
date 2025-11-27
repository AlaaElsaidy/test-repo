import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/shared-prefrences/shared-prefrences-helper.dart';
import '../../services/lobna/lobna_voice_controller.dart';
import '../../services/lobna/activity_reminder_service.dart';
import '../../services/lobna/prompts/lobna_dialect_adapter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lobna_listen_button.dart';
import '../services/chat_manager.dart';
import 'lobna_text_chat_screen.dart';
import 'chat_with_doctor_screen.dart';
import 'live_tracking_screen.dart';
import 'memory_activities_screen.dart';
import 'patient_dashboard.dart';
import 'patient_profile_screen.dart'; // ADDED: نحتاجه عشان نمرّر Patient

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  int _currentIndex = 0;

  // Initialize immediately - no late variables
  final Patient _patient = const Patient(
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

  // Initialize immediately - no late variables
  final LobnaVoiceController _voiceController = LobnaVoiceController();
  final ChatManager _chatManager = ChatManager();
  final ActivityReminderService _reminderService =
      ActivityReminderService.instance;
  static const _lobnaChatId = 'lobna-lenny-thread';

  // Initialize screens in initState - late final ensures initialization happens after constructor
  late final List<Widget> _screens;
  StreamSubscription<ActivityReminder>? _reminderSub;

  @override
  void initState() {
    super.initState();
    // Build screens in initState after super.initState() to ensure all dependencies are ready
    // This guarantees _voiceController and _patient are fully initialized
    _screens = [
      const PatientDashboard(),
      const MemoryActivitiesScreen(),
      LiveTrackingScreen(voiceController: _voiceController),
      const ChatWithDoctorScreen(),
      PatientProfileScreen(patient: _patient),
    ];

    _reminderSub = _reminderService.onReminderDue.listen(_handleReminderTrigger);
  }

  @override
  void dispose() {
    _reminderSub?.cancel();
    _voiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.lightGradient,
        ),
        // CHANGED: IndexedStack لحفظ حالة كل تبويب بدل ما يعاد بناؤه كل مرة
        // _screens is guaranteed to be initialized in initState() before build() is called
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
              color: Colors.black.withValues(alpha: 0.05),
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'lobnaTextChat',
            mini: true,
            onPressed: _openTextChat,
            child: const Icon(Icons.chat),
          ),
          const SizedBox(height: 12),
          LobnaListenButton(
            controller: _voiceController,
            onTranscript: _handleTranscript,
            onReplyRequested: _handleAssistantReply,
            chatManager: _chatManager,
            chatId: _lobnaChatId,
            patientId: SharedPrefsHelper.getString("patientUid") ?? 
                      SharedPrefsHelper.getString("userId"),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _handleTranscript(String text) {
    _chatManager.addMessage(
      _lobnaChatId,
      ChatMessage(
        sender: 'patient',
        text: text,
        time: _chatManager.getCurrentTime(),
      ),
    );
  }

  Future<String?> _handleAssistantReply(String transcript) async {
    final reply = await _voiceController.generateAssistantReply(transcript);
    _chatManager.addMessage(
      _lobnaChatId,
      ChatMessage(
        sender: 'lobna',
        text: reply,
        time: _chatManager.getCurrentTime(),
      ),
    );
    return reply;
  }

  Future<void> _handleReminderTrigger(ActivityReminder reminder) async {
    // تحسين النص باللهجة المصرية
    final timeParts = reminder.time24h.split(':');
    final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 8 : 8;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
    final time12h = hour > 12 
        ? '${hour - 12}:${minute.toString().padLeft(2, '0')}'
        : '$hour:${minute.toString().padLeft(2, '0')}';
    final amPm = hour >= 12 ? 'بعد الظهر' : 'الصبح';
    
    final bodyText = reminder.body.isNotEmpty 
        ? reminder.body 
        : 'لو سمحت استعد للنشاط دلوقتي.';
    
    final message = LobnaDialectAdapter.ensureMasri(
        'عندنا نشاط دلوقتي! النشاط "$reminder.title" هيبدأ الساعة $time12h $amPm. $bodyText');
    
    _chatManager.addMessage(
      _lobnaChatId,
      ChatMessage(
        sender: 'lobna',
        text: message,
        time: _chatManager.getCurrentTime(),
      ),
    );
    await _voiceController.speak(message);
  }

  void _openTextChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LobnaTextChatScreen(
          chatManager: _chatManager,
          voiceController: _voiceController,
          chatId: _lobnaChatId,
          patientId: SharedPrefsHelper.getString("patientUid") ??
              SharedPrefsHelper.getString("userId"),
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