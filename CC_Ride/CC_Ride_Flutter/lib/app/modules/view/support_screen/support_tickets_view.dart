import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/support_controllers/support_tickets_controller.dart';
import '../../../routes/app_pages.dart';

class SupportTicketsView extends GetView<SupportTicketsController> {
  const SupportTicketsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SupportTicketsController>();
    return Scaffold(
      backgroundColor: ccBackground,
      appBar: AppBar(
        backgroundColor: ccSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "My Tickets",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ccNavyText,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: ccInputBorder),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ccPrimary,
        onPressed: () => _openCreateSheet(context, c),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Raise a Ticket",
            style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
      body: RefreshIndicator(
        color: ccPrimary,
        onRefresh: c.fetchTicketsApi,
        child: Obx(() {
          if (c.isLoading.value && c.tickets.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: ccPrimary));
          }
          if (c.tickets.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: Get.height * 0.25),
                Icon(Icons.support_agent_rounded,
                    size: 56, color: ccSecondaryText.withOpacity(0.5)),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    "No tickets yet.\nTap \"Raise a Ticket\" if you need help.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Inter', color: ccSecondaryText),
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: c.tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final t = c.tickets[i];
              return _TicketCard(ticket: t);
            },
          );
        }),
      ),
    );
  }

  void _openCreateSheet(BuildContext context, SupportTicketsController c) {
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    final categories = ['general', 'payment', 'driver', 'app', 'booking'];
    final selectedCategory = 'general'.obs;

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: ccSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(CCRadius.sheet))),
      Padding(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Raise a Support Ticket",
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ccNavyText)),
              const SizedBox(height: 16),
              Obx(() => Wrap(
                    spacing: 8,
                    children: categories.map((cat) {
                      final selected = selectedCategory.value == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        selectedColor: ccPrimary.withOpacity(0.15),
                        labelStyle: TextStyle(
                            color: selected ? ccPrimary : ccSecondaryText,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w400),
                        onSelected: (_) => selectedCategory.value = cat,
                      );
                    }).toList(),
                  )),
              const SizedBox(height: 14),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                    labelText: "Subject", hintText: "Short summary of the issue"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: "Description",
                    hintText: "Describe what happened in detail"),
              ),
              const SizedBox(height: 16),
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: c.isSubmitting.value
                          ? null
                          : () async {
                              if (subjectController.text.trim().isEmpty ||
                                  descriptionController.text.trim().isEmpty) {
                                return;
                              }
                              final success = await c.createTicketApi(
                                subject: subjectController.text.trim(),
                                description: descriptionController.text.trim(),
                                category: selectedCategory.value,
                              );
                              if (success) Get.back();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ccPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(CCRadius.btn)),
                      ),
                      child: c.isSubmitting.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text("Submit Ticket",
                              style: TextStyle(
                                  fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});
  final Map<String, dynamic> ticket;

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return const Color(0xFF2E7D32);
      case 'in_progress':
        return const Color(0xFFF9A825);
      case 'closed':
        return ccSecondaryText;
      default:
        return ccPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = "${ticket["status"] ?? 'open'}";
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.SUPPORT_TICKET_DETAIL,
          arguments: {"ticket_id": "${ticket["id"]}"}),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ccSurface,
          borderRadius: BorderRadius.circular(CCRadius.card),
          boxShadow: CCShadow.card,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${ticket["subject"]}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: ccNavyText)),
                  const SizedBox(height: 4),
                  Text("${ticket["last_message"] ?? ''}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CCText.bodyMd.copyWith(color: ccSecondaryText)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.replaceAll('_', ' '),
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(status)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
