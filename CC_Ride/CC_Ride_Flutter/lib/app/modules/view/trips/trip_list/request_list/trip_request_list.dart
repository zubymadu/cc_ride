// ignore_for_file: deprecated_member_use

import 'package:carride/app/modules/controllers/trips_controllers/trip_screen_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TripRequestList extends GetView<TripScreenController> {
  const TripRequestList({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TripScreenController>(
      init: TripScreenController(),
      initState: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.requestIsLoading = true;
          controller.update();
          controller.tripRequestListApi().then((_) {
            controller.isLoading = false;
            controller.update();
          });
        });
      },
      builder: (_) {
        return Obx(
          () => controller.requestIsLoading
              ? const Center(
                  child: CircularProgressIndicator(color: ccPrimary))
              : controller.tripRequestListApiModel!.data!.isEmpty
                  ? Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/image/emptyOrder.png',
                              width: 150),
                          const SizedBox(height: 10),
                          const Text(
                            'No trip requests found.',
                            style: TextStyle(
                              color: ccSecondaryText,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(10),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemCount: controller
                          .tripRequestListApiModel!.data!.length,
                      itemBuilder: (context, index) {
                        final item = controller
                            .tripRequestListApiModel!.data![index];
                        return InkWell(
                          onTap: () {
                            Get.toNamed(
                              Routes.POST_REQ_PREIVIEW_SCREEN,
                              arguments: {
                                'requestId': item.requestId,
                                'fromAddress': item.fromAddress,
                                'fromLat': item.fromLat,
                                'fromLong': item.fromLong,
                                'toAddress': item.toAddress,
                                'toLat': item.toLat,
                                'toLong': item.toLong,
                                'requestDescription':
                                    item.requestDescription,
                                'departureDate': item.departureDate,
                                'seatRequire': item.seatRequire,
                                'tripInfo': item.tripInfo!,
                                'userProfile':
                                    '${item.userProfile}',
                                'userTitle': '${item.userTitle}',
                                'avgRating': '${item.avgRating}',
                                'ridesTaken': '${item.ridesTaken}',
                                'userId': '${item.userId}',
                                // Gates the "Invite to join a trip" button on
                                // the preview screen — without this the
                                // button never rendered here at all, so a
                                // driver browsing the request queue via this
                                // (correct, dedicated) screen had no way to
                                // actually pick one up. legacyRequestList
                                // only ever returns still-open requests, so
                                // isInvited is always '0' for anything
                                // reachable from this list.
                                'findTrip': true,
                                'isInvited': '0',
                              },
                            );
                          },
                          borderRadius:
                              BorderRadius.circular(CCRadius.card),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  CCRadius.card),
                              color: ccSurface,
                              boxShadow: CCShadow.card,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        DateFormat(
                                                "EEE, MMM d 'at' h:mma")
                                            .format(DateTime.parse(
                                                item.requestDatetime
                                                    .toString())),
                                        style: const TextStyle(
                                          color: ccNavyText,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF9900)
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${item.seatRequire} seat needed',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFFFF9900),
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                for (int i = 0; i < 2; i++) ...[
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: i == 0
                                              ? ccIceBlue
                                              : ccErrorLight,
                                        ),
                                        child: SvgPicture.asset(
                                          i == 0
                                              ? 'assets/image/svg/arrow-down-circle-filled.svg'
                                              : 'assets/image/svg/locationpinfilled.svg',
                                          color: i == 0
                                              ? ccPrimary
                                              : ccError,
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
                                              i == 0
                                                  ? item.fromAddress!
                                                      .split(',')
                                                      .first
                                                  : item.toAddress!
                                                      .split(',')
                                                      .first,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: ccNavyText,
                                                fontFamily: 'Inter',
                                                fontWeight:
                                                    FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (i == 0) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                DateFormat(
                                                        "EEE, MMM d 'at' h:mma")
                                                    .format(DateTime.parse(
                                                        '${item.departureDate}')),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: ccSecondaryText,
                                                  fontFamily: 'Inter',
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
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
                                    ],
                                  ),
                                  if (i != 1)
                                    SizedBox(
                                      width: 42,
                                      child:
                                          controller.buildDashedLine(),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}
