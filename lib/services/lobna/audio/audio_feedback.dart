import 'package:flutter/services.dart';

class LobnaAudioFeedback {
  static Future<void> startListeningTone() =>
      SystemSound.play(SystemSoundType.alert);

  static Future<void> endListeningTone() =>
      SystemSound.play(SystemSoundType.click);
}

