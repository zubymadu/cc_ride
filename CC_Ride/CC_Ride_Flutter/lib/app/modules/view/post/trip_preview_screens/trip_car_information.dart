import 'package:carride/app/data/confing.dart';
import 'package:carride/app/modules/controllers/post_controllers/trip_preview_screen_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class TripCarInformation extends GetView<TripPreviewScreenController> {
  const TripCarInformation({super.key});

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
          const Text(
            'Car Information',
            style: TextStyle(
              color: ccNavyText,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(CCRadius.card),
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/image/ezgif.com-crop.gif',
                image: '${Confing.imageurl}${data.vehicleImage}',
                fit: BoxFit.cover,
                imageErrorBuilder: (context, error, stackTrace) =>
                    Image.asset('assets/image/ezgif.com-crop.gif',
                        fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              data.vehicleType ?? '',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                color: ccSecondaryText,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              data.vehicleTitle ?? '',
              style: const TextStyle(
                fontSize: 17,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: ccNavyText,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: ccInputBorder, height: 1),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/image/svg/car.svg',
                        color: ccSecondaryText,
                        height: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${data.year} ${data.vehicleColor}',
                          style: const TextStyle(
                            color: ccNavyText,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                    height: 25, width: 1, color: ccInputBorder),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/image/svg/card.svg',
                        color: ccSecondaryText,
                        height: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          controller.finadTrip == true
                              ? 'XXXXXXXXXX'
                              : '${data.licensePlate}',
                          style: const TextStyle(
                            color: ccNavyText,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      '${data.luggageDetails}',
                      style: const TextStyle(
                        color: ccSecondaryText,
                        fontFamily: 'Inter',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Container(
                    height: 25, width: 1, color: ccInputBorder),
                Expanded(
                  child: Center(
                    child: Text(
                      '${data.backrowDetails}',
                      style: const TextStyle(
                        color: ccSecondaryText,
                        fontFamily: 'Inter',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
