// ignore_for_file: deprecated_member_use

import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/booking_controllers/book_details_controller.dart';

class BookDetailsView extends GetView<BookDetailsController> {
  const BookDetailsView({super.key});

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
          "Review Trip Details",
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
          label: "Meet the Driver",
          onPressed: () => Get.toNamed(Routes.BOOK_DRIVE),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Itinerary card ──────────────────────────────────────────
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
                  // Header row with tooltip
                  GestureDetector(
                    key: controller.buttonKey,
                    onTap: () => controller.toggleTooltip(context),
                    child: Row(
                      children: [
                        const Icon(Icons.route_rounded,
                            color: ccPrimary, size: 18),
                        const SizedBox(width: 8),
                        const Text("Itinerary", style: CCText.titleMd),
                        const SizedBox(width: 4),
                        const Icon(Icons.info_outline_rounded,
                            color: ccSecondaryText, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Route stops
                  for (int i = 0; i < 2; i++) ...[
                    _RouteStop(
                      controller: controller,
                      index: i,
                    ),
                    if (i == 0)
                      ...List.generate(
                        controller.tripPreviewScreenController
                                .tripDetailsApiModel
                                ?.tripData
                                ?.stopsDetails
                                ?.length ??
                            0,
                        (si) => _StopPoint(
                          controller: controller,
                          stopIndex: si,
                        ),
                      ),
                    if (i != 1) _DashedLine(controller: controller),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Description card ─────────────────────────────────────────
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
                  const Text("Trip Description", style: CCText.titleMd),
                  const SizedBox(height: 10),
                  Text(
                    "${controller.tripPreviewScreenController.tripDetailsApiModel?.tripData?.tripDescription ?? ''}",
                    style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Route Stop Row ────────────────────────────────────────────────────────────

class _RouteStop extends StatelessWidget {
  const _RouteStop({required this.controller, required this.index});
  final BookDetailsController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tripData =
        controller.tripPreviewScreenController.tripDetailsApiModel?.tripData;
    if (tripData == null) return const SizedBox.shrink();

    final label = index == 0 ? "Pickup point" : "Destination";
    final name = index == 0
        ? tripData.originAddress?.split(",").first ?? ""
        : tripData.destiAddress?.split(",").first ?? "";

    String time = "";
    try {
      if (index == 0) {
        time = DateFormat('EEE, MMM d \'at\' h:mma').format(DateTime.parse(
          "${tripData.tripStartDate!.toIso8601String().split('T').first} ${tripData.tripStartTime}"
              .trim(),
        ));
      } else {
        time = controller.tripPreviewScreenController.tripEndTime.value;
      }
    } catch (_) {}

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StopIcon(isPickup: index == 0),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CCText.titleMd),
              const SizedBox(height: 2),
              Text(time,
                  overflow: TextOverflow.ellipsis,
                  style: CCText.bodyMd.copyWith(color: ccSecondaryText)),
              const SizedBox(height: 2),
              Text(label,
                  style: CCText.labelSm.copyWith(color: ccSecondaryText)),
            ],
          ),
        ),
        if (index == 1 &&
            tripData.tripIsReturn != null &&
            tripData.tripIsReturn != "0")
          GestureDetector(
            onTap: () {
              controller.tripPreviewScreenController.finadTrip = true;
              controller.tripPreviewScreenController.backInBottombar = false;
              controller.tripPreviewScreenController
                  .findTripDetailsApi(
                      tripId: "${tripData.tripIsReturn}")
                  .then(controller
                      .tripPreviewScreenController.handleApiResponse);
              controller.update();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ccIceBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.swap_horiz_rounded,
                  color: ccPrimary, size: 18),
            ),
          ),
      ],
    );
  }
}

// ── Intermediate Stop ─────────────────────────────────────────────────────────

class _StopPoint extends StatelessWidget {
  const _StopPoint({required this.controller, required this.stopIndex});
  final BookDetailsController controller;
  final int stopIndex;

  @override
  Widget build(BuildContext context) {
    final stops = controller.tripPreviewScreenController.tripDetailsApiModel
        ?.tripData?.stopsDetails;
    if (stops == null || stopIndex >= stops.length) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        _DashedLine(controller: controller),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StopIcon(isPickup: false, isIntermediate: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stops[stopIndex].location?.split(",").first ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CCText.titleMd,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.tripPreviewScreenController
                        .tripStopPointTime[stopIndex],
                    overflow: TextOverflow.ellipsis,
                    style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Stop ${stopIndex + 1}",
                    style: CCText.labelSm.copyWith(color: ccSecondaryText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Dashed Line ────────────────────────────────────────────────────────────────

class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.controller});
  final BookDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: controller.tripPreviewScreenController.buildDashedLine(),
    );
  }
}

// ── Stop Icon ─────────────────────────────────────────────────────────────────

class _StopIcon extends StatelessWidget {
  const _StopIcon({required this.isPickup, this.isIntermediate = false});
  final bool isPickup;
  final bool isIntermediate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isIntermediate
            ? const Color(0xFFFFF3E0)
            : isPickup
                ? ccIceBlue
                : ccPrimary.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: isIntermediate
              ? const Color(0xFFEF6C00)
              : isPickup
                  ? ccPrimary
                  : ccPrimary,
          width: 1.5,
        ),
      ),
      child: Icon(
        isIntermediate
            ? Icons.circle_rounded
            : isPickup
                ? Icons.trip_origin_rounded
                : Icons.location_on_rounded,
        color: isIntermediate
            ? const Color(0xFFEF6C00)
            : ccPrimary,
        size: 20,
      ),
    );
  }
}
