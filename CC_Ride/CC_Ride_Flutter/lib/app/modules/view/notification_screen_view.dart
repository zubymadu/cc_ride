// ignore_for_file: deprecated_member_use

import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/notification_screen_controller.dart';

class NotificationScreenView extends GetView<NotificationScreenController> {
  const NotificationScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ccBackground,
      appBar: AppBar(
        backgroundColor: ccSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ccNavyText,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: ccInputBorder),
        ),
        actions: [
          GetBuilder<NotificationScreenController>(
            builder: (c) => c.notifications.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () => _confirmClearAll(context, c),
                    child: Text('Clear all'.tr,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ccPrimary,
                        )),
                  ),
          ),
        ],
      ),
      body: GetBuilder<NotificationScreenController>(
        builder: (c) => c.isLoading
            ? const Center(child: CircularProgressIndicator(color: ccPrimary))
            : RefreshIndicator(
                onRefresh: c.fetchNotifications,
                color: ccPrimary,
                child: c.notifications.isEmpty
                    ? _emptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: c.notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _notificationTile(c, c.notifications[i]),
                      ),
              ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, NotificationScreenController c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear all notifications?'.tr),
        content: Text('This removes every notification from this list.'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              c.clearAllNotifications();
            },
            child: Text('Clear all'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _notificationTile(NotificationScreenController c, NotificationItem n) {
    final kind = n.data['kind'];
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(CCRadius.card),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => c.deleteNotification(n.id),
      child: _notificationTileContent(c, n, kind),
    );
  }

  Widget _notificationTileContent(NotificationScreenController c, NotificationItem n, dynamic kind) {
    return InkWell(
      borderRadius: BorderRadius.circular(CCRadius.card),
      onTap: () {
        if (!n.isRead) c.markRead(n.id);
        if (kind == 'ride_request') {
          Get.toNamed(Routes.BOTTOM_BAR_SCREEN, arguments: 1);
        } else if (kind == 'request_matched' && n.data['request_id'] != null) {
          // A driver committing a trip against this request doesn't book
          // the passenger automatically — send them to explicitly confirm
          // or decline first, rather than straight into the trip preview.
          Get.toNamed(Routes.MATCHED_REQUEST_SCREEN, arguments: {
            'request_id': '${n.data['request_id']}',
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.isRead ? ccSurface : ccIceBlue,
          borderRadius: BorderRadius.circular(CCRadius.card),
          boxShadow: CCShadow.card,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: ccSurface, shape: BoxShape.circle),
              child: Icon(
                kind == 'ride_request'
                    ? Icons.fork_right_rounded
                    : kind == 'request_matched'
                        ? Icons.directions_car_rounded
                        : Icons.notifications_outlined,
                color: ccPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                        color: ccNavyText,
                      )),
                  const SizedBox(height: 3),
                  Text(n.body,
                      style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(DateFormat('MMM d, h:mm a').format(n.sentAt),
                      style: CCText.labelSm.copyWith(color: ccSecondaryText)),
                ],
              ),
            ),
            if (!n.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(color: ccPrimary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(color: ccIceBlue, shape: BoxShape.circle),
              child: const Icon(Icons.notifications_outlined, color: ccPrimary, size: 36),
            ),
            const SizedBox(height: 16),
            Text('No notifications yet',
                style: CCText.bodyLg.copyWith(color: ccSecondaryText)),
          ],
        ),
      );
}
