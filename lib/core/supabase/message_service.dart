import 'package:alzcare/core/supabase/supabase-config.dart';
import 'package:supabase/supabase.dart';

class MessageService {
  final _client = SupabaseConfig.client;

  /// Send a text message
  Future<Map<String, dynamic>> sendTextMessage({
    required String chatId,
    required String senderId,
    required String senderType,
    required String content,
  }) async {
    final response = await _client.from('chat_messages').insert({
      'conversation_id': chatId,
      'sender_id': senderId,
      'sender_type': senderType,
      'content': content,
      'message_type': 'text',
    }).select().single();

    // Update chat's last message
    await _client.from('chat_conversations').update({
      'last_message_at': DateTime.now().toIso8601String(),
      'last_message_preview': content.length > 50
          ? '${content.substring(0, 50)}...'
          : content,
    }).eq('id', chatId);

    return response;
  }

  /// Send a file/image message
  Future<Map<String, dynamic>> sendFileMessage({
    required String chatId,
    required String senderId,
    required String senderType,
    required String fileUrl,
    required String messageType, // 'image' or 'file'
    String? fileName,
    int? fileSize,
    String? content, // Optional caption for images
  }) async {
    final response = await _client.from('chat_messages').insert({
      'conversation_id': chatId,
      'sender_id': senderId,
      'sender_type': senderType,
      'message_type': messageType,
      'file_url': fileUrl,
      if (fileName != null) 'file_name': fileName,
      if (fileSize != null) 'file_size': fileSize,
      if (content != null) 'content': content,
    }).select().single();

    // Update chat's last message
    final preview = messageType == 'image'
        ? (content ?? '📷 Image')
        : (fileName ?? '📎 File');
    await _client.from('chat_conversations').update({
      'last_message_at': DateTime.now().toIso8601String(),
      'last_message_preview': preview,
    }).eq('id', chatId);

    return response;
  }

  /// Get messages for a chat with pagination
  Future<List<Map<String, dynamic>>> getMessages({
    required String chatId,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client
        .from('chat_messages')
        .select('''
          *,
          users:sender_id (
            id,
            name
          )
        ''')
        .eq('conversation_id', chatId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    // Reverse to show oldest first
    final messages = List<Map<String, dynamic>>.from(response);
    return messages.reversed.toList();
  }

  /// Mark a message as read
  Future<void> markAsRead(String messageId, String userId) async {
    // Only mark as read if the user is not the sender
    await _client.from('chat_messages').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId).neq('sender_id', userId);
  }

  /// Mark all messages in a chat as read
  Future<void> markChatAsRead(String chatId, String userId) async {
    await _client.from('chat_messages').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('conversation_id', chatId)
        .neq('sender_id', userId)
        .eq('is_read', false);
  }

  /// Get unread message count for a chat
  Future<int> getUnreadCount(String chatId, String userId) async {
    final response = await _client
        .from('chat_messages')
        .select('id')
        .eq('conversation_id', chatId)
        .neq('sender_id', userId)
        .eq('is_read', false);

    return response.length;
  }

  /// Subscribe to new messages in a chat (Realtime)
  RealtimeChannel subscribeToMessages(
    String chatId,
    void Function(Map<String, dynamic> message) onMessage,
  ) {
    final channel = _client.channel('chat_$chatId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: chatId,
      ),
      callback: (payload) {
        onMessage(payload.newRecord);
      },
    );

    channel.subscribe();

    return channel;
  }
}

