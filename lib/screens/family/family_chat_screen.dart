import 'dart:async';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../services/chat_manager.dart';

class FamilyChatScreen extends StatefulWidget {
  const FamilyChatScreen({
    super.key,
    this.currentSender = 'family',
    this.chatTitle = '',
    this.isOnline = true,
    this.recipientId = '',
    this.currentUserId = '',
    this.currentUserName = 'Family Member',
  });

  final String currentSender;
  final String chatTitle;
  final bool isOnline;
  final String recipientId; // ID الدكتور
  final String currentUserId; // ID فرد العائلة الحالي
  final String currentUserName; // اسم فرد العائلة

  @override
  State<FamilyChatScreen> createState() => _FamilyChatScreenState();
}

class _FamilyChatScreenState extends State<FamilyChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatManager _chatManager = ChatManager();
  late final String _chatId;

  List<ChatMessage> _messages = [];
  StreamSubscription<List<ChatMessage>>? _sub;
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _chatId = _generateChatId(widget.currentUserId, widget.recipientId);
    print('DEBUG Family Chat ID: $_chatId');
    print('DEBUG Family Sender ID: ${widget.currentUserId}');
    print('DEBUG Family Recipient ID: ${widget.recipientId}');
    _initializeChat();
  }

  String _generateChatId(String userId1, String userId2) {
    final ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  void _initializeChat() {
    // استخدم polling بدل الـ stream العادي
    _sub = Stream.periodic(const Duration(milliseconds: 500))
        .asyncMap((_) async {
          return await _chatManager.watchMessages(_chatId).first;
        })
        .listen((msgs) {
          if (!mounted) return;
          setState(() => _messages = msgs);
          _scrollToBottom();
        });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      await _chatManager.addMessage(
        chatId: _chatId,
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        senderType: widget.currentSender,
        receiverId: widget.recipientId,
        receiverType: widget.currentSender == 'doctor' ? 'family' : 'doctor',
        messageText: _messageController.text.trim(),
      );
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.defaultError ?? 'Error sending message')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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
                offset: const Offset(0, -5)),
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
                  TextPosition(offset: _messageController.text.length));
          },
          config: const Config(
            height: 256,
            emojiViewConfig: EmojiViewConfig(
              columns: 7,
              emojiSizeMax: 28,
              verticalSpacing: 0,
              horizontalSpacing: 0,
              backgroundColor: Colors.white,
              noRecents: Text('No Recents',
                  style: TextStyle(fontSize: 20, color: Colors.black26),
                  textAlign: TextAlign.center),
            ),
            skinToneConfig: SkinToneConfig(enabled: false),
            categoryViewConfig: CategoryViewConfig(
              iconColor: AppTheme.gray500,
              iconColorSelected: AppTheme.teal500,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusDotColor = widget.isOnline ? Colors.green : Colors.grey;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.teal500,
                    child: Icon(Icons.person, color: Colors.white)),
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
                  widget.chatTitle.isEmpty ? 'Chat' : widget.chatTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  widget.isOnline ? 'Online' : 'Offline',
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
                    end: Alignment.bottomRight),
              ),
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        localizations?.noContent ?? 'No messages yet',
                        style: const TextStyle(color: AppTheme.gray500),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                  color: AppTheme.gray200,
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Text('Today',
                                  style: TextStyle(
                                      fontSize: 12, color: AppTheme.gray600)),
                            ),
                          );
                        }

                        final message = _messages[index - 1];
                        final isDoctor = message.senderType == 'doctor';

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
                                      child: Icon(Icons.person,
                                          color: Colors.white, size: 16)),
                                ),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: isDoctor
                                      ? CrossAxisAlignment.start
                                      : CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isDoctor
                                            ? AppTheme.teal500
                                            : AppTheme.cyan100,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft:
                                              Radius.circular(isDoctor ? 4 : 16),
                                          bottomRight:
                                              Radius.circular(isDoctor ? 16 : 4),
                                        ),
                                      ),
                                      child: Text(message.text,
                                          style: TextStyle(
                                              color: isDoctor
                                                  ? Colors.white
                                                  : AppTheme.teal900,
                                              fontSize: 14)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(message.time,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.gray500)),
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
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5))
            ]),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.attach_file),
                      color: AppTheme.teal600),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                          color: AppTheme.gray100,
                          borderRadius: BorderRadius.circular(24)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                  hintText: 'Type a message...',
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 12)),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          IconButton(
                              onPressed: _showEmojiPicker,
                              icon: const Icon(Icons.emoji_emotions_outlined),
                              color: AppTheme.gray500),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: (_messageController.text.trim().isEmpty || _isSending)
                        ? null
                        : _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: (_messageController.text.trim().isEmpty ||
                                _isSending)
                            ? LinearGradient(colors: [
                                AppTheme.teal500.withOpacity(0.5),
                                AppTheme.teal600.withOpacity(0.5)
                              ])
                            : AppTheme.tealGradient,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
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
    _messageController.dispose();
    _scrollController.dispose();
    _chatManager.disposeChat(_chatId);
    super.dispose();
  }
}