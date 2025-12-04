// lib/screens/doctor/doctor_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/shared-prefrences/shared-prefrences-helper.dart';
import '../../core/supabase/chat_service.dart';
import '../../core/supabase/message_service.dart';
import '../../core/supabase/supabase-config.dart';
import '../../screens/family/family_chat_screen.dart';
import '../../screens/patient/chat_with_doctor_screen.dart';
import '../../theme/app_theme.dart';

class DoctorChatScreen extends StatefulWidget {
  const DoctorChatScreen({super.key});

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  final ChatService _chatService = ChatService();
  final MessageService _messageService = MessageService();
  
  String? _doctorId;
  List<Map<String, dynamic>> _patientChats = [];
  List<Map<String, dynamic>> _familyChats = [];
  bool _loading = true;
  Map<String, int> _unreadCounts = {};

  bool get _isAr =>
      (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ar';

  String tr(String en, String ar) => _isAr ? ar : en;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _loading = true);
    try {
      // Use auth.uid() for consistency with RLS policies
      _doctorId = SupabaseConfig.client.auth.currentUser?.id ??
          SharedPrefsHelper.getString("userId") ??
          SharedPrefsHelper.getString("doctorUid");
      
      if (_doctorId == null) {
        setState(() => _loading = false);
        return;
      }

      final chats = await _chatService.getChatsForDoctor(_doctorId!);
      
      // Separate patient and family chats
      _patientChats = chats.where((chat) => chat['patient_id'] != null).toList();
      _familyChats = chats.where((chat) => chat['family_member_id'] != null).toList();

      // Load unread counts
      for (final chat in chats) {
        final chatId = chat['id'] as String;
        final count = await _messageService.getUnreadCount(chatId, _doctorId!);
        _unreadCounts[chatId] = count;
      }
    } catch (e) {
      debugPrint('Error loading chats: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return DateFormat('h:mm a').format(dateTime);
      } else if (difference.inDays == 1) {
        return tr('Yesterday', 'أمس');
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE').format(dateTime);
      } else {
        return DateFormat('MMM d').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  String _getChatName(Map<String, dynamic> chat) {
    if (chat['patient_id'] != null) {
      final patient = chat['patients'] as Map<String, dynamic>?;
      return patient?['name'] as String? ?? tr('Patient', 'مريض');
    } else if (chat['family_member_id'] != null) {
      final family = chat['family_members'] as Map<String, dynamic>?;
      return family?['name'] as String? ?? tr('Family Member', 'فرد العائلة');
    }
    return tr('Unknown', 'غير معروف');
  }

  Future<void> _deleteChat(String chatId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Delete Chat', 'حذف المحادثة')),
        content: Text(tr(
          'Are you sure you want to delete this chat?',
          'هل أنت متأكد أنك تريد حذف هذه المحادثة؟',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Cancel', 'إلغاء')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(tr('Delete', 'حذف')),
          ),
        ],
      ),
    );

    if (confirm == true && _doctorId != null) {
      try {
        await _chatService.deleteChat(chatId, _doctorId!);
        await _loadChats();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('Chat deleted', 'تم حذف المحادثة'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('Failed to delete chat', 'فشل حذف المحادثة')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

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
                  Expanded(
                    child: Text(
                      tr('Messages', 'الرسائل'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadChats,
                    icon: const Icon(Icons.refresh),
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
              child: TabBar(
                labelColor: AppTheme.teal600,
                unselectedLabelColor: AppTheme.gray500,
                indicatorColor: AppTheme.teal500,
                tabs: [
                  Tab(text: tr('Patients', 'المرضى')),
                  Tab(text: tr('Families', 'العائلة')),
                ],
              ),
            ),

            // Chat Lists
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
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
    if (_patientChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: AppTheme.gray500),
            const SizedBox(height: 16),
            Text(
              tr('No patient chats yet', 'لا توجد محادثات مع المرضى بعد'),
              style: TextStyle(color: AppTheme.gray500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _patientChats.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final chat = _patientChats[index];
          final chatId = chat['id'] as String;
          final name = _getChatName(chat);
          final lastMessage = chat['last_message_preview'] as String? ?? '';
          final lastMessageTime = chat['last_message_at'] as String?;
          final unreadCount = _unreadCounts[chatId] ?? 0;

          return Dismissible(
            key: Key(chatId),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: AlignmentDirectional.centerEnd,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => _deleteChat(chatId),
            child: _ChatItem(
              name: name,
              subtitle: tr('Patient', 'مريض'),
              lastMessage: lastMessage,
              time: _formatTime(lastMessageTime),
              isOnline: false, // TODO: Add online status
              avatar: Icons.person,
              color: AppTheme.teal500,
              unreadCount: unreadCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatWithDoctorScreen(
                      chatId: chatId,
                      currentSender: 'doctor',
                      chatTitle: name,
                      isOnline: false,
                    ),
                  ),
                ).then((_) => _loadChats());
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFamilyList(BuildContext context) {
    if (_familyChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.family_restroom,
                size: 64, color: AppTheme.gray500),
            const SizedBox(height: 16),
            Text(
              tr('No family chats yet', 'لا توجد محادثات مع العائلة بعد'),
              style: TextStyle(color: AppTheme.gray500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _familyChats.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final chat = _familyChats[index];
          final chatId = chat['id'] as String;
          final name = _getChatName(chat);
          final lastMessage = chat['last_message_preview'] as String? ?? '';
          final lastMessageTime = chat['last_message_at'] as String?;
          final unreadCount = _unreadCounts[chatId] ?? 0;

          return Dismissible(
            key: Key(chatId),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: AlignmentDirectional.centerEnd,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => _deleteChat(chatId),
            child: _ChatItem(
              name: name,
              subtitle: tr('Family Member', 'فرد العائلة'),
              lastMessage: lastMessage,
              time: _formatTime(lastMessageTime),
              isOnline: false, // TODO: Add online status
              avatar: Icons.family_restroom,
              color: AppTheme.cyan500,
              unreadCount: unreadCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FamilyChatScreen(
                      chatId: chatId,
                      currentSender: 'doctor',
                      chatTitle: name,
                      isOnline: false,
                    ),
                  ),
                ).then((_) => _loadChats());
              },
            ),
          );
        },
      ),
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
  final int unreadCount;
  final VoidCallback onTap;

  const _ChatItem({
    required this.name,
    required this.subtitle,
    required this.lastMessage,
    required this.time,
    required this.isOnline,
    required this.avatar,
    required this.color,
    this.unreadCount = 0,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.gray600,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.teal600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
