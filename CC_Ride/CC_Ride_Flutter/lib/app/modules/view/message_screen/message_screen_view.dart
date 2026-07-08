// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/view/message_screen/location_map_widget.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/textfield/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/message_controllers/message_screen_controller.dart';

class MessageScreenView extends GetView<MessageScreenController> {
  const MessageScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MessageScreenController>();
    return Scaffold(
      backgroundColor: ccBackground,
      appBar: AppBar(
        backgroundColor: ccSurface,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
          onPressed: () => Get.back(),
        ),
        title: Obx(
          () {
            final hasPic = c.reciverData["profilePic"] != null &&
                c.reciverData["profilePic"].toString().isNotEmpty &&
                c.reciverData["profilePic"] != "null";
            return Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ccIceBlue,
                    border: Border.all(color: ccInputBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasPic
                      ? FadeInImage.assetNetwork(
                          placeholder: "assets/image/ezgif.com-crop.gif",
                          image:
                              "${Confing.imageurl}${c.reciverData["profilePic"]}",
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Text(
                            c.reciverData["userName"] != null &&
                                    c.reciverData["userName"]
                                        .toString()
                                        .isNotEmpty
                                ? c.reciverData["userName"][0]
                                    .toString()
                                    .toUpperCase()
                                : "?",
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: ccPrimary,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${c.reciverData["userName"]}",
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ccNavyText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: ccInputBorder),
        ),
      ),
      body: GetBuilder<MessageScreenController>(
        initState: (state) {
          c.reciverData.clear();
          c.stopPointData.clear();
          c.reciverData = Get.arguments;
          c.update();
          final senderId = "${getData.read("userLogin")["id"]}";
          final receiverId = "${c.reciverData["reciverId"]}";
          if (c.reciverData["stopPoint"] != null) {
            c.stopPointData.addAll(c.reciverData["stopPoint"]);
          }
          c.setChatId(senderId, receiverId);
          c.fetchReceiverData(receiverId);
          c.getUser(uid: senderId);
          c.update();
        },
        builder: (_) {
          return Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: c.firestore
                      .collection("CCRideChat")
                      .doc(c.chatId)
                      .collection("message")
                      .orderBy("timestamp", descending: true)
                      .snapshots(),
                  builder: (context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: ccPrimary));
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                    color: ccIceBlue,
                                    shape: BoxShape.circle),
                                child: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: ccPrimary,
                                    size: 32),
                              ),
                              const SizedBox(height: 12),
                              const Text("No messages yet",
                                  style: CCText.headlineMd),
                              const SizedBox(height: 6),
                              Text(
                                "Send a message to start the conversation.",
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
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      physics: const BouncingScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data =
                            doc.data() as Map<String, dynamic>;

                        // Timestamp
                        DateTime ts = DateTime.now();
                        try {
                          final raw = data["timestamp"];
                          if (raw is Timestamp) {
                            ts = raw.toDate().toLocal();
                          } else if (raw is int) {
                            ts = DateTime.fromMillisecondsSinceEpoch(raw)
                                .toLocal();
                          }
                        } catch (_) {}

                        final msgDate =
                            DateFormat("yyyy-MM-dd").format(ts);
                        final fmtTime =
                            DateFormat("h:mm a").format(ts);

                        String? prevDate;
                        if (index + 1 < snapshot.data!.docs.length) {
                          try {
                            final pd = snapshot.data!.docs[index + 1]
                                .data() as Map<String, dynamic>;
                            final pRaw = pd["timestamp"];
                            DateTime pTs = DateTime.now();
                            if (pRaw is Timestamp) {
                              pTs = pRaw.toDate().toLocal();
                            } else if (pRaw is int) {
                              pTs =
                                  DateTime.fromMillisecondsSinceEpoch(
                                          pRaw)
                                      .toLocal();
                            }
                            prevDate =
                                DateFormat("yyyy-MM-dd").format(pTs);
                          } catch (_) {}
                        }
                        final showDateHeader = msgDate != prevDate;

                        final type =
                            data["type"]?.toString() ?? "text";
                        final isMe =
                            "${data["senderid"]}" ==
                                "${getData.read("userLogin")["id"]}";

                        final todayStr = DateFormat("yyyy-MM-dd")
                            .format(DateTime.now());
                        final yesterdayStr = DateFormat("yyyy-MM-dd")
                            .format(DateTime.now()
                                .subtract(const Duration(days: 1)));
                        final dateLabel = msgDate == todayStr
                            ? "Today"
                            : msgDate == yesterdayStr
                                ? "Yesterday"
                                : DateFormat("EEE, MMM d").format(ts);

                        return Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            if (showDateHeader)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8),
                                child: Center(
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ccIceBlue,
                                      borderRadius:
                                          BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      dateLabel,
                                      style: CCText.labelSm.copyWith(
                                          color: ccSecondaryText),
                                    ),
                                  ),
                                ),
                              ),

                            // Message bubble
                            Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    if (!isMe) ...[
                                      _Avatar(
                                          url:
                                              "${Confing.imageurl}${c.reciverData["profilePic"]}"),
                                      const SizedBox(width: 6),
                                    ],
                                    if (type == "text")
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 12),
                                        constraints: BoxConstraints(
                                            maxWidth:
                                                Get.width * 0.65),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? ccPrimary
                                              : ccSurface,
                                          borderRadius: BorderRadius
                                              .only(
                                            topLeft:
                                                const Radius.circular(
                                                    14),
                                            topRight:
                                                const Radius.circular(
                                                    14),
                                            bottomLeft:
                                                Radius.circular(
                                                    isMe ? 14 : 4),
                                            bottomRight:
                                                Radius.circular(
                                                    isMe ? 4 : 14),
                                          ),
                                          boxShadow: isMe
                                              ? null
                                              : CCShadow.card,
                                        ),
                                        child: Text(
                                          data["message"] ?? "",
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 15,
                                            color: isMe
                                                ? Colors.white
                                                : ccNavyText,
                                          ),
                                        ),
                                      )
                                    else if (type == "location")
                                      InkWell(
                                        onTap: () => launchUrl(
                                            Uri.parse(
                                                "https://www.google.com/maps?q=${data["lat"]},${data["lng"]}")),
                                        child: LocationMapWidget(
                                          key: ValueKey(
                                              "${data["lat"]}_${data["lng"]}_${doc.id}"),
                                          lat: data["lat"],
                                          lng: data["lng"],
                                          address: data["address"] ??
                                              "Location",
                                        ),
                                      ),
                                    if (isMe) ...[
                                      const SizedBox(width: 6),
                                      _Avatar(
                                          url:
                                              "${Confing.imageurl}${getData.read("userLogin")["profile_pic"]}"),
                                    ],
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 2, left: 34, right: 34),
                                  child: Text(
                                    fmtTime,
                                    style: CCText.labelSm.copyWith(
                                        color: ccSecondaryText),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Input bar ───────────────────────────────────────────────
              Container(
                color: ccSurface,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => c.sendLocationBottomsheet(),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: ccIceBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            color: ccPrimary, size: 22),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: customTextFormField(
                        hintText: "Message...",
                        controller: c.messageController,
                        inputFormatters: [],
                        borderRadius: BorderRadius.circular(CCRadius.btn),
                        onChanged: (v) {
                          c.messageController.text = v;
                          c.update();
                        },
                        suffixIcon: c.messageController.text.isNotEmpty
                            ? InkWell(
                                onTap: () => c.sendMessage(),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  margin: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: ccPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.send_rounded,
                                      color: Colors.white, size: 18),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ccIceBlue,
        border: Border.all(color: ccInputBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: FadeInImage.assetNetwork(
        placeholder: "assets/image/ezgif.com-crop.gif",
        image: url,
        fit: BoxFit.cover,
        imageErrorBuilder: (_, __, ___) =>
            Image.asset("assets/image/ezgif.com-crop.gif",
                fit: BoxFit.cover),
      ),
    );
  }
}
