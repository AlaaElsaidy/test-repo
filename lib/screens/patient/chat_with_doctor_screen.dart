import 'dart:async';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../services/chat_manager.dart';

class ChatWithDoctorScreen extends StatefulWidget {
  const ChatWithDoctorScreen({
    super.key,
    this.currentSender = 'patient', // المرسل الحالي
    this.chatTitle = 'Dr. Sarah Johnson', // اسم يُعرض في العنوان
    this.isOnline = true, // حالة الأونلاين
  });

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
  final String _chatId = 'patient_doctor'; // معرف المحادثة

  List<ChatMessage> _messages = [];
  StreamSubscription<List<ChatMessage>>? _sub;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    _chatManager.initializeChat(
      _chatId,
      [
        ChatMessage(
            sender: 'doctor',
            text: 'Good morning Margaret! How are you feeling today?',
            time: _chatManager.getCurrentTime()),
        ChatMessage(
            sender: 'patient',
            text: 'Good morning Dr. Johnson! I\'m feeling good today.',
            time: _chatManager.getCurrentTime()),
        ChatMessage(
            sender: 'doctor',
            text:
                'That\'s wonderful to hear! Did you complete your memory exercises?',
            time: _chatManager.getCurrentTime()),
      ],
    );

    _sub = _chatManager.watchMessages(_chatId).listen((msgs) {
      if (!mounted) return;
      setState(() => _messages = msgs);
      _scrollToBottom();
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = ChatMessage(
      sender: widget.currentSender, // مرسل ديناميكي
      text: _messageController.text.trim(),
      time: _chatManager.getCurrentTime(),
    );

    _chatManager.addMessage(_chatId, newMessage);
    _messageController.clear();
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

  @override
  Widget build(BuildContext context) {
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
                  widget.chatTitle, // اسم ديناميكي
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
                  end: Alignment.bottomRight,
                ),
              ),
              child: ListView.builder(
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
                  final isDoctor = message.sender == 'doctor';

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
                                  color: Colors.white, size: 16),
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
                                child: Text(
                                  message.text,
                                  style: TextStyle(
                                      color: isDoctor
                                          ? Colors.white
                                          : AppTheme.teal900,
                                      fontSize: 14),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(message.time,
                                  style: const TextStyle(
                                      fontSize: 11, color: AppTheme.gray500)),
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
                    onTap: _messageController.text.trim().isEmpty
                        ? null
                        : _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: _messageController.text.trim().isEmpty
                            ? LinearGradient(colors: [
                                AppTheme.teal500.withOpacity(0.5),
                                AppTheme.teal600.withOpacity(0.5)
                              ])
                            : AppTheme.tealGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
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
    super.dispose();
  }
}