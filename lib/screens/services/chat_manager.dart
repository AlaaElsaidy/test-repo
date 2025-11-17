// lib/services/chat_manager.dart
import 'dart:async';

import 'package:intl/intl.dart';

class ChatMessage {
  final String sender; // 'doctor', 'patient', 'family'
  final String text;
  final String time;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'text': text,
      'time': time,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      sender: map['sender'] ?? '',
      text: map['text'] ?? '',
      time: map['time'] ?? '',
    );
  }
}

class ChatManager {
  static final ChatManager _instance = ChatManager._internal();

  factory ChatManager() => _instance;

  ChatManager._internal();

  final Map<String, List<ChatMessage>> _chats = {};
  final Map<String, StreamController<List<ChatMessage>>> _streams = {};

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
    if (!_chats.containsKey(chatId) || _chats[chatId]!.isEmpty) {
      _chats[chatId] = messages;
      _emit(chatId);
    }
  }

  String getCurrentTime() {
    return DateFormat('h:mm a').format(DateTime.now());
  }

  void clearAll() {
    _chats.clear();
    for (final c in _streams.values) {
      if (!c.isClosed) c.close();
    }
    _streams.clear();
  }

  void disposeChat(String chatId) {
    _chats.remove(chatId);
    final c = _streams.remove(chatId);
    if (c != null && !c.isClosed) c.close();
  }
}
