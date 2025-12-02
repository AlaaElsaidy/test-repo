// lib/screens/services/chat_manager.dart
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  final String id;
  final String sender; // 'doctor', 'patient', 'family'
  final String senderName;
  final String senderType;
  final String receiverType;
  final String text;
  final String time;
  final DateTime createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.senderName,
    required this.senderType,
    required this.receiverType,
    required this.text,
    required this.time,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'sender_name': senderName,
      'sender_type': senderType,
      'receiver_type': receiverType,
      'message_text': text,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    final createdAt = DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String());
    return ChatMessage(
      id: map['id'] ?? '',
      sender: map['sender'] ?? '',
      senderName: map['sender_name'] ?? '',
      senderType: map['sender_type'] ?? '',
      receiverType: map['receiver_type'] ?? '',
      text: map['message_text'] ?? '',
      time: DateFormat('h:mm a').format(createdAt),
      createdAt: createdAt,
      isRead: map['is_read'] ?? false,
    );
  }
}

class ChatManager {
  static final ChatManager _instance = ChatManager._internal();

  factory ChatManager() => _instance;

  ChatManager._internal();

  final supabase = Supabase.instance.client;
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, List<ChatMessage>> _cachedMessages = {};

  /// مراقبة الرسائل في الوقت الفعلي من Supabase
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    print('DEBUG: Subscribing to chat: $chatId');
    
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .map((data) {
          print('DEBUG: Received ${(data as List).length} messages for $chatId');
          final messages = (data as List).map((e) {
            print('DEBUG: Message - ${e['message_text']}');
            return ChatMessage.fromMap(e as Map<String, dynamic>);
          }).toList();
          _cachedMessages[chatId] = messages;
          return messages;
        })
        .handleError((error) {
          print('ERROR watching messages: $error');
        });
  }

  /// إرسال رسالة جديدة إلى Supabase
  Future<void> addMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String receiverId,
    required String receiverType,
    required String messageText,
  }) async {
    try {
      await supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_type': senderType,
        'receiver_id': receiverId,
        'receiver_type': receiverType,
        'message_text': messageText,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding message: $e');
      rethrow;
    }
  }

  /// الحصول على الرسائل المحفوظة
  List<ChatMessage> getMessages(String chatId) {
    return _cachedMessages[chatId] ?? [];
  }

  /// تحميل الرسائل القديمة (pagination)
  Future<List<ChatMessage>> loadOlderMessages(String chatId, {int limit = 20}) async {
    try {
      final oldestMessage = _cachedMessages[chatId]?.firstOrNull;
      
      final data = await supabase
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .lt('created_at', oldestMessage?.createdAt.toIso8601String() ?? DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(limit);

      return (data as List).map((e) => ChatMessage.fromMap(e as Map<String, dynamic>)).toList().reversed.toList();
    } catch (e) {
      print('Error loading older messages: $e');
      return [];
    }
  }

  /// وضع علامة على الرسالة بأنها تمت قراءتها
  Future<void> markAsRead(String messageId) async {
    try {
      await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('id', messageId);
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  /// حذف رسالة
  Future<void> deleteMessage(String messageId) async {
    try {
      await supabase.from('messages').delete().eq('id', messageId);
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  /// إيقاف المراقبة
  void disposeChat(String chatId) {
    _subscriptions[chatId]?.cancel();
    _subscriptions.remove(chatId);
    _cachedMessages.remove(chatId);
  }

  /// إيقاف جميع المراقبات
  void clearAll() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _cachedMessages.clear();
  }

  String getCurrentTime() {
    return DateFormat('h:mm a').format(DateTime.now());
  }
}