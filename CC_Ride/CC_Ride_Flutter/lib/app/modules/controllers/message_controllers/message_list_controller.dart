import 'package:carride/theme/theme_colores.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class MessageListController extends GetxController {
  ThemeColores themeColores = Get.put(ThemeColores());

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Returns chat list for a specific user with last message + time
  Stream<List<Map<String, dynamic>>> getUserChatList(String userId) {
    return firestore.collection("CCRideChat").snapshots().asyncMap((
      snapshot,
    ) async {
      List<Map<String, dynamic>> chats = [];

      for (var doc in snapshot.docs) {
        String chatId = doc.id; // e.g., user123_user456 (sorted user IDs)

        // Check if the chat involves the given user
        if (chatId.contains(userId)) {
          // Extract the other user's ID
          List<String> userIds = chatId.split("_");
          String otherUserId = userIds[0] == userId ? userIds[1] : userIds[0];

          // Fetch the other user's profile
          var userSnap = await firestore.collection("CCRideUser").doc(otherUserId).get();

          if (userSnap.exists) {
            var userData = userSnap.data()!;

            // Fetch last message
            var lastMsgSnap = await firestore.collection("CCRideChat").doc(chatId).collection("message").orderBy("timestamp", descending: true).limit(1).get();

            String lastMessage = "";
            Timestamp? lastTime;

            if (lastMsgSnap.docs.isNotEmpty) {
              var msgData = lastMsgSnap.docs.first.data();
              lastMessage = msgData["message"] ?? "";
              lastTime = msgData["timestamp"];
              debugPrint("----------------------------- msgData : $msgData");
            }


            chats.add({
              "chatId": chatId,
              "otherUserId": otherUserId,
              "userName": userData["name"] ?? "Unknown",
              "userPic": userData["pro_pic"] ?? "",
              "lastMessage": lastMessage,
              "lastTime": lastTime,
            });
          }
        }
      }

      // Sort by latest message time
      chats.sort((a, b) {
        var aTime = a["lastTime"] as Timestamp?;
        var bTime = b["lastTime"] as Timestamp?;
        return (bTime?.compareTo(aTime ?? Timestamp.now())) ?? 0;
      });
      return chats;
    });
  }
}
