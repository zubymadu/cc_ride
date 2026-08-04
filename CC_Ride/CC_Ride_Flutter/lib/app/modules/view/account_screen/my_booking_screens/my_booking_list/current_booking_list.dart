import 'package:carride/utils/color.dart';
import 'package:carride/app/modules/controllers/account_controllers/my_booking_controllers/my_booking_screen_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CurrentBookingList extends GetView<MyBookingScreenController> {
  const CurrentBookingList({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MyBookingScreenController>();
    return GetBuilder<MyBookingScreenController>(
      builder: (myBookingScreenController) {
        return RefreshIndicator(
          // Bookings only ever fetched once at controller construction
          // before this — reused as a singleton across bottom-nav tab
          // switches, so status could otherwise go stale indefinitely.
          onRefresh: () => controller.myBookingListApi(status: "current"),
          child: controller.currentTripListApiModel!.tripData!.isEmpty
        ? ListView(
            // AlwaysScrollableScrollPhysics so the pull-to-refresh gesture
            // still works even with no content to scroll.
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        "assets/image/emptyOrder.png",
                        height: 150,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${controller.currentTripListApiModel!.responseMsg}",
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          color: ccSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        : ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.all(10),
            itemCount: controller.currentTripListApiModel!.tripData!.length,
            itemBuilder: (context, index) {
              final RxString tripEndTime = "".obs;
              // A synthesized "searching for driver" entry (a ride request
              // that hasn't been matched yet) has no confirmed start time,
              // only a target date — an unparsable/empty value here used to
              // throw inside itemBuilder and silently break rendering for
              // this whole tab, which is exactly why those entries were
              // invisible. Falling back to midnight on the given date keeps
              // this list resilient regardless of what any endpoint sends.
              DateTime safeParse(String date, String time) {
                try {
                  return DateTime.parse("$date ${time.isEmpty ? '00:00' : time}");
                } catch (_) {
                  try {
                    return DateTime.parse(date);
                  } catch (_) {
                    return DateTime.now();
                  }
                }
              }
              DateTime startDateTime = safeParse(
                controller.currentTripListApiModel!.tripData![index].tripStartDate ?? '',
                controller.currentTripListApiModel!.tripData![index].tripStartTime ?? '',
              );
              final distanceKm = controller.calculateDistance(
                lat1: controller.currentTripListApiModel!.tripData![index].originLat ?? 0,
                lon1: controller.currentTripListApiModel!.tripData![index].originLong ?? 0,
                lat2: controller.currentTripListApiModel!.tripData![index].destiLat ?? 0,
                lon2: controller.currentTripListApiModel!.tripData![index].destiLong ?? 0,
              );
              final totalMinutes = (distanceKm / 20 * 60).toInt();
              DateTime endDateTime = startDateTime.add(Duration(minutes: totalMinutes));
              tripEndTime.value = DateFormat("EEE, MMM d 'at' h:mm a").format(endDateTime);
              return controller.bookDetailsData(
                onTap: () {
                  Get.toNamed(
                    Routes.BOOKING_DATAILS,
                    arguments: {
                      "trip_id" : "${controller.currentTripListApiModel!.tripData![index].tripId}",
                      "owner_id" : "${controller.currentTripListApiModel!.tripData![index].ownerId}",
                    },
                  )!.then((value) => controller.update());
                },
                date: [
                  DateFormat('EEE, MMM d \'at\' h:mma').format(startDateTime),
                  tripEndTime.value,
                ],
                totalSeat: "${controller.currentTripListApiModel!.tripData![index].totalSeat}",
                seatPrice: "${controller.currentTripListApiModel!.tripData![index].seatPrice}",
                type: ["Pickup point", "Destination"],
                address: [
                  (controller.currentTripListApiModel!.tripData![index].originAddress!.split(",").first),
                  (controller.currentTripListApiModel!.tripData![index].destiAddress!.split(",").first),
                ],
                profilePic: "${controller.currentTripListApiModel!.tripData![index].userProfile}",
                profileName: "${controller.currentTripListApiModel!.tripData![index].userTitle}",
                totalRate: "${controller.currentTripListApiModel!.tripData![index].totalRate}",
                totalDriven: "${controller.currentTripListApiModel!.tripData![index].totalDriven}",
                tripIsReturn: "${controller.currentTripListApiModel!.tripData![index].tripIsReturn}",
              );
            },
            separatorBuilder: (BuildContext context, int index) => SizedBox(height: 10),
          ),
        );
      }
    );
  }
}
