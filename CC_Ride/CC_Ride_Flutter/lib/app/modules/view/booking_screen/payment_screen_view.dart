import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/corporate_models.dart';
import 'package:carride/app/modules/view/booking_screen/payment_bottomsheert.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/textfield/custom_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../controllers/booking_controllers/payment_screen_controller.dart';

class PaymentScreenView extends GetView<PaymentScreenController> {
  const PaymentScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PaymentScreenController>();
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
                "Message to Driver",
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
            bottomNavigationBar: Obx(
              () => c.paymentGatewayListController.isLoading
                  ? const SizedBox()
                  : Container(
                      color: ccSurface,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      child: Obx(() => CCButton(
                            label: c.isAuthorizedForCorpPayment &&
                                    c.useCorpAccount
                                ? "Book on Company Account"
                                : "Proceed to Payment",
                            onPressed: () {
                              c.paymentId = "0";
                              if (c.messageController.text.isNotEmpty) {
                                if (c.isAuthorizedForCorpPayment &&
                                    c.useCorpAccount) {
                                  final wallet = c.selectedCompanyWallet;
                                  Get.toNamed(
                                    Routes.CORPORATE_BOOKING_CONFIRM,
                                    arguments: {
                                      'company_id': wallet?.companyId,
                                      'company_name': wallet?.companyName,
                                      'department_id': wallet?.departmentId,
                                      'cost_centre_id': wallet?.costCentreId,
                                    },
                                  );
                                  return;
                                }
                                if (c.bookPricingController.totalAmount == 0) {
                                  c.bookSeat(transactionID: "");
                                } else {
                                  payBottomsheet(
                                      totalAmt:
                                          "${c.bookPricingController.totalAmount}");
                                }
                              } else {
                                showToastMessage("Please enter a message".tr);
                              }
                            },
                          )),
                    ),
            ),
            body: c.paymentGatewayListController.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: ccPrimary))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // ── Payment method: Wallet / Organisation ────────
                        _WalletToggle(c: c),
                        const SizedBox(height: 12),
                        if (c.isLoadingWallets) ...[
                          const SizedBox(
                            height: 96,
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: ccPrimary, strokeWidth: 2),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ] else if (c.isCorpEmployee) ...[
                          _CompanyWalletSection(c: c),
                          const SizedBox(height: 12),
                        ],

                        // ── Message card ─────────────────────────────────
                        Container(
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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: ccIceBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        color: ccPrimary,
                                        size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      "Tell the driver why you're travelling",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: ccNavyText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              customTextFormField(
                                hintText:
                                    "e.g. I'm visiting my parents over the weekend and would love a ride.",
                                maxLines: 5,
                                contentPadding: const EdgeInsets.all(14),
                                controller: c.messageController,
                                borderRadius:
                                    BorderRadius.circular(CCRadius.input),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (c.isLoading)
            Container(
              color: Colors.black.withOpacity(0.35),
              width: Get.width,
              height: Get.height,
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

class _WalletToggle extends StatelessWidget {
  const _WalletToggle({required this.c});
  final PaymentScreenController c;

  @override
  Widget build(BuildContext context) {
    final pricing = c.bookPricingController;
    return Obx(
      () => GestureDetector(
        onTap: () {
          final enable = !pricing.isUseWallet;
          pricing.walletCalculation(enable);
          if (enable) c.selectCompanyWallet(null);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: pricing.isUseWallet
                ? ccPrimary.withOpacity(0.06)
                : ccSurface,
            borderRadius: BorderRadius.circular(CCRadius.card),
            border: Border.all(
              color: pricing.isUseWallet ? ccPrimary : ccInputBorder,
              width: pricing.isUseWallet ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ccIceBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: ccPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pay from wallet",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ccNavyText,
                      ),
                    ),
                    Text(
                      "Balance: $currency${pricing.totalWalletAmount.toStringAsFixed(2)}",
                      style:
                          CCText.bodyMd.copyWith(color: ccSecondaryText),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: pricing.isUseWallet,
                onChanged: (v) {
                  pricing.walletCalculation(v);
                  if (v) c.selectCompanyWallet(null);
                },
                activeColor: ccPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row of animated, tappable "debit card"-style tiles — one per company the
/// rider is an active employee of. Selecting one charges the ride to that
/// company's prepaid wallet instead of a personal payment method.
class _CompanyWalletSection extends StatelessWidget {
  const _CompanyWalletSection({required this.c});
  final PaymentScreenController c;

  @override
  Widget build(BuildContext context) {
    final authorized = c.isAuthorizedForCorpPayment;
    return Obx(
      () => Opacity(
        opacity: authorized ? 1 : 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pay with a company wallet",
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ccNavyText,
              ),
            ),
            if (!authorized) ...[
              const SizedBox(height: 4),
              Text(
                "Not available — verify your account to use a company wallet",
                style: CCText.bodyMd.copyWith(color: ccSecondaryText),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              height: 138,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: c.companyWallets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _CompanyWalletCard(
                  c: c,
                  wallet: c.companyWallets[i],
                  enabled: authorized,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyWalletCard extends StatelessWidget {
  const _CompanyWalletCard({
    required this.c,
    required this.wallet,
    required this.enabled,
  });

  final PaymentScreenController c;
  final CompanyWalletModel wallet;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = c.selectedCompanyId == wallet.companyId;
      return GestureDetector(
        onTap: !enabled
            ? null
            : () => c.selectCompanyWallet(selected ? null : wallet.companyId),
        child: AnimatedScale(
          scale: selected ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            width: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: selected
                    ? const [Color(0xFF001B3D), ccPrimary]
                    : [ccSurface, ccSurface],
              ),
              borderRadius: BorderRadius.circular(CCRadius.card),
              border: Border.all(
                color: selected ? ccPrimary : ccInputBorder,
                width: selected ? 1.5 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: ccPrimary.withOpacity(0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : CCShadow.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (wallet.logoUrl ?? '').isEmpty
                          ? const Icon(Icons.business_rounded,
                              size: 18, color: ccPrimary)
                          : Image.network(
                              '${Confing.imageurl}${wallet.logoUrl}',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.business_rounded,
                                  size: 18,
                                  color: ccPrimary),
                            ),
                    ),
                    const Spacer(),
                    AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 15, color: ccPrimary),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : ccNavyText,
                  ),
                  child: Text(
                    wallet.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: selected
                        ? Colors.white.withOpacity(0.7)
                        : ccSecondaryText,
                  ),
                  child: Text(
                    '•••• ${wallet.companyId.length >= 4 ? wallet.companyId.substring(wallet.companyId.length - 4) : wallet.companyId}',
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : ccPrimary,
                  ),
                  child: Text(
                    '$currency${wallet.walletBalance.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
