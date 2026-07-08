import 'package:carride/app/modules/controllers/post_controllers/trip_preview_screen_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TripInfo extends GetView<TripPreviewScreenController> {
  const TripInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final data = controller.tripDetailsApiModel!.tripData!;
    return Container(
      width: Get.width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ccSurface,
        borderRadius: BorderRadius.circular(CCRadius.card),
        boxShadow: CCShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 4,
            children: [
              for (int i = 0; i < 3; i++) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      i == 0
                          ? (data.vehicleTitle!.isEmpty
                              ? ''
                              : '${data.vehicleTitle}')
                          : i == 1
                              ? '${data.luggageDetails}'
                              : '${data.totalSeat} Seats Available',
                      style: const TextStyle(
                        color: ccSecondaryText,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    if (data.vehicleTitle!.isEmpty
                        ? i == 1
                        : i != 2)
                      Container(
                        padding: const EdgeInsets.all(2),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 5),
                        decoration: const BoxDecoration(
                          color: ccSecondaryText,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              text: '${data.seatPrice}',
              style: const TextStyle(
                color: ccNavyText,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: 26,
              ),
              children: [
                const TextSpan(text: ' '),
                TextSpan(
                  text: '$currency per seat',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: ccSecondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ccBackground,
              borderRadius: BorderRadius.circular(CCRadius.card),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < 2; i++) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i == 0 ? 'DURATION' : 'DISTANCE',
                          style: const TextStyle(
                            color: ccSecondaryText,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          i == 0
                              ? '${controller.hours == '00' ? '' : '${controller.hours} hours '}${controller.minutesLeft} min'
                              : '${controller.totalTripKm.toStringAsFixed(2)} km',
                          style: const TextStyle(
                            color: ccNavyText,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i == 0)
                    Container(
                      width: 1,
                      height: 44,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12),
                      color: ccInputBorder,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
