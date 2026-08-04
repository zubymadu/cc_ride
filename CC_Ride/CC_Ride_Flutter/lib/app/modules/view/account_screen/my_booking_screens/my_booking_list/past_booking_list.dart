import 'package:carride/utils/color.dart';
import 'package:carride/app/modules/controllers/account_controllers/my_booking_controllers/my_booking_screen_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PastBookingList extends GetView<MyBookingScreenController> {
  const PastBookingList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MyBookingScreenController>();
    return GetBuilder<MyBookingScreenController>(
      builder: (_) {
        return RefreshIndicator(
          onRefresh: () => controller.myBookingListApi(status: "past"),
          child: controller.pastTripListApiModel!.tripData!.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset("assets/image/emptyOrder.png", height: 150),
                          const SizedBox(height: 10),
                          Text(
                            "${controller.pastTripListApiModel!.responseMsg}",
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
                padding: const EdgeInsets.all(10),
                shrinkWrap: true,
                itemCount:
                    controller.pastTripListApiModel!.tripData!.length,
                itemBuilder: (context, index) {
                  // Same resilience as CurrentBookingList — an unparsable or
                  // empty trip_start_time (a synthesized, never-matched ride
                  // request has no confirmed time slot) must never throw
                  // inside itemBuilder, or this whole tab silently stops
                  // rendering rather than just that one row.
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
                  final tripDate = safeParse(
                    controller.pastTripListApiModel!.tripData![index].tripStartDate.toString().split(" ").first,
                    controller.pastTripListApiModel!.tripData![index].tripStartTime.toString().split(" ").first,
                  );
                  return controller.bookDetailsData(
                    onTap: () {
                      Get.toNamed(
                        Routes.BOOKING_DATAILS,
                        arguments: {
                          "trip_id":
                              "${controller.pastTripListApiModel!.tripData![index].tripId}",
                          "owner_id":
                              "${controller.pastTripListApiModel!.tripData![index].ownerId}",
                        },
                      )!.then((_) => controller.update());
                    },
                    date: [
                      DateFormat("EEE, MMM d 'at' h:mma").format(tripDate),
                      DateFormat("EEE, MMM d 'at' h:mma").format(tripDate),
                    ],
                    totalSeat:
                        "${controller.pastTripListApiModel!.tripData![index].totalSeat}",
                    seatPrice:
                        "${controller.pastTripListApiModel!.tripData![index].seatPrice}",
                    type: ["Pickup point", "Destination"],
                    address: [
                      controller.pastTripListApiModel!.tripData![index]
                          .originAddress!
                          .split(",")
                          .first,
                      controller.pastTripListApiModel!.tripData![index]
                          .destiAddress!
                          .split(",")
                          .first,
                    ],
                    profilePic:
                        "${controller.pastTripListApiModel!.tripData![index].userProfile}",
                    profileName:
                        "${controller.pastTripListApiModel!.tripData![index].userTitle}",
                    totalRate:
                        "${controller.pastTripListApiModel!.tripData![index].totalRate}",
                    totalDriven:
                        "${controller.pastTripListApiModel!.tripData![index].totalDriven}",
                    tripIsReturn:
                        "${controller.pastTripListApiModel!.tripData![index].tripIsReturn}",
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
              ),
        );
      },
    );
  }
}
