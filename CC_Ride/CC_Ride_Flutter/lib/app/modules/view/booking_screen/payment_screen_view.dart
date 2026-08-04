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
                      child: Obx(() {
                        // selectedCompanyId is only ever non-null when the
                        // rider tapped a wallet card the backend already
                        // confirmed is granted AND within its access window
                        // (see _CompanyWalletCards — a card's onTap is null
                        // otherwise), so it alone is the accurate signal here.
                        // The old `isAuthorizedForCorpPayment && useCorpAccount`
                        // check was a stale proxy (company membership + phone
                        // verification) from before that real gate existed,
                        // and could disagree with it for no reason relevant
                        // to wallet-payment eligibility specifically.
                        final bookingOnCorpAccount = c.selectedCompanyId.value != null;
                        return CCButton(
                          label: bookingOnCorpAccount
                              ? "Book on Company Account"
                              : "Proceed to Payment",
                          onPressed: () {
                            c.paymentId = "0";
                            if (c.messageController.text.isNotEmpty) {
                              if (bookingOnCorpAccount) {
                                Get.toNamed(Routes.CORPORATE_BOOKING_CONFIRM);
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
                        );
                      }),
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
                        _CompanyWalletCards(c: c),

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
          if (enable) { c.useCorpAccount.value = false; c.selectedCompanyId.value = null; }
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
                  if (v) { c.useCorpAccount.value = false; c.selectedCompanyId.value = null; }
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

// Each active company an employee belongs to shows up as its own tappable
// "card" — visually modeled on a debit/credit card so it reads as a payment
// method the rider is choosing between, not just a company they're a member
// of. Selecting one charges the ride to that company's wallet instead of a
// personal payment method; tapping the selected card again deselects it.
class _CompanyWalletCards extends StatelessWidget {
  const _CompanyWalletCards({required this.c});
  final PaymentScreenController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.isLoadingWallets.value && c.companyWallets.isEmpty) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(color: ccPrimary, strokeWidth: 2),
            ),
          ),
        );
      }
      if (c.companyWallets.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                "Pay with a company wallet",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ccNavyText,
                ),
              ),
            ),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: c.companyWallets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final wallet = c.companyWallets[i];
                  final companyId = "${wallet["company_id"]}";
                  final granted = wallet["wallet_access_enabled"] == true;
                  final available = wallet["wallet_available_now"] == true;
                  final selected = c.selectedCompanyId.value == companyId;
                  final pending = c.pendingWalletAccessRequests.contains(companyId);
                  final requesting = c.requestingAccessFor.value == companyId;
                  return _WalletCard(
                    name: "${wallet["company_name"] ?? 'Company'}",
                    logoUrl: wallet["company_logo"] as String?,
                    granted: granted,
                    available: available,
                    selected: selected,
                    pending: pending,
                    requesting: requesting,
                    onTap: !available
                        ? null
                        : () => c.selectCompanyWallet(companyId),
                    onRequestAccess: (!granted && !pending && !requesting)
                        ? () => c.requestWalletAccess(companyId)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _WalletCard extends StatefulWidget {
  const _WalletCard({
    required this.name,
    required this.logoUrl,
    required this.granted,
    required this.available,
    required this.selected,
    required this.pending,
    required this.requesting,
    required this.onTap,
    required this.onRequestAccess,
  });

  final String name;
  final String? logoUrl;
  // Whether the company admin has enabled wallet payment for this employee
  // at all. `available` is a stricter subset — granted AND within the
  // configured access-hours window right now.
  final bool granted;
  final bool available;
  final bool selected;
  final bool pending;
  final bool requesting;
  final VoidCallback? onTap;
  final VoidCallback? onRequestAccess;

  @override
  State<_WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<_WalletCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    lowerBound: 0.94,
    upperBound: 1.0,
    value: 1.0,
  );

  static const _gradients = [
    [Color(0xFF1E3A5F), Color(0xFF2E5B8A)],
    [Color(0xFF2C3E50), Color(0xFF4B6584)],
    [Color(0xFF1A237E), Color(0xFF3949AB)],
    [Color(0xFF004D40), Color(0xFF00796B)],
  ];

  List<Color> get _gradient =>
      _gradients[widget.name.hashCode.abs() % _gradients.length];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => _controller.reverse(),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              _controller.forward();
              widget.onTap!();
            },
      onTapCancel: widget.onTap == null ? null : () => _controller.forward(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) =>
            Transform.scale(scale: _controller.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: 190,
          height: 118,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.available
                  ? _gradient
                  : [Colors.grey.shade400, Colors.grey.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: _gradient[1].withOpacity(0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : CCShadow.card,
            border: widget.selected
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 30,
                        height: 30,
                        color: Colors.white.withOpacity(0.15),
                        child: (widget.logoUrl ?? '').isNotEmpty
                            ? Image.network(
                                widget.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.business_rounded,
                                    color: Colors.white,
                                    size: 16),
                              )
                            : const Icon(Icons.business_rounded,
                                color: Colors.white, size: 16),
                      ),
                    ),
                    const Spacer(),
                    AnimatedScale(
                      scale: widget.selected ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  widget.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                if (!widget.granted) ...[
                  GestureDetector(
                    onTap: widget.onRequestAccess,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: widget.requesting
                          ? const SizedBox(
                              width: 10, height: 10,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                            )
                          : Text(
                              widget.pending ? "Request pending" : "Request access",
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ] else
                  Text(
                    widget.available ? "Company account" : "Outside allowed hours",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
