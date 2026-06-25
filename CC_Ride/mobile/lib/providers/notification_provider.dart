import 'package:flutter/foundation.dart';
import '../data/models/notification_model.dart';
import '../data/services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _api;

  List<NotificationModel> _notifications = [];
  bool _loading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get loading => _loading;

  NotificationProvider(this._api);

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final list = await _api.getNotifications();
      _notifications = list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _notifications = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    try {
      await _api.markNotificationRead(id);
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        _notifications[idx] = NotificationModel(
          id: _notifications[idx].id,
          type: _notifications[idx].type,
          title: _notifications[idx].title,
          body: _notifications[idx].body,
          data: _notifications[idx].data,
          isRead: true,
          sentAt: _notifications[idx].sentAt,
        );
        notifyListeners();
      }
    } catch (_) {}
  }
}
