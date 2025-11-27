import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class GroqChatResponse {
  final bool success;
  final String? reply;
  final String? error;

  const GroqChatResponse._(this.success, this.reply, this.error);

  factory GroqChatResponse.success(String reply) =>
      GroqChatResponse._(true, reply, null);

  factory GroqChatResponse.failure(String error) =>
      GroqChatResponse._(false, null, error);
}

class LobnaGroqClient {
  LobnaGroqClient({
    String? apiKey,
    Dio? dio,
    String model = 'llama-3.1-8b-instant', // النموذج المتاح حالياً
  })  : _apiKey = apiKey,
        _model = model,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.groq.com/openai/v1',
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 30),
              ),
            );

  final String? _apiKey;
  final String _model;
  final Dio _dio;

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  Future<GroqChatResponse> chat({
    required String prompt,
    List<Map<String, String>> history = const [],
    String? systemPrompt,
  }) async {
    if (!isConfigured) {
      return GroqChatResponse.failure(
        'GROQ_API_KEY غير مضبوط. أضفه إلى .env أو متغيرات البيئة.',
      );
    }

    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      return GroqChatResponse.failure(
          'النص المرسل إلى Groq فارغ، لا يمكن توليد رد.');
    }

    final sanitizedHistory = history
        .map((entry) => {
              'role': (entry['role'] ?? '').isNotEmpty
                  ? entry['role']!
                  : 'assistant',
              'content': entry['content']?.trim() ?? '',
            })
        .where((entry) => entry['content']!.isNotEmpty)
        .toList();

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': systemPrompt ??
            'أنت لُبنى، مساعدة شخصية ودودة لمرضى الزهايمر. تجاوب دائماً باللهجة المصرية الدارجة فقط، استخدم كلمات مثل "إزيك"، "ما تقلقش"، "دلوقتي"، "عايز".'
      },
      ...sanitizedHistory,
      {'role': 'user', 'content': trimmedPrompt},
    ];

    try {
      // Log للـ debugging
      debugPrint('🔵 [Groq] Sending request with model: $_model');
      debugPrint('🔵 [Groq] Messages count: ${messages.length}');
      
      // Log الـ request بالتفصيل
      debugPrint('🔵 [Groq] Request URL: https://api.groq.com/openai/v1/chat/completions');
      debugPrint('🔵 [Groq] Model: $_model');
      debugPrint('🔵 [Groq] API Key: ${_apiKey?.substring(0, 10)}...');
      debugPrint('🔵 [Groq] Messages: ${messages.length}');
      debugPrint('🔵 [Groq] First message: ${messages.first['content']?.substring(0, 50)}...');
      
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': _model,
          'temperature': 0.6, // زيادة للتنوع وعدم التكرار
          'max_tokens': 512,
          'messages': List<Map<String, dynamic>>.from(messages.map((m) => {
            'role': m['role'],
            'content': m['content'],
          })),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500, // قبول جميع الـ status codes أقل من 500
        ),
      );

      debugPrint('✅ [Groq] Response status: ${response.statusCode}');
      debugPrint('✅ [Groq] Response data type: ${response.data.runtimeType}');
      debugPrint('✅ [Groq] Response data: ${response.data}');
      
      // التحقق من الـ status code أولاً
      if (response.statusCode != 200) {
        final errorMsg = response.data is Map 
            ? (response.data['error']?['message'] ?? response.data.toString())
            : response.data.toString();
        debugPrint('❌ [Groq] Error status ${response.statusCode}: $errorMsg');
        return GroqChatResponse.failure('خطأ من Groq (${response.statusCode}): $errorMsg');
      }
      
      // التحقق من وجود choices
      if (response.data is! Map || !response.data.containsKey('choices')) {
        debugPrint('❌ [Groq] Invalid response structure: ${response.data}');
        return GroqChatResponse.failure('رد غير صحيح من Groq.');
      }
      
      final choices = response.data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        debugPrint('❌ [Groq] No choices in response');
        debugPrint('❌ [Groq] Full response: ${response.data}');
        return GroqChatResponse.failure('لم يصل رد من Groq.');
      }
      
      final firstChoice = choices.first;
      if (firstChoice is! Map || !firstChoice.containsKey('message')) {
        debugPrint('❌ [Groq] Invalid choice structure: $firstChoice');
        return GroqChatResponse.failure('رد غير صحيح من Groq.');
      }
      
      final content =
          firstChoice['message']?['content']?.toString().trim() ?? '';
      if (content.isEmpty) {
        debugPrint('❌ [Groq] Empty content in response');
        debugPrint('❌ [Groq] Choice: $firstChoice');
        return GroqChatResponse.failure('النص المستلم فارغ.');
      }
      
      debugPrint('✅ [Groq] Success! Content length: ${content.length}');
      debugPrint('✅ [Groq] Content preview: ${content.substring(0, content.length > 100 ? 100 : content.length)}...');
      
      return GroqChatResponse.success(content);
    } on DioException catch (dioError) {
      final status = dioError.response?.statusCode;
      final data = dioError.response?.data;
      
      debugPrint('❌ [Groq] DioException: ${dioError.type}');
      debugPrint('❌ [Groq] Status: $status');
      debugPrint('❌ [Groq] Data: $data');
      
      String? details;
      if (data is Map && data['error'] is Map) {
        details = data['error']['message']?.toString();
      } else if (data is Map && data['message'] != null) {
        details = data['message'].toString();
      } else if (data is Map && data['error'] != null) {
        details = data['error'].toString();
      } else if (data is String) {
        details = data;
      } else {
        details = dioError.message;
      }
      
      // Log الخطأ بالتفصيل
      debugPrint('❌ [Groq] Error details: $details');
      
      final statusPart = status != null ? ' ($status)' : '';
      return GroqChatResponse.failure(
        'فشل طلب Groq$statusPart: ${details ?? 'تحقق من البيانات المرسلة.'}',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [Groq] Unexpected error: $e');
      debugPrint('❌ [Groq] Stack trace: $stackTrace');
      return GroqChatResponse.failure('فشل طلب Groq: $e');
    }
  }
}

