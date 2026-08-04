// ignore_for_file: deprecated_member_use

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/booking_controllers/book_details_controller.dart';
import '../../controllers/booking_controllers/book_pricing_controller.dart';

class OneWaySummaryView extends StatelessWidget {
  const OneWaySummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    final details = Get.find<BookDetailsController>();

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
          "One Way Summary",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ccNavyText,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: ccInputBorder),
        ),
      ),
      bottomNavigationBar: GetBuilder<BookPricingController>(
        builder: (c) => Container(
          color: ccSurface,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: c.walletScreenController.isLoading
              ? const SizedBox(
                  height: 52,
                  child: Center(child: CircularProgressIndicator(color: ccPrimary)),
                )
              : CCButton(
                  label:
                      "Book Trip $currency${double.parse(c.totalAmount.toString()).toStringAsFixed(2)}",
                  onPressed: () => Get.toNamed(Routes.PAYMENT_SCREEN),
                ),
        ),
      ),
      body: GetBuilder<BookPricingController>(
        builder: (c) => c.walletScreenController.isLoading
            ? const Center(child: CircularProgressIndicator(color: ccPrimary))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Promo code ─────────────────────────────────────
                    GestureDetector(
                      onTap: c.couponButton,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ccIceBlue,
                          borderRadius: BorderRadius.circular(CCRadius.card),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.card_giftcard_rounded,
                                color: ccPrimary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c.couponCode.isNotEmpty
                                    ? "Coupon applied: ${c.couponCode}"
                                    : "Apply promo code",
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: ccPrimary,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: ccPrimary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Seats ────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Number of seats", style: CCText.titleMd),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: ccInputBorder),
                            borderRadius: BorderRadius.circular(CCRadius.btn),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _SeatStepButton(
                                  icon: Icons.remove, onTap: c.decrement),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  "${c.counter}",
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: ccNavyText,
                                  ),
                                ),
                              ),
                              _SeatStepButton(
                                  icon: Icons.add, onTap: c.increment,
                                  filled: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Booking for ──────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ccSurface,
                        borderRadius: BorderRadius.circular(CCRadius.card),
                        border: Border.all(color: ccInputBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_seat_rounded,
                              color: ccSecondaryText, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: CCText.bodyMd.copyWith(color: ccNavyText),
                                children: [
                                  const TextSpan(text: "You will be booking for "),
                                  TextSpan(
                                    text:
                                        "${getData.read("userLogin")?["name"] ?? "you"}",
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Driver + vehicle ─────────────────────────────────
                    _DriverCard(details: details),
                    const SizedBox(height: 20),

                    // ── Itinerary ────────────────────────────────────────
                    _ItineraryCard(details: details),
                    const SizedBox(height: 20),

                    // ── Booking breakdown ────────────────────────────────
                    const Text("Booking breakdown", style: CCText.titleMd),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ccSurface,
                        borderRadius: BorderRadius.circular(CCRadius.card),
                        boxShadow: CCShadow.card,
                      ),
                      child: Column(
                        children: [
                          if (num.parse(c.walletScreenController
                                      .walletReportApiModel?.wallet ??
                                  '0') >
                              0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Pay from Wallet",
                                    style: CCText.titleMd),
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
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: ccInputBorder, height: 1),
                            ),
                          ],
                          _PriceRow(
                            label: "${c.counter} Seat(s)",
                            value: "$currency${c.subTotal.toStringAsFixed(1)}",
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
                            value: "$currency${c.bookfee.toStringAsFixed(1)}",
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

// ── Driver + vehicle card ───────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.details});
  final BookDetailsController details;

  @override
  Widget build(BuildContext context) {
    final tripData =
        details.tripPreviewScreenController.tripDetailsApiModel?.tripData;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ccSurface,
        borderRadius: BorderRadius.circular(CCRadius.card),
        boxShadow: CCShadow.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: ccIceBlue, shape: BoxShape.circle),
            clipBehavior: Clip.antiAlias,
            child: (tripData?.userProfile ?? '').isNotEmpty
                ? FadeInImage.assetNetwork(
                    placeholder: "assets/image/ezgif.com-crop.gif",
                    image: "${Confing.imageurl}${tripData?.userProfile}",
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.person_rounded, color: ccPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tripData?.userTitle ?? '', style: CCText.titleMd),
                const SizedBox(height: 2),
                Text(
                  [tripData?.vehicleTitle, tripData?.licensePlate]
                      .where((s) => s != null && s.isNotEmpty)
                      .join(' • '),
                  style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Itinerary card ───────────────────────────────────────────────────────────

class _ItineraryCard extends StatelessWidget {
  const _ItineraryCard({required this.details});
  final BookDetailsController details;

  @override
  Widget build(BuildContext context) {
    final tripData =
        details.tripPreviewScreenController.tripDetailsApiModel?.tripData;
    if (tripData == null) return const SizedBox.shrink();

    final stops = tripData.stopsDetails ?? [];
    final hasIntermediateStop = stops.isNotEmpty;

    String startTime = '';
    try {
      startTime = DateFormat('h:mm a').format(DateTime.parse(
        "${tripData.tripStartDate!.toIso8601String().split('T').first} ${tripData.tripStartTime}"
            .trim(),
      ));
    } catch (_) {}

    return Container(
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
          _ItineraryRow(
            icon: Icons.directions_car_filled_rounded,
            label: "Trip starts here",
            place: tripData.originAddress?.split(',').first ?? '',
            trailing: "Starts at: $startTime",
          ),
          const SizedBox(height: 12),
          _ItineraryRow(
            icon: Icons.trip_origin_rounded,
            iconColor: ccSuccess,
            label: "Your pick up location",
            place: hasIntermediateStop
                ? (stops.first.location?.split(',').first ?? '')
                : (tripData.originAddress?.split(',').first ?? ''),
          ),
          const SizedBox(height: 12),
          _ItineraryRow(
            icon: Icons.location_on_rounded,
            iconColor: ccPrimary,
            label: "Your drop off location",
            place: tripData.destiAddress?.split(',').first ?? '',
          ),
          if ((tripData.routeCode ?? '').isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(color: ccInputBorder, height: 1),
            ),
            _SummaryLine(label: "Route code", value: tripData.routeCode!),
            const SizedBox(height: 8),
            _SummaryLine(label: "Trip start time", value: startTime),
          ],
        ],
      ),
    );
  }
}

class _ItineraryRow extends StatelessWidget {
  const _ItineraryRow({
    required this.icon,
    required this.label,
    required this.place,
    this.iconColor = ccSecondaryText,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String place;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: CCText.labelSm.copyWith(color: ccSecondaryText)),
              const SizedBox(height: 2),
              Text(place,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CCText.titleMd),
            ],
          ),
        ),
        if (trailing != null)
          Text(trailing!,
              style: CCText.bodyMd.copyWith(color: ccSecondaryText)),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: CCText.bodyMd.copyWith(color: ccSecondaryText)),
        Text(value,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: ccPrimary)),
      ],
    );
  }
}

// ── Small shared widgets ─────────────────────────────────────────────────────

class _SeatStepButton extends StatelessWidget {
  const _SeatStepButton(
      {required this.icon, required this.onTap, this.filled = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: filled ? ccNavyText : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: filled ? Colors.white : ccSecondaryText, size: 16),
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
        Text(label, style: CCText.bodyMd.copyWith(color: ccSecondaryText)),
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
