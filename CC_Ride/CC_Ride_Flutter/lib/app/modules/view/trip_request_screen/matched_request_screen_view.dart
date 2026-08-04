import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/trip_request_controllers/matched_request_controller.dart';

class MatchedRequestScreenView extends GetView<MatchedRequestController> {
  const MatchedRequestScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<MatchedRequestController>()
        ? Get.find<MatchedRequestController>()
        : Get.put(MatchedRequestController());

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
          "Confirm Your Trip",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ccNavyText,
          ),
        ),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: ccPrimary));
        }
        final r = c.request.value;
        if (r == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                "This request could no longer be found — it may have already been resolved.",
                textAlign: TextAlign.center,
                style: CCText.bodyMd.copyWith(color: ccSecondaryText),
              ),
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ccIceBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car_rounded,
                        color: ccPrimary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "A driver has committed to a trip that matches your request. Confirm to book your seat, or decline to cancel this request.",
                        style: CCText.bodyMd.copyWith(color: ccPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: ccIceBlue,
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: ccPrimary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.matchedDriverName?.isNotEmpty == true
                                    ? r.matchedDriverName!
                                    : "Driver",
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  color: ccNavyText,
                                ),
                              ),
                              if (r.matchedVehicleTitle?.isNotEmpty == true)
                                Text(
                                  r.matchedVehicleTitle!,
                                  style: CCText.labelSm
                                      .copyWith(color: ccSecondaryText),
                                ),
                            ],
                          ),
                        ),
                        if (r.matchedSeatPrice?.isNotEmpty == true)
                          Text(
                            "$currency ${r.matchedSeatPrice}",
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: ccPrimary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: ccInputBorder, height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.my_location_rounded,
                            color: ccPrimary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text("${r.fromAddress}",
                              style: CCText.bodyMd, maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: ccError, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text("${r.toAddress}",
                              style: CCText.bodyMd, maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    if (r.matchedStartDate?.isNotEmpty == true) ...[
                      const SizedBox(height: 14),
                      const Divider(color: ccInputBorder, height: 1),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              color: ccSecondaryText, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "${r.matchedStartDate} • ${r.matchedStartTime}",
                            style: CCText.bodyMd
                                .copyWith(color: ccSecondaryText),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Obx(() => CCButton(
                    label: "Confirm & Book Seat",
                    icon: Icons.check_rounded,
                    loading: c.isSubmitting.value,
                    onPressed: c.confirm,
                  )),
              const SizedBox(height: 12),
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: c.isSubmitting.value ? null : c.decline,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Decline",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: ccError,
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        );
      }),
    );
  }
}
