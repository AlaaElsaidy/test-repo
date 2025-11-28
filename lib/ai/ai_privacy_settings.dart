import '../core/shared-prefrences/shared-prefrences-helper.dart';

/// Privacy settings for AI assistant (Lobna)
/// Allows users to control data sharing and AI features
class AiPrivacySettings {
  static const String _keyVoiceEnabled = 'ai_voice_enabled';
  static const String _keyChatEnabled = 'ai_chat_enabled';
  static const String _keyLocationTracking = 'ai_location_tracking';
  static const String _keyActivityReminders = 'ai_activity_reminders';
  static const String _keyDataSharing = 'ai_data_sharing';
  static const String _keyAnalyticsEnabled = 'ai_analytics_enabled';

  /// Check if voice assistant is enabled
  static Future<bool> isVoiceEnabled() async {
    return SharedPrefsHelper.getBool(_keyVoiceEnabled) ?? true; // Default: enabled
  }

  /// Enable/disable voice assistant
  static Future<void> setVoiceEnabled(bool enabled) async {
    await SharedPrefsHelper.saveBool(_keyVoiceEnabled, enabled);
  }

  /// Check if chat assistant is enabled
  static Future<bool> isChatEnabled() async {
    return SharedPrefsHelper.getBool(_keyChatEnabled) ?? true; // Default: enabled
  }

  /// Enable/disable chat assistant
  static Future<void> setChatEnabled(bool enabled) async {
    await SharedPrefsHelper.saveBool(_keyChatEnabled, enabled);
  }

  /// Check if location tracking for AI is enabled
  static Future<bool> isLocationTrackingEnabled() async {
    return SharedPrefsHelper.getBool(_keyLocationTracking) ?? true; // Default: enabled
  }

  /// Enable/disable location tracking
  static Future<void> setLocationTrackingEnabled(bool enabled) async {
    await SharedPrefsHelper.saveBool(_keyLocationTracking, enabled);
  }

  /// Check if activity reminders are enabled
  static Future<bool> areActivityRemindersEnabled() async {
    return SharedPrefsHelper.getBool(_keyActivityReminders) ?? true; // Default: enabled
  }

  /// Enable/disable activity reminders
  static Future<void> setActivityRemindersEnabled(bool enabled) async {
    await SharedPrefsHelper.saveBool(_keyActivityReminders, enabled);
  }

  /// Check if data sharing with AI is enabled
  static Future<bool> isDataSharingEnabled() async {
    return SharedPrefsHelper.getBool(_keyDataSharing) ?? true; // Default: enabled
  }

  /// Enable/disable data sharing
  static Future<void> setDataSharingEnabled(bool enabled) async {
    await SharedPrefsHelper.saveBool(_keyDataSharing, enabled);
  }

  /// Check if analytics is enabled
  static Future<bool> isAnalyticsEnabled() async {
    return SharedPrefsHelper.getBool(_keyAnalyticsEnabled) ?? false; // Default: disabled
  }

  /// Enable/disable analytics
  static Future<void> setAnalyticsEnabled(bool enabled) async {
    await SharedPrefsHelper.saveBool(_keyAnalyticsEnabled, enabled);
  }

  /// Reset all privacy settings to defaults
  static Future<void> resetToDefaults() async {
    await setVoiceEnabled(true);
    await setChatEnabled(true);
    await setLocationTrackingEnabled(true);
    await setActivityRemindersEnabled(true);
    await setDataSharingEnabled(true);
    await setAnalyticsEnabled(false);
  }

  /// Get all settings as a map
  static Future<Map<String, bool>> getAllSettings() async {
    return {
      'voiceEnabled': await isVoiceEnabled(),
      'chatEnabled': await isChatEnabled(),
      'locationTracking': await isLocationTrackingEnabled(),
      'activityReminders': await areActivityRemindersEnabled(),
      'dataSharing': await isDataSharingEnabled(),
      'analyticsEnabled': await isAnalyticsEnabled(),
    };
  }
}

/// Simple analytics/usage tracking for AI features
class AiUsageAnalytics {
  static const String _keyTotalInteractions = 'ai_total_interactions';
  static const String _keyVoiceInteractions = 'ai_voice_interactions';
  static const String _keyChatInteractions = 'ai_chat_interactions';
  static const String _keyRemindersSent = 'ai_reminders_sent';
  static const String _keyZoneAlerts = 'ai_zone_alerts';
  static const String _keyLastInteraction = 'ai_last_interaction';

  /// Increment total interactions
  static Future<void> incrementTotalInteractions() async {
    final current = SharedPrefsHelper.getInt(_keyTotalInteractions) ?? 0;
    await SharedPrefsHelper.saveInt(_keyTotalInteractions, current + 1);
    await _updateLastInteraction();
  }

  /// Increment voice interactions
  static Future<void> incrementVoiceInteractions() async {
    final current = SharedPrefsHelper.getInt(_keyVoiceInteractions) ?? 0;
    await SharedPrefsHelper.saveInt(_keyVoiceInteractions, current + 1);
    await incrementTotalInteractions();
  }

  /// Increment chat interactions
  static Future<void> incrementChatInteractions() async {
    final current = SharedPrefsHelper.getInt(_keyChatInteractions) ?? 0;
    await SharedPrefsHelper.saveInt(_keyChatInteractions, current + 1);
    await incrementTotalInteractions();
  }

  /// Increment reminders sent
  static Future<void> incrementRemindersSent() async {
    final current = SharedPrefsHelper.getInt(_keyRemindersSent) ?? 0;
    await SharedPrefsHelper.saveInt(_keyRemindersSent, current + 1);
  }

  /// Increment zone alerts
  static Future<void> incrementZoneAlerts() async {
    final current = SharedPrefsHelper.getInt(_keyZoneAlerts) ?? 0;
    await SharedPrefsHelper.saveInt(_keyZoneAlerts, current + 1);
  }

  /// Update last interaction timestamp
  static Future<void> _updateLastInteraction() async {
    await SharedPrefsHelper.saveString(
      _keyLastInteraction,
      DateTime.now().toIso8601String(),
    );
  }

  /// Get usage statistics
  static Future<Map<String, dynamic>> getUsageStats() async {
    return {
      'totalInteractions': SharedPrefsHelper.getInt(_keyTotalInteractions) ?? 0,
      'voiceInteractions': SharedPrefsHelper.getInt(_keyVoiceInteractions) ?? 0,
      'chatInteractions': SharedPrefsHelper.getInt(_keyChatInteractions) ?? 0,
      'remindersSent': SharedPrefsHelper.getInt(_keyRemindersSent) ?? 0,
      'zoneAlerts': SharedPrefsHelper.getInt(_keyZoneAlerts) ?? 0,
      'lastInteraction': SharedPrefsHelper.getString(_keyLastInteraction),
    };
  }

  /// Reset all analytics
  static Future<void> reset() async {
    await SharedPrefsHelper.remove(_keyTotalInteractions);
    await SharedPrefsHelper.remove(_keyVoiceInteractions);
    await SharedPrefsHelper.remove(_keyChatInteractions);
    await SharedPrefsHelper.remove(_keyRemindersSent);
    await SharedPrefsHelper.remove(_keyZoneAlerts);
    await SharedPrefsHelper.remove(_keyLastInteraction);
  }
}

