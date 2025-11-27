import '../../core/supabase/safe-zone-service.dart';
import 'lobna_voice_controller.dart';
import 'prompts/lobna_dialect_adapter.dart';
import 'prompts/lobna_prompts.dart';
import 'safe_zone_monitor.dart';

class LobnaScenarioEngine {
  LobnaScenarioEngine({
    required LobnaVoiceController voiceController,
  }) : _voiceController = voiceController;

  final LobnaVoiceController _voiceController;

  bool? _lastInside;

  Future<SafeZoneAlertResult> handleLocationStatus({
    required double latitude,
    required double longitude,
    required List<SafeZone> zones,
    String? patientId,
    String? locationHint,
    String? familyContactName,
  }) async {
    final evaluation = SafeZoneMonitor.evaluate(
      latitude: latitude,
      longitude: longitude,
      zones: zones,
    );

    final changed = _lastInside == null || evaluation.isInside != _lastInside;
    _lastInside = evaluation.isInside;

    if (!changed) {
      return SafeZoneAlertResult(
        isInside: evaluation.isInside,
        triggeredChange: false,
        zoneName: evaluation.closestZone?.name,
        locationHint: locationHint,
      );
    }

    if (!evaluation.isInside) {
      final hint = locationHint ??
          (evaluation.closestZone?.address ??
              evaluation.closestZone?.name ??
              'موقعك الحالي');
      final prompt = LobnaPromptBuilder.safeZoneAlertPrompt(
        hint,
        familyContact: familyContactName,
      );
      final reply = await _voiceController.generateAssistantReply(
        prompt,
        patientId: patientId,
      );
      await _voiceController.speak(reply);
      return SafeZoneAlertResult(
        isInside: false,
        triggeredChange: true,
        zoneName: evaluation.closestZone?.name,
        locationHint: hint,
        spokenMessage: reply,
      );
    } else {
      final message =
          LobnaDialectAdapter.ensureMasri('عظيم! رجعت للمنطقة الآمنة تاني. لو محتاج أي مساعدة أنا معاكي. ما تقلقش.');
      await _voiceController.speak(message);
      return SafeZoneAlertResult(
        isInside: true,
        triggeredChange: true,
        zoneName: null,
        locationHint: null,
        spokenMessage: message,
      );
    }
  }
}

class SafeZoneAlertResult {
  const SafeZoneAlertResult({
    required this.isInside,
    required this.triggeredChange,
    this.zoneName,
    this.locationHint,
    this.spokenMessage,
  });

  final bool isInside;
  final bool triggeredChange;
  final String? zoneName;
  final String? locationHint;
  final String? spokenMessage;
}

