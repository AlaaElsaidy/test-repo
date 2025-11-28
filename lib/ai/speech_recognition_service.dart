import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'ai_config.dart';
import 'azure_speech_service.dart';

/// Service for Speech-to-Text conversion
/// Supports both local STT and Azure Speech Services
class SpeechRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AzureSpeechService _azureService = AzureSpeechService();
  bool _isInitialized = false;
  bool _isListening = false;
  final StreamController<String> _resultController =
      StreamController<String>.broadcast();
  final StreamController<bool> _listeningStateController =
      StreamController<bool>.broadcast();

  Stream<String> get recognitionResult => _resultController.stream;
  Stream<bool> get listeningState => _listeningStateController.stream;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize Azure if enabled
      if (AiConfig.useAzureSpeech && AzureSpeechService.isConfigured) {
        final azureInit = await _azureService.initialize();
        if (azureInit) {
          debugPrint('Azure STT initialized successfully');
        }
      }

      // Always initialize local STT as fallback
      final available = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: ${error.errorMsg}');
          _resultController.addError(error.errorMsg);
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            _listeningStateController.add(false);
          }
        },
      );

      _isInitialized = available || (AiConfig.useAzureSpeech && AzureSpeechService.isConfigured);
      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
      return false;
    }
  }

  /// Start listening for speech
  /// Returns true if started successfully
  Future<bool> startListening({
    String localeId = 'ar-EG', // Egyptian Arabic by default
    bool listenFor = true,
    Duration? pauseFor,
    stt.SpeechListenOptions? listenOptions,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('Speech recognition not available');
        return false;
      }
    }

    if (_isListening) {
      debugPrint('Already listening');
      return true;
    }

    try {
      // Use local speech recognition (Azure STT requires audio file upload)
      // For real-time recognition, we use the device's speech recognition
      // Azure STT is better for processing recorded audio files
      
      final options = listenOptions ??
          stt.SpeechListenOptions(
            cancelOnError: true,
            partialResults: true,
          );

      // Try different locale formats
      String? actualLocale = localeId;
      final availableLocales = await _speech.locales();
      // Filter Arabic locales by checking localeId starts with 'ar'
      final arLocales = availableLocales.where((l) => 
        l.localeId.startsWith('ar') || l.localeId.startsWith('ar_') || l.localeId.startsWith('ar-')
      ).toList();
      
      if (arLocales.isNotEmpty) {
        // Prefer Egyptian Arabic, fallback to any Arabic
        try {
          actualLocale = arLocales.firstWhere(
            (l) => l.localeId.contains('EG') || l.localeId.contains('eg') || l.localeId.contains('_EG') || l.localeId.contains('-EG'),
            orElse: () => arLocales.first,
          ).localeId;
        } catch (e) {
          actualLocale = arLocales.first.localeId;
        }
        debugPrint('Using locale: $actualLocale');
      } else {
        debugPrint('No Arabic locales found, using: $localeId');
      }

      final result = await _speech.listen(
        onResult: (result) {
          debugPrint('Speech result: ${result.recognizedWords}, final: ${result.finalResult}');
          if (result.finalResult) {
            _handleResult(result);
          } else if (result.recognizedWords.isNotEmpty) {
            // Show partial results
            _resultController.add(result.recognizedWords);
          }
        },
        localeId: actualLocale ?? localeId,
        listenFor: listenFor ? const Duration(seconds: 30) : null,
        pauseFor: pauseFor ?? const Duration(seconds: 3),
        listenOptions: options,
      );

      if (result) {
        _isListening = true;
        _listeningStateController.add(true);
      }

      return result;
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      return false;
    }
  }

  /// Convert audio bytes to text using Azure (for recorded audio)
  Future<String?> transcribeAudio(Uint8List audioData) async {
    if (!AiConfig.useAzureSpeech || !AzureSpeechService.isConfigured) {
      debugPrint('Azure STT not configured');
      return null;
    }

    try {
      return await _azureService.speechToText(audioData);
    } catch (e) {
      debugPrint('Error transcribing audio: $e');
      return null;
    }
  }

  /// Stop listening
  void stopListening() {
    if (!_isListening) return;

    try {
      _speech.stop();
      _isListening = false;
      _listeningStateController.add(false);
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
    }
  }

  /// Cancel listening
  void cancelListening() {
    try {
      _speech.cancel();
      _isListening = false;
      _listeningStateController.add(false);
    } catch (e) {
      debugPrint('Error canceling speech recognition: $e');
    }
  }

  void _handleResult(SpeechRecognitionResult result) {
    if (result.recognizedWords.isNotEmpty) {
      _resultController.add(result.recognizedWords);
    }
  }

  /// Check if speech recognition is available
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      return await initialize();
    }
    return _isInitialized;
  }

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Check if using Azure
  bool get isUsingAzure => AiConfig.useAzureSpeech && AzureSpeechService.isConfigured;

  /// Get available locales
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speech.locales();
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _resultController.close();
    _listeningStateController.close();
    _azureService.dispose();
  }
}
