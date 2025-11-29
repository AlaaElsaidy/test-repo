import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/supabase/notification-service.dart';
import '../core/shared-prefrences/shared-prefrences-helper.dart';
import '../theme/app_theme.dart';

/// Widget that listens for realtime notifications and shows them
/// Use this in the family member's main screen
class NotificationListenerWidget extends StatefulWidget {
  final Widget child;
  final bool showSnackBar; // Show snackbar on new notification
  final bool showDialog; // Show dialog for critical notifications
  final Function(AppNotification)? onNotification; // Custom handler

  const NotificationListenerWidget({
    super.key,
    required this.child,
    this.showSnackBar = true,
    this.showDialog = true,
    this.onNotification,
  });

  @override
  State<NotificationListenerWidget> createState() =>
      _NotificationListenerWidgetState();
}

class _NotificationListenerWidgetState
    extends State<NotificationListenerWidget> {
  final NotificationService _notificationService = NotificationService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<AppNotification>? _subscription;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initLocalNotifications();
    _startListening();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(initSettings);

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  Future<void> _startListening() async {
    final familyId = SharedPrefsHelper.getString("familyUid") ??
        SharedPrefsHelper.getString("userId");

    if (familyId == null) return;

    // Get initial unread count
    _unreadCount = await _notificationService.getUnreadCount(familyId);
    if (mounted) setState(() {});

    // Start listening for new notifications
    _notificationService.startListening(familyId);

    _subscription = _notificationService.onNotification.listen((notification) {
      _handleNotification(notification);
    });
  }

  void _handleNotification(AppNotification notification) {
    if (!mounted) return;

    setState(() {
      _unreadCount++;
    });

    // Call custom handler if provided
    widget.onNotification?.call(notification);

    // Show OS-level local notification (banner + sound) while app is running
    _showLocalNotification(notification);

    // Show snackbar for non-critical notifications
    if (widget.showSnackBar && notification.type != NotificationType.emergency) {
      _showNotificationSnackBar(notification);
    }

    // Show dialog for critical notifications (zone exit, emergency)
    if (widget.showDialog &&
        (notification.type == NotificationType.zoneExit ||
            notification.type == NotificationType.emergency)) {
      _showCriticalNotificationDialog(notification);
    }
  }

  Future<void> _showLocalNotification(AppNotification notification) async {
    const androidDetails = AndroidNotificationDetails(
      'family_notifications',
      'Family Notifications',
      channelDescription: 'إشعارات المريض لأفراد العائلة',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      notification.title,
      notification.message,
      details,
    );
  }

  void _showNotificationSnackBar(AppNotification notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getNotificationIcon(notification.type),
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    notification.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _getNotificationColor(notification.type),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'عرض',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to notifications screen or show details
          },
        ),
      ),
    );
  }

  void _showCriticalNotificationDialog(AppNotification notification) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            if (notification.data['latitude'] != null) ...[
              const SizedBox(height: 16),
              Text(
                'الموقع: ${notification.data['latitude']}, ${notification.data['longitude']}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _notificationService.markAsRead(notification.id);
              setState(() {
                _unreadCount = (_unreadCount - 1).clamp(0, 999);
              });
            },
            child: const Text('حسناً'),
          ),
          if (notification.type == NotificationType.zoneExit)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to tracking screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal500,
              ),
              child: const Text('عرض الموقع'),
            ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.zoneExit:
        return Icons.warning_amber_rounded;
      case NotificationType.zoneEnter:
        return Icons.check_circle_outline;
      case NotificationType.reminderMissed:
        return Icons.alarm_off;
      case NotificationType.emergency:
        return Icons.emergency;
      case NotificationType.activityCompleted:
        return Icons.task_alt;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.zoneExit:
        return Colors.orange;
      case NotificationType.zoneEnter:
        return Colors.green;
      case NotificationType.reminderMissed:
        return Colors.amber;
      case NotificationType.emergency:
        return Colors.red;
      case NotificationType.activityCompleted:
        return AppTheme.teal500;
      case NotificationType.general:
        return AppTheme.cyan500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _notificationService.dispose();
    super.dispose();
  }
}

/// Badge widget to show unread notification count
class NotificationBadge extends StatefulWidget {
  final Widget child;

  const NotificationBadge({
    super.key,
    required this.child,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  StreamSubscription<AppNotification>? _subscription;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final familyId = SharedPrefsHelper.getString("familyUid") ??
        SharedPrefsHelper.getString("userId");

    if (familyId == null) return;

    _unreadCount = await _notificationService.getUnreadCount(familyId);
    if (mounted) setState(() {});

    // Listen for new notifications
    _notificationService.startListening(familyId);
    _subscription = _notificationService.onNotification.listen((_) {
      setState(() {
        _unreadCount++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_unreadCount > 0)
          Positioned(
            right: -5,
            top: -5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _notificationService.dispose();
    super.dispose();
  }
}

