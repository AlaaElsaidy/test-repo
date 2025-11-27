import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum SttProviderType { device, local }

enum TtsProviderType { device, placeholder, azure }

class EnvConfig {
  static final _env = dotenv;
  // النماذج المدعومة في Groq (2025)
  static const String _defaultGroqModel = 'llama-3.1-8b-instant'; // النموذج المتاح حالياً
  static const List<String> _supportedGroqModels = [
    'llama-3.3-70b-versatile', // الأحدث - 70B
    'llama-3.1-8b-instant', // سريع - 8B (متاح)
    'llama-3-70b-8192', // مدعوم
    'llama-3-8b-8192', // مدعوم
  ];
  static const Map<String, String> _groqModelAliases = {
    'mixtral-8x7b': 'llama-3.1-8b-instant', // تحديث إلى نموذج متاح
    'llama3-8b': 'llama-3.1-8b-instant',
    'llama3-70b': 'llama-3.3-70b-versatile',
    'llama3.1-70b': 'llama-3.3-70b-versatile', // تحديث إلى 3.3
    'llama3.1-70b-versatile': 'llama-3.3-70b-versatile', // تحديث إلى 3.3
    'llama3.1-8b': 'llama-3.1-8b-instant',
    'gemma-7b': 'llama-3.1-8b-instant',
    'gemma2-9b': 'llama-3.1-8b-instant',
  };

  static String get timezone =>
      _env.maybeGet('TIMEZONE')?.trim().isNotEmpty == true
          ? _env.get('TIMEZONE')
          : 'Africa/Cairo';

  static SttProviderType get sttProvider {
    final value = _env.maybeGet('STT_PROVIDER')?.toLowerCase().trim();
    switch (value) {
      case 'local':
        return SttProviderType.local;
      case 'device':
      default:
        return SttProviderType.device;
    }
  }

  static TtsProviderType get ttsProvider {
    final value = _env.maybeGet('TTS_PROVIDER')?.toLowerCase().trim();
    switch (value) {
      case 'azure':
        return TtsProviderType.azure;
      case 'device':
      default:
        return TtsProviderType.device;
    }
  }

  static String? get azureTtsApiKey {
    final key = _env.maybeGet('AZURE_TTS_API_KEY');
    if (key == null || key.trim().isEmpty) return null;
    return key.trim();
  }

  static String get azureTtsRegion {
    return _env.maybeGet('AZURE_TTS_REGION')?.trim() ?? 'eastus';
  }

  static String get azureTtsEndpoint {
    final endpoint = _env.maybeGet('AZURE_TTS_ENDPOINT')?.trim();
    if (endpoint != null && endpoint.isNotEmpty) {
      // Return as-is, the provider will handle the format
      return endpoint;
    }
    // Default endpoint format for TTS: https://{region}.tts.speech.microsoft.com/cognitiveservices/v1
    final region = azureTtsRegion;
    return 'https://$region.tts.speech.microsoft.com/cognitiveservices/v1';
  }

  static Uri get localSttEndpoint {
    final raw = _env.maybeGet('LOCAL_STT_ENDPOINT') ??
        'http://localhost:8080/transcribe';
    return Uri.parse(raw);
  }

  static String get localSttModel =>
      _env.maybeGet('LOCAL_STT_MODEL')?.trim().isNotEmpty == true
          ? _env.get('LOCAL_STT_MODEL')
          : 'small';

  static String? get groqApiKey {
    final key = _env.maybeGet('GROQ_API_KEY');
    if (key == null || key.trim().isEmpty) return null;
    return key;
  }

  static String get groqModel {
    final raw = _env.maybeGet('GROQ_MODEL')?.trim();
    if (raw == null || raw.isEmpty) {
      return _defaultGroqModel;
    }
    final normalized = _normalizeGroqModel(raw);
    if (_supportedGroqModels.contains(normalized)) {
      return normalized;
    }
    debugPrint(
        'GROQ_MODEL "$raw" غير مدعوم. سيتم استخدام $_defaultGroqModel بدلاً منه.');
    return _defaultGroqModel;
  }

  static String _normalizeGroqModel(String value) {
    final lower = value.toLowerCase();
    return _groqModelAliases[lower] ?? lower;
  }
}

