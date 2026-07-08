import 'package:carride/app/modules/controllers/trips_controllers/trip_screen_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ActiveTrips extends GetView<TripScreenController> {
  const ActiveTrips({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TripScreenController>();
    return Obx(
      () => c.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ccPrimary))
          : c.tripListActiveApiModel == null ||
                  c.tripListActiveApiModel!.tripData!.isEmpty
              ? Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset("assets/image/emptyOrder.png", width: 150),
                      const SizedBox(height: 10),
                      Text(
                        "Nothing here right now".tr,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          color: ccSecondaryText,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount:
                      c.tripListActiveApiModel!.tripData!.length,
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final RxString tripEndTime = "".obs;
                    final startDt = DateTime.parse(
                        "${c.tripListActiveApiModel!.tripData![index].tripStartDate} ${c.tripListActiveApiModel!.tripData![index].tripStartTime}");
                    final distKm = c.calculateDistance(
                      lat1: c.tripListActiveApiModel!
                          .tripData![index].originLat!,
                      lon1: c.tripListActiveApiModel!
                          .tripData![index].originLong!,
                      lat2: c.tripListActiveApiModel!
                          .tripData![index].destiLat!,
                      lon2: c.tripListActiveApiModel!
                          .tripData![index].destiLong!,
                    );
                    final endDt = startDt.add(Duration(
                        minutes: (distKm / 15 * 60).toInt()));
                    tripEndTime.value =
                        DateFormat("EEE, MMM d 'at' h:mm a")
                            .format(endDt);
                    return c.tripDetailsData(
                      onTap: () => Get.toNamed(
                        Routes.TRIP_PREVIEW_SCREEN,
                        arguments: {
                          "tripId":
                              "${c.tripListActiveApiModel!.tripData![index].tripId}",
                        },
                      ),
                      date: [
                        DateFormat("EEE, MMM d 'at' h:mma").format(
                          DateTime.parse(
                            "${c.tripListActiveApiModel!.tripData![index].tripStartDate.toString().split(" ").first} at ${c.tripListActiveApiModel!.tripData![index].tripStartTime.toString().split(" ").first}"
                                .replaceAll(" at ", " "),
                          ),
                        ),
                        tripEndTime.value,
                      ],
                      type: ["Pickup point", "Destination"],
                      address: [
                        c.tripListActiveApiModel!.tripData![index]
                            .originAddress!
                            .split(",")
                            .first,
                        c.tripListActiveApiModel!.tripData![index]
                            .destiAddress!
                            .split(",")
                            .first,
                      ],
                      profilePic:
                          "${c.tripListActiveApiModel!.tripData![index].userProfile}",
                      profileName:
                          "${c.tripListActiveApiModel!.tripData![index].userTitle}",
                      seatPrice:
                          "${c.tripListActiveApiModel!.tripData![index].seatPrice}",
                      totalSeat:
                          "${c.tripListActiveApiModel!.tripData![index].totalSeat}",
                      totalDriven:
                          "${c.tripListActiveApiModel!.tripData![index].totalDriven}",
                      totalRate:
                          "${c.tripListActiveApiModel!.tripData![index].totalRate}",
                      tripIsReturn:
                          "${c.tripListActiveApiModel!.tripData![index].tripIsReturn}",
                    );
                  },
                ),
    );
  }
}
