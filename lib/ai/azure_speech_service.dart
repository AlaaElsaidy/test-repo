import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'ai_config.dart';

/// Azure Speech Service for high-quality Arabic STT and TTS
/// Uses Azure Cognitive Services Speech API
class AzureSpeechService {
  String? _accessToken;
  DateTime? _tokenExpiry;
  bool _isInitialized = false;

  // Azure Speech API endpoints
  String get _tokenEndpoint =>
      'https://${AiConfig.azureSpeechRegion}.api.cognitive.microsoft.com/sts/v1.0/issueToken';
  String get _sttEndpoint =>
      'https://${AiConfig.azureSpeechRegion}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=ar-SA';
  String get _ttsEndpoint =>
      'https://${AiConfig.azureSpeechRegion}.tts.speech.microsoft.com/cognitiveservices/v1';

  // Arabic voice for TTS (female Egyptian voice - Salma is soft and natural)
  static const String _arabicVoice = 'ar-EG-SalmaNeural';
  // Alternative voices:
  // 'ar-SA-ZariyahNeural' - Saudi Female
  // 'ar-SA-HamedNeural' - Saudi Male
  // 'ar-EG-ShakirNeural' - Egyptian Male

  /// Initialize Azure Speech Service
  Future<bool> initialize() async {
    if (_isInitialized && _accessToken != null && !_isTokenExpired()) {
      return true;
    }

    try {
      final token = await _getAccessToken();
      if (token != null) {
        _accessToken = token;
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 9)); // Token valid for 10 mins
        _isInitialized = true;
        debugPrint('Azure Speech Service initialized successfully');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error initializing Azure Speech Service: $e');
      return false;
    }
  }

  /// Get access token from Azure
  Future<String?> _getAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {
          'Ocp-Apim-Subscription-Key': AiConfig.azureSpeechKey,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        debugPrint('Failed to get Azure token: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting Azure token: $e');
      return null;
    }
  }

  /// Check if token is expired
  bool _isTokenExpired() {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!);
  }

  /// Ensure valid token
  Future<bool> _ensureToken() async {
    if (_accessToken == null || _isTokenExpired()) {
      return await initialize();
    }
    return true;
  }

  /// Speech-to-Text: Convert audio bytes to text
  /// [audioData] should be WAV format audio
  Future<String?> speechToText(Uint8List audioData) async {
    if (!await _ensureToken()) {
      debugPrint('Failed to get Azure token for STT');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse(_sttEndpoint),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'audio/wav',
          'Accept': 'application/json',
        },
        body: audioData,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recognitionStatus = data['RecognitionStatus'] as String?;
        
        if (recognitionStatus == 'Success') {
          return data['DisplayText'] as String?;
        } else {
          debugPrint('STT recognition status: $recognitionStatus');
          return null;
        }
      } else {
        debugPrint('Azure STT error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error in Azure STT: $e');
      return null;
    }
  }

  /// Text-to-Speech: Convert text to audio bytes
  /// Returns WAV audio data
  Future<Uint8List?> textToSpeech(String text, {String? voice}) async {
    if (text.trim().isEmpty) {
      debugPrint('Empty text for TTS');
      return null;
    }

    if (!await _ensureToken()) {
      debugPrint('Failed to get Azure token for TTS');
      return null;
    }

    try {
      final selectedVoice = voice ?? _arabicVoice;
      
      // SSML format for better control
      final ssml = '''
<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='ar-SA'>
  <voice name='$selectedVoice'>
    <prosody rate='0.9' pitch='0%'>
      $text
    </prosody>
  </voice>
</speak>
''';

      final response = await http.post(
        Uri.parse(_ttsEndpoint),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/ssml+xml',
          'X-Microsoft-OutputFormat': 'audio-16khz-128kbitrate-mono-mp3',
          'User-Agent': 'AlzCare-Lobna',
        },
        body: ssml,
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint('Azure TTS error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error in Azure TTS: $e');
      return null;
    }
  }

  /// Get list of available Arabic voices
  Future<List<Map<String, String>>> getAvailableVoices() async {
    if (!await _ensureToken()) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('https://${AiConfig.azureSpeechRegion}.tts.speech.microsoft.com/cognitiveservices/voices/list'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> voices = jsonDecode(response.body);
        // Filter Arabic voices
        return voices
            .where((v) => (v['Locale'] as String).startsWith('ar-'))
            .map((v) => {
                  'name': v['ShortName'] as String,
                  'displayName': v['DisplayName'] as String,
                  'gender': v['Gender'] as String,
                  'locale': v['Locale'] as String,
                })
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting voices: $e');
      return [];
    }
  }

  /// Check if Azure Speech is configured
  static bool get isConfigured {
    return AiConfig.azureSpeechKey.isNotEmpty &&
        AiConfig.azureSpeechKey != 'YOUR_AZURE_SPEECH_KEY_HERE' &&
        AiConfig.azureSpeechRegion.isNotEmpty;
  }

  /// Dispose resources
  void dispose() {
    _accessToken = null;
    _tokenExpiry = null;
    _isInitialized = false;
  }
}

