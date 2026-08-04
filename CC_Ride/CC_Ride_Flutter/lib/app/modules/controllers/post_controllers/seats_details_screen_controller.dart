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

  @override
  void onInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) => estimateFareApi());
    // A single onInit-time fetch can run before the map screen has actually
    // written origin/destination/vehicle into postTripController, silently
    // leaving hasEstimate stuck at false for the rest of this screen's
    // lifetime (the catch block never surfaces a retry). Re-fetching
    // whenever any of these three actually change makes the estimate
    // self-correct regardless of navigation timing.
    ever(postTripController.originLatRx, (_) => estimateFareApi());
    ever(postTripController.destiLatRx, (_) => estimateFareApi());
    ever(postTripController.vehicleIdRx, (_) => estimateFareApi());
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
        pricingModel = data["data"]?["pricing_model"] ?? 'driver_set';
        estimatedFare = double.tryParse("${data["data"]?["estimated_fare"] ?? 0}") ?? 0;
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

  PostTripController postTripController = Get.put(PostTripController());

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
