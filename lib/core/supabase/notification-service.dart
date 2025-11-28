import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase-config.dart';
import 'patient-family-service.dart';

/// Notification types
enum NotificationType {
  zoneExit,
  zoneEnter,
  reminderMissed,
  emergency,
  activityCompleted,
  general,
}

/// Notification model
class AppNotification {
  final String id;
  final String patientId;
  final String familyMemberId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.patientId,
    required this.familyMemberId,
    required this.type,
    required this.title,
    required this.message,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      familyMemberId: json['family_member_id'] as String,
      type: _parseType(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'zone_exit':
        return NotificationType.zoneExit;
      case 'zone_enter':
        return NotificationType.zoneEnter;
      case 'reminder_missed':
        return NotificationType.reminderMissed;
      case 'emergency':
        return NotificationType.emergency;
      case 'activity_completed':
        return NotificationType.activityCompleted;
      default:
        return NotificationType.general;
    }
  }

  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.zoneExit:
        return 'zone_exit';
      case NotificationType.zoneEnter:
        return 'zone_enter';
      case NotificationType.reminderMissed:
        return 'reminder_missed';
      case NotificationType.emergency:
        return 'emergency';
      case NotificationType.activityCompleted:
        return 'activity_completed';
      case NotificationType.general:
        return 'general';
    }
  }
}

/// Service for sending and receiving notifications via Supabase Realtime
class NotificationService {
  final SupabaseClient _client = SupabaseConfig.client;
  final PatientFamilyService _patientFamilyService = PatientFamilyService();
  
  static const String _table = 'notifications';
  
  StreamSubscription? _realtimeSubscription;
  final StreamController<AppNotification> _notificationController =
      StreamController<AppNotification>.broadcast();

  /// Stream of incoming notifications (for family members)
  Stream<AppNotification> get onNotification => _notificationController.stream;

  /// Send notification to all family members of a patient
  Future<void> sendNotificationToFamily({
    required String patientId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all family members linked to this patient
      final relations = await _patientFamilyService.getFamilyMembersByPatient(patientId);
      
      if (relations.isEmpty) {
        debugPrint('No family members found for patient: $patientId');
        return;
      }

      // Send notification to each family member
      for (final relation in relations) {
        final familyMember = relation['family_members'] as Map<String, dynamic>?;
        if (familyMember == null) continue;
        
        final familyMemberId = familyMember['id'] as String?;
        if (familyMemberId == null) continue;

        await _sendNotification(
          patientId: patientId,
          familyMemberId: familyMemberId,
          type: type,
          title: title,
          message: message,
          data: data,
        );
      }

      debugPrint('Notifications sent to ${relations.length} family members');
    } catch (e) {
      debugPrint('Error sending notifications to family: $e');
    }
  }

  /// Send notification to a specific family member
  Future<void> _sendNotification({
    required String patientId,
    required String familyMemberId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _client.from(_table).insert({
        'patient_id': patientId,
        'family_member_id': familyMemberId,
        'type': AppNotification._typeToString(type),
        'title': title,
        'message': message,
        'data': data ?? {},
      });

      debugPrint('Notification sent: $type to $familyMemberId');
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// Start listening for notifications (for family members)
  void startListening(String familyMemberId) {
    _realtimeSubscription?.cancel();

    _realtimeSubscription = _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('family_member_id', familyMemberId)
        .order('created_at', ascending: false)
        .listen((data) {
      if (data.isNotEmpty) {
        // Get the latest notification
        final latestNotification = AppNotification.fromJson(data.first);
        
        // Only emit if it's unread and recent (within last 5 seconds)
        final now = DateTime.now();
        final diff = now.difference(latestNotification.createdAt);
        
        if (!latestNotification.isRead && diff.inSeconds < 5) {
          _notificationController.add(latestNotification);
          debugPrint('New notification received: ${latestNotification.type}');
        }
      }
    });

    debugPrint('Started listening for notifications: $familyMemberId');
  }

  /// Stop listening for notifications
  void stopListening() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
  }

  /// Get all notifications for a family member
  Future<List<AppNotification>> getNotifications(String familyMemberId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('family_member_id', familyMemberId)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount(String familyMemberId) async {
    try {
      final response = await _client
          .from(_table)
          .select('id')
          .eq('family_member_id', familyMemberId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client.from(_table).update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String familyMemberId) async {
    try {
      await _client.from(_table).update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('family_member_id', familyMemberId).eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  /// Delete old notifications (older than 30 days)
  Future<void> cleanupOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      await _client
          .from(_table)
          .delete()
          .lt('created_at', thirtyDaysAgo.toIso8601String());
    } catch (e) {
      debugPrint('Error cleaning up notifications: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _notificationController.close();
  }
}

