import 'package:carride/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static Future<void> initializeOneSignal() async {
    OneSignal.initialize("c90e9b2c-8f33-443d-8f28-2bc1993cd367");

    // Ask permissions
    OneSignal.Notifications.requestPermission(true);

    // Foreground listener
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint("🔔 Foreground Notification: ${event.notification.additionalData}");

      NotificationHandler.handleForeground(event.notification.additionalData);

      event.preventDefault();
      event.notification.display();
    });

    // Click listener
    OneSignal.Notifications.addClickListener((event) {
      debugPrint("👉 Notification Clicked: ${event.notification.additionalData}");
      NotificationHandler.handleClick(event.notification.additionalData);
    });
  }
}

class NotificationHandler {
  static void handleForeground(Map<String, dynamic>? data) {
    if (data == null) return;

    if (data["type"] == "order_status") {
      debugPrint("Order Status Changed → ${data["status"]}");
    }
  }

  static void handleClick(Map<String, dynamic>? data) {
    if (data == null) return;

    debugPrint("---------- data ---------- $data");

    if (data["click_action"] == "BOOKING_DETAILS") {
      Get.toNamed(
        Routes.BOOKING_DATAILS,
        arguments: {
          "trip_id" : "${data["trip_id"]}",
          "owner_id" : "${data["user_id"]}",
        },
      );
    }
  }
}

// {trip_id: 8, book_id: 19, click_action: BOOKING_DETAILS, type: booking_approved, status: 1}
// {trip_id: 8, user_id: 4, book_uid: 7, click_action: BOOKING_DETAILS, type: booking_approved, status: 1}