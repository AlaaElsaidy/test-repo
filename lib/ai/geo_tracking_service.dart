import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../core/supabase/safe-zone-service.dart';
import '../core/supabase/notification-service.dart';
import '../core/supabase/supabase-service.dart';
import '../core/shared-prefrences/shared-prefrences-helper.dart';
import 'text_to_speech_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for monitoring safe zones and alerting when patient leaves
class GeoTrackingService {
  final SafeZoneService _safeZoneService = SafeZoneService();
  final TextToSpeechService _ttsService = TextToSpeechService();
  final NotificationService _notificationService = NotificationService();
  final PatientService _patientService = PatientService();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<Position>? _positionStream;
  List<SafeZone> _safeZones = [];
  bool _isMonitoring = false;
  String? _lastZoneId; // Track which zone patient was in
  String? _patientId; // Patient record ID for notifications

  /// Start monitoring patient location
  Future<void> startMonitoring() async {
    if (_isMonitoring) {
      debugPrint('Already monitoring location');
      return;
    }

    try {
      // Initialize TTS
      await _ttsService.initialize();

      // Initialize notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings =
          InitializationSettings(android: androidSettings, iOS: iosSettings);
      await _notifications.initialize(initSettings);

      // Load safe zones
      await _loadSafeZones();

      // Request location permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied forever');
        return;
      }

      // Start listening to position updates
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (position) => _onPositionUpdate(position),
        onError: (error) {
          debugPrint('Location stream error: $error');
        },
      );

      _isMonitoring = true;
      debugPrint('Started monitoring location');
    } catch (e) {
      debugPrint('Error starting location monitoring: $e');
    }
  }

  /// Stop monitoring
  void stopMonitoring() {
    _positionStream?.cancel();
    _positionStream = null;
    _isMonitoring = false;
    debugPrint('Stopped monitoring location');
  }

  /// Load safe zones for current patient
  Future<void> _loadSafeZones() async {
    try {
      final userId = SharedPrefsHelper.getString("userId") ??
          SharedPrefsHelper.getString("patientUid");

      if (userId == null) {
        debugPrint('User ID not found for safe zones');
        return;
      }

      // Get patient record ID for notifications
      final patient = await _patientService.getPatientByUserId(userId);
      if (patient != null && patient['id'] != null) {
        _patientId = patient['id'] as String;
      }

      final zones = await _safeZoneService.getSafeZonesByPatient(userId);
      _safeZones = zones.where((zone) => zone.isActive).toList();
      debugPrint('Loaded ${_safeZones.length} active safe zones');
    } catch (e) {
      debugPrint('Error loading safe zones: $e');
    }
  }

  /// Handle position update
  Future<void> _onPositionUpdate(Position position) async {
    try {
      bool isInSafeZone = false;
      String? currentZoneId;

      // Check if position is within any safe zone
      for (final zone in _safeZones) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          zone.latitude,
          zone.longitude,
        );

        if (distance <= zone.radiusMeters) {
          isInSafeZone = true;
          currentZoneId = zone.id;
          break;
        }
      }

      // If patient was in a zone and now left, or was outside and still outside
      if (!isInSafeZone && _lastZoneId != null) {
        // Patient left safe zone
        await _handleZoneExit(position);
        _lastZoneId = null;
      } else if (isInSafeZone && currentZoneId != _lastZoneId) {
        // Patient entered a safe zone
        _lastZoneId = currentZoneId;
        debugPrint('Patient entered safe zone: ${currentZoneId}');
      }
    } catch (e) {
      debugPrint('Error processing position update: $e');
    }
  }

  /// Handle patient leaving safe zone
  Future<void> _handleZoneExit(Position position) async {
    debugPrint('Patient left safe zone at ${position.latitude}, ${position.longitude}');

    const patientMessage = 'انت خرجت من المنطقه الامنه بس متقلقش هنبلع قرايبك';

    // Send local notification to patient
    await _showAlertNotification(patientMessage);

    // Speak alert to patient
    try {
      await _ttsService.speak(patientMessage);
    } catch (e) {
      debugPrint('Error speaking zone exit alert: $e');
    }

    // Send notification to family members via Supabase Realtime
    if (_patientId != null) {
      try {
        await _notificationService.sendNotificationToFamily(
          patientId: _patientId!,
          type: NotificationType.zoneExit,
          title: 'تنبيه: خروج من المنطقة الآمنة',
          message: 'المريض خرج من المنطقة الآمنة',
          data: {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        debugPrint('Notification sent to family members');
      } catch (e) {
        debugPrint('Error sending notification to family: $e');
      }
    }
  }

  /// Show alert notification
  Future<void> _showAlertNotification(String message) async {
    const androidDetails = AndroidNotificationDetails(
      'lobna_geo_alerts',
      'Lobna Safe Zone Alerts',
      channelDescription: 'تنبيهات المناطق الآمنة من لبنى',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      'تنبيه من لبنى',
      message,
      details,
    );
  }

  /// Refresh safe zones (call when zones are updated)
  Future<void> refreshSafeZones() async {
    await _loadSafeZones();
  }

  /// Check if currently monitoring
  bool get isMonitoring => _isMonitoring;

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _ttsService.dispose();
    _notificationService.dispose();
  }
}

