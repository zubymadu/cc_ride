// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime sentAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.sentAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: '${json["notification_id"]}',
        type: '${json["type"]}',
        title: '${json["title"]}',
        body: '${json["body"]}',
        data: json["data"] is Map ? Map<String, dynamic>.from(json["data"]) : {},
        isRead: json["is_read"] == true,
        sentAt: DateTime.tryParse('${json["sent_at"]}') ?? DateTime.now(),
      );
}

class NotificationScreenController extends GetxController {
  final Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  final RxList<NotificationItem> _notifications = <NotificationItem>[].obs;
  List<NotificationItem> get notifications => _notifications;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  final RxInt _unreadCount = 0.obs;
  int get unreadCount => _unreadCount.value;
  set unreadCount(int value) => _unreadCount.value = value;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final user = getData.read("userLogin");
    if (user == null) {
      isLoading = false;
      update();
      return;
    }
    isLoading = true;
    update();
    try {
      final response = await http.post(
        Uri.parse(Confing.baseurl + Confing.notificationList),
        headers: userHeader,
        body: jsonEncode({"uid": user["id"]}),
      );
      final data = jsonDecode(response.body);
      if (data["Result"] == "true") {
        final list = (data["Data"] as List? ?? [])
            .map((e) => NotificationItem.fromJson(e))
            .toList();
        _notifications.assignAll(list);
        unreadCount = data["unread_count"] ?? 0;
      }
    } catch (e) {
      log(name: "notification_list error", "$e");
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> markRead(String notificationId) async {
    final user = getData.read("userLogin");
    if (user == null) return;
    try {
      await http.post(
        Uri.parse(Confing.baseurl + Confing.notificationRead),
        headers: userHeader,
        body: jsonEncode({"uid": user["id"], "notification_id": notificationId}),
      );
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = NotificationItem(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          body: _notifications[index].body,
          data: _notifications[index].data,
          isRead: true,
          sentAt: _notifications[index].sentAt,
        );
        unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
        update();
      }
    } catch (e) {
      log(name: "notification_read error", "$e");
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final user = getData.read("userLogin");
    if (user == null) return;
    // Remove from the visible list immediately — a delete the user swiped
    // away shouldn't wait on a round-trip before disappearing. If the
    // request fails, restore it and let them know rather than leaving the
    // UI silently out of sync with the server.
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;
    final removed = _notifications[index];
    final wasUnread = !removed.isRead;
    _notifications.removeAt(index);
    if (wasUnread) unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
    update();

    try {
      final response = await http.post(
        Uri.parse(Confing.baseurl + Confing.notificationDelete),
        headers: userHeader,
        body: jsonEncode({"uid": user["id"], "notification_id": notificationId}),
      );
      final data = jsonDecode(response.body);
      if (data["Result"] != "true") {
        _notifications.insert(index, removed);
        if (wasUnread) unreadCount += 1;
        update();
      }
    } catch (e) {
      log(name: "notification_delete error", "$e");
      _notifications.insert(index, removed);
      if (wasUnread) unreadCount += 1;
      update();
    }
  }

  Future<void> clearAllNotifications() async {
    final user = getData.read("userLogin");
    if (user == null) return;
    final previous = List<NotificationItem>.from(_notifications);
    final previousUnread = unreadCount;
    _notifications.clear();
    unreadCount = 0;
    update();

    try {
      final response = await http.post(
        Uri.parse(Confing.baseurl + Confing.notificationDelete),
        headers: userHeader,
        body: jsonEncode({"uid": user["id"]}),
      );
      final data = jsonDecode(response.body);
      if (data["Result"] != "true") {
        _notifications.assignAll(previous);
        unreadCount = previousUnread;
        update();
      }
    } catch (e) {
      log(name: "notification_delete_all error", "$e");
      _notifications.assignAll(previous);
      unreadCount = previousUnread;
      update();
    }
  }
}
