import 'package:carride/app/data/data_store.dart';
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
                                    c.useCorpAccount.value
                                ? "Book on Company Account"
                                : "Proceed to Payment",
                            onPressed: () {
                              c.paymentId = "0";
                              if (c.messageController.text.isNotEmpty) {
                                if (c.isAuthorizedForCorpPayment &&
                                    c.useCorpAccount.value) {
                                  Get.toNamed(
                                      Routes.CORPORATE_BOOKING_CONFIRM);
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
                        if (c.isCorpEmployee) ...[
                          _CorporateToggle(c: c),
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
          if (enable) c.useCorpAccount.value = false;
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
                  if (v) c.useCorpAccount.value = false;
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

class _CorporateToggle extends StatelessWidget {
  const _CorporateToggle({required this.c});
  final PaymentScreenController c;

  @override
  Widget build(BuildContext context) {
    final companyName =
        (getData.read('companyName') as String? ?? '').isEmpty
            ? 'Company'
            : getData.read('companyName') as String;
    final authorized = c.isAuthorizedForCorpPayment;
    return Obx(
      () => Opacity(
        opacity: authorized ? 1 : 0.5,
        child: GestureDetector(
          onTap: !authorized
              ? null
              : () {
                  c.useCorpAccount.value = !c.useCorpAccount.value;
                  if (c.useCorpAccount.value) {
                    c.bookPricingController.walletCalculation(false);
                  }
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: authorized && c.useCorpAccount.value
                  ? ccPrimary.withOpacity(0.06)
                  : ccSurface,
              borderRadius: BorderRadius.circular(CCRadius.card),
              border: Border.all(
                color: authorized && c.useCorpAccount.value
                    ? ccPrimary
                    : ccInputBorder,
                width: authorized && c.useCorpAccount.value ? 1.5 : 1,
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
                  child: const Icon(Icons.business_outlined,
                      color: ccPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Book on company account",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ccNavyText,
                        ),
                      ),
                      Text(
                        authorized
                            ? companyName
                            : "Not available — verify your account or contact your organisation admin",
                        style:
                            CCText.bodyMd.copyWith(color: ccSecondaryText),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: authorized && c.useCorpAccount.value,
                  onChanged: !authorized
                      ? null
                      : (v) {
                          c.useCorpAccount.value = v;
                          if (v) c.bookPricingController.walletCalculation(false);
                        },
                  activeColor: ccPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
