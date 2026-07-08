import 'package:carride/app/modules/view/account_screen/wallet/add_wallet_payment_sheet.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../../controllers/account_controllers/wallet_screen_controller.dart';

class WalletScreenView extends GetView<WalletScreenController> {
  const WalletScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<WalletScreenController>();

    return Obx(
      () => Stack(
        children: [
          Scaffold(
            backgroundColor: ccBackground,
            appBar: AppBar(
              backgroundColor: ccSurface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
                onPressed: () => Get.back(),
              ),
              title: const Text(
                "Wallet",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ccPrimary,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: ccInputBorder),
              ),
            ),
            body: Obx(
              () => c.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: ccPrimary))
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Wallet gradient card ──────────────────────
                          _WalletCard(controller: c),
                          const SizedBox(height: 24),

                          // ── Top-up button ─────────────────────────────
                          CCButton(
                            label: "Top-up Wallet",
                            onPressed: () {
                              c.paymentId = "0";
                              addWalletPaymentSheet().then((_) => c.update());
                            },
                          ),
                          const SizedBox(height: 28),

                          // ── Transaction history ────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Transaction History",
                                  style: CCText.titleMd),
                              Text(
                                "View All",
                                style: CCText.labelSm
                                    .copyWith(color: ccPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (c.walletReportApiModel?.walletitem?.isEmpty ??
                              true)
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 40),
                                child: Text(
                                  "No transactions yet",
                                  style: CCText.bodyLg
                                      .copyWith(color: ccSecondaryText),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: c.walletReportApiModel!.walletitem!.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item =
                                    c.walletReportApiModel!.walletitem![index];
                                final isCredit = item.status == "Credit";
                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: ccSurface,
                                    borderRadius:
                                        BorderRadius.circular(CCRadius.card),
                                    boxShadow: CCShadow.card,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isCredit
                                              ? ccSuccessLight
                                              : const Color(0xFFFFEBEE),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isCredit
                                              ? Icons.arrow_downward_rounded
                                              : Icons.arrow_upward_rounded,
                                          color: isCredit
                                              ? ccSuccess
                                              : const Color(0xFFD32F2F),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${item.status}",
                                              style: CCText.titleMd,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "${item.message}",
                                              style: CCText.bodyMd.copyWith(
                                                  color: ccSecondaryText),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "${isCredit ? '+' : '-'}$currency${item.amt}",
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isCredit
                                              ? ccSuccess
                                              : const Color(0xFFD32F2F),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
            ),
          ),

          // Loading overlay
          if (c.addWalletLodar)
            Container(
              color: Colors.black54,
              child: Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: ccSurface,
                  size: 32,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Wallet gradient card ────────────────────────────────────────────────────

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.controller});
  final WalletScreenController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF001B3D), ccPrimary],
        ),
        borderRadius: BorderRadius.circular(CCRadius.card),
        boxShadow: CCShadow.card,
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Corporate Wallet",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Available Balance",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "$currency ${controller.walletReportApiModel?.wallet ?? '0.00'}",
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.domain_rounded,
                            color: Colors.white70, size: 14),
                        SizedBox(width: 4),
                        Text(
                          "CC Ride",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                          color: Colors.green.withOpacity(0.3), width: 1),
                    ),
                    child: const Text(
                      "Active",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
