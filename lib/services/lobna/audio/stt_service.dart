import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../config/env/env_config.dart';

class SttCaptureResult {
  final bool success;
  final String? text;
  final String? error;
  final Duration elapsed;

  const SttCaptureResult({
    required this.success,
    this.text,
    this.error,
    this.elapsed = Duration.zero,
  });

  factory SttCaptureResult.success(String text, Duration elapsed) =>
      SttCaptureResult(success: true, text: text, elapsed: elapsed);

  factory SttCaptureResult.failure(String message) =>
      SttCaptureResult(success: false, error: message);
}

abstract class SpeechToTextProvider {
  Future<SttCaptureResult> transcribe({
    Duration listenFor,
    Duration pauseFor,
    String? localeId,
  });

  Future<void> cancel();
}

class DeviceSpeechToTextProvider implements SpeechToTextProvider {
  DeviceSpeechToTextProvider({
    stt.SpeechToText? speech,
    List<String>? fallbackLocales,
  })  : _speech = speech ?? stt.SpeechToText(),
        _locales = fallbackLocales ?? const ['ar_EG', 'ar_SA', 'en_US'];

  final stt.SpeechToText _speech;
  final List<String> _locales;
  bool _initialised = false;

  /// Returns true only if speech recognition is currently listening
  /// Safe to call even if not initialized - returns false instead of throwing
  bool get _isListeningSafe {
    if (!_initialised) return false;
    try {
      return _speech.isListening;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _ensureInit() async {
    if (_initialised) return true;
    try {
      final available = await _speech.initialize(
        onError: (error) => debugPrint('STT error: $error'),
        onStatus: (status) => debugPrint('STT status: $status'),
      );
      _initialised = available;
      return available;
    } catch (e) {
      debugPrint('STT initialization failed: $e');
      return false;
    }
  }

  String _resolveLocale(String? preferred) {
    if (preferred != null) return preferred;
    return _locales.first;
  }

  @override
  Future<SttCaptureResult> transcribe({
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 5),
    String? localeId,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      if (!await _ensureInit()) {
        return SttCaptureResult.failure(
            'تعذّر تهيئة التعرف على الصوت. تأكد من الأذونات.');
      }

      final hasPermission = await _speech.hasPermission;
      if (!hasPermission) {
        final allowed = await _speech.initialize();
        final granted = await _speech.hasPermission;
        if (!allowed || !granted) {
          return SttCaptureResult.failure(
              'الميكروفون غير مفعّل. الرجاء منح الإذن.');
        }
      }

      String transcript = '';
      final completer = Completer<void>();
      await _speech.listen(
        localeId: _resolveLocale(localeId),
        listenFor: listenFor,
        pauseFor: pauseFor,
        onResult: (result) {
          transcript = result.recognizedWords;
          if (result.finalResult && !completer.isCompleted) {
            completer.complete();
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
        ),
      );

      await Future.any([
        Future.delayed(listenFor + const Duration(seconds: 1)),
        completer.future,
      ]);

      await _speech.stop();
      stopwatch.stop();

      if (transcript.trim().isEmpty) {
        return SttCaptureResult.failure('لم أسمع أي كلام. حاول مرة أخرى.');
      }

      return SttCaptureResult.success(transcript.trim(), stopwatch.elapsed);
    } catch (e) {
      stopwatch.stop();
      await _speech.cancel();
      return SttCaptureResult.failure('حدث خطأ أثناء الاستماع: $e');
    }
  }

  @override
  Future<void> cancel() async {
    // Use safe getter to avoid NotInitializedError
    if (_isListeningSafe) {
      try {
        await _speech.cancel();
      } catch (e) {
        debugPrint('STT cancel failed: $e');
      }
    }
  }
}

class LocalWhisperSttProvider implements SpeechToTextProvider {
  LocalWhisperSttProvider({
    required this.endpoint,
    AudioRecorder? recorder,
  }) : _recorder = recorder ?? AudioRecorder();

  final Uri endpoint;
  final AudioRecorder _recorder;

  @override
  Future<SttCaptureResult> transcribe({
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 5),
    String? localeId,
  }) async {
    final stopwatch = Stopwatch()..start();
    String? path;
    Directory? tempDir;
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        return SttCaptureResult.failure('مطلوب إذن الميكروفون للتسجيل المحلي.');
      }

      tempDir = await Directory.systemTemp.createTemp('lobna_stt_');
      final targetPath =
          '${tempDir.path}${Platform.pathSeparator}capture.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          bitRate: 128000,
        ),
        path: targetPath,
      );

      await Future.delayed(listenFor);
      path = await _recorder.stop();
      stopwatch.stop();

      if (path == null) {
        return SttCaptureResult.failure('لم أستطع تسجيل الصوت.');
      }

      final file = File(path);
      if (!await file.exists()) {
        return SttCaptureResult.failure('ملف الصوت غير متاح.');
      }

      final request = http.MultipartRequest('POST', endpoint)
        ..fields['model'] = EnvConfig.localSttModel
        ..fields['locale'] = localeId ?? 'ar_EG'
        ..files.add(await http.MultipartFile.fromPath('audio', file.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        return SttCaptureResult.failure(
            'الخادم المحلي رفض الطلب: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = (data['text'] as String?)?.trim() ?? '';

      if (text.isEmpty) {
        return SttCaptureResult.failure('لم يتمكن المزود المحلي من فهم الصوت.');
      }

      return SttCaptureResult.success(text, stopwatch.elapsed);
    } catch (e) {
      return SttCaptureResult.failure('فشل المزود المحلي: $e');
    } finally {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      if (tempDir != null && await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  @override
  Future<void> cancel() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }
}

class LobnaSttService {
  LobnaSttService._(this._provider);

  final SpeechToTextProvider _provider;

  factory LobnaSttService() {
    switch (EnvConfig.sttProvider) {
      case SttProviderType.local:
        return LobnaSttService._(
          LocalWhisperSttProvider(endpoint: EnvConfig.localSttEndpoint),
        );
      case SttProviderType.device:
        return LobnaSttService._(DeviceSpeechToTextProvider());
    }
  }

  Future<SttCaptureResult> capture({
    Duration listenFor = const Duration(seconds: 30),
    String localeId = 'ar_EG',
  }) {
    return _provider.transcribe(listenFor: listenFor, localeId: localeId);
  }

  Future<void> cancel() => _provider.cancel();
}

