import 'package:carride/app/modules/controllers/trips_controllers/trip_screen_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CancelledTrips extends GetView<TripScreenController> {
  const CancelledTrips({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TripScreenController>();
    return Obx(
      () => c.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ccPrimary))
          : c.tripListCancelledApiModel == null ||
                  c.tripListCancelledApiModel!.tripData!.isEmpty
              ? Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset("assets/image/emptyOrder.png",
                          width: 150),
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
                      c.tripListCancelledApiModel!.tripData!.length,
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final RxString tripEndTime = "".obs;
                    final startDt = DateTime.parse(
                        "${c.tripListCancelledApiModel!.tripData![index].tripStartDate} ${c.tripListCancelledApiModel!.tripData![index].tripStartTime}");
                    final distKm = c.calculateDistance(
                      lat1: c.tripListCancelledApiModel!
                          .tripData![index].originLat!,
                      lon1: c.tripListCancelledApiModel!
                          .tripData![index].originLong!,
                      lat2: c.tripListCancelledApiModel!
                          .tripData![index].destiLat!,
                      lon2: c.tripListCancelledApiModel!
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
                              "${c.tripListCancelledApiModel!.tripData![index].tripId}",
                        },
                      ),
                      date: [
                        DateFormat("EEE, MMM d 'at' h:mma").format(
                          DateTime.parse(
                            "${c.tripListCancelledApiModel!.tripData![index].tripStartDate.toString().split(" ").first} at ${c.tripListCancelledApiModel!.tripData![index].tripStartTime.toString().split(" ").first}"
                                .replaceAll(" at ", " "),
                          ),
                        ),
                        tripEndTime.value,
                      ],
                      type: ["Pickup point", "Destination"],
                      address: [
                        c.tripListCancelledApiModel!.tripData![index]
                            .originAddress!
                            .split(",")
                            .first,
                        c.tripListCancelledApiModel!.tripData![index]
                            .destiAddress!
                            .split(",")
                            .first,
                      ],
                      profilePic:
                          "${c.tripListCancelledApiModel!.tripData![index].userProfile}",
                      profileName:
                          "${c.tripListCancelledApiModel!.tripData![index].userTitle}",
                      seatPrice:
                          "${c.tripListCancelledApiModel!.tripData![index].seatPrice}",
                      totalSeat:
                          "${c.tripListCancelledApiModel!.tripData![index].totalSeat}",
                      totalDriven:
                          "${c.tripListCancelledApiModel!.tripData![index].totalDriven}",
                      totalRate:
                          "${c.tripListCancelledApiModel!.tripData![index].totalRate}",
                      tripIsReturn:
                          "${c.tripListCancelledApiModel!.tripData![index].tripIsReturn}",
                    );
                  },
                ),
    );
  }
}
