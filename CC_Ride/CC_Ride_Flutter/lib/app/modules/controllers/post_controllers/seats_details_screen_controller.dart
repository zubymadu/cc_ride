import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/post_controllers/post_trip_controller.dart';
import 'package:carride/theme/theme_colores.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class SeatsDetailsScreenController extends GetxController {
  ThemeColores themeColores = Get.put(ThemeColores());

  // A pool driver drives their organisation's car for organisation points,
  // never cash — DriverModeController persists this choice to 'driverMode'
  // the moment they pick "Pool driver" at the mode prompt. Pricing still
  // gets computed server-side (computeFareSplit) purely for analytics/
  // savings reporting, but there is no passenger-facing price for a pool
  // driver to set, so the whole price UI is suppressed for them rather than
  // just being pre-filled or disabled.
  bool get isPoolDriverMode => getData.read('driverMode') == 'pool';

  @override
  void onInit() {
    if (isPoolDriverMode) {
      // No price UI for a pool driver at all, so there's nothing for an
      // estimate to inform — skip the fetch entirely. The price field
      // itself is hidden in the view, but posttripApi's request body still
      // has a seat_price key, and the form validator would otherwise block
      // submission on an empty price the driver is never shown.
      postTripController.seatPrice = "0";
      seatpricecontroller.text = "0";
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => estimateFareApi());
      // A single onInit-time fetch can run before the map screen has
      // actually written origin/destination/vehicle into postTripController,
      // silently leaving hasEstimate stuck at false for the rest of this
      // screen's lifetime (the catch block never surfaces a retry).
      // Re-fetching whenever any of these three actually change makes the
      // estimate self-correct regardless of navigation timing.
      ever(postTripController.originLatRx, (_) => estimateFareApi());
      ever(postTripController.destiLatRx, (_) => estimateFareApi());
      ever(postTripController.vehicleIdRx, (_) => estimateFareApi());
    }
    super.onInit();
  }

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  // Only meaningful once the super-admin has switched pricing_model to
  // platform_computed — otherwise it's just a reference figure the driver
  // isn't expected to follow, per how this shows up in the UI below.
  final RxBool _hasEstimate = false.obs;
  bool get hasEstimate => _hasEstimate.value;
  set hasEstimate(bool value) => _hasEstimate.value = value;

  final RxDouble _estimatedFare = 0.0.obs;
  double get estimatedFare => _estimatedFare.value;
  set estimatedFare(double value) => _estimatedFare.value = value;

  final RxString _pricingModel = 'driver_set'.obs;
  String get pricingModel => _pricingModel.value;
  set pricingModel(String value) => _pricingModel.value = value;

  Future<void> estimateFareApi() async {
    try {
      final body = {
        "origin_lat": postTripController.originLat,
        "origin_long": postTripController.originLong,
        "desti_lat": postTripController.destiLat,
        "desti_long": postTripController.destiLong,
        if (postTripController.vehicleId.isNotEmpty) "vehicle_id": postTripController.vehicleId,
      };
      final response = await http
          .post(Uri.parse(Confing.baseurl + Confing.estimateFare), body: jsonEncode(body), headers: userHeader)
          .timeout(const Duration(seconds: 15));
      log(name: "=========== Estimate Fare response ===========", response.body);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["Result"] == "true") {
        // Same response-shape bug as the other three estimate_fare.php call
        // sites in this app — fields are flat at the top level, confirmed
        // via direct curl against the live endpoint.
        pricingModel = data["pricing_model"] ?? 'driver_set';
        estimatedFare = double.tryParse("${data["estimated_fare"] ?? 0}") ?? 0;
        hasEstimate = pricingModel == 'platform_computed' && estimatedFare > 0;
      }
    } catch (e) {
      // Advisory only — never blocks posting a trip if this fails.
      log(name: "=========== Estimate Fare error ===========", "$e");
    }
  }
  // @override
  // void onInit() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     debugPrint("------------ arguments ------------ ${Get.arguments}");
  //     if (Get.arguments != null) {
  //       if (Get.arguments["seat_price"] != null) {
  //         postTripController.seatPrice = "${Get.arguments["seat_price"]}";
  //         seatpricecontroller.text = postTripController.seatPrice;
  //       }
  //       postTripController.totalSeat = "${Get.arguments["total_seat"]}";
  //       if (Get.arguments["trip_description"] != null) {
  //         postTripController.tripDescription = "${Get.arguments["trip_description"]}";
  //         tripdescriptioncontroller.text = postTripController.tripDescription;
  //       }
  //     } else {
  //       postTripController.totalSeat = "";
  //       postTripController.seatPrice = "";
  //       postTripController.tripDescription = "";
  //     }
  //     update();
  //   });
  //   super.onInit();
  // }

  // See multipolyline_map_screen_controller.dart — Get.put() on an
  // already-registered type replaces it with a blank instance, wiping
  // whatever's already been picked earlier in the post-trip flow (this was
  // silently breaking the live price-estimate hint on this exact screen,
  // since a blank instance has empty origin/destination and the estimate
  // call's guard clause bails out immediately).
  PostTripController postTripController =
      Get.isRegistered<PostTripController>() ? Get.find<PostTripController>() : Get.put(PostTripController());

  TextEditingController seatpricecontroller = TextEditingController();
  TextEditingController tripdescriptioncontroller = TextEditingController();

  final formKey = GlobalKey<FormState>();

  Widget buildDashedLine() {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Column(
        children: List.generate(
          4,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: Container(width: 2, height: 4, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
