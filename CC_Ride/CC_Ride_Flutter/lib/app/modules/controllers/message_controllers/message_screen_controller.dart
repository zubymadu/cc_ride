// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/post_controllers/trip_preview_screen_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../models/book_trip_details_api_model.dart';

class MessageScreenController extends GetxController {
  final TripPreviewScreenController tripPreviewScreenController = Get.put(TripPreviewScreenController());
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController messageController = TextEditingController();

  final RxMap _reciverData = {}.obs;
  Map get reciverData => _reciverData;
  set reciverData(Map value) => _reciverData.value = value;

  final RxString _chatId = "".obs;
  String get chatId => _chatId.value;
  set chatId(String value) => _chatId.value = value;

  Rx<DocumentSnapshot?> userDoc = Rx<DocumentSnapshot?>(null);
  RxString receiverName = "".obs;
  RxString receiverProfilePic = "".obs;

  final RxList<StopsDetail> _stopPointData = <StopsDetail>[].obs;
  List<StopsDetail> get stopPointData => _stopPointData;
  set stopPointData(List<StopsDetail> value) => _stopPointData.value = value;


  // void setChatId(String senderId, String receiverId) {
  //   debugPrint("-------------- senderId --------------- $senderId");
  //   debugPrint("------------- receiverId -------------- $receiverId");
  //   List<String> ids = [senderId, receiverId]..sort();
  //   debugPrint("---------------- ids ------------------ $ids");
  //   chatId = "${ids[0]}_${ids[1]}";
  //   debugPrint("-------------- chatId --------------- $chatId");
  // }

  void setChatId(String senderId, String receiverId) {
    debugPrint("-------------- senderId --------------- $senderId");
    debugPrint("------------- receiverId -------------- $receiverId");
  
    // Convert to int, sort numerically, then back to String
    List<String> ids = [senderId, receiverId];
    ids.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  
    debugPrint("---------------- ids ------------------ $ids");
    chatId = "${ids[0]}_${ids[1]}";
    debugPrint("-------------- chatId --------------- $chatId");
  }

  Future<void> getUser({required String uid}) async {
    try {
      DocumentSnapshot doc = await firestore.collection("CCRideUser").doc(uid).get();
      userDoc.value = doc;
      update();
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
  }

  Future<void> fetchReceiverData(String receiverId) async {
    try {
      DocumentSnapshot doc = await firestore.collection("CCRideUser").doc(receiverId).get();
      receiverName.value = doc["name"] ?? "Unknown";
      receiverProfilePic.value = doc["profilePic"] ?? "";
      update();
    } catch (e) {
      debugPrint("Error fetching receiver data: $e");
    }
  }

  Future<String?> getReceiverToken(String receiverId) async {
    DocumentSnapshot userDoc = await firestore.collection("CCRideUser").doc(receiverId).get();
    return userDoc["token"];
  }

  void sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    Timestamp timestamp = Timestamp.now();

    await firestore.collection('CCRideChat').doc(chatId).set({"timeStamp": timestamp}, SetOptions(merge: true));

    await firestore.collection('CCRideChat').doc(chatId).collection('message').add({
      "message": messageController.text.trim(),
      "reciverId": reciverData["reciverId"],
      "senderName": getData.read("userLogin")["name"],
      "senderid": getData.read("userLogin")["id"],
      "timestamp": timestamp,
      "type": "text",
    });

    String? receiverToken = await getReceiverToken(reciverData["reciverId"]);
    if (receiverToken != null && receiverToken.isNotEmpty) {
      sendPushNotification(receiverToken, messageController.text.trim(), getData.read("userLogin")["name"]);
    }

    messageController.clear();
    update();
  }

  void sendPushNotification(String token, String message, String senderName) async {
    try {
      var body = {
        "message": {
          "token": token,
          "notification": {"title": senderName, "body": message},
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "senderId": getData.read("userLogin")["id"],
            "profilePic": getData.read("userLogin")["profile_pic"] ?? "",
            "userName": getData.read("userLogin")["name"],
          }
        }
      };

      var response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/${Confing.projectID}/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Confing.firebaseKey}',
        },
        body: jsonEncode(body),
      );

      debugPrint("FCM Response: ${response.statusCode} - ${response.body}");
    } catch (e) {
      debugPrint("FCM Error: $e");
    }
  }

  Future<void> sendLocation({required String locationType, int? index}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar("Location Off", "Please turn on location", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar("Permission Denied", "Location access is required");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar("Permission Blocked", "Go to settings → Allow location");
      Geolocator.openAppSettings();
      return;
    }

    Get.dialog(const Center(child: CircularProgressIndicator(color: ccPrimary)), barrierDismissible: false);

    try {
      String address = "";
      String message = "";
      double lat = 0.0;
      double lng = 0.0;
      if (locationType == "Pickup") {
        message = "Pickup Location";
        address = reciverData["originAddress"].toString().split(", ").first;
        lat = double.parse("${reciverData["originLat"]}");
        lng = double.parse("${reciverData["originLong"]}");
        update();
      } else if (locationType == "Drop") {
        message = "Pickup Location";
        address = reciverData["destiAddress"].toString().split(", ").first;
        lat = double.parse("${reciverData["destiLat"]}");
        lng = double.parse("${reciverData["destiLong"]}");
        update();
      } else if (locationType == "stop") {
        message = "Stop Location";
        address = stopPointData[index ?? 0].location.toString().split(", ").first;
        lat = double.parse("${stopPointData[index ?? 0].lat}");
        lng = double.parse("${stopPointData[index ?? 0].long}");
        update();
      } else if (locationType == "Current") {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        );
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        Placemark place = placemarks[0];
        address = [place.street, place.subLocality, place.locality, place.administrativeArea, place.country].where((e) => e != null && e.isNotEmpty).join(', ');
        if (address.isEmpty) address = "Current Location";
        lat = double.parse("${position.latitude}");
        lng = double.parse("${position.longitude}");
        message = "Current Location";
        update();
      }

      debugPrint("--------- address --------- $address");
      debugPrint("--------- message --------- $message");
      debugPrint("----------- lat ----------- $lat");
      debugPrint("----------- lng ----------- $lng");

      // Send to Firestore
      await firestore.collection('CCRideChat').doc(chatId).collection('message').add({
        "senderid": getData.read("userLogin")["id"],
        "senderName": getData.read("userLogin")["name"],
        "reciverId": reciverData["reciverId"],
        "timestamp": FieldValue.serverTimestamp(),
        "type": "location",
        "message" : message,
        "lat": lat,
        "lng": lng,
        // "lat": position.latitude,
        // "lng": position.longitude,
        "address": address,
      });

      Get.back();
      String? receiverToken = await getReceiverToken(reciverData["reciverId"]);
      if (receiverToken != null && receiverToken.isNotEmpty) {
        sendPushNotification(receiverToken, "Location", getData.read("userLogin")["name"]);
      }
      update();
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Failed to get location");
      debugPrint("Location Error: $e");
    }
  }

  RxList get _locationType => [
    reciverData["originAddress"].toString().split(", ").first,
    reciverData["destiAddress"].toString().split(", ").first,
    // "Pickup Location",
    // "Drop Location",
    "Current Location",
  ].obs;
  List get locationType => _locationType;
  set locationType(List value) => _locationType.value = value;

  sendLocationBottomsheet() {
    return Get.bottomSheet(
      backgroundColor: ccBackground,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(15))),
      Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Send Location",
              style: TextStyle(
                color: ccNavyText,
                fontSize: 18,
                fontFamily: 'Inter', fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10),
            if(reciverData["originAddress"] != null)...[
              for(int i = 0; i < locationType.length; i++)...[
                InkWell(
                  onTap: () {
                    Get.back();
                    if (i == 0) {
                      sendLocation(locationType: "Pickup");
                    } else if (i == 1) {
                      sendLocation(locationType: "Drop");
                    } else if (i == 2) {
                      sendLocation(locationType: "Current");
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      border: Border.all(color: ccNavyText),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        "${locationType[i]}",
                        style: TextStyle(
                          color: ccNavyText,
                          fontFamily: 'Inter', fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if(i == 0)...[
                  for(int s = 0; s < stopPointData.length; s++)...[
                    SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        // sendLocation();
                        Get.back();
                        sendLocation(locationType: "stop", index: s);
                        // sendLocation(locationType: "Pickup");
                      },
                      child: Container(
                        padding: EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          border: Border.all(color: ccNavyText),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            stopPointData[s].location.toString().split(", ").first,
                            style: TextStyle(
                              color: ccNavyText,
                              fontFamily: 'Inter', fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
                if(i != locationType.length - 1) SizedBox(height: 10),
              ],
            ] else...[
              InkWell(
                onTap: () {
                  Get.back();
                  sendLocation(locationType: "Current");
                },
                child: Container(
                  padding: EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    border: Border.all(color: ccNavyText),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      "Send Current Location",
                      style: TextStyle(
                        color: ccNavyText,
                        fontFamily: 'Inter', fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
