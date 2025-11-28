import 'dart:async';
import 'package:flutter/foundation.dart';
import 'speech_recognition_service.dart';
import 'text_to_speech_service.dart';
import 'ai_chat_service.dart';
import 'context_manager.dart';

/// Main controller for Lobna voice assistant
/// Manages states and coordinates all AI services
enum LobnaState {
  idle, // Not doing anything
  listening, // Listening to user speech
  processing, // Processing user message with AI
  speaking, // Speaking response
}

class LobnaVoiceController extends ChangeNotifier {
  final SpeechRecognitionService _sttService = SpeechRecognitionService();
  final TextToSpeechService _ttsService = TextToSpeechService();
  final AiChatService _aiChatService = AiChatService();
  final ContextManager _contextManager = ContextManager();

  LobnaState _state = LobnaState.idle;
  String? _lastRecognizedText;
  String? _lastResponse;
  StreamSubscription<String>? _sttSubscription;
  StreamSubscription<bool>? _listeningSubscription;

  LobnaState get state => _state;
  String? get lastRecognizedText => _lastRecognizedText;
  String? get lastResponse => _lastResponse;

  /// Initialize all services
  Future<bool> initialize() async {
    try {
      // Initialize STT
      final sttInitialized = await _sttService.initialize();
      if (!sttInitialized) {
        debugPrint('Failed to initialize STT');
        return false;
      }

      // Initialize TTS
      final ttsInitialized = await _ttsService.initialize();
      if (!ttsInitialized) {
        debugPrint('Failed to initialize TTS');
        return false;
      }

      // Listen to STT results
      _sttSubscription = _sttService.recognitionResult.listen(
        _onSpeechRecognized,
        onError: (error) {
          debugPrint('STT error: $error');
          _setState(LobnaState.idle);
        },
      );

      // Listen to listening state
      _listeningSubscription = _sttService.listeningState.listen(
        (isListening) {
          if (!isListening && _state == LobnaState.listening) {
            // Finished listening, start processing
            if (_lastRecognizedText != null && _lastRecognizedText!.isNotEmpty) {
              _processUserMessage(_lastRecognizedText!);
            } else {
              _setState(LobnaState.idle);
            }
          }
        },
      );

      return true;
    } catch (e) {
      debugPrint('Error initializing Lobna controller: $e');
      return false;
    }
  }

  /// Start listening to user speech
  Future<bool> startListening({String localeId = 'ar-EG'}) async {
    if (_state != LobnaState.idle) {
      debugPrint('Cannot start listening, current state: $_state');
      return false;
    }

    try {
      _lastRecognizedText = null;
      final started = await _sttService.startListening(localeId: localeId);
      if (started) {
        _setState(LobnaState.listening);
      }
      return started;
    } catch (e) {
      debugPrint('Error starting listening: $e');
      _setState(LobnaState.idle);
      return false;
    }
  }

  /// Stop listening
  void stopListening() {
    _sttService.stopListening();
    if (_state == LobnaState.listening) {
      _setState(LobnaState.idle);
    }
  }

  /// Cancel listening
  void cancelListening() {
    _sttService.cancelListening();
    _setState(LobnaState.idle);
  }

  /// Process user message (text input)
  Future<void> processUserMessage(String message) async {
    if (message.trim().isEmpty) return;
    _lastRecognizedText = message;
    await _processUserMessage(message);
  }

  /// Handle recognized speech
  void _onSpeechRecognized(String text) {
    if (text.trim().isNotEmpty) {
      _lastRecognizedText = text;
      debugPrint('Recognized: $text');
    }
  }

  /// Process user message with AI
  Future<void> _processUserMessage(String message) async {
    if (_state == LobnaState.processing) return;

    _setState(LobnaState.processing);
    debugPrint('Processing message: $message');

    try {
      // Get AI response
      final response = await _aiChatService.sendMessage(message);
      debugPrint('AI response received: $response');
      _lastResponse = response;
      notifyListeners(); // Notify listeners that response is ready

      // Speak the response
      await speak(response);
    } catch (e) {
      debugPrint('Error processing message: $e');
      _lastResponse = 'عذراً، حدث خطأ. هل يمكنك إعادة المحاولة؟';
      notifyListeners();
      _setState(LobnaState.idle);
      // Fallback message
      await speak(_lastResponse!);
    }
  }

  /// Speak text using TTS
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    try {
      _setState(LobnaState.speaking);
      final success = await _ttsService.speak(text);

      if (success) {
        // Wait for TTS to complete (approximate)
        // TTS completion is handled by TTS service callbacks
        // We'll set state to idle after a delay or when TTS completes
        await Future.delayed(const Duration(seconds: 1));
      }

      _setState(LobnaState.idle);
    } catch (e) {
      debugPrint('Error speaking: $e');
      _setState(LobnaState.idle);
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _ttsService.stop();
    if (_state == LobnaState.speaking) {
      _setState(LobnaState.idle);
    }
  }

  /// Get context (for debugging or UI display)
  Future<String> getContext() async {
    return await _contextManager.buildContext();
  }

  /// Clear conversation history
  void clearHistory() {
    _aiChatService.clearHistory();
  }

  /// Set state and notify listeners
  void _setState(LobnaState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  /// Check if listening is available
  Future<bool> isListeningAvailable() async {
    return await _sttService.isAvailable();
  }

  /// Dispose all resources
  @override
  void dispose() {
    _sttSubscription?.cancel();
    _listeningSubscription?.cancel();
    _sttService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}

