// lib/services/chat_manager.dart
import 'dart:async';

import 'package:intl/intl.dart';
import 'package:supabase/supabase.dart';
import '../../core/supabase/message_service.dart';

class ChatMessage {
  final String id;
  final String sender; // 'doctor', 'patient', 'family_member'
  final String senderId;
  final String? senderName;
  final String text;
  final String time;
  final String messageType; // 'text', 'image', 'file'
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.senderId,
    this.senderName,
    required this.text,
    required this.time,
    this.messageType = 'text',
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'time': time,
      'messageType': messageType,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromSupabase(Map<String, dynamic> map) {
    final senderType = map['sender_type'] as String? ?? '';
    final sender = senderType == 'family_member' ? 'family' : senderType;
    final senderId = map['sender_id'] as String? ?? '';
    final user = map['users'] as Map<String, dynamic>?;
    final senderName = user?['name'] as String?;

    final createdAt = map['created_at'] as String?;
    DateTime? dateTime;
    if (createdAt != null) {
      dateTime = DateTime.tryParse(createdAt);
    }
    final time = dateTime != null
        ? DateFormat('h:mm a').format(dateTime)
        : DateFormat('h:mm a').format(DateTime.now());

    return ChatMessage(
      id: map['id'] as String? ?? '',
      sender: sender,
      senderId: senderId,
      senderName: senderName,
      text: map['content'] as String? ?? '',
      time: time,
      messageType: map['message_type'] as String? ?? 'text',
      fileUrl: map['file_url'] as String?,
      fileName: map['file_name'] as String?,
      fileSize: map['file_size'] as int?,
      isRead: map['is_read'] as bool? ?? false,
    );
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      sender: map['sender'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'],
      text: map['text'] ?? '',
      time: map['time'] ?? '',
      messageType: map['messageType'] ?? 'text',
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      isRead: map['isRead'] ?? false,
    );
  }
}

class ChatManager {
  static final ChatManager _instance = ChatManager._internal();

  factory ChatManager() => _instance;

  ChatManager._internal();

  final Map<String, List<ChatMessage>> _chats = {};
  final Map<String, StreamController<List<ChatMessage>>> _streams = {};
  final Map<String, RealtimeChannel> _realtimeChannels = {};

  StreamController<List<ChatMessage>> _ensureController(String chatId) {
    return _streams.putIfAbsent(
      chatId,
      () => StreamController<List<ChatMessage>>.broadcast(),
    );
  }

  void _emit(String chatId) {
    final controller = _streams[chatId];
    if (controller == null || controller.isClosed) return;
    final list = List<ChatMessage>.unmodifiable(_chats[chatId] ?? []);
    controller.add(list);
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    _ensureController(chatId);
    Future.microtask(() => _emit(chatId));
    return _streams[chatId]!.stream;
  }

  List<ChatMessage> getMessages(String chatId) {
    return _chats[chatId] ?? [];
  }

  void addMessage(String chatId, ChatMessage message) {
    if (!_chats.containsKey(chatId)) {
      _chats[chatId] = [];
    }
    _chats[chatId]!.add(message);
    _emit(chatId);
  }

  void initializeChat(String chatId, List<ChatMessage> messages) {
    _chats[chatId] = messages;
    _emit(chatId);
  }

  /// Subscribe to realtime messages for a chat
  void subscribeToRealtime(
    String chatId,
    void Function(ChatMessage message) onNewMessage,
  ) {
    // Dispose existing subscription if any
    disposeRealtime(chatId);

    final messageService = MessageService();
    final channel = messageService.subscribeToMessages(
      chatId,
      (messageMap) {
        final message = ChatMessage.fromSupabase(messageMap);
        addMessage(chatId, message);
        onNewMessage(message);
      },
    );

    _realtimeChannels[chatId] = channel;
  }

  /// Dispose realtime subscription for a chat
  void disposeRealtime(String chatId) {
    final channel = _realtimeChannels.remove(chatId);
    if (channel != null) {
      channel.unsubscribe();
    }
  }

  String getCurrentTime() {
    return DateFormat('h:mm a').format(DateTime.now());
  }

  void clearAll() {
    // Dispose all realtime channels
    for (final channel in _realtimeChannels.values) {
      channel.unsubscribe();
    }
    _realtimeChannels.clear();

    _chats.clear();
    for (final c in _streams.values) {
      if (!c.isClosed) c.close();
    }
    _streams.clear();
  }

  void disposeChat(String chatId) {
    disposeRealtime(chatId);
    _chats.remove(chatId);
    final c = _streams.remove(chatId);
    if (c != null && !c.isClosed) c.close();
  }
}
