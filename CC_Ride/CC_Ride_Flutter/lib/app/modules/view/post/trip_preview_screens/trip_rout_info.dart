// ignore_for_file: deprecated_member_use

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/modules/controllers/post_controllers/trip_preview_screen_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TripRoutInfo extends GetView<TripPreviewScreenController> {
  const TripRoutInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final data = controller.tripDetailsApiModel!.tripData!;
    return Container(
      width: Get.width,
      decoration: BoxDecoration(
        color: ccSurface,
        borderRadius: BorderRadius.circular(CCRadius.card),
        boxShadow: CCShadow.card,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < 2; i++) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0 ? ccIceBlue : ccErrorLight,
                        ),
                        child: SvgPicture.asset(
                          i == 0
                              ? 'assets/image/svg/arrow-down-circle-filled.svg'
                              : 'assets/image/svg/locationpinfilled.svg',
                          color: i == 0 ? ccPrimary : ccError,
                          height: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i == 0
                                  ? data.originAddress!
                                      .split(',')
                                      .first
                                  : data.destiAddress!
                                      .split(',')
                                      .first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ccNavyText,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              i == 0
                                  ? DateFormat(
                                          "EEE, MMM d 'at' h:mma")
                                      .format(DateTime.parse(
                                          '${data.tripStartDate!.toIso8601String().split('T').first} ${data.tripStartTime}'
                                              .trim()))
                                  : controller.tripEndTime.value,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ccSecondaryText,
                                fontFamily: 'Inter',
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              i == 0
                                  ? 'Pickup point'
                                  : 'Destination',
                              style: const TextStyle(
                                color: ccSecondaryText,
                                fontFamily: 'Inter',
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i != 0 &&
                          data.tripIsReturn != '0')
                        InkWell(
                          onTap: () {
                            controller.appBarTitel =
                                'Return Trip';
                            controller.update();
                            if (args['findtrip'] == true) {
                              controller.finadTrip = true;
                              controller.backInBottombar = false;
                              controller
                                  .findTripDetailsApi(
                                      tripId:
                                          '${data.tripIsReturn}')
                                  .then(controller
                                      .handleApiResponse);
                            } else {
                              controller.backInBottombar =
                                  args['postTrip'] ?? false;
                              controller
                                  .tripDetailsApi(
                                      tripId:
                                          '${data.tripIsReturn}')
                                  .then(controller
                                      .handleApiResponse);
                            }
                            controller.startLocationTracking();
                            controller.update();
                          },
                          child: SvgPicture.asset(
                            'assets/image/svg/returenarrow.svg',
                            color: ccPrimary,
                            height: 20,
                          ),
                        ),
                    ],
                  ),
                  if (i == 0)
                    for (int si = 0;
                        si < data.stopsDetails!.length;
                        si++) ...[
                      SizedBox(
                          width: 42,
                          child: controller.buildDashedLine()),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: ccErrorLight,
                            ),
                            child: SvgPicture.asset(
                              'assets/image/svg/Gps.svg',
                              color: ccError,
                              height: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.stopsDetails![si].location!
                                      .split(',')
                                      .first,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: ccNavyText,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  controller
                                      .tripStopPointTime[si],
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: ccSecondaryText,
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Stop ${si + 1}',
                                  style: const TextStyle(
                                    color: ccSecondaryText,
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  if (i != 1)
                    SizedBox(
                        width: 42,
                        child: controller.buildDashedLine()),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: ccInputBorder, height: 1),
                ),
                InkWell(
                  onTap: () {
                    Get.toNamed(Routes.PROFILE_SCREEN,
                        arguments: data.userId);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: ccIceBlue,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: data.userProfile!.isEmpty
                            ? SvgPicture.asset(
                                'assets/image/svg/user-filled.svg',
                                color: ccPrimary,
                              )
                            : FadeInImage.assetNetwork(
                                placeholder:
                                    'assets/image/ezgif.com-crop.gif',
                                image:
                                    '${Confing.imageurl}${data.userProfile}',
                                fit: BoxFit.cover,
                                imageErrorBuilder:
                                    (context, error, stackTrace) =>
                                        Image.asset(
                                            'assets/image/ezgif.com-crop.gif',
                                            fit: BoxFit.cover),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data.userTitle}',
                              style: CCText.titleMd,
                            ),
                            Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/image/svg/star-filled.svg',
                                  height: 16,
                                  color: const Color(0xFFFFB800),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${data.avgRating}',
                                  style: CCText.bodyMd,
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 5),
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: ccSecondaryText,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    '${data.kmShared!.toStringAsFixed(2)}km driven',
                                    overflow: TextOverflow.ellipsis,
                                    style: CCText.bodyMd.copyWith(
                                        color: ccSecondaryText),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () {
                          Get.toNamed(Routes.PROFILE_SCREEN,
                              arguments: data.userId);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: ccInputBorder),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  CCRadius.btn)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                        ),
                        child: const Text('View Profile',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                color: ccNavyText,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if ((data.tripDescription ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/image/svg/chat-dots.svg',
                    color: ccSecondaryText,
                    height: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${data.tripDescription}',
                      style: CCText.bodyMd
                          .copyWith(color: ccSecondaryText),
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
