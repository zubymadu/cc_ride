import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_theme.dart';
import '../../providers/notification_provider.dart';
import '../../data/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () {},
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: AppTheme.textSecondary),
                      SizedBox(height: 12),
                      Text('No notifications yet', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.load(),
                  child: ListView.separated(
                    itemCount: provider.notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final n = provider.notifications[i];
                      return _NotifTile(
                        notification: n,
                        onTap: () => provider.markRead(n.id),
                      );
                    },
                  ),
                ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotifTile({required this.notification, required this.onTap});

  IconData get _icon => switch (notification.type) {
        'booking_confirmed' => Icons.check_circle_outline,
        'driver_assigned' => Icons.directions_car,
        'driver_arrived' => Icons.location_on,
        'ride_started' => Icons.play_arrow,
        'ride_completed' => Icons.done_all,
        'payment_processed' => Icons.payment,
        'approval_required' => Icons.pending,
        'approval_decided' => Icons.gavel,
        'budget_alert' => Icons.warning_amber,
        _ => Icons.notifications,
      };

  Color get _color => switch (notification.type) {
        'ride_completed' || 'booking_confirmed' || 'approval_decided' => AppTheme.secondary,
        'budget_alert' => AppTheme.warning,
        'payment_processed' => AppTheme.primary,
        _ => AppTheme.primary,
      };

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          color: notification.isRead ? null : AppTheme.primary.withOpacity(0.04),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: _color.withOpacity(0.1),
                child: Icon(_icon, color: _color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w600,
                        )),
                    const SizedBox(height: 4),
                    Text(notification.body,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(notification.sentAt),
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      );
}
