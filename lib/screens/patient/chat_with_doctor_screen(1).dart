import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ChatWithDoctorScreen extends StatefulWidget {
  const ChatWithDoctorScreen({super.key});

  @override
  State<ChatWithDoctorScreen> createState() => _ChatWithDoctorScreenState();
}

class _ChatWithDoctorScreenState extends State<ChatWithDoctorScreen> {
  final TextEditingController _messageController = TextEditingController();
  
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'doctor',
      'text': 'Good morning Margaret! How are you feeling today?',
      'time': '9:30 AM',
    },
    {
      'sender': 'patient',
      'text': 'Good morning Dr. Johnson! I\'m feeling good today.',
      'time': '9:32 AM',
    },
    {
      'sender': 'doctor',
      'text': 'That\'s wonderful to hear! Did you complete your memory exercises?',
      'time': '9:33 AM',
    },
    {
      'sender': 'patient',
      'text': 'Yes! I finished 4 activities this morning. The photo memory one was my favorite.',
      'time': '9:35 AM',
    },
    {
      'sender': 'doctor',
      'text': 'Excellent work! Keep up the great progress.',
      'time': '9:36 AM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.teal500,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. Sarah Johnson',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF0FDFA), Color(0xFFECFEFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.gray200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.gray600,
                          ),
                        ),
                      ),
                    );
                  }
                  
                  final message = _messages[index - 1];
                  final isDoctor = message['sender'] == 'doctor';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isDoctor
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isDoctor)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.teal500,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isDoctor
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isDoctor
                                      ? AppTheme.teal500
                                      : AppTheme.cyan100,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isDoctor ? 4 : 16),
                                    bottomRight: Radius.circular(isDoctor ? 16 : 4),
                                  ),
                                ),
                                child: Text(
                                  message['text'],
                                  style: TextStyle(
                                    color: isDoctor
                                        ? Colors.white
                                        : AppTheme.teal900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message['time'],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.gray500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.attach_file),
                    color: AppTheme.teal600,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.gray100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.emoji_emotions_outlined),
                            color: AppTheme.gray500,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.tealGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.send),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
