import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'context_manager.dart';
import 'ai_config.dart';

/// Service for AI chat interactions
/// Connects to AI API (OpenAI/Gemini) with Lobna persona
class AiChatService {
  final ContextManager _contextManager = ContextManager();
  final List<Map<String, String>> _conversationHistory = [];
  static const int _maxHistoryLength = 10;

  /// System prompt for Lobna
  static const String _systemPrompt = '''
أنت "لبنى"، مساعد ذكي ودود ومتعاطف لمريض زهايمر يعيش في مصر.

سيصلك دائماً "سياق" يحتوي على:
- اسم المريض الحقيقي
- قائمة بالأنشطة القادمة
- قائمة بالمناطق الآمنة المتاحة
- معلومات عن اليوم الحالي والوقت الحالي في مصر

**أولاً – كيف تستخدم السياق والمعرفة العامة؟**
- استخدم السياق لتخصيص ردودك للمريض (اسمه، أنشطته، المناطق الآمنة...).
- لكن مسموح لك تماماً أن تستخدم معرفتك العامة للإجابة على أي سؤال عام
  (مثل: البرمجة، الأكل، المحافظات، الصحة النفسية... إلخ)، حتى لو لم تكن موجودة في السياق.
- ❌ لا تقل جملة مثل: "لا توجد معلومات عن X في السياق الحالي". إذا لم تكن متأكدة، أعطِ إجابة بسيطة عامة أو اعتذار لطيف مثل:
  "مش متأكدة قوي، بس اللي أعرفه إن..." ثم قدمي أفضل ما يمكنك.

**ثانياً – قواعد مهمة جداً (يجب اتباعها بدقة):**
1. **الاسم**:
   - استخدم فقط الاسم الموجود في السياق تحت "اسم المريض"
   - ❌ لا تستنتج الاسم من الرسائل
   - ❌ لا تخترع أسماء مثل "ماي" أو "Margaret" أو أي اسم آخر
2. **طول الرد**:
   - اجعل ردودك قصيرة وواضحة: من 1 إلى 3 جمل فقط
   - لا تكتب فقرات طويلة أو نصوص كبيرة
3. **الأماكن (Safe Zones)**:
   - استخدم فقط الأماكن المذكورة في قسم "المناطق الآمنة المتاحة" في السياق
   - ❌ ممنوع تماماً ذكر "New Zone" أو أي مكان غير موجود في هذه القائمة
4. **الأنشطة**:
   - استخدم فقط الأنشطة المذكورة في "الأنشطة القادمة"
   - إذا لم توجد أنشطة، قل ذلك ببساطة
5. **الوقت واليوم**:
   - اعتبر أن التوقيت دائماً هو **توقيت مصر**
   - إذا سُئلت عن "النهاردة إيه؟" أو "كم الساعة؟" استخدم المعلومات الموجودة في السياق عن "اليوم الحالي في مصر" و"الوقت الحالي في مصر"
6. **اللغة والأسلوب**:
   - استخدم العربية فقط، بدون كلمات إنجليزية أو حروف لاتينية
   - استخدم لغة بسيطة جداً، مؤنثة، وهادئة
   - خاطب المريض بلطف واطمئنان، وتجنّب المصطلحات التقنية أو الباردة
7. **الصبر**:
   - كن صبوراً ومتفهماً، ولا تُظهر ضيقاً أو مللاً

**تحذيرات صارمة:**
- ❌ ممنوع تماماً ذكر "New Zone" أو أي مكان غير موجود في قائمة Safe Zones في السياق
- ❌ ممنوع استخدام أسماء غير الاسم الموجود في "اسم المريض"
- ❌ ممنوع كتابة ردود طويلة (أكثر من 3 جمل)
- ❌ ممنوع استخدام حروف أو كلمات إنجليزية مثل "mai", "Mosque", "asf" إلخ.

**أمثلة:**
- رد جيد: "ممكن نعمل كذا أو كذا، بس الأهم ترجعي لراحة نفسك، أنا معاكِ."
- رد سيء (ممنوع): "لا توجد معلومات عن الاكتئاب في السياق الحالي."
''';

  /// Send message to AI and get response
  Future<String> sendMessage(String userMessage) async {
    try {
      debugPrint('=== AI Chat Service: Sending message ===');
      debugPrint('User message: $userMessage');
      debugPrint('Using Groq: ${AiConfig.useGroq}');
      debugPrint('API configured: ${AiConfig.isConfigured}');
      
      // Build context
      String context = '';
      try {
        context = await _contextManager.buildContext();
        debugPrint('Context built successfully');
      } catch (e) {
        debugPrint('Error building context: $e');
        context = 'لا توجد معلومات سياقية متاحة حالياً.';
      }

      // Add user message to history
      _conversationHistory.add({'role': 'user', 'content': userMessage});

      // Keep only last N messages
      if (_conversationHistory.length > _maxHistoryLength) {
        _conversationHistory.removeAt(0);
      }

      // Simple intent detection from current user message
      final normalized = userMessage.toLowerCase();
      final asksAboutTimeOrDay = normalized.contains('النهاردة') ||
          normalized.contains('النهارده') ||
          normalized.contains('اليوم') ||
          normalized.contains('ايام الاسبوع') ||
          normalized.contains('أيام الاسبوع') ||
          normalized.contains('ايه النهاردة') ||
          normalized.contains('إيه النهاردة') ||
          normalized.contains('اليوم ايه') ||
          normalized.contains('اليوم إيه') ||
          normalized.contains('كم الساعة') ||
          normalized.contains('كم الساعه') ||
          normalized.contains('الساعة كام') ||
          normalized.contains('الساعه كام') ||
          normalized.contains('الوقت كام') ||
          normalized.contains('الوقت') ||
          normalized.contains('الساعة') ||
          normalized.contains('الساعه') ||
          normalized.contains('كام في الشهر') ||
          normalized.contains('كام ف الشهر') ||
          normalized.contains('الشهر كام') ||
          normalized.contains('شهر كام') ||
          normalized.contains('احنا في شهر ايه') ||
          normalized.contains('احنا فى شهر ايه') ||
          normalized.contains('إحنا في شهر إيه');

      final asksForSuggestion = normalized.contains('اقترح') ||
          normalized.contains('فكرة') ||
          normalized.contains('افكار') ||
          normalized.contains('أفكار') ||
          normalized.contains('اعمل ايه') ||
          normalized.contains('أعمل ايه') ||
          normalized.contains('اعمل ايه؟') ||
          normalized.contains('اروح فين') ||
          normalized.contains('اذهب فين') ||
          normalized.contains('اتفسح') ||
          normalized.contains('اتفسح؟') ||
          normalized.contains('اتفسح فين');

      // Build messages for API
      final List<Map<String, String>> messages = [
        {
          'role': 'system',
          'content': '$_systemPrompt\n\nالسياق الحالي:\n$context',
        },
        if (!asksAboutTimeOrDay)
          {
            'role': 'system',
            'content':
                'في هذه الرسالة المريض لم يسأل عن اليوم أو التاريخ أو الوقت، لذلك لا تذكر اليوم أو الساعة في إجابتك، وركّز فقط على سؤال المريض.',
          },
        if (!asksForSuggestion)
          {
            'role': 'system',
            'content':
                'في هذه الرسالة المريض لم يطلب اقتراح نشاط أو مكان جديد، لذلك لا تقترح أفعالاً أو أماكن جديدة مثل الطبخ أو الخروج، فقط أجب على سؤاله بشكل مباشر وبسيط.',
          },
        ..._conversationHistory,
      ];

      debugPrint('Calling AI API with ${messages.length} messages');

      // Call AI API
      final response = await _callAiApi(messages);

      if (response != null && response.isNotEmpty) {
        debugPrint('AI response received: ${response.substring(0, response.length > 100 ? 100 : response.length)}...');
        // Add AI response to history
        _conversationHistory.add({'role': 'assistant', 'content': response});
        return response;
      } else {
        debugPrint('AI API returned null or empty response, using fallback');
        return _getFallbackResponse(userMessage);
      }
    } catch (e, stackTrace) {
      debugPrint('Error in AI chat service: $e');
      debugPrint('Stack trace: $stackTrace');
      return _getFallbackResponse(userMessage);
    }
  }

  /// Call AI API (Groq/OpenAI/Gemini)
  Future<String?> _callAiApi(List<Map<String, String>> messages) async {
    // Check if configuration is valid
    if (!AiConfig.isConfigured) {
      debugPrint('AI API not configured. Using fallback responses.');
      return _getSimpleResponse(messages.last['content'] ?? '');
    }

    try {
      if (AiConfig.useBackendProxy && AiConfig.backendProxyUrl.isNotEmpty) {
        // Use backend proxy (recommended for production)
        return await _callBackendProxy(messages);
      } else if (AiConfig.useGroq) {
        // Use Groq (FREE - Llama 3)
        return await _callGroqApi(messages);
      } else if (AiConfig.useGemini) {
        // Use Google Gemini
        return await _callGeminiApi(messages);
      } else {
        // Use OpenAI (default)
        return await _callOpenAiApi(messages);
      }
    } catch (e) {
      debugPrint('AI API call error: $e');
      return _getSimpleResponse(messages.last['content'] ?? '');
    }
  }

  /// Call Groq API (FREE - Llama 3)
  Future<String?> _callGroqApi(List<Map<String, String>> messages) async {
    try {
      debugPrint('Calling Groq API with model: ${AiConfig.groqModel}');
      debugPrint('URL: ${AiConfig.groqBaseUrl}/chat/completions');
      
      final response = await http.post(
        Uri.parse('${AiConfig.groqBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AiConfig.groqApiKey}',
        },
        body: jsonEncode({
          'model': AiConfig.groqModel,
          'messages': messages,
          'temperature': 0.5,
          'max_tokens': 200, // Short responses مع شوية إبداع
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Groq API timeout');
          throw TimeoutException('Groq API request timeout');
        },
      );

      debugPrint('Groq API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('Groq API response data: $data');
        
        // Check if response has choices
        if (data.containsKey('choices') && 
            (data['choices'] as List).isNotEmpty) {
          final choice = data['choices'][0] as Map<String, dynamic>;
          if (choice.containsKey('message')) {
            final message = choice['message'] as Map<String, dynamic>;
            final content = message['content'] as String?;
            if (content != null && content.isNotEmpty) {
              debugPrint('Groq API response received successfully: ${content.substring(0, content.length > 100 ? 100 : content.length)}...');
              return content.trim();
            } else {
              debugPrint('Groq API response content is empty');
              return null;
            }
          } else {
            debugPrint('Groq API response missing message in choice');
            return null;
          }
        } else {
          debugPrint('Groq API response missing choices. Full response: ${response.body}');
          return null;
        }
      } else {
        debugPrint('Groq API error: ${response.statusCode}');
        debugPrint('Error body: ${response.body}');
        // Try to parse error message
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          if (errorData.containsKey('error')) {
            final error = errorData['error'] as Map<String, dynamic>;
            debugPrint('Groq API error message: ${error['message']}');
          }
        } catch (e) {
          debugPrint('Could not parse error response');
        }
        return null;
      }
    } on TimeoutException catch (e) {
      debugPrint('Groq API timeout: $e');
      return null;
    } on http.ClientException catch (e) {
      debugPrint('Groq API network error: $e');
      return null;
    } catch (e) {
      debugPrint('Groq API call error: $e');
      return null;
    }
  }

  /// Call OpenAI API
  Future<String?> _callOpenAiApi(List<Map<String, String>> messages) async {
    try {
      final response = await http.post(
        Uri.parse('${AiConfig.openAiBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AiConfig.openAiApiKey}',
        },
        body: jsonEncode({
          'model': AiConfig.openAiModel,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 200,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String?;
        return content?.trim();
      } else {
        debugPrint('OpenAI API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('OpenAI API call error: $e');
      return null;
    }
  }

  /// Call Google Gemini API
  Future<String?> _callGeminiApi(List<Map<String, String>> messages) async {
    try {
      // Convert messages format for Gemini
      final contents = messages
          .where((msg) => msg['role'] != 'system')
          .map((msg) => {
                'role': msg['role'] == 'user' ? 'user' : 'model',
                'parts': [{'text': msg['content']}]
              })
          .toList();

      // Add system instruction
      final systemMessage = messages.firstWhere(
        (msg) => msg['role'] == 'system',
        orElse: () => {'role': 'system', 'content': ''},
      );

      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${AiConfig.geminiApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': contents,
          'systemInstruction': {
            'parts': [{'text': systemMessage['content']}]
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'] as String?;
        return content?.trim();
      } else {
        debugPrint('Gemini API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Gemini API call error: $e');
      return null;
    }
  }

  /// Call backend proxy (Supabase Edge Function or custom server)
  Future<String?> _callBackendProxy(List<Map<String, String>> messages) async {
    try {
      final response = await http.post(
        Uri.parse(AiConfig.backendProxyUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] as String?;
      } else {
        debugPrint('Backend proxy error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Backend proxy call error: $e');
      return null;
    }
  }

  /// Simple keyword-based response (fallback when API is not configured)
  String _getSimpleResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    if (message.contains('مرحبا') || message.contains('السلام')) {
      return 'مرحباً! كيف يمكنني مساعدتك اليوم؟';
    } else if (message.contains('نشاط') || message.contains('موعد')) {
      return 'دعني أتحقق من أنشطتك القادمة...';
    } else if (message.contains('أين') || message.contains('مكان')) {
      return 'أنت في المنطقة الآمنة. لا تقلق.';
    } else if (message.contains('مساعدة') || message.contains('مساعدة')) {
      return 'أنا هنا لمساعدتك. ماذا تحتاج؟';
    } else {
      return 'فهمت. هل يمكنك توضيح أكثر؟';
    }
  }

  /// Fallback response when API fails
  String _getFallbackResponse(String userMessage) {
    debugPrint('Using fallback response for: $userMessage');
    // Try to give a helpful response based on the message
    final message = userMessage.toLowerCase();
    
    if (message.contains('مرحبا') || message.contains('السلام') || message.contains('اهلا')) {
      return 'مرحباً! كيف يمكنني مساعدتك اليوم؟';
    } else if (message.contains('أيام') && message.contains('أسبوع')) {
      return 'أيام الأسبوع هي: السبت، الأحد، الاثنين، الثلاثاء، الأربعاء، الخميس، الجمعة';
    } else if (message.contains('وقت') || message.contains('ساعة')) {
      final now = DateTime.now();
      return 'الوقت الحالي هو ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    } else if (message.contains('تاريخ') || message.contains('يوم')) {
      final now = DateTime.now();
      return 'التاريخ اليوم هو ${now.day}/${now.month}/${now.year}';
    } else {
      return 'عذراً، حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.';
    }
  }

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// Get conversation history
  List<Map<String, String>> getHistory() {
    return List.unmodifiable(_conversationHistory);
  }
}

