import 'package:flutter/material.dart';

import '../core/supabase/safe-zone-service.dart';
import '../services/lobna/lobna_voice_controller.dart';
import '../services/lobna/safe_zone_monitor.dart';
import '../screens/services/chat_manager.dart';

class LobnaListenButton extends StatefulWidget {
  const LobnaListenButton({
    super.key,
    required this.controller,
    this.onTranscript,
    this.onReplyRequested,
    this.localeId = 'ar_EG',
    this.label = 'استمع',
    this.chatManager,
    this.chatId,
    this.patientId,
    this.safeZones,
    this.currentLatitude,
    this.currentLongitude,
  });

  final LobnaVoiceController controller;
  final ValueChanged<String>? onTranscript;
  final Future<String?> Function(String transcript)? onReplyRequested;
  final String localeId;
  final String label;
  final ChatManager? chatManager;
  final String? chatId;
  final String? patientId;
  final List<SafeZone>? safeZones;
  final double? currentLatitude;
  final double? currentLongitude;

  @override
  State<LobnaListenButton> createState() => _LobnaListenButtonState();
}

class _LobnaListenButtonState extends State<LobnaListenButton> {
  String? _status;

  // Use widget.controller directly - it's always initialized since it's required
  LobnaVoiceController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(covariant LobnaListenButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onStateChanged);
      widget.controller.addListener(_onStateChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {
      switch (controller.state) {
        case LobnaVoiceState.listening:
          _status = 'جارٍ الاستماع...';
          break;
        case LobnaVoiceState.processing:
          _status = 'أحلل كلامك...';
          break;
        case LobnaVoiceState.speaking:
          _status = 'أرد عليك...';
          break;
        case LobnaVoiceState.error:
          _status = controller.lastError ?? 'حدث خطأ';
          break;
        case LobnaVoiceState.idle:
          _status = null;
          break;
      }
    });
  }

  Future<void> _handlePress() async {
    final transcript =
        await controller.listen(localeId: widget.localeId);
    if (transcript == null || transcript.isEmpty) {
      return;
    }

    widget.onTranscript?.call(transcript);

    if (widget.onReplyRequested != null) {
      final reply = await widget.onReplyRequested!(transcript);
      if (reply != null && reply.isNotEmpty) {
        await controller.speak(reply);
        return;
      }
    }

    // جلب history من chat manager إذا كان متاحاً
    List<Map<String, String>> history = [];
    if (widget.chatManager != null && widget.chatId != null) {
      final messages = widget.chatManager!.getMessages(widget.chatId!);
      history = messages
          .map((msg) => {
                'role': msg.sender == 'lobna' ? 'assistant' : 'user',
                'content': msg.text,
              })
          .toList();
    }

    // تقييم Safe Zone status إذا كانت البيانات متاحة
    String? safeZoneStatus;
    if (widget.safeZones != null &&
        widget.safeZones!.isNotEmpty &&
        widget.currentLatitude != null &&
        widget.currentLongitude != null) {
      final evaluation = SafeZoneMonitor.evaluate(
        latitude: widget.currentLatitude!,
        longitude: widget.currentLongitude!,
        zones: widget.safeZones!,
      );
      safeZoneStatus = evaluation.isInside
          ? 'داخل المنطقة الآمنة'
          : 'خارج المنطقة الآمنة';
    }

    // استدعاء generateAssistantReply مع history و patientId و safeZoneStatus
    final reply = await controller.generateAssistantReply(
      transcript,
      history: history,
      patientId: widget.patientId,
      safeZoneStatus: safeZoneStatus,
    );
    await controller.speak(reply);
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = controller.state == LobnaVoiceState.listening ||
        controller.state == LobnaVoiceState.processing ||
        controller.state == LobnaVoiceState.speaking;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: 'lobna_listen_button',
          onPressed: isBusy ? null : _handlePress,
          label: Text(isBusy ? '...' : widget.label),
          icon: Icon(
            controller.state == LobnaVoiceState.listening
                ? Icons.hearing
                : Icons.mic,
          ),
        ),
        if (_status != null) ...[
          const SizedBox(height: 8),
          Text(
            _status!,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.black87),
          ),
        ],
      ],
    );
  }
}

