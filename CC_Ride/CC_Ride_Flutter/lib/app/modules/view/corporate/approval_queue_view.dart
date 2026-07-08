// ignore_for_file: deprecated_member_use

import 'package:carride/app/modules/controllers/corporate_controllers/approval_queue_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ApprovalQueueView extends GetView<ApprovalQueueController> {
  const ApprovalQueueView({super.key});

  @override
  Widget build(BuildContext context) {
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
          "Approvals",
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
      body: Column(
        children: [
          _tabs(),
          Expanded(
            child: GetBuilder<ApprovalQueueController>(
              builder: (c) => c.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: ccPrimary))
                  : Obx(
                      () => RefreshIndicator(
                        onRefresh: c.fetchApprovals,
                        color: ccPrimary,
                        child: c.tabIndex == 0
                            ? _pendingList(c)
                            : _historyList(c),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() => GetBuilder<ApprovalQueueController>(
        builder: (c) => Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: ccIceBlue,
            borderRadius: BorderRadius.circular(CCRadius.btn),
          ),
          child: Obx(
            () => Row(
              children: [
                _tab(c, 0, 'Pending', c.pending.length),
                _tab(c, 1, 'History', c.history.length),
              ],
            ),
          ),
        ),
      );

  Widget _tab(ApprovalQueueController c, int index, String label,
          int count) =>
      Expanded(
        child: GestureDetector(
          onTap: () => c.tabIndex = index,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: c.tabIndex == index ? ccPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(CCRadius.btn - 2),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: c.tabIndex == index ? ccSurface : ccNavyText,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.tabIndex == index
                            ? Colors.white.withOpacity(0.25)
                            : ccPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          color: c.tabIndex == index ? ccSurface : ccPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );

  Widget _pendingList(ApprovalQueueController c) => c.pending.isEmpty
      ? _emptyState('No pending approvals', Icons.check_circle_outline)
      : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: c.pending.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _pendingCard(c, c.pending[i]),
        );

  Widget _pendingCard(ApprovalQueueController c, req) => GestureDetector(
        onTap: () => c.showApprovalDetail(req),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ccSurface,
            borderRadius: BorderRadius.circular(CCRadius.card),
            boxShadow: CCShadow.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: ccIceBlue, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        req.requesterName.isNotEmpty
                            ? req.requesterName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          color: ccPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req.requesterName, style: CCText.titleMd),
                        Text(
                          req.requesterDept,
                          style: CCText.bodyMd
                              .copyWith(color: ccSecondaryText),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        c.formatNaira(req.estimatedFare),
                        style: const TextStyle(
                          fontSize: 15,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          color: ccPrimary,
                        ),
                      ),
                      const Text(
                        'Est. fare',
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'Inter',
                          color: ccSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: ccInputBorder, height: 1),
              const SizedBox(height: 12),
              _routeRow(Icons.radio_button_checked, ccSuccess, req.origin),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  children: List.generate(
                    3,
                    (_) => Container(
                      width: 2,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 2),
                      color: ccInputBorder,
                    ),
                  ),
                ),
              ),
              _routeRow(Icons.location_on, ccError, req.destination),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: ccSecondaryText),
                  const SizedBox(width: 6),
                  Text(
                    _fmtDate(req.scheduledAt),
                    style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                  ),
                  const Spacer(),
                  const Icon(Icons.hourglass_bottom_outlined,
                      size: 14, color: Color(0xFFFF9900)),
                  const SizedBox(width: 4),
                  Text(
                    'Expires ${_fmtShort(req.expiresAt)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'Inter',
                      color: Color(0xFFFF9900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => c.decide(
                          approvalId: req.id, action: 'rejected'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: ccErrorLight,
                          borderRadius: BorderRadius.circular(CCRadius.btn),
                          border: Border.all(color: ccError.withOpacity(0.3)),
                        ),
                        child: const Center(
                          child: Text(
                            'Reject',
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: ccError,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => c.decide(
                          approvalId: req.id, action: 'approved'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: ccSuccessLight,
                          borderRadius: BorderRadius.circular(CCRadius.btn),
                          border:
                              Border.all(color: ccSuccess.withOpacity(0.3)),
                        ),
                        child: const Center(
                          child: Text(
                            'Approve',
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: ccSuccess,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _routeRow(IconData icon, Color iconColor, String address) =>
      Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              address,
              style: CCText.bodyMd,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _historyList(ApprovalQueueController c) => c.history.isEmpty
      ? _emptyState('No decision history', Icons.history_outlined)
      : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: c.history.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _historyCard(c, c.history[i]),
        );

  Widget _historyCard(ApprovalQueueController c, req) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ccSurface,
          borderRadius: BorderRadius.circular(CCRadius.card),
          boxShadow: CCShadow.card,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.statusColor(req.status).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                req.status == 'approved'
                    ? Icons.check
                    : req.status == 'rejected'
                        ? Icons.close
                        : Icons.arrow_upward,
                color: c.statusColor(req.status),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(req.requesterName, style: CCText.bodyMd),
                  Text(
                    '${req.origin.split(',').first} → ${req.destination.split(',').first}',
                    style: CCText.labelSm.copyWith(color: ccSecondaryText),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  c.formatNaira(req.estimatedFare),
                  style: CCText.titleMd,
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.statusColor(req.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    req.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: c.statusColor(req.status),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  String _fmtDate(String raw) {
    try {
      return DateFormat('EEE dd MMM, h:mm a')
          .format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  String _fmtShort(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final diff = dt.difference(DateTime.now());
      if (diff.inHours < 1) return 'in ${diff.inMinutes}m';
      return 'in ${diff.inHours}h';
    } catch (_) {
      return raw;
    }
  }

  Widget _emptyState(String msg, IconData icon) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: ccIceBlue, shape: BoxShape.circle),
              child: Icon(icon, color: ccPrimary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(msg, style: CCText.headlineMd),
          ],
        ),
      );
}
