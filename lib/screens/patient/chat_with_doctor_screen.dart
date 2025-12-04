import 'dart:async';
import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/supabase/chat_service.dart';
import '../../core/supabase/message_service.dart';
import '../../core/supabase/chat_file_service.dart';
import '../../core/supabase/supabase-config.dart';
import '../../core/supabase/supabase-service.dart';
import '../../theme/app_theme.dart';
import '../services/chat_manager.dart';

class ChatWithDoctorScreen extends StatefulWidget {
  const ChatWithDoctorScreen({
    super.key,
    this.chatId,
    this.currentSender = 'patient',
    this.chatTitle = 'Dr. Sarah Johnson',
    this.isOnline = true,
  });

  final String? chatId;
  final String currentSender;
  final String chatTitle;
  final bool isOnline;

  @override
  State<ChatWithDoctorScreen> createState() => _ChatWithDoctorScreenState();
}

class _ChatWithDoctorScreenState extends State<ChatWithDoctorScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatManager _chatManager = ChatManager();
  final ChatService _chatService = ChatService();
  final MessageService _messageService = MessageService();
  final ChatFileService _fileService = ChatFileService();
  final PatientService _patientService = PatientService();
  final UserService _userService = UserService();

  String? _chatId;
  String? _userId;
  String? _senderType;
  String? _doctorName;
  List<ChatMessage> _messages = [];
  StreamSubscription<List<ChatMessage>>? _sub;
  bool _loading = true;
  bool _sending = false;

  bool get _isAr =>
      (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ar';

  String tr(String en, String ar) => _isAr ? ar : en;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() => _loading = true);
    try {
      // Use auth.uid() for sender_id (required by RLS policy)
      _userId = SupabaseConfig.client.auth.currentUser?.id;
      
      if (_userId == null) {
        setState(() => _loading = false);
        return;
      }

      // Determine sender type
      _senderType = widget.currentSender == 'doctor' ? 'doctor' : 'patient';

      // Get or create chat
      if (widget.chatId != null) {
        _chatId = widget.chatId;
        _doctorName = widget.chatTitle;
      } else {
        // Get patient_id and doctor_id
        final patientData = await _patientService.getPatientByUserId(_userId!);
        if (patientData == null) {
          setState(() => _loading = false);
          return;
        }

        final patientId = patientData['id'] as String;
        final doctorId = (patientData['doctor_id'] as String?)?.trim();
        
        if (doctorId == null || doctorId.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(tr('No doctor linked to this patient', 'لا يوجد طبيب مرتبط بالمريض')),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _loading = false);
          return;
        }

        final doctorUser = await _userService.getUser(doctorId);
        _doctorName = (doctorUser?['name'] as String?)?.trim().isNotEmpty == true
            ? doctorUser!['name'] as String
            : widget.chatTitle;

        final chat = await _chatService.getOrCreateChat(
          doctorId: doctorId,
          patientId: patientId,
        );
        _chatId = chat['id'] as String;
      }

      // Load messages
      await _loadMessages();

      // Subscribe to realtime
      _chatManager.subscribeToRealtime(_chatId!, (message) {
        if (mounted) {
          setState(() => _messages = _chatManager.getMessages(_chatId!));
          _scrollToBottom();
        }
      });

      // Mark as read
      await _messageService.markChatAsRead(_chatId!, _userId!);

      // Watch messages stream
      _sub = _chatManager.watchMessages(_chatId!).listen((msgs) {
        if (mounted) {
          setState(() => _messages = msgs);
          _scrollToBottom();
        }
      });
    } catch (e) {
      debugPrint('Error initializing chat: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_chatId == null) return;

    try {
      final messagesData = await _messageService.getMessages(chatId: _chatId!);
      final messages = messagesData
          .map((m) => ChatMessage.fromSupabase(m))
          .toList();
      
      _chatManager.initializeChat(_chatId!, messages);
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatId == null || _userId == null || _senderType == null) return;

    final content = _messageController.text.trim();
    _messageController.clear();
    setState(() => _sending = true);

    try {
      debugPrint('=== SENDING MESSAGE DEBUG ===');
      debugPrint('chatId: $_chatId');
      debugPrint('senderId: $_userId');
      debugPrint('senderType: $_senderType');
      debugPrint('auth.uid: ${SupabaseConfig.client.auth.currentUser?.id}');
      
      // Debug: check conversation details
      try {
        final conv = await SupabaseConfig.client
            .from('chat_conversations')
            .select('id, doctor_id, patient_id, family_member_id, is_active')
            .eq('id', _chatId!)
            .maybeSingle();
        debugPrint('Conversation: $conv');
      } catch (e) {
        debugPrint('Error fetching conversation: $e');
      }
      
      await _messageService.sendTextMessage(
        chatId: _chatId!,
        senderId: _userId!,
        senderType: _senderType!,
        content: content,
      );
      // Realtime will update the UI automatically
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Failed to send message', 'فشل إرسال الرسالة')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _sendFile(File file, String messageType) async {
    if (_chatId == null || _userId == null || _senderType == null) return;

    setState(() => _sending = true);

    try {
      // Upload file
      final fileUrl = await _fileService.uploadFile(
        file: file,
        chatId: _chatId!,
        senderId: _userId!,
      );

      final fileName = _fileService.getFileName(file);
      final fileSize = await _fileService.getFileSize(file);

      // Send message
      await _messageService.sendFileMessage(
        chatId: _chatId!,
        senderId: _userId!,
        senderType: _senderType!,
        fileUrl: fileUrl,
        messageType: messageType,
        fileName: fileName,
        fileSize: fileSize,
      );
    } catch (e) {
      debugPrint('Error sending file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Failed to send file', 'فشل إرسال الملف')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      await _sendFile(File(picked.path), 'image');
    }
  }

  Future<void> _pickFile() async {
    // TODO: Implement file picker when file_picker package is added
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('File picker not available yet', 'اختيار الملف غير متاح بعد')),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: AppTheme.teal600),
              title: Text(tr('Send Image', 'إرسال صورة')),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: AppTheme.teal600),
              title: Text(tr('Send File', 'إرسال ملف')),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: EmojiPicker(
          onEmojiSelected: (category, emoji) {
            _messageController.text += emoji.emoji;
            setState(() {});
          },
          onBackspacePressed: () {
            _messageController
              ..text = _messageController.text.characters.skipLast(1).toString()
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: _messageController.text.length),
              );
          },
          config: const Config(
            height: 256,
            checkPlatformCompatibility: true,
            emojiViewConfig: EmojiViewConfig(
              columns: 7,
              emojiSizeMax: 28,
              verticalSpacing: 0,
              horizontalSpacing: 0,
              backgroundColor: Colors.white,
              noRecents: Text(
                'No Recents',
                style: TextStyle(fontSize: 20, color: Colors.black26),
                textAlign: TextAlign.center,
              ),
            ),
            skinToneConfig: SkinToneConfig(enabled: false),
            categoryViewConfig: CategoryViewConfig(
              iconColor: AppTheme.gray500,
              iconColorSelected: AppTheme.teal500,
              backgroundColor: Colors.white,
            ),
            bottomActionBarConfig: BottomActionBarConfig(enabled: false),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isMe = message.sender == _senderType;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.teal500,
                child: Icon(Icons.person, color: Colors.white, size: 16),
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.cyan100 : AppTheme.teal500,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: _buildMessageContent(message, isMe),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.time,
                      style: const TextStyle(fontSize: 11, color: AppTheme.gray500),
                    ),
                    if (isMe && message.isRead) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all, size: 14, color: AppTheme.teal600),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message, bool isMe) {
    if (message.messageType == 'image') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.fileUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                message.fileUrl!,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              ),
            ),
          if (message.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? AppTheme.teal900 : Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ],
      );
    } else if (message.messageType == 'file') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_file, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.fileName ?? tr('File', 'ملف'),
              style: TextStyle(
                color: isMe ? AppTheme.teal900 : Colors.white,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      return Text(
        message.text,
        style: TextStyle(
          color: isMe ? AppTheme.teal900 : Colors.white,
          fontSize: 14,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _doctorName ?? widget.chatTitle;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(titleText),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final statusDotColor = widget.isOnline ? Colors.green : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
                      color: statusDotColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  widget.isOnline ? tr('Online', 'متصل') : tr('Offline', 'غير متصل'),
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isOnline ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
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
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        tr('No messages yet. Start the conversation!',
                            'لا توجد رسائل بعد. ابدأ المحادثة!'),
                        style: TextStyle(color: AppTheme.gray500),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessage(_messages[index]);
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
                    onPressed: _showAttachmentOptions,
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
                              decoration: InputDecoration(
                                hintText: tr('Type a message...', 'اكتب رسالة...'),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          IconButton(
                            onPressed: _showEmojiPicker,
                            icon: const Icon(Icons.emoji_emotions_outlined),
                            color: AppTheme.gray500,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _messageController.text.trim().isEmpty || _sending
                        ? null
                        : _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: _messageController.text.trim().isEmpty || _sending
                            ? LinearGradient(colors: [
                                AppTheme.teal500.withOpacity(0.5),
                                AppTheme.teal600.withOpacity(0.5),
                              ])
                            : AppTheme.tealGradient,
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
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
    _sub?.cancel();
    if (_chatId != null) {
      _chatManager.disposeRealtime(_chatId!);
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
