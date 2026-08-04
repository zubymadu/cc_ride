import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/support_controllers/support_tickets_controller.dart';

class SupportTicketDetailView extends GetView<SupportTicketsController> {
  const SupportTicketDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SupportTicketsController>();
    final ticketId = (Get.arguments as Map?)?["ticket_id"] as String? ?? '';
    final replyController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.fetchTicketDetailApi(ticketId);
    });

    return Scaffold(
      backgroundColor: ccBackground,
      appBar: AppBar(
        backgroundColor: ccSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => Text(
              c.activeTicket.value?["subject"] as String? ?? "Ticket",
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ccNavyText),
            )),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: ccInputBorder),
        ),
      ),
      body: Obx(() {
        if (c.isLoadingDetail.value && c.activeMessages.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: ccPrimary));
        }
        final ticket = c.activeTicket.value;
        final closed = ticket?["status"] == 'closed';
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (ticket != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: ccIceBlue,
                        borderRadius: BorderRadius.circular(CCRadius.card),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Category: ${ticket["category"]}",
                              style: CCText.labelSm.copyWith(color: ccSecondaryText)),
                          const SizedBox(height: 4),
                          Text("Status: ${"${ticket["status"]}".replaceAll('_', ' ')}",
                              style: CCText.labelSm.copyWith(color: ccSecondaryText)),
                        ],
                      ),
                    ),
                  for (final m in c.activeMessages)
                    _MessageBubble(
                      body: "${m["body"]}",
                      isMine: m["sender_type"] == 'user',
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: ccSurface,
                  border: const Border(top: BorderSide(color: ccInputBorder)),
                ),
                child: closed
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text("This ticket is closed.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'Inter', color: ccSecondaryText)),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: replyController,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: "Type a reply…",
                                filled: true,
                                fillColor: ccBackground,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Obx(() => c.isReplying.value
                              ? const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: ccPrimary, strokeWidth: 2)),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.send_rounded, color: ccPrimary),
                                  onPressed: () async {
                                    final text = replyController.text.trim();
                                    if (text.isEmpty) return;
                                    replyController.clear();
                                    await c.replyToTicketApi(ticketId, text);
                                  },
                                )),
                        ],
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.body, required this.isMine});
  final String body;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: Get.width * 0.75),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? ccPrimary : ccSurface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMine ? 14 : 2),
            bottomRight: Radius.circular(isMine ? 2 : 14),
          ),
          boxShadow: isMine ? null : CCShadow.card,
        ),
        child: Text(
          body,
          style: TextStyle(
            fontFamily: 'Inter',
            color: isMine ? Colors.white : ccNavyText,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
