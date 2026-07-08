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

  Future<String> getAccessToken() async {
    final credentials = ServiceAccountCredentials.fromJson(
      {
        "type": "service_account",
        "project_id": "project-2025-fe5ee",
        "private_key_id": "325b5b48403de1ac153f144d8c7b949916ba3788",
        "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC+01APT7jkzCka\n5ckTeNkRmckr7Io2jYBc523waYxhtQF2InTnBQ1epCdmPdoajJWI+rz6A5Pizbzz\neKE+lzACuBvurtvCA1R1WwuMdvE8QErok80GhBn+c+VXRyH2eDNkd78pJNK3SjJp\no+EF4PetCLOHKhFmXbHIW8C/FDimih+oJUpd9XltGXxyJdSmf6fMhZonC4EnxxDw\nbDN4SrMi24WweVE6cQIQiD1Gi+5u5clSQWEcVMDFYlGXgaEpjSpS0aBaN7d5N5yE\n9XSGvhE7uUcfTJ90AOV2CrMw7fASn8n+51Ge0rldN6+6/pUyAXjmytmxVHiu3gjK\nIrbGucaZAgMBAAECggEADkAtKSuQuQN3KWNSMCJVAZ+8uotEah0IokeFOhBD09Mm\n7AnYNZ12uWPkbln9pQBtNWjWPoyQWX54Vy1hy1ESnI1fxqQn1LYXc1kshF2ol9GM\nVpCdHdi1MT+595ngEy44Vk8sBzhRBS+lEqcSqbP6gyFUeOpfGMgz++zAOPTbYzJp\n9TMVjFtySKIzFd/ldIJ90cC2kA5+bORhb61MVFRzI9qiueNdn14bmFNXna19JGU/\ngu8yTnyg2BvQyGRyeku81sKlSXaA+QJLzlN6cnpTl88k+XfZUvR2W7RG8TCDzLC2\n+xToJafd0zn++qgd5STc2ge1P0GxTqXbhE2E7AqDgQKBgQDgbQPwzdbzrXlWEYPx\nNfd8drOtl19ilEgoK69ZoYRK/euDXPXGhYydbzLUXS9vyoYHn8WsU7AXZN6ll7Cn\nD4ZwuLOlnxbSeKmNeM6+l6JGh0aYGMoYWpOI0u35y58nU+qlfkDKjD7iC9l5DzcA\ndXmNhKsXASag22Hce6SudB4/QQKBgQDZrCLDIhffR5Vjtz1Mno0YUnvZxOdy4wLt\nG17r7iQuMv5WOWh/uSFHkIHi44YPu5CGJmjCOt7VxcwObcc6h8DqTJzzT5Wr8swh\nPmBj5NebXFAEFSbb2INhJyb+pqdTgLX4dU5Qb3WsqD66PU3ByN/zfxKNPwEoN1RB\nOII7PVyJWQKBgAViGAoapeFKc/KgkO2kQb92iXDMhLk0nVZ5VcdsnGPAG3oXLL4K\nTgkotatqYMzpqrVcG726dCrbfIu0S8R2Ft91TrnWSxHZWxfNogfoUzgl3oefcJmM\n8qUBijvHqpWi6an2kU9KdeeuKRVCTCtypevDFueCW47YNEy5moWku2UBAoGBAJ0M\nKPiIvJiH2SzcpAmHy1zlBh6UhjjJuO7BdLbcVpZOjFpBiTe9plkv1caRScRIG3nu\ndF7Ogr/RuewfIEMGdxWUuRiDLwWkY8sIahsonLam38RSTnsHt6J80RGhw8/naWMd\nn6dBA7HSoY9Vc6iA+bOA1y25a2hMoyl7T9rV5tHhAoGBAIEB99anVMUWtsToGKBH\n8KwaI0JPbKIXp1COdf2kR919qGVnQrB+7cJyPGQY5zBTl+Yoyf/ilOyQUX0ah8tk\n9LRmf//M5JIwasCd8S7JxXuS8IxTc+IHotKazEczAkHzugeLXsnEAe+b9umjeOiQ\ngAfQaUYMvrIC3tAQOib2cbrl\n-----END PRIVATE KEY-----\n",
        "client_email": "firebase-adminsdk-fbsvc@project-2025-fe5ee.iam.gserviceaccount.com",
        "client_id": "109993506953802403949",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40project-2025-fe5ee.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com"
      }
    );
    debugPrint("+++++++++++++++++1:---- $credentials");
    try{
      final client = await clientViaServiceAccount(credentials, [firebaseMessageScope]);
      debugPrint("+++++++++++++++++2:---- ${client.credentials.accessToken.data}");

      final accessToken = client.credentials.accessToken.data;
      Confing.firebaseKey = accessToken;
      debugPrint("+++++++++++++++++3:---- ${Confing.firebaseKey}");
      return accessToken;

    }catch(e){
      debugPrint("Error --${e.toString()}");
      return "";
    }
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
