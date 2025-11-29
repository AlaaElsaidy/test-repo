import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/supabase/notification-service.dart';
import '../../core/shared-prefrences/shared-prefrences-helper.dart';
import '../../theme/app_theme.dart';

class FamilyNotificationsScreen extends StatefulWidget {
  const FamilyNotificationsScreen({super.key});

  @override
  State<FamilyNotificationsScreen> createState() =>
      _FamilyNotificationsScreenState();
}

class _FamilyNotificationsScreenState
    extends State<FamilyNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;
  String? _familyId;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final familyId = SharedPrefsHelper.getString("familyUid") ??
          SharedPrefsHelper.getString("userId");

      if (familyId == null) {
        setState(() {
          _error = 'Family account not found';
          _loading = false;
        });
        return;
      }

      _familyId = familyId;

      final items = await _notificationService.getNotifications(familyId);

      if (!mounted) return;
      setState(() {
        _notifications = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load notifications: $e';
        _loading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (_familyId == null) return;
    try {
      await _notificationService.markAllAsRead(_familyId!);
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map(
              (n) => AppNotification(
                id: n.id,
                patientId: n.patientId,
                familyMemberId: n.familyMemberId,
                type: n.type,
                title: n.title,
                message: n.message,
                data: n.data,
                isRead: true,
                createdAt: n.createdAt,
                readAt: n.readAt ?? DateTime.now(),
              ),
            )
            .toList();
      });
    } catch (_) {
      // ignore errors, user can try again
    }
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.zoneExit:
        return Icons.warning_amber_rounded;
      case NotificationType.zoneEnter:
        return Icons.location_on;
      case NotificationType.reminderMissed:
        return Icons.access_time_rounded;
      case NotificationType.emergency:
        return Icons.emergency;
      case NotificationType.activityCompleted:
        return Icons.check_circle_outline;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.zoneExit:
      case NotificationType.emergency:
        return Colors.redAccent;
      case NotificationType.reminderMissed:
        return Colors.orangeAccent;
      case NotificationType.activityCompleted:
        return AppTheme.teal500;
      case NotificationType.zoneEnter:
        return AppTheme.teal600;
      case NotificationType.general:
        return AppTheme.gray500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: AppTheme.teal600,
        foregroundColor: Colors.white,
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'تحديد الكل كمقروء',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد إشعارات بعد.',
          style: TextStyle(color: AppTheme.gray500),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final n = _notifications[index];
          final icon = _iconForType(n.type);
          final color = _colorForType(n.type);
          final created = DateFormat('dd/MM/yyyy HH:mm').format(n.createdAt);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            title: Text(
              n.title,
              style: TextStyle(
                fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.message),
                const SizedBox(height: 4),
                Text(
                  created,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.gray500,
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          );
        },
      ),
    );
  }
}


