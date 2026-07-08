import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/view/post/trip_preview_screens/meet_your_carpool_crew.dart';
import 'package:carride/app/modules/view/post/trip_preview_screens/trip_car_information.dart';
import 'package:carride/app/modules/view/post/trip_preview_screens/trip_info.dart';
import 'package:carride/app/modules/view/post/trip_preview_screens/trip_preview_map.dart';
import 'package:carride/app/modules/view/post/trip_preview_screens/trip_rout_info.dart';
import 'package:carride/app/modules/view/post/trip_preview_screens/vehicle_preferences.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/post_controllers/trip_preview_screen_controller.dart';

class TripPreviewScreenView extends GetView<TripPreviewScreenController> {
  const TripPreviewScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TripPreviewScreenController>();
    final args = Get.arguments;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (c.backInBottombar == true) {
          Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN, arguments: 2);
        } else {
          Get.back();
        }
      },
      child: GetBuilder<TripPreviewScreenController>(
        initState: (state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            c.appBarTitel = "Trip Preview";
            c.update();
            if (args["findtrip"] == true) {
              c.finadTrip = true;
              c.backInBottombar = false;
              c.findTripDetailsApi(tripId: args["tripId"])
                  .then(c.handleApiResponse);
              c.update();
            } else {
              c.backInBottombar = args["postTrip"] ?? false;
              c.finadTrip = false;
              c.tripDetailsApi(tripId: args["tripId"])
                  .then(c.handleApiResponse);
              c.update();
            }
            c.startLocationTracking();
          });
        },
        builder: (c) {
          return Scaffold(
            backgroundColor: ccBackground,
            appBar: AppBar(
              backgroundColor: ccSurface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
                onPressed: () {
                  if (c.backInBottombar == true) {
                    Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN, arguments: 2);
                  } else {
                    Get.back();
                  }
                },
              ),
              title: Text(
                c.appBarTitel,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ccNavyText,
                ),
              ),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: ccInputBorder),
              ),
              actions: [
                if (!c.isLoading &&
                    c.tripDetailsApiModel!.tripData!.bookedUsers!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: c.finadTrip == true
                        ? IconButton(
                            onPressed: () => Get.toNamed(Routes.HELP_SCREEN),
                            icon: const Icon(Icons.help_outline_rounded,
                                color: ccSecondaryText),
                          )
                        : TextButton(
                            onPressed: () {
                              final trip =
                                  c.tripDetailsApiModel!.tripData!;
                              List storData = [];
                              List restridetails = [];
                              for (var s in trip.stopsDetails ?? []) {
                                storData.add({
                                  "stop_address": "${s.location}",
                                  "stop_lat": "${s.lat}",
                                  "stop_long": "${s.long}",
                                });
                              }
                              for (var r in trip.restriDetails ?? []) {
                                restridetails.add("${r.title}");
                              }
                              Get.toNamed(
                                Routes.MULTIPOLYLINE_MAP_SCREEN,
                                arguments: {
                                  "trip_id": "${trip.tripId}",
                                  "origin_address": "${trip.originAddress}",
                                  "origin_lat": "${trip.originLat}",
                                  "origin_long": "${trip.originLong}",
                                  "desti_address": "${trip.destiAddress}",
                                  "desti_lat": "${trip.destiLat}",
                                  "desti_long": "${trip.destiLong}",
                                  "ride_schedule": "${trip.rideSchedule}",
                                  "start_date": "${trip.tripStartDate}",
                                  "start_time": "${trip.tripStartTime}",
                                  "seat_price": "${trip.seatPrice}",
                                  "total_seat": "${trip.totalSeat}",
                                  "trip_is_return": "${trip.tripIsReturn}",
                                  "luggage_details": "${trip.luggageDetails}",
                                  "backrow_details": "${trip.backrowDetails}",
                                  "remain_seat": "${trip.remainSeat}",
                                  "license_plate": "${trip.licensePlate}",
                                  "return_date":
                                      "${trip.returnTripDetail!.returnDate}",
                                  "return_time":
                                      "${trip.returnTripDetail!.returnTime}",
                                  "trip_description":
                                      "${trip.tripDescription}",
                                  "stopdata": storData,
                                  "restri_details": restridetails,
                                },
                              );
                            },
                            child: const Text(
                              "Edit",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: ccPrimary,
                              ),
                            ),
                          ),
                  ),
              ],
            ),
            bottomNavigationBar: getData.read("userLogin") == null
                ? null
                : c.isLoading
                    ? null
                    : (c.finadTrip == false &&
                                c.tripDetailsApiModel!.tripData!.bookedUsers!
                                    .isNotEmpty) ||
                            c.tripDetailsApiModel!.tripData!.totalSeat! ==
                                "${c.tripDetailsApiModel!.tripData!.bookedSeat}"
                        ? null
                        : Container(
                            color: ccSurface,
                            padding:
                                const EdgeInsets.fromLTRB(20, 12, 20, 28),
                            child: CCButton(
                              label: c.finadTrip == true
                                  ? "Request to Book"
                                  : "Cancel Trip",
                              onPressed: () {
                                if (c.finadTrip == true) {
                                  if (getData.read("userLogin")[
                                              "is_mobile_verify"] ==
                                          "1" &&
                                      getData.read("userLogin")[
                                              "is_email_verify"] ==
                                          "1") {
                                    Get.toNamed(Routes.BOOKING_SERVICE,
                                        arguments:
                                            Get.arguments["requestId"]);
                                  } else {
                                    Get.toNamed(Routes.PROFILE_SCREEN);
                                    showToastMessage(
                                        "Mobile and email verification is not completed.");
                                  }
                                } else {
                                  c.cancelTripBottomsheet();
                                }
                              },
                            ),
                          ),
            body: Obx(
              () => c.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: ccPrimary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const TripInfo(),
                          const SizedBox(height: 12),
                          if (c.tripDetailsApiModel!.tripData!.bookedUsers!
                              .isNotEmpty) ...[
                            const MeetYourCarpoolCrew(),
                            const SizedBox(height: 12),
                          ],
                          const TripRoutInfo(),
                          const SizedBox(height: 12),
                          const TripPreviewMap(),
                          const SizedBox(height: 12),
                          if (c.tripDetailsApiModel!.tripData!.vehicleImage!
                              .isNotEmpty) ...[
                            const TripCarInformation(),
                            const SizedBox(height: 12),
                          ],
                          const VehiclePreferences(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
