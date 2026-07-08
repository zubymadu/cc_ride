import 'dart:convert';
import 'dart:io';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:googleapis_auth/auth_io.dart';

class FirebaseAccesstoken {
  static String firebaseMessageScope = "https://www.googleapis.com/auth/firebase.messaging";

  // A Firebase service account private key used to live here, hardcoded in
  // client source — that leaked full FCM-send authority to anyone who
  // decompiled the APK, and was caught by GitHub push protection.
  // TODO: move chat push notifications through the backend (which can hold
  // this credential server-side) instead of minting an FCM access token
  // on-device. Returning empty for now so this fails the same way it
  // already did on any other error, without shipping a live secret.
  Future<String> getAccessToken() async {
    return "";
  }
}

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// 🔹 Initialize Notifications (FCM & Local)
  static Future<void> initialize() async {

    if (Platform.isIOS) {
      await _registerForRemoteNotifications();
    }

    // ✅ Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint("🔔 Notifications Allowed");
    } else {
      debugPrint("🚫 Notifications Denied");
      return;
    }

    // ✅ Ensure APNS Token is available before getting FCM token (iOS only)
    if (Platform.isIOS) {
      await _ensureAPNSToken();
    }

    // ✅ Get FCM Token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      debugPrint("📌 FCM Token: $token");
      // todo: Send token to backend if needed
    } else {
      debugPrint("❌ Failed to get FCM token");
    }

    // ✅ Handle Token Refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint("🔄 FCM Token Refreshed: $newToken");
      // todo: Update backend with new token
    });

    // ✅ Configure iOS foreground notifications
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // ✅ Initialize Local Notifications
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("📩 Notification Clicked: ${response.payload}");
        _handleNotificationClick(response.payload);
      },
    );

    // ✅ Listen for FCM messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 Foreground Message: ${message.notification?.title}");
      if (!_isChatScreenOpen()) {
        showNotification(message);
      }
    });

    // ✅ Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("📩 Opened App via Notification: ${message.data}");
      _navigateToChat(message.data);
    });

    // ✅ Handle notification tap when app is terminated
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("📩 App opened from terminated state via notification");
      _navigateToChat(initialMessage.data);
    }
  }

  /// 🔹 Register for Remote Notifications (iOS)
  static Future<void> _registerForRemoteNotifications() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// 🔹 Ensure APNS Token is available (iOS only)
  static Future<void> _ensureAPNSToken() async {
    if (!Platform.isIOS) return;

    int retryCount = 0;
    String? apnsToken;

    while (apnsToken == null && retryCount < 5) {
      apnsToken = await _firebaseMessaging.getAPNSToken();
      if (apnsToken != null) break;
      
      await Future.delayed(Duration(seconds: 2 * (retryCount + 1))); // Exponential backoff
      retryCount++;
    }

    if (apnsToken != null) {
      debugPrint("✅ APNS Token Retrieved: $apnsToken");
    } else {
      debugPrint("❌ Failed to get APNS token after retries");
    }
  }

  /// 🔹 Show Local Notification (Foreground)
  static Future<void> showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // Prepare payload
    String? payload = message.data.isNotEmpty ? jsonEncode(message.data) : null;

    await _flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      message.notification?.title,
      message.notification?.body,
      platformDetails,
      payload: payload,
    );
  }

  /// 🔹 Handle notification click and navigate to chat
  static void _handleNotificationClick(String? payload) {
    debugPrint("------------------ zzxzxzxxzxzxzxzx ---------------");
    if (payload != null && payload.isNotEmpty) {
      try {
        Map<String, dynamic> data = jsonDecode(payload);
    debugPrint("------------------ zzxzxzxxzxzxzxzx ---------------$data");
        _navigateToChat(data);
      } catch (e) {
        debugPrint("❌ Error decoding JSON payload: $e");
      }
    }
  }

  /// 🔹 Navigate to chat screen
  static void _navigateToChat(Map<String, dynamic> data) {
    try {
      String receiverId = data['senderId'] ?? "";
      debugPrint("-------- notifiaction data ------------ $data");

      if (receiverId.isNotEmpty) {
        Get.toNamed(
          Routes.MESSAGE_SCREEN,
          arguments: {
            "reciverId" : "${data["senderId"]}",
            "profilePic" : "${data["profilePic"]}",
            "userName" : "${data["userName"]}",
          },
        );
      } else {
        debugPrint("❌ Invalid receiver data, cannot navigate to chat.");
      }
    } catch (e) {
      debugPrint("❌ Error navigating to chat: $e");
    }
  }

  /// 🔹 Check if chat screen is open
  static bool _isChatScreenOpen() {
    return Get.currentRoute == Routes.MESSAGE_SCREEN;
  }
}

  // Request notification permission (for iOS)
  void requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint("Notification permission granted");
    } else {
      debugPrint("Notification permission denied");
    }
  }
