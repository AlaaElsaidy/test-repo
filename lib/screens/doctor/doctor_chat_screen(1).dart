import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DoctorChatScreen extends StatelessWidget {
  const DoctorChatScreen({super.key});

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
            child: DefaultTabController(
              length: 3,
              child: const TabBar(
                labelColor: AppTheme.teal600,
                unselectedLabelColor: AppTheme.gray500,
                indicatorColor: AppTheme.teal500,
                tabs: [
                  Tab(text: 'Patients'),
                  Tab(text: 'Families'),
                  Tab(text: 'Groups'),
                ],
              ),
            ),
          ),

          // Chat List
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.lightGradient,
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ChatItem(
                    name: 'Margaret Smith',
                    message: 'Thank you doctor! I completed the activities.',
                    time: '10:30 AM',
                    unread: 2,
                    isOnline: true,
                    avatar: Icons.person,
                    color: AppTheme.teal500,
                  ),
                  const SizedBox(height: 12),
                  _ChatItem(
                    name: 'Emily Smith (Family)',
                    message: 'Could we schedule a call to discuss progress?',
                    time: 'Yesterday',
                    unread: 0,
                    isOnline: false,
                    avatar: Icons.family_restroom,
                    color: AppTheme.cyan500,
                  ),
                  const SizedBox(height: 12),
                  _ChatItem(
                    name: 'John Davis',
                    message: 'I forgot to take my morning medication',
                    time: 'Yesterday',
                    unread: 1,
                    isOnline: false,
                    avatar: Icons.person,
                    color: AppTheme.teal500,
                  ),
                  const SizedBox(height: 12),
                  _ChatItem(
                    name: 'Support Group - Caregivers',
                    message: 'Dr. Johnson: That\'s a great question...',
                    time: '2 days ago',
                    unread: 0,
                    isOnline: true,
                    avatar: Icons.groups,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _ChatItem(
                    name: 'Mary Taylor',
                    message: 'Feeling much better today!',
                    time: '3 days ago',
                    unread: 0,
                    isOnline: false,
                    avatar: Icons.person,
                    color: AppTheme.teal500,
                  ),
                  const SizedBox(height: 12),
                  _ChatItem(
                    name: 'Robert Brown (Family)',
                    message: 'Thank you for the advice',
                    time: '4 days ago',
                    unread: 0,
                    isOnline: false,
                    avatar: Icons.family_restroom,
                    color: AppTheme.cyan500,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatItem extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final int unread;
  final bool isOnline;
  final IconData avatar;
  final Color color;

  const _ChatItem({
    required this.name,
    required this.message,
    required this.time,
    required this.unread,
    required this.isOnline,
    required this.avatar,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _ChatConversationScreen(
                name: name,
                isOnline: isOnline,
                avatar: avatar,
                color: color,
              ),
            ),
          );
        },
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              fontSize: 14,
                              color: unread > 0
                                  ? AppTheme.teal900
                                  : AppTheme.gray600,
                              fontWeight: unread > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.teal500,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
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

class _ChatConversationScreen extends StatefulWidget {
  final String name;
  final bool isOnline;
  final IconData avatar;
  final Color color;

  const _ChatConversationScreen({
    required this.name,
    required this.isOnline,
    required this.avatar,
    required this.color,
  });

  @override
  State<_ChatConversationScreen> createState() =>
      _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<_ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'patient',
      'text': 'Good morning Dr. Johnson!',
      'time': '9:30 AM',
    },
    {
      'sender': 'doctor',
      'text': 'Good morning! How are you feeling today?',
      'time': '9:32 AM',
    },
    {
      'sender': 'patient',
      'text': 'I\'m feeling good! I completed 4 activities this morning.',
      'time': '9:35 AM',
    },
    {
      'sender': 'doctor',
      'text': 'That\'s wonderful! Keep up the great work.',
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: widget.color.withOpacity(0.2),
                  child: Icon(widget.avatar, color: widget.color, size: 20),
                ),
                if (widget.isOnline)
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  widget.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isOnline ? Colors.green : AppTheme.gray500,
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
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isDoctor)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: widget.color.withOpacity(0.2),
                              child: Icon(
                                widget.avatar,
                                color: widget.color,
                                size: 16,
                              ),
                            ),
                          ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isDoctor
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isDoctor
                                      ? AppTheme.teal500
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft:
                                        Radius.circular(isDoctor ? 16 : 4),
                                    bottomRight:
                                        Radius.circular(isDoctor ? 4 : 16),
                                  ),
                                  boxShadow: isDoctor
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
                                    color:
                                        isDoctor ? Colors.white : AppTheme.teal900,
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
