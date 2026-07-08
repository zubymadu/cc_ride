import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/booking_controllers/book_pricing_controller.dart';

class BookPricingView extends GetView<BookPricingController> {
  const BookPricingView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<BookPricingController>();
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
          "Seats & Pricing",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ccNavyText,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: ccInputBorder),
        ),
      ),
      bottomNavigationBar: Container(
        color: ccSurface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: CCButton(
          label: "Proceed to Payment",
          onPressed: () => Get.toNamed(Routes.PAYMENT_SCREEN),
        ),
      ),
      body: Obx(
        () => c.walletScreenController.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ccPrimary))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Seats selector ─────────────────────────────────
                    _Card(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Seats needed", style: CCText.titleMd),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _SteButton(
                                icon: Icons.remove,
                                onTap: c.decrement,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20),
                                child: Text(
                                  "${c.counter}",
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: ccNavyText,
                                  ),
                                ),
                              ),
                              _SteButton(
                                icon: Icons.add,
                                onTap: c.increment,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Wallet section ─────────────────────────────────
                    if (num.parse(c.walletScreenController
                            .walletReportApiModel?.wallet ??
                        '0') >
                        0) ...[
                      const SizedBox(height: 12),
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: ccIceBlue,
                                    borderRadius:
                                        BorderRadius.circular(CCRadius.btn),
                                  ),
                                  child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: ccPrimary,
                                      size: 18),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                    child: Text("Pay from Wallet",
                                        style: CCText.titleMd)),
                                CupertinoSwitch(
                                  activeTrackColor: ccPrimary,
                                  value: c.isUseWallet,
                                  onChanged: (val) {
                                    c.isUseWallet = val;
                                    c.walletCalculation(val);
                                    c.update();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Available Balance",
                                    style: CCText.bodyMd
                                        .copyWith(color: ccSecondaryText)),
                                Text(
                                  "$currency${c.totalWalletAmount.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: ccPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Coupon section ─────────────────────────────────
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: c.couponButton,
                      child: _Card(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: c.couponCode != ""
                                    ? ccSuccessLight
                                    : ccIceBlue,
                                borderRadius:
                                    BorderRadius.circular(CCRadius.btn),
                              ),
                              child: Icon(
                                Icons.local_offer_rounded,
                                color: c.couponCode != ""
                                    ? ccSuccess
                                    : ccPrimary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.couponCode != ""
                                        ? "Coupon applied!"
                                        : "Coupons & Offers",
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: c.couponCode != ""
                                          ? ccSuccess
                                          : ccNavyText,
                                    ),
                                  ),
                                  if (c.couponCode != "") ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      "Code: ${c.couponCode}",
                                      style: CCText.bodyMd
                                          .copyWith(color: ccSecondaryText),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (c.couponCode == "")
                              const Icon(Icons.chevron_right_rounded,
                                  color: ccPrimary)
                            else
                              GestureDetector(
                                onTap: () {
                                  if (c.isUseWallet) c.walletCalculation(false);
                                  c.totalAmount =
                                      c.totalAmount + c.couponAmount;
                                  c.couponAmount = 0;
                                  c.couponCode = "";
                                },
                                child: Text(
                                  "Remove",
                                  style: CCText.labelSm
                                      .copyWith(color: ccPrimary),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // ── Price breakdown ────────────────────────────────
                    const SizedBox(height: 12),
                    _Card(
                      child: Column(
                        children: [
                          _PriceRow(
                            label: "${c.counter} Seat(s)",
                            value:
                                "$currency${c.subTotal.toStringAsFixed(1)}",
                          ),
                          if (c.isUseWallet) ...[
                            const SizedBox(height: 8),
                            _PriceRow(
                              label: "Wallet",
                              value: "- $currency${c.useWalletAmount}",
                              isDiscount: true,
                            ),
                          ],
                          if (c.couponAmount != 0) ...[
                            const SizedBox(height: 8),
                            _PriceRow(
                              label: "Coupon",
                              value: "- $currency${c.couponAmount}",
                              isDiscount: true,
                            ),
                          ],
                          const SizedBox(height: 8),
                          _PriceRow(
                            label: "Booking fee",
                            value:
                                "$currency${c.bookfee.toStringAsFixed(1)}",
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: ccInputBorder, height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: ccNavyText,
                                  )),
                              Text(
                                "$currency${double.parse(c.totalAmount.toString()).toStringAsFixed(1)}",
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: ccPrimary,
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

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ccSurface,
        borderRadius: BorderRadius.circular(CCRadius.card),
        boxShadow: CCShadow.card,
      ),
      child: child,
    );
  }
}

class _SteButton extends StatelessWidget {
  const _SteButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: ccPrimary,
          borderRadius: BorderRadius.circular(CCRadius.btn),
        ),
        child: Icon(icon, color: ccSurface, size: 20),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(
      {required this.label, required this.value, this.isDiscount = false});
  final String label;
  final String value;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: CCText.bodyMd.copyWith(color: ccSecondaryText)),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDiscount ? ccSuccess : ccNavyText,
          ),
        ),
      ],
    );
  }
}
