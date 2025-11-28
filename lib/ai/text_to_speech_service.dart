import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'ai_config.dart';
import 'azure_speech_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Service for Text-to-Speech conversion
/// Supports both local TTS and Azure Speech Services
class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  final AzureSpeechService _azureService = AzureSpeechService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// Initialize TTS service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize Azure if enabled
      if (AiConfig.useAzureSpeech && AzureSpeechService.isConfigured) {
        final azureInit = await _azureService.initialize();
        if (azureInit) {
          debugPrint('Azure TTS initialized successfully');
          _isInitialized = true;
          return true;
        }
        debugPrint('Azure TTS failed, falling back to local TTS');
      }

      // Fallback to local TTS
      await _flutterTts.setLanguage("ar-SA");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('TTS completed');
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS error: $msg');
      });

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('TTS started');
      });

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      return false;
    }
  }

  /// Speak text
  /// Uses Azure Speech if enabled, otherwise falls back to local TTS
  Future<bool> speak(String text, {String? language}) async {
    if (text.trim().isEmpty) {
      debugPrint('Empty text, skipping TTS');
      return false;
    }

    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('TTS not initialized');
        return false;
      }
    }

    // Stop any ongoing speech
    if (_isSpeaking) {
      await stop();
    }

    try {
      // Try Azure Speech first if enabled
      if (AiConfig.useAzureSpeech && AzureSpeechService.isConfigured) {
        final success = await _speakWithAzure(text);
        if (success) return true;
        debugPrint('Azure TTS failed, falling back to local');
      }

      // Fallback to local TTS
      return await _speakWithLocal(text, language: language);
    } catch (e) {
      debugPrint('Error speaking text: $e');
      return false;
    }
  }

  /// Speak using Azure Speech Services
  Future<bool> _speakWithAzure(String text) async {
    try {
      _isSpeaking = true;
      
      final audioData = await _azureService.textToSpeech(
        text,
        voice: AiConfig.azureVoice,
      );

      if (audioData == null) {
        _isSpeaking = false;
        return false;
      }

      // Save audio to temp file and play
      final success = await _playAudioBytes(audioData);
      _isSpeaking = false;
      return success;
    } catch (e) {
      debugPrint('Error in Azure TTS: $e');
      _isSpeaking = false;
      return false;
    }
  }

  /// Play audio bytes using audioplayers
  Future<bool> _playAudioBytes(Uint8List audioData) async {
    try {
      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/lobna_speech.mp3');
      await tempFile.writeAsBytes(audioData);

      // Play using audioplayers
      await _audioPlayer.play(DeviceFileSource(tempFile.path));
      
      // Wait for completion
      await _audioPlayer.onPlayerComplete.first;
      
      debugPrint('Azure TTS audio played successfully');
      return true;
    } catch (e) {
      debugPrint('Error playing audio: $e');
      return false;
    }
  }

  /// Speak using local TTS
  Future<bool> _speakWithLocal(String text, {String? language}) async {
    try {
      if (language != null) {
        await _flutterTts.setLanguage(language);
      }

      final result = await _flutterTts.speak(text);
      return result == 1;
    } catch (e) {
      debugPrint('Error in local TTS: $e');
      return false;
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }

  /// Pause speaking
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      debugPrint('Error pausing TTS: $e');
    }
  }

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Check if using Azure
  bool get isUsingAzure => AiConfig.useAzureSpeech && AzureSpeechService.isConfigured;

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Error setting speech rate: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  /// Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
    } catch (e) {
      debugPrint('Error setting pitch: $e');
    }
  }

  /// Get available languages
  Future<List<dynamic>> getAvailableLanguages() async {
    try {
      return await _flutterTts.getLanguages;
    } catch (e) {
      debugPrint('Error getting languages: $e');
      return [];
    }
  }

  /// Get available Azure voices (Arabic)
  Future<List<Map<String, String>>> getAzureVoices() async {
    if (AzureSpeechService.isConfigured) {
      return await _azureService.getAvailableVoices();
    }
    return [];
  }

  /// Dispose resources
  void dispose() {
    stop();
    _audioPlayer.dispose();
    _azureService.dispose();
  }
}
