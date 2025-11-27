import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../config/env/env_config.dart';

class TtsPlaybackResult {
  final bool success;
  final String? error;

  const TtsPlaybackResult({required this.success, this.error});

  factory TtsPlaybackResult.success() =>
      const TtsPlaybackResult(success: true);

  factory TtsPlaybackResult.failure(String message) =>
      TtsPlaybackResult(success: false, error: message);
}

abstract class TextToSpeechProvider {
  Future<TtsPlaybackResult> speak(String text);

  Future<void> stop();
}

class DeviceTextToSpeechProvider implements TextToSpeechProvider {
  DeviceTextToSpeechProvider({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    // Configuration will happen lazily on first use
  }

  final FlutterTts _tts;
  bool _initialised = false;

  Future<void> _configure() async {
    if (_initialised) return;
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('ar-EG');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _initialised = true;
    } catch (e) {
      debugPrint('TTS configuration failed: $e');
    }
  }

  Future<void> _ensureConfigured() async {
    await _configure();
  }

  @override
  Future<TtsPlaybackResult> speak(String text) async {
    if (text.trim().isEmpty) {
      return TtsPlaybackResult.failure('النص فارغ.');
    }
    await _ensureConfigured();
    try {
      await _tts.speak(text);
      return TtsPlaybackResult.success();
    } catch (e) {
      return TtsPlaybackResult.failure('خطأ في تحويل النص إلى كلام: $e');
    }
  }

  @override
  Future<void> stop() => _tts.stop();
}

class AzureTextToSpeechProvider implements TextToSpeechProvider {
  AzureTextToSpeechProvider({
    Dio? dio,
    AudioPlayer? audioPlayer,
  })  : _dio = dio ?? Dio(),
        _audioPlayer = audioPlayer ?? AudioPlayer();

  final Dio _dio;
  final AudioPlayer _audioPlayer;

  static const String _voice = 'ar-EG-SalmaNeural';

  @override
  Future<TtsPlaybackResult> speak(String text) async {
    if (text.trim().isEmpty) {
      return TtsPlaybackResult.failure('النص فارغ.');
    }

    final apiKey = EnvConfig.azureTtsApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      return TtsPlaybackResult.failure(
          'مفتاح Azure TTS غير متوفر. يرجى التحقق من الإعدادات.');
    }

    try {
      // Stop any currently playing audio
      await stop();

      // Get Azure TTS endpoint
      final region = EnvConfig.azureTtsRegion;
      
      // Azure TTS endpoint format: https://{region}.tts.speech.microsoft.com/cognitiveservices/v1
      // If custom endpoint is provided, append /cognitiveservices/v1 if needed
      final customEndpoint = dotenv.maybeGet('AZURE_TTS_ENDPOINT')?.trim();
      String endpoint;
      if (customEndpoint != null && customEndpoint.isNotEmpty) {
        // If custom endpoint is provided, use it but ensure it has the path
        if (customEndpoint.contains('/cognitiveservices/v1')) {
          endpoint = customEndpoint;
        } else {
          // Append the path if not present
          endpoint = customEndpoint.endsWith('/')
              ? '${customEndpoint}cognitiveservices/v1'
              : '$customEndpoint/cognitiveservices/v1';
        }
      } else {
        // Default endpoint format
        endpoint = 'https://$region.tts.speech.microsoft.com/cognitiveservices/v1';
      }

      // Create SSML for Arabic text
      final ssml = _buildSsml(text);

      // Get temporary directory for audio file
      final tempDir = await getTemporaryDirectory();
      final audioFile = File(path.join(tempDir.path, 'azure_tts_${DateTime.now().millisecondsSinceEpoch}.wav'));

      debugPrint('🔵 [Azure TTS] Generating speech for text: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
      debugPrint('🔵 [Azure TTS] Endpoint: $endpoint');
      debugPrint('🔵 [Azure TTS] Region: $region');
      debugPrint('🔵 [Azure TTS] Voice: $_voice');

      // Call Azure TTS REST API
      final response = await _dio.post(
        endpoint,
        data: ssml,
        options: Options(
          headers: {
            'Ocp-Apim-Subscription-Key': apiKey,
            'Content-Type': 'application/ssml+xml',
            'X-Microsoft-OutputFormat': 'riff-24khz-16bit-mono-pcm',
            'User-Agent': 'AlzCare-TTS',
          },
          responseType: ResponseType.bytes,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode != 200) {
        String errorMsg;
        if (response.data is String) {
          errorMsg = response.data as String;
        } else if (response.data is Map) {
          errorMsg = (response.data as Map)['error']?['message']?.toString() ?? 
                     response.data.toString();
        } else {
          errorMsg = 'خطأ في Azure TTS: ${response.statusCode}';
        }
        debugPrint('❌ [Azure TTS] API Error: ${response.statusCode}');
        debugPrint('❌ [Azure TTS] Error details: $errorMsg');
        debugPrint('❌ [Azure TTS] Response data type: ${response.data.runtimeType}');
        debugPrint('❌ [Azure TTS] Response data: ${response.data}');
        
        // Fallback to device TTS on Azure error
        debugPrint('⚠️ [Azure TTS] Falling back to device TTS');
        try {
          final deviceProvider = DeviceTextToSpeechProvider();
          final result = await deviceProvider.speak(text);
          if (result.success) {
            debugPrint('✅ [Azure TTS] Device TTS fallback successful');
          }
          return result;
        } catch (e) {
          debugPrint('❌ [Azure TTS] Device TTS fallback also failed: $e');
          return TtsPlaybackResult.failure('فشل تحويل النص إلى كلام: $errorMsg');
        }
      }

      // Save audio bytes to file
      await audioFile.writeAsBytes(response.data as List<int>);
      debugPrint('✅ [Azure TTS] Audio generated and saved to: ${audioFile.path}');

      // Play audio using just_audio
      await _audioPlayer.setFilePath(audioFile.path);
      await _audioPlayer.play();
      await _audioPlayer.playerStateStream
          .firstWhere((state) => state.processingState == ProcessingState.completed);

      // Clean up temporary file
      try {
        await audioFile.delete();
      } catch (e) {
        debugPrint('⚠️ [Azure TTS] Failed to delete temp file: $e');
      }

      debugPrint('✅ [Azure TTS] Playback completed');
      return TtsPlaybackResult.success();
    } catch (e) {
      debugPrint('❌ [Azure TTS] Error: $e');
      return TtsPlaybackResult.failure('خطأ في تحويل النص إلى كلام: $e');
    }
  }

  String _buildSsml(String text) {
    // Escape special XML characters
    final escapedText = text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    return '''<?xml version="1.0" encoding="utf-8"?>
<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="ar-EG">
  <voice name="$_voice">
    <prosody rate="0.95" pitch="+0Hz">
      $escapedText
    </prosody>
  </voice>
</speak>''';
  }

  @override
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('⚠️ [Azure TTS] Error stopping playback: $e');
    }
  }
}

class LobnaTtsService {
  LobnaTtsService._(this._provider);

  final TextToSpeechProvider _provider;

  factory LobnaTtsService() {
    switch (EnvConfig.ttsProvider) {
      case TtsProviderType.azure:
        return LobnaTtsService._(AzureTextToSpeechProvider());
      case TtsProviderType.device:
      default:
        return LobnaTtsService._(DeviceTextToSpeechProvider());
    }
  }

  Future<TtsPlaybackResult> speak(String text) => _provider.speak(text);

  Future<void> stop() => _provider.stop();
}

