import 'package:flutter/material.dart';

import '../../services/lobna/lobna_voice_controller.dart';
import '../services/chat_manager.dart';

class LobnaTextChatScreen extends StatefulWidget {
  const LobnaTextChatScreen({
    super.key,
    required this.chatManager,
    required this.voiceController,
    required this.chatId,
    this.patientId,
  });

  final ChatManager chatManager;
  final LobnaVoiceController voiceController;
  final String chatId;
  final String? patientId;

  @override
  State<LobnaTextChatScreen> createState() => _LobnaTextChatScreenState();
}

class _LobnaTextChatScreenState extends State<LobnaTextChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);

    widget.chatManager.addMessage(
      widget.chatId,
      ChatMessage(
        sender: 'patient',
        text: text,
        time: widget.chatManager.getCurrentTime(),
      ),
    );
    _inputController.clear();
    _jumpToBottom();

    // جلب الـ history بدون الرسالة الأخيرة (لأنها ستُضاف في generateAssistantReply)
    final allMessages = widget.chatManager.getMessages(widget.chatId);
    final history = allMessages
        .take(allMessages.length - 1) // استبعاد الرسالة الأخيرة (التي أضفناها للتو)
        .map((msg) => {
              'role': msg.sender == 'lobna' ? 'assistant' : 'user',
              'content': msg.text,
            })
        .toList();

    // Note: safeZoneStatus could be added here if safeZones and location are available
    // For now, we'll pass null and let the system prompt handle it without safe zone info
    final reply = await widget.voiceController.generateAssistantReply(
      text,
      history: history,
      patientId: widget.patientId,
      safeZoneStatus: null, // TODO: Add safeZoneStatus support if needed
    );

    widget.chatManager.addMessage(
      widget.chatId,
      ChatMessage(
        sender: 'lobna',
        text: reply,
        time: widget.chatManager.getCurrentTime(),
      ),
    );

    if (mounted) {
      setState(() => _sending = false);
      _jumpToBottom();
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دردشة لُبنى'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: widget.chatManager.watchMessages(widget.chatId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, index) {
                    final message = messages[index];
                    final isLobna = message.sender == 'lobna';
                    return Align(
                      alignment:
                          isLobna ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 300),
                        decoration: BoxDecoration(
                          color: isLobna
                              ? const Color(0xFFE0F2F1)
                              : const Color(0xFFDCF8C6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                message.time,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'اكتب سؤالك بالمصري...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _sending ? null : _sendMessage,
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, size: 18),
                    label: const Text('إرسال'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}


