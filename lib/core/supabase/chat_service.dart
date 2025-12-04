import 'package:alzcare/core/supabase/supabase-config.dart';

class ChatService {
  final _client = SupabaseConfig.client;

  /// Create a new chat between doctor and patient/family member
  Future<Map<String, dynamic>> createChat({
    required String doctorId,
    String? patientId,
    String? familyMemberId,
  }) async {
    if (patientId == null && familyMemberId == null) {
      throw Exception('Either patientId or familyMemberId must be provided');
    }
    if (patientId != null && familyMemberId != null) {
      throw Exception('Cannot provide both patientId and familyMemberId');
    }

    final response = await _client.from('chat_conversations').insert({
      'doctor_id': doctorId,
      if (patientId != null) 'patient_id': patientId,
      if (familyMemberId != null) 'family_member_id': familyMemberId,
    }).select().single();

    return response;
  }

  /// Get chat by ID
  Future<Map<String, dynamic>?> getChatById(String chatId) async {
    final response = await _client
        .from('chat_conversations')
        .select()
        .eq('id', chatId)
        .eq('is_active', true)
        .maybeSingle();

    return response;
  }

  /// Get or create a chat between doctor and patient/family member
  Future<Map<String, dynamic>> getOrCreateChat({
    required String doctorId,
    String? patientId,
    String? familyMemberId,
  }) async {
    // Try to find existing chat
    Map<String, dynamic>? existingChat;

    if (patientId != null) {
      existingChat = await _client
          .from('chat_conversations')
          .select()
          .eq('doctor_id', doctorId)
          .eq('patient_id', patientId)
          .eq('is_active', true)
          .maybeSingle();
    } else if (familyMemberId != null) {
      existingChat = await _client
          .from('chat_conversations')
          .select()
          .eq('doctor_id', doctorId)
          .eq('family_member_id', familyMemberId)
          .eq('is_active', true)
          .maybeSingle();
    }

    if (existingChat != null) {
      return existingChat;
    }

    // Create new chat if not found
    return await createChat(
      doctorId: doctorId,
      patientId: patientId,
      familyMemberId: familyMemberId,
    );
  }

  /// Get all chats for a doctor
  Future<List<Map<String, dynamic>>> getChatsForDoctor(String doctorId) async {
    final response = await _client
        .from('chat_conversations')
        .select('''
          *,
          patients:patient_id (
            id,
            name,
            user_id
          ),
          family_members:family_member_id (
            id,
            name
          )
        ''')
        .eq('doctor_id', doctorId)
        .eq('is_active', true)
        .order('last_message_at', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get all chats for a patient
  Future<List<Map<String, dynamic>>> getChatsForPatient(
      String patientUserId) async {
    // First get patient_id from user_id
    final patient = await _client
        .from('patients')
        .select('id')
        .eq('user_id', patientUserId)
        .maybeSingle();

    if (patient == null) {
      return [];
    }

    final patientId = patient['id'] as String;

    final response = await _client
        .from('chat_conversations')
        .select('''
          *,
          users:doctor_id (
            id,
            name,
            email
          )
        ''')
        .eq('patient_id', patientId)
        .eq('is_active', true)
        .order('last_message_at', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get all chats for a family member
  Future<List<Map<String, dynamic>>> getChatsForFamilyMember(
      String familyMemberId) async {
    final response = await _client
        .from('chat_conversations')
        .select('''
          *,
          users:doctor_id (
            id,
            name,
            email
          )
        ''')
        .eq('family_member_id', familyMemberId)
        .eq('is_active', true)
        .order('last_message_at', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Soft delete a chat (set is_active = false)
  Future<void> deleteChat(String chatId, String userId) async {
    // Verify user has access to this chat
    final chat = await getChatById(chatId);
    if (chat == null) {
      throw Exception('Chat not found');
    }

    final doctorId = chat['doctor_id'] as String?;
    final patientId = chat['patient_id'] as String?;
    final familyMemberId = chat['family_member_id'] as String?;

    // Check if user is authorized
    bool isAuthorized = false;

    if (doctorId == userId) {
      isAuthorized = true;
    } else if (patientId != null) {
      final patient = await _client
          .from('patients')
          .select('user_id')
          .eq('id', patientId)
          .maybeSingle();
      if (patient != null && patient['user_id'] == userId) {
        isAuthorized = true;
      }
    } else if (familyMemberId == userId) {
      isAuthorized = true;
    }

    if (!isAuthorized) {
      throw Exception('Unauthorized to delete this chat');
    }

    await _client
        .from('chat_conversations')
        .update({'is_active': false})
        .eq('id', chatId);
  }

  /// Update last message info in chat
  Future<void> updateLastMessage(
    String chatId,
    String? preview,
    DateTime timestamp,
  ) async {
    await _client.from('chat_conversations').update({
      'last_message_at': timestamp.toIso8601String(),
      'last_message_preview': preview,
    }).eq('id', chatId);
  }
}

