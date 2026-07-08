import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../controllers/account_controllers/earning_controllers/payout_history_screen_controller.dart';

class PayoutHistoryScreenView extends GetView<PayoutHistoryScreenController> {
  const PayoutHistoryScreenView({super.key});

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
          "Payout History",
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
      body: Obx(
        () => controller.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ccPrimary))
            : controller.payoutHistoryApiModel!.payoutlist!.isEmpty
                ? Center(
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
                                shape: BoxShape.circle),
                            child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: ccPrimary,
                                size: 36),
                          ),
                          const SizedBox(height: 16),
                          const Text("No Payouts Yet",
                              style: CCText.headlineMd),
                          const SizedBox(height: 8),
                          Text(
                            "Your payouts will appear here once you start earning.",
                            textAlign: TextAlign.center,
                            style: CCText.bodyLg
                                .copyWith(color: ccSecondaryText),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: controller
                        .payoutHistoryApiModel!.payoutlist!.length,
                    itemBuilder: (context, index) {
                      final p = controller
                          .payoutHistoryApiModel!.payoutlist![index];
                      final isPaid =
                          "${p.status}".toLowerCase() == "completed";
                      final accountRef = p.accNumber != null &&
                              p.accNumber!.isNotEmpty
                          ? "Account: ${p.accNumber}"
                          : p.upiId != null && p.upiId!.isNotEmpty
                              ? "UPI: ${p.upiId}"
                              : "PayPal: ${p.paypalId}";
                      String formattedDate = '';
                      try {
                        formattedDate = DateFormat('d MMM, h:mma')
                            .format(DateTime.parse("${p.rDate}"))
                            .toLowerCase();
                      } catch (_) {}

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ccSurface,
                          borderRadius:
                              BorderRadius.circular(CCRadius.card),
                          boxShadow: CCShadow.card,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Request #${p.payoutId}",
                                    style: CCText.titleMd,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPaid
                                        ? ccSuccessLight
                                        : const Color(0xFFFFFBEB),
                                    borderRadius:
                                        BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    isPaid ? "Paid" : "Pending",
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isPaid
                                          ? ccSuccess
                                          : const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            const Divider(color: ccInputBorder, height: 1),
                            const SizedBox(height: 10),

                            _row("Account", accountRef),
                            const SizedBox(height: 8),
                            _row("Amount",
                                "${p.amt}$currency",
                                bold: true,
                                valueColor: ccNavyText),
                            const SizedBox(height: 8),
                            _row("Requested", formattedDate),

                            if (p.proof != null) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      controller
                                          .paymentRecetpitBottomSheet(
                                              "${p.proof}"),
                                  icon: const Icon(
                                      Icons.receipt_long_rounded,
                                      size: 16),
                                  label: const Text(
                                      "View Payment Receipt"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: ccPrimary,
                                    side: const BorderSide(
                                        color: ccPrimary),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                CCRadius.btn)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                  ),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: CCText.bodyMd.copyWith(color: ccSecondaryText)),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? ccNavyText,
          ),
        ),
      ],
    );
  }
}
