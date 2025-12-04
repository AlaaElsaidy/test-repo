import 'dart:async';
import 'package:flutter/material.dart';
import '../../ai/ai_chat_service.dart';
import '../../theme/app_theme.dart';

class LobnaChatScreen extends StatefulWidget {
  const LobnaChatScreen({
    super.key,
  });

  @override
  State<LobnaChatScreen> createState() => _LobnaChatScreenState();
}

class _LobnaChatScreenState extends State<LobnaChatScreen> {
  final AiChatService _chatService = AiChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  bool get _isAr =>
      (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ar';

  String tr(String en, String ar) => _isAr ? ar : en;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {}); // Update UI when text changes
    });
    
    // Add welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addMessage(ChatMessage(
        text: tr(
          'Hello! I\'m Lobna, your smart assistant. How can I help you today?',
          'مرحباً! أنا لبنى، مساعدتك الذكي. كيف يمكنني مساعدتك اليوم؟',
        ),
        isFromUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    // Add user message
    _addMessage(ChatMessage(
      text: text,
      isFromUser: true,
      timestamp: DateTime.now(),
    ));

    _messageController.clear();

    try {
      // Get AI response (text only, no voice)
      debugPrint('Sending message to AI: $text');
      final response = await _chatService.sendMessage(text);
      debugPrint('Received AI response: $response');
      
      if (response.isNotEmpty) {
        // Add AI response
        _addMessage(ChatMessage(
          text: response,
          isFromUser: false,
          timestamp: DateTime.now(),
        ));
      } else {
        debugPrint('AI response is empty');
        _addMessage(ChatMessage(
          text: tr(
            'Sorry, I couldn\'t get a response. Please try again.',
            'عذراً، لم أتمكن من الحصول على رد. يرجى المحاولة مرة أخرى.',
          ),
          isFromUser: false,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e, stackTrace) {
      debugPrint('Error sending message: $e');
      debugPrint('Stack trace: $stackTrace');
      _addMessage(ChatMessage(
        text: tr(
          'Sorry, a connection error occurred. Please check your internet connection and try again.',
          'عذراً، حدث خطأ في الاتصال. يرجى التحقق من الإنترنت والمحاولة مرة أخرى.',
        ),
        isFromUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    final isProcessing = _isSending;

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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.tealGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lobna',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  tr('Voice Assistant', 'المساعد الصوتي'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.gray500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Status indicator
          if (isProcessing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppTheme.cyan50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.cyan600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr('Processing...', 'جاري المعالجة...'),
                    style: const TextStyle(
                      color: AppTheme.cyan600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Messages list
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppTheme.tealGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            tr('Hello! I\'m Lobna', 'مرحباً! أنا لبنى'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.teal900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr('How can I help you today?', 'كيف يمكنني مساعدتك اليوم؟'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.gray600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageBubble(message);
                      },
                    ),
            ),
          ),

          // Input area
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
                  // Text input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.gray100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: tr('Type your message...', 'اكتب رسالتك...'),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Send button
                  GestureDetector(
                    onTap: (_messageController.text.trim().isEmpty || _isSending)
                        ? null
                        : _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: (_messageController.text.trim().isEmpty || _isSending)
                            ? LinearGradient(
                                colors: [
                                  AppTheme.teal500.withOpacity(0.5),
                                  AppTheme.teal600.withOpacity(0.5)
                                ],
                              )
                            : AppTheme.tealGradient,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isFromUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.tealGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.cyan100 : AppTheme.teal500,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? AppTheme.teal900 : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatTime(message.timestamp),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.gray500,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatTime(message.timestamp),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.gray500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return tr('Just now', 'الآن');
    } else if (diff.inHours < 1) {
      return tr(
        '${diff.inMinutes} min ago',
        'منذ ${diff.inMinutes} دقيقة',
      );
    } else if (diff.inDays < 1) {
      return tr(
        '${diff.inHours} hour ago',
        'منذ ${diff.inHours} ساعة',
      );
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isFromUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isFromUser,
    required this.timestamp,
  });
}

