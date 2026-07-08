import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class FirebaseAuthService extends GetxService {
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  /// Sign In and Store Data
  Future<void> firebaseStoreData({
    required String uid,
    required String name,
    required String email,
    required String number,
    required String proPicPath,
  }) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      await _fireStore.collection("CCRideUser").doc(uid).set({
        "email": email,
        "name": name,
        "number": number,
        "pro_pic": proPicPath,
        "token": "$token",
        "uid": uid,
      });
    } catch (e) {
      debugPrint("+++++++ FirebaseAuthException +++++ $e");
    }
  }
}
