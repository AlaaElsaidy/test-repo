import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../config/env/env_config.dart';
import 'package:alzcare/core/supabase/activity-service.dart';
import 'groq_client.dart';
import 'audio/audio_feedback.dart';
import 'audio/stt_service.dart';
import 'audio/tts_service.dart';
import 'prompts/lobna_dialect_adapter.dart';
import 'prompts/lobna_prompts.dart';

enum LobnaVoiceState { idle, listening, processing, speaking, error }

class LobnaVoiceController extends ChangeNotifier {
  LobnaVoiceController({
    LobnaSttService? sttService,
    LobnaTtsService? ttsService,
    ActivityService? activityService,
    LobnaGroqClient? groqClient,
  })  : _stt = sttService ?? LobnaSttService(),
        _tts = ttsService ?? LobnaTtsService(),
        _activityService = activityService ?? ActivityService(),
        _groq = groqClient ??
            LobnaGroqClient(
              apiKey: EnvConfig.groqApiKey,
              model: EnvConfig.groqModel,
            );

  final LobnaSttService _stt;
  final LobnaTtsService _tts;
  final ActivityService _activityService;
  final LobnaGroqClient _groq;

  LobnaVoiceState _state = LobnaVoiceState.idle;
  LobnaVoiceState get state => _state;

  String? _lastTranscript;
  String? get lastTranscript => _lastTranscript;

  String? _lastError;
  String? get lastError => _lastError;

  void _setState(LobnaVoiceState state, {String? error}) {
    _state = state;
    _lastError = error;
    notifyListeners();
  }

  Future<String?> listen({
    Duration listenFor = const Duration(seconds: 30),
    String localeId = 'ar_EG',
  }) async {
    if (_state == LobnaVoiceState.listening) return null;
    _setState(LobnaVoiceState.listening);
    await LobnaAudioFeedback.startListeningTone();
    final result = await _stt.capture(
      listenFor: listenFor,
      localeId: localeId,
    );
    await LobnaAudioFeedback.endListeningTone();

    if (!result.success) {
      _setState(LobnaVoiceState.error, error: result.error);
      return null;
    }

    _lastTranscript = result.text;
    _setState(LobnaVoiceState.processing);
    return _lastTranscript;
  }

  Future<void> cancel() async {
    await _stt.cancel();
    _setState(LobnaVoiceState.idle);
  }

  Future<void> speak(String text) async {
    _setState(LobnaVoiceState.speaking);
    final res = await _tts.speak(text);
    if (!res.success) {
      _setState(LobnaVoiceState.error, error: res.error);
      return;
    }
    _setState(LobnaVoiceState.idle);
  }

  Future<String?> fetchNextActivityReminder(String patientId) async {
    try {
      final activities =
          await _activityService.getActivitiesByPatient(patientId);
      if (activities.isEmpty) {
        return 'لا توجد أنشطة مجدولة حالياً.';
      }
      activities.sort((a, b) {
        final dateA = DateTime.parse('${a['scheduled_date']}');
        final dateB = DateTime.parse('${b['scheduled_date']}');
        return dateA.compareTo(dateB);
      });

      final next = activities.first;
      final name = next['name'] ?? '';
      final date = next['scheduled_date'] ?? '';
      final time = next['scheduled_time'] ?? '';
      final reminder =
          'النشاط القادم هو $name في تاريخ $date الساعة $time. لا تنس الالتزام بالموعد.';
      return reminder;
    } catch (e) {
      return 'تعذر جلب الأنشطة: $e';
    }
  }

  Future<void> remindNextActivity(String patientId) async {
    final text = await fetchNextActivityReminder(patientId);
    if (text != null) {
      await speak(text);
    }
  }

  Future<String> generateAssistantReply(
    String transcript, {
    List<Map<String, String>> history = const [],
    String? patientId,
    String? safeZoneStatus,
  }) async {
    if (!_groq.isConfigured) {
      return LobnaDialectAdapter.ensureMasri('سمعتك بتقول: $transcript');
    }

    final reminder =
        patientId != null ? await fetchNextActivityReminder(patientId) : null;
    final systemPrompt = LobnaPromptBuilder.baseSystemPrompt(
      timezone: EnvConfig.timezone,
      nextActivity: reminder,
      safeZoneStatus: safeZoneStatus,
    );

    final response = await _groq.chat(
      prompt: transcript,
      history: history,
      systemPrompt: systemPrompt,
    );

    if (!response.success) {
      // Log الخطأ
      debugPrint('❌ [Lobna] Failed to generate reply');
      debugPrint('❌ [Lobna] Error: ${response.error}');
      debugPrint('❌ [Lobna] Transcript: $transcript');
      
      // لا نعرض رسائل الخطأ الفنية للمستخدم
      // بدلاً من ذلك نعرض رسالة ودودة
      final errorMsg = response.error ?? '';
      
      // التحقق من نوع الخطأ
      if (errorMsg.contains('401') || errorMsg.contains('unauthorized')) {
        debugPrint('❌ [Lobna] API Key invalid or unauthorized');
        return LobnaDialectAdapter.ensureMasri(
          'آسفة، في مشكلة في الاتصال. لو سمحت تأكد من الإنترنت وجرب تاني.'
        );
      } else if (errorMsg.contains('429') || errorMsg.contains('rate limit')) {
        debugPrint('❌ [Lobna] Rate limit exceeded');
        return LobnaDialectAdapter.ensureMasri(
          'آسفة، في ضغط على الخدمة دلوقتي. لو سمحت استنى شوية وجرب تاني.'
        );
      } else if (errorMsg.contains('decommissioned') || 
          errorMsg.contains('no longer supported') ||
          errorMsg.contains('model')) {
        debugPrint('❌ [Lobna] Model error');
        return LobnaDialectAdapter.ensureMasri(
          'آسفة، في مشكلة تقنية دلوقتي. لو سمحت جرب تاني بعد شوية.'
        );
      } else if (errorMsg.contains('400')) {
        // 400 errors can be various issues - log full error for debugging
        debugPrint('❌ [Lobna] Bad request (400) - Full error: $errorMsg');
        // Try to provide a helpful message or fallback
        return LobnaDialectAdapter.ensureMasri(
          'آسفة، مش فاهمه السؤال. ممكن تكرره بطريقة تانية؟'
        );
      } else if (errorMsg.contains('timeout') || errorMsg.contains('Timeout')) {
        debugPrint('❌ [Lobna] Timeout error');
        return LobnaDialectAdapter.ensureMasri(
          'الاتصال بطيء شوية. لو سمحت جرب تاني.'
        );
      }
      
      // أخطاء أخرى - رسالة عامة ودودة
      debugPrint('❌ [Lobna] Unknown error type');
      return LobnaDialectAdapter.ensureMasri(
        'آسفة، مش قادرة أرد دلوقتي. لو سمحت جرب تاني بعد شوية.'
      );
    }
    
    var reply = response.reply ?? 'مش فاهم، ممكن تكرر لو سمحت؟';
    debugPrint('✅ [Lobna] Reply generated: ${reply.substring(0, reply.length > 50 ? 50 : reply.length)}...');
    
    // تنظيف الرد وإزالة التكرارات
    reply = _cleanReply(reply);
    
    final masriReply = LobnaDialectAdapter.ensureMasri(reply);
    debugPrint('✅ [Lobna] Masri reply: ${masriReply.substring(0, masriReply.length > 50 ? 50 : masriReply.length)}...');
    
    return masriReply;
  }

  /// تنظيف الرد وإزالة الجمل المكررة وغير المفيدة
  String _cleanReply(String reply) {
    if (reply.trim().isEmpty) {
      return 'مش فاهم، ممكن تكرر لو سمحت؟';
    }

    var cleaned = reply.trim();
    
    // إزالة الجمل المكررة التي تظهر في كل رد
    final repetitivePhrases = [
      'إزيك في وقت كويس',
      'وانا معاك',
      'إزيك في وقت كويس، . وانا معاك',
      '. وانا معاك',
      'في وقت كويس',
    ];

    for (final phrase in repetitivePhrases) {
      cleaned = cleaned.replaceAll(phrase, '');
      cleaned = cleaned.replaceAll(phrase.replaceAll('،', ','), '');
    }

    // إزالة علامات الترقيم المكررة
    cleaned = cleaned.replaceAll(RegExp(r'\.{2,}'), '.');
    cleaned = cleaned.replaceAll(RegExp(r'،{2,}'), '،');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    // إزالة المسافات الزائدة في البداية والنهاية
    cleaned = cleaned.trim();
    
    // إزالة النقاط المتبقية في نهاية الجمل إذا كانت كثيرة
    cleaned = cleaned.replaceAll(RegExp(r'\.\s*\.'), '.');
    
    // إذا كان الرد فارغاً بعد التنظيف، إرجاع رد افتراضي
    if (cleaned.isEmpty || cleaned.length < 3) {
      return 'مش فاهم، ممكن تكرر لو سمحت؟';
    }

    return cleaned;
  }

  @override
  void dispose() {
    // Use Future.wait to ensure cleanup happens but don't block
    // Wrap in try-catch to prevent any errors during disposal
    try {
      _stt.cancel().catchError((_) {});
      _tts.stop().catchError((_) {});
    } catch (_) {
      // Ignore any errors during disposal
    }
    super.dispose();
  }
}

