import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/message_controllers/message_list_controller.dart';

class MessageListView extends GetView<MessageListController> {
  const MessageListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ccBackground,
      body: SafeArea(
        child: GetBuilder<MessageListController>(
          init: MessageListController(),
          builder: (_) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: const Text(
                    "Messages",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: ccNavyText,
                    ),
                  ),
                ),
                Container(height: 1, color: ccInputBorder),
                const SizedBox(height: 8),

                // ── Chat list ─────────────────────────────────────────
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: controller.getUserChatList(
                        "${getData.read("userLogin")["id"]}"),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Something went wrong",
                            style: CCText.bodyLg
                                .copyWith(color: ccSecondaryText),
                          ),
                        );
                      }

                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child:
                              CircularProgressIndicator(color: ccPrimary),
                        );
                      }

                      final chats = snapshot.data ?? [];

                      if (chats.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: ccIceBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: ccPrimary,
                                      size: 36),
                                ),
                                const SizedBox(height: 16),
                                const Text("No Messages Yet",
                                    style: CCText.headlineMd),
                                const SizedBox(height: 8),
                                Text(
                                  "Your conversations with drivers and riders will appear here.",
                                  textAlign: TextAlign.center,
                                  style: CCText.bodyMd
                                      .copyWith(color: ccSecondaryText),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        physics: const BouncingScrollPhysics(),
                        itemCount: chats.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          String formattedTime = "";
                          if (chat["lastTime"] != null) {
                            final ts = chat["lastTime"] as Timestamp;
                            formattedTime = DateFormat('hh:mm a')
                                .format(ts.toDate());
                          }
                          final hasPic = chat["userPic"] != null &&
                              chat["userPic"] != "null" &&
                              chat["userPic"].toString().isNotEmpty;

                          return InkWell(
                            onTap: () {
                              Get.toNamed(
                                Routes.MESSAGE_SCREEN,
                                arguments: {
                                  "reciverId": "${chat["otherUserId"]}",
                                  "profilePic": "${chat["userPic"]}",
                                  "userName": "${chat["userName"]}",
                                },
                              )?.then((_) => controller.update());
                            },
                            borderRadius:
                                BorderRadius.circular(CCRadius.card),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: ccSurface,
                                borderRadius:
                                    BorderRadius.circular(CCRadius.card),
                                boxShadow: CCShadow.card,
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: ccInputBorder,
                                        width: 1.5,
                                      ),
                                      color: ccIceBlue,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: hasPic
                                        ? FadeInImage.assetNetwork(
                                            placeholder:
                                                "assets/image/ezgif.com-crop.gif",
                                            image:
                                                "${Confing.imageurl}${chat["userPic"]}",
                                            fit: BoxFit.cover,
                                          )
                                        : Center(
                                            child: Text(
                                              chat["userName"] != null &&
                                                      chat["userName"]
                                                          .toString()
                                                          .isNotEmpty
                                                  ? chat["userName"][0]
                                                      .toString()
                                                      .toUpperCase()
                                                  : "?",
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: ccPrimary,
                                              ),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Name + last message
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          chat["userName"] != null &&
                                                  chat["userName"]
                                                      .toString()
                                                      .isNotEmpty
                                              ? "${chat["userName"]}"
                                              : "Unknown user",
                                          style: CCText.titleMd,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          chat["lastMessage"] != null &&
                                                  chat["lastMessage"]
                                                      .isNotEmpty
                                              ? "${chat["lastMessage"]}"
                                              : "Start chatting...",
                                          style: CCText.bodyMd.copyWith(
                                              color: ccSecondaryText),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Time
                                  Text(
                                    formattedTime,
                                    style: CCText.labelSm.copyWith(
                                        color: ccSecondaryText),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
