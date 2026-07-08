import 'package:carride/app/modules/controllers/account_controllers/refer_screen_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/utils/string.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class ReferAndEarnScreenView extends GetView<ReferAndEarnScreenController> {
  const ReferAndEarnScreenView({super.key});

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
          "Refer & Earn",
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
      bottomNavigationBar: Container(
        color: ccSurface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Obx(
          () => controller.isLoading
              ? const SizedBox(height: 52)
              : CCButton(
                  label: "Refer a Friend".tr,
                  icon: Icons.share_rounded,
                  onPressed: () => controller.share(),
                ),
        ),
      ),
      body: Obx(
        () => controller.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ccPrimary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // ── Animation ───────────────────────────────────────
                    Lottie.asset(
                      "assets/image/lottie/refer.json",
                      height: 200,
                    ),
                    const SizedBox(height: 16),

                    // ── Headline ─────────────────────────────────────────
                    Text(
                      "${"Earn".tr} $currency${controller.referAndEarnApiModel!.signupcredit} ${"for each friend you refer".tr}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: ccNavyText,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── How it works ──────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ccSurface,
                        borderRadius: BorderRadius.circular(CCRadius.card),
                        boxShadow: CCShadow.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("How it works", style: CCText.titleMd),
                          const SizedBox(height: 12),
                          _Step(
                            icon: Icons.share_rounded,
                            text: "Share the referral link with your friends".tr,
                          ),
                          const SizedBox(height: 12),
                          _Step(
                            icon: Icons.person_add_rounded,
                            text:
                                "${"Your friend gets".tr} $currency${controller.referAndEarnApiModel!.refercredit} ${"on their first complete transaction".tr}",
                          ),
                          const SizedBox(height: 12),
                          _Step(
                            icon: Icons.account_balance_wallet_rounded,
                            text:
                                "${"You get".tr} $currency${controller.referAndEarnApiModel!.signupcredit} ${"added to your wallet".tr}",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Referral code ─────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ccIceBlue,
                        borderRadius: BorderRadius.circular(CCRadius.card),
                        border: Border.all(color: ccInputBorder),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Your Referral Code",
                            style:
                                CCText.bodyMd.copyWith(color: ccSecondaryText),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "${controller.referAndEarnApiModel!.code}",
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: ccNavyText,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(
                                    text:
                                        "${controller.referAndEarnApiModel!.code}",
                                  ));
                                  showToastMessage("Copied!".tr);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: ccSurface,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: ccInputBorder),
                                  ),
                                  child: const Icon(Icons.copy_rounded,
                                      color: ccPrimary, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: ccIceBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: ccPrimary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: CCText.bodyMd,
          ),
        ),
      ],
    );
  }
}
