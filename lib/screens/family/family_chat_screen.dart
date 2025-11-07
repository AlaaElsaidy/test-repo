import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FamilyChatScreen extends StatefulWidget {
  const FamilyChatScreen({super.key});

  @override
  State<FamilyChatScreen> createState() => _FamilyChatScreenState();
}

class _FamilyChatScreenState extends State<FamilyChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'patient',
      'text': 'Hi Emily! I just finished my morning activities.',
      'time': '9:30 AM',
    },
    {
      'sender': 'family',
      'text': 'That\'s wonderful Mom! I\'m so proud of you!',
      'time': '9:32 AM',
    },
    {
      'sender': 'patient',
      'text': 'Thank you dear. When will you visit?',
      'time': '9:35 AM',
    },
    {
      'sender': 'family',
      'text': 'I\'ll be there tomorrow afternoon around 2 PM.',
      'time': '9:36 AM',
    },
    {
      'sender': 'patient',
      'text': 'Looking forward to seeing you! ❤️',
      'time': '9:38 AM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        color: AppTheme.teal500,
                        size: 28,
                      ),
                    ),
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Margaret Smith',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Online',
                        style: TextStyle(
                          color: Color(0xFFCFFAFE),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.phone),
                  color: Colors.white,
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.videocam),
                  color: Colors.white,
                ),
              ],
            ),
          ),

          // Quick Info Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.teal50,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.teal100,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'At Home',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 16,
                  color: AppTheme.teal200,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.task_alt,
                      size: 16,
                      color: AppTheme.teal600,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '8/12 Activities',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.teal600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 16,
                  color: AppTheme.teal200,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite,
                      size: 16,
                      color: Colors.pink,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Feeling Good',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.pink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Messages
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
                  final isFamily = message['sender'] == 'family';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isFamily
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isFamily)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.teal50,
                              child: Icon(
                                Icons.person,
                                color: AppTheme.teal500,
                                size: 16,
                              ),
                            ),
                          ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isFamily
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isFamily
                                      ? AppTheme.teal500
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft:
                                        Radius.circular(isFamily ? 16 : 4),
                                    bottomRight:
                                        Radius.circular(isFamily ? 4 : 16),
                                  ),
                                  boxShadow: isFamily
                                      ? []
                                      : [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 5,
                                          ),
                                        ],
                                ),
                                child: Text(
                                  message['text'],
                                  style: TextStyle(
                                    color: isFamily
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

          // Input Area
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
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 12),
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
