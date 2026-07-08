import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/account_controllers/earning_controllers/earning_screen_controller.dart';

class EarningScreenView extends GetView<EarningScreenController> {
  const EarningScreenView({super.key});

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
          "My Earnings",
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
      body: GetBuilder<EarningScreenController>(
        initState: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.earningApi();
          });
        },
        builder: (_) {
          if (controller.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: ccPrimary));
          }
          if (controller.earningApiModel == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: ccSecondaryText, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    "Unable to load earnings",
                    style: TextStyle(fontFamily: 'Inter', color: ccSecondaryText),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => controller.earningApi(),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }
          final m = controller.earningApiModel!;
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Balance card ─────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF001B3D), ccPrimary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(CCRadius.card + 4),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Total Earnings",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${m.currency}${m.totalEarning}",
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  controller.withdrawBottomSheet(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: ccPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        CCRadius.btn)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                              ),
                              child: const Text("Withdraw",
                                  style: CCText.titleMd),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Get.toNamed(
                                  Routes.PAYOUT_HISTORY_SCREEN),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Colors.white54),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        CCRadius.btn)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                              ),
                              child: const Text(
                                "Payout History",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Stats grid ───────────────────────────────────────────
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2,
                  children: [
                    _StatTile(
                      label: "Completed",
                      value: "${m.totalCompleted}",
                      dotColor: ccSuccess,
                    ),
                    _StatTile(
                      label: "Cancelled",
                      value: "${m.totalCancelled}",
                      dotColor: ccError,
                    ),
                    _StatTile(
                      label: "Pending",
                      value: "${m.totalPending}",
                      dotColor: const Color(0xFFF59E0B),
                    ),
                    _StatTile(
                      label: "KM Driven",
                      value: "${m.totalKmDriven}",
                      dotColor: ccPrimary,
                    ),
                    _StatTile(
                      label: "Total Payout",
                      value: "${m.totalPayout}${m.currency}",
                      dotColor: ccSecondaryText,
                    ),
                  ],
                ),

                if (m.pastTrips != null && m.pastTrips!.isNotEmpty) ...[
                  const SizedBox(height: 16),

                  // ── Past trips ─────────────────────────────────────────
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
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "Past Trip History",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: ccNavyText,
                                ),
                              ),
                            ),
                            if (m.pastTrips!.length > 2)
                              GestureDetector(
                                onTap: () =>
                                    controller.pastTripHistory(),
                                child: const Text(
                                  "View All",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: ccPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: ccInputBorder, height: 1),
                        const SizedBox(height: 12),
                        for (int i = 0;
                            i < m.pastTrips!.length && i < 2;
                            i++) ...[
                          _TripRow(
                            trip: m.pastTrips![i],
                            currency: "${m.currency}",
                          ),
                          if (i == 0 && m.pastTrips!.length > 1) ...[
                            const SizedBox(height: 8),
                            const Divider(
                                color: ccInputBorder, height: 1),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.dotColor,
  });
  final String label;
  final String value;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ccSurface,
        borderRadius: BorderRadius.circular(CCRadius.card - 2),
        border: Border.all(color: ccInputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label,
                  style:
                      CCText.labelSm.copyWith(color: ccSecondaryText)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ccNavyText,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip, required this.currency});
  final dynamic trip;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: ccSuccessLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.directions_car_rounded,
              color: ccSuccess, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Trip #${trip.tripId} · ${trip.originAddress?.split(" ").first} → ${trip.destiAddress?.split(" ").first}",
                style: CCText.titleMd,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "${trip.totalSeat} seats × $currency${trip.seatPrice}  ·  ${trip.startTime}",
                style:
                    CCText.bodyMd.copyWith(color: ccSecondaryText),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                const Icon(Icons.arrow_upward_rounded,
                    color: ccSuccess, size: 14),
                const SizedBox(width: 2),
                Text(
                  "${trip.driverEarning}$currency",
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ccSuccess,
                  ),
                ),
              ],
            ),
            Text("Earnings",
                style:
                    CCText.labelSm.copyWith(color: ccSecondaryText)),
          ],
        ),
      ],
    );
  }
}
