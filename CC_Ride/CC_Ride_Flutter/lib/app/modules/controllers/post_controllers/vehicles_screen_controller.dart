import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/driver_mode/driver_mode_controller.dart';
import 'package:carride/app/modules/controllers/post_controllers/post_trip_controller.dart';
import 'package:carride/app/modules/models/data_get_api_model.dart';
import 'package:carride/theme/theme_colores.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class VehiclesScreenController extends GetxController {
  ThemeColores themeColores = Get.put(ThemeColores());
  // The mode prompt already asked which pool vehicle they're driving — a
  // Pool driver's vehicle is never in dataGetApiModel.vehicleData (that's
  // only vehicles they personally own, driverId = them; pool cars belong to
  // the company), so without this a Pool driver would find their assigned
  // car simply doesn't appear as an option here at all.
  DriverModeController get driverModeController => Get.find<DriverModeController>();
  bool get isPoolDriverMode => driverModeController.mode == 'pool';

  @override
  void onInit() {
    fetchData();
    super.onInit();
  }
  void fetchData() async {
    isLoading = true;
    update();
    await dataGetApi();
    update();
  }

  // See multipolyline_map_screen_controller.dart — Get.put() on an
  // already-registered type replaces it with a blank instance, wiping
  // whatever's already been picked earlier in the post-trip flow.
  PostTripController postTripController =
      Get.isRegistered<PostTripController>() ? Get.find<PostTripController>() : Get.put(PostTripController());

  DataGetApiModel? dataGetApiModel;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  final RxBool _skipVehicle = false.obs;
  bool get skipVehicle => _skipVehicle.value;
  set skipVehicle(bool value) => _skipVehicle.value = value;

  final RxInt _selectedIndex = 0.obs;
  int get selectedIndex => _selectedIndex.value;
  set selectedIndex(int value) => _selectedIndex.value = value;

  final RxList _restrictionList = [].obs;
  List get restrictionList => _restrictionList;
  set restrictionList(List value) => _restrictionList.value = value;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  Future dataGetApi() async {
    isLoading = true;
    update();
    Map body = {"uid": "${getData.read("userLogin")["id"]}"};

    // try {
      String url = Confing.baseurl + Confing.dataGet;

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(name: "============= dataGet Api url ==============", url);
      log(name: "============= dataGet Api body =============", "$body");
      log(name: "=========== dataGet Api response ===========", response.body);

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          dataGetApiModel = dataGetApiModelFromJson(response.body);
          update();
          if (dataGetApiModel!.result == "true") {
            if (Get.arguments != null) {
              debugPrint("-------- luggage_details --------- ${Get.arguments["luggage_details"]}");
              debugPrint("-------- backrow_details --------- ${Get.arguments["backrow_details"]}");
              debugPrint("--------- restri_details --------- ${Get.arguments["restri_details"]}");
              debugPrint("--------- vehicle_title ---------- ${Get.arguments["vehicle_title"]}");
              debugPrint("--------- vehicle_title ---------- ${Get.arguments["vehicle_title"]}");
              if (Get.arguments["luggage_details"] != null) {
                for(int l = 0; l < dataGetApiModel!.luggageData!.length; l++) {
                  if (dataGetApiModel!.luggageData![l].title == Get.arguments["luggage_details"]) {
                    postTripController.luggageId = "${dataGetApiModel!.luggageData![l].id}";
                  }
                } 
              } else {
                postTripController.luggageId = "${dataGetApiModel!.luggageData!.first.id}";
              }
              if (Get.arguments["restri_details"] != null) {
              List restriDetails = Get.arguments["restri_details"];
                for(int r = 0; r < dataGetApiModel!.restrictionData!.length; r++) {
                  if (restriDetails.contains(dataGetApiModel!.restrictionData![r].title)) {
                    restrictionList.add(dataGetApiModel!.restrictionData![r].id);
                  }
                }
              } else {
                postTripController.restrictionList = "";
              }
              if (Get.arguments["backrow_details"] != null) {
                postTripController.restrictionList = restrictionList.join(", ");
                for(int b = 0; b < dataGetApiModel!.backSeatingData!.length; b++) {
                  if (dataGetApiModel!.backSeatingData![b].title == Get.arguments["backrow_details"]) {
                    postTripController.backRowId = "${dataGetApiModel!.backSeatingData![b].id}";
                  }
                } 
              } else {
                postTripController.backRowId = "${dataGetApiModel!.backSeatingData!.first.id}";
              }
              if (Get.arguments["license_plate"] != null) {
                if (Get.arguments["license_plate"] == "") {
                  postTripController.skipVehicle = "1";
                  postTripController.vehicleId = "";
                  skipVehicle = true;
                } else {
                  for(int v = 0; v < dataGetApiModel!.vehicleData!.length; v++) {
                    if (dataGetApiModel!.vehicleData![v].licensePlate == Get.arguments["license_plate"]) {
                      postTripController.skipVehicle = "1";
                      selectedIndex = v;
                      postTripController.vehicleId = "${dataGetApiModel!.vehicleData![v].id}";
                    }
                  }
                }
                debugPrint("--------- restrictionList --------- $restrictionList");
                debugPrint("------ Post restrictionList ------- ${postTripController.restrictionList}");
              } else {
                postTripController.skipVehicle = "0";
                if (isPoolDriverMode && driverModeController.vehicleId != null) {
                  postTripController.vehicleId = driverModeController.vehicleId!;
                } else if (dataGetApiModel!.vehicleData!.isNotEmpty) {
                  postTripController.vehicleId = "${dataGetApiModel!.vehicleData!.first.id}";
                }
              }
            } else {
              postTripController.luggageId = "${dataGetApiModel!.luggageData!.first.id}";
              postTripController.backRowId = "${dataGetApiModel!.backSeatingData!.first.id}";
              postTripController.restrictionList = "";
              postTripController.skipVehicle = "0";
              if (isPoolDriverMode && driverModeController.vehicleId != null) {
                postTripController.vehicleId = driverModeController.vehicleId!;
              } else if (dataGetApiModel!.vehicleData!.isNotEmpty) {
                postTripController.vehicleId = "${dataGetApiModel!.vehicleData!.first.id}";
              }
            }
            update();
            debugPrint("-------- post trip skipVehicle --------- ${postTripController.skipVehicle}");
            debugPrint("------------- vehicle Id --------------- ${postTripController.vehicleId}");
            debugPrint("------------- luggage Id --------------- ${postTripController.luggageId}");
            debugPrint("------------- backRow Id --------------- ${postTripController.backRowId}");
            isLoading = false;
            update();
            return data;
          } else {
            showToastMessage("${dataGetApiModel!.responseMsg}");
            return data;
          }
        } else {
          showToastMessage("${data["ResponseMsg"]}");
          return data;
        }
      } else {
        showToastMessage("Somthing went wrong!.....");
      }
    // } catch (e) {
    //   log(name: "============= dataGet Api Error ============= ", "$e");
    // }
  }
}
