import 'package:carride/app/modules/controllers/search_controllers/search_results_screen_controller.dart';
import 'package:carride/app/modules/view/search/search_results/post_trip_bottomsheet.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class SearchTrip extends GetView<SearchResultsScreenController> {
  const SearchTrip({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SearchResultsScreenController>();
    return GetBuilder<SearchResultsScreenController>(
      builder: (_) {
        if (c.findTripController.tripIsLoading) {
          return const Center(
              child: CircularProgressIndicator(color: ccPrimary));
        }
        if (c.findTripController.findTripsmodel!.result == 'false') {
          return _emptyState();
        }
        return ListView.separated(
          shrinkWrap: true,
          itemCount: c.findTripController.findTripsmodel!.data!
              .tripData!.length,
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.all(10),
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final trips = c.findTripController.findTripsmodel!
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
            final totalMinutes = (distanceKm / 15 * 60).toInt();
            final endDateTime =
                startDateTime.add(Duration(minutes: totalMinutes));
            tripEndTime.value =
                DateFormat("EEE, MMM d 'at' h:mm a").format(endDateTime);
            void goToPreview() => Get.toNamed(Routes.TRIP_PREVIEW_SCREEN,
                arguments: {
                  'tripId': '${trips[index].tripId}',
                  'findtrip': true,
                });
            return c.findTripDetailsData(
              onTap: goToPreview,
              onJoinWaitlist: goToPreview,
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
              routeCode: trips[index].routeCode ?? '',
              isFull: (trips[index].remainSeat ?? 1) <= 0,
              remainSeat: '${trips[index].remainSeat ?? 0}',
              startDateTime: startDateTime,
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 10),
        );
      },
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: ccIceBlue, shape: BoxShape.circle),
              child: const Icon(Icons.directions_car_outlined,
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
