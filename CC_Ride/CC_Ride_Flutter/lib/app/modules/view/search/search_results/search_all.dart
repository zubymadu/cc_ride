import 'package:carride/app/modules/controllers/search_controllers/search_results_screen_controller.dart';
import 'package:carride/app/modules/view/search/search_results/post_trip_bottomsheet.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class SearchAll extends GetView<SearchResultsScreenController> {
  const SearchAll({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SearchResultsScreenController>();
    return GetBuilder<SearchResultsScreenController>(
      builder: (_) {
        if (c.findTripController.allIsLoading) {
          return const Center(
              child: CircularProgressIndicator(color: ccPrimary));
        }
        if (c.findTripController.findAllmodel!.result == 'false') {
          return _emptyState(c);
        }
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shrinkWrap: true,
                itemCount: c.findTripController.findAllmodel!.data!
                    .tripData!.length,
                scrollDirection: Axis.vertical,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final trips = c.findTripController.findAllmodel!
                      .data!.tripData!;
                  final RxString tripEndTime = ''.obs;
                  final startDateTime = DateTime.parse(
                      '${trips[index].tripStartDate} ${trips[index].tripStartTime}');
                  final distanceKm = c.calculateDistance(
                    lat1: trips[index].originLat!,
                    lon1: trips[index].originLong!,
                    lat2: trips[index].destiLat!,
                    lon2: trips[index].destiLong!,
                  );
                  final totalMinutes =
                      (distanceKm / 15 * 60).toInt();
                  final endDateTime = startDateTime
                      .add(Duration(minutes: totalMinutes));
                  tripEndTime.value = DateFormat(
                          "EEE, MMM d 'at' h:mm a")
                      .format(endDateTime);
                  return c.findTripDetailsData(
                    onTap: () {
                      Get.toNamed(Routes.TRIP_PREVIEW_SCREEN,
                          arguments: {
                            'tripId': '${trips[index].tripId}',
                            'findtrip': true,
                          });
                    },
                    date: [
                      DateFormat("EEE, MMM d 'at' h:mma").format(
                          DateTime.parse(
                              '${trips[index].tripStartDate.toString().split(' ').first} ${trips[index].tripStartTime.toString().split(' ').first}')),
                      tripEndTime.value,
                    ],
                    seatPrice: '${trips[index].seatPrice}',
                    addresstype: ['Pickup point', 'Destination'],
                    address: [
                      trips[index].originAddress!.split(',').first,
                      trips[index].destiAddress!.split(',').first,
                    ],
                    profilePic: '${trips[index].userProfile}',
                    profileName: '${trips[index].userTitle}',
                    totalDriven: '${trips[index].totalDriven}',
                    totalRate: '${trips[index].avgRating}',
                    totalSeat: '${trips[index].totalSeat}',
                    tripIsReturn: '${trips[index].tripIsReturn}',
                  );
                },
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: c.findTripController.findAllmodel!.data!
                    .requestData!.length,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final reqs = c.findTripController.findAllmodel!
                      .data!.requestData!;
                  return c.findRequestDetailsData(
                    onTap: () {
                      Get.toNamed(
                        Routes.POST_REQ_PREIVIEW_SCREEN,
                        arguments: {
                          'requestId': '${reqs[index].requestId}',
                          'fromAddress': '${reqs[index].fromAddress}',
                          'fromLat': '${reqs[index].fromLat}',
                          'fromLong': '${reqs[index].fromLong}',
                          'toAddress': '${reqs[index].toAddress}',
                          'toLat': '${reqs[index].toLat}',
                          'toLong': '${reqs[index].toLong}',
                          'requestDescription':
                              '${reqs[index].requestDescription}',
                          'departureDate':
                              '${reqs[index].departureDate}',
                          'seatRequire': '${reqs[index].seatRequire}',
                          'userProfile': '${reqs[index].userProfile}',
                          'userTitle': '${reqs[index].userTitle}',
                          'userId': '${reqs[index].userId}',
                          'isInvited': '${reqs[index].isInvited}',
                          'avgRating': '${reqs[index].avgRating}',
                          'ridesTaken': '${reqs[index].ridesTaken}',
                          'findTrip': true,
                        },
                      );
                    },
                    date: DateFormat('EEEE, MMMM dd').format(
                        DateTime.parse(reqs[index]
                            .departureDate
                            .toString()
                            .split(' ')
                            .first)),
                    address: [
                      reqs[index].fromAddress!.split(',').first,
                      reqs[index].toAddress!.split(',').first,
                    ],
                    profilePic: '${reqs[index].userProfile}',
                    totalSeat: '${reqs[index].seatRequire}',
                    profileName: '${reqs[index].userTitle}',
                    totalRate: '${reqs[index].avgRating}',
                    ridesTaken: '${reqs[index].ridesTaken}',
                  );
                },
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState(SearchResultsScreenController c) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: ccIceBlue, shape: BoxShape.circle),
              child: const Icon(Icons.search_off_rounded,
                  color: ccPrimary, size: 36),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 280,
              child: Text(
                'Nothing to see here… yet!'.tr,
                style: CCText.bodyLg.copyWith(color: ccSecondaryText),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: postTripBottomsheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ccPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(CCRadius.btn)),
                ),
                child: const Text('Post a trip',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      );
}
