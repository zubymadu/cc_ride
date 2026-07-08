import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/models/post_trip_api_model.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class PostTripController extends GetxController {

  PostTripApiModel? postTripApiModel;

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  final RxString _originAddress = "".obs;
  String get originAddress => _originAddress.value;
  set originAddress(String value) => _originAddress.value = value;

  final RxList _stopData = [].obs;
  List get stopData => _stopData;
  set stopData(List value) => _stopData.value = value;

  final RxString _originLat = "".obs;
  String get originLat => _originLat.value;
  set originLat(String value) => _originLat.value = value;

  final RxString _originLong = "".obs;
  String get originLong => _originLong.value;
  set originLong(String value) => _originLong.value = value;

  final RxString _destiAddress = "".obs;
  String get destiAddress => _destiAddress.value;
  set destiAddress(String value) => _destiAddress.value = value;

  final RxString _destiLat = "".obs;
  String get destiLat => _destiLat.value;
  set destiLat(String value) => _destiLat.value = value;

  final RxString _destiLong = "".obs;
  String get destiLong => _destiLong.value;
  set destiLong(String value) => _destiLong.value = value;

  final RxString _rideSchedule = "one_time".obs;
  String get rideSchedule => _rideSchedule.value;
  set rideSchedule(String value) => _rideSchedule.value = value;

  final RxString _startDate = "".obs;
  String get startDate => _startDate.value;
  set startDate(String value) => _startDate.value = value;

  final RxString _startTime = "".obs;
  String get startTime => _startTime.value;
  set startTime(String value) => _startTime.value = value;

  final RxString _vehicleId = "".obs;
  String get vehicleId => _vehicleId.value;
  set vehicleId(String value) => _vehicleId.value = value;

  final RxString _skipVehicle = "".obs;
  String get skipVehicle => _skipVehicle.value;
  set skipVehicle(String value) => _skipVehicle.value = value;

  final RxString _returnDate = "".obs;
  String get returnDate => _returnDate.value;
  set returnDate(String value) => _returnDate.value = value;

  final RxString _returnTime = "".obs;
  String get returnTime => _returnTime.value;
  set returnTime(String value) => _returnTime.value = value;

  final RxString _luggageId = "".obs;
  String get luggageId => _luggageId.value;
  set luggageId(String value) => _luggageId.value = value;

  final RxString _backRowId = "".obs;
  String get backRowId => _backRowId.value;
  set backRowId(String value) => _backRowId.value = value;

  final RxString _restrictionList = "".obs;
  String get restrictionList => _restrictionList.value;
  set restrictionList(String value) => _restrictionList.value = value;

  final RxString _totalSeat = "".obs;
  String get totalSeat => _totalSeat.value;
  set totalSeat(String value) => _totalSeat.value = value;

  final RxString _seatPrice = "".obs;
  String get seatPrice => _seatPrice.value;
  set seatPrice(String value) => _seatPrice.value = value;

  final RxString _tripDescription = "".obs;
  String get tripDescription => _tripDescription.value;
  set tripDescription(String value) => _tripDescription.value = value;

  final RxString _requestId = "0".obs;
  String get requestId => _requestId.value;
  set requestId(String value) => _requestId.value = value;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
  };

  Future posttripApi() async {
    isLoading = true;
    update();
    Map oneWayBody = {
      "uid": "${getData.read("userLogin")["id"]}",
      "origin_address": originAddress,
      "origin_lat": originLat,
      "origin_long": originLong,
      "desti_address": destiAddress,
      "desti_lat": destiLat,
      "desti_long": destiLong,
      "ride_schedule": rideSchedule,
      "start_date": startDate,
      "start_time": startTime,
      "skip_vehicle": skipVehicle,
      "vehicle_id": vehicleId,
      "return_date": returnDate,
      "return_time": returnTime,
      "luggage_id": luggageId,
      "back_row_id": backRowId,
      "restriction_list": restrictionList,
      "total_seat": totalSeat,
      "seat_price": seatPrice,
      "book_preference": "Manual",
      "trip_description": tripDescription,
      "request_id": requestId,
      "stopdata": stopData,
    };
    
    Map returnTripbody = {
      "uid": "${getData.read("userLogin")["id"]}",
      "origin_address": originAddress,
      "origin_lat": originLat,
      "origin_long": originLong,
      "desti_address": destiAddress,
      "desti_lat": destiLat,
      "desti_long": destiLong,
      "ride_schedule": rideSchedule,
      "start_date": startDate,
      "start_time": startTime,
      "return_date": returnDate,
      "return_time": returnTime,
      "skip_vehicle": skipVehicle,
      "vehicle_id": vehicleId,
      "luggage_id": luggageId,
      "back_row_id": backRowId,
      "restriction_list": restrictionList,
      "total_seat": totalSeat,
      "seat_price": seatPrice,
      "book_preference": "Manual",
      "trip_description": tripDescription,
      "request_id": requestId,
      "stopdata": stopData,
    };

    Map recurringTripbody = {
      "uid": "${getData.read("userLogin")["id"]}",
      "origin_address": originAddress,
      "origin_lat": originLat,
      "origin_long": originLong,
      "desti_address": destiAddress,
      "desti_lat": destiLat,
      "desti_long": destiLong,
      "ride_schedule": rideSchedule,
      "start_date": startDate,
      "start_time": startTime,
      "return_date": returnDate,
      "return_time": returnTime,
      "skip_vehicle": skipVehicle,
      "vehicle_id": vehicleId,
      "luggage_id": luggageId,
      "back_row_id": backRowId,
      "restriction_list": restrictionList,
      "total_seat": totalSeat,
      "seat_price": seatPrice,
      "book_preference": "Manual",
      "trip_description": tripDescription,
      "request_id": requestId,
      "stopdata": stopData,
    };

    try {
      String url = Confing.baseurl + Confing.postTrip;

      log(name: "================ ${rideSchedule == "one_time" ? (returnDate != "" ? "Return" : "One Way") : "Recurring"} Trip Api url ================", url);
      log(name: "================ ${rideSchedule == "one_time" ? (returnDate != "" ? "Return" : "One Way") : "Recurring"} Trip Api body ===============", "${rideSchedule == "one_time" ? ( returnDate != "" ? returnTripbody : oneWayBody) : recurringTripbody}");

      var response = await http.post(
        Uri.parse(url),
        body: rideSchedule == "one_time" ? (returnDate != "" ? jsonEncode(returnTripbody) : jsonEncode(oneWayBody)) : jsonEncode(recurringTripbody),
        headers: userHeader,
      );

      log(name: "============== ${rideSchedule == "one_time" ? (returnDate != "" ? "Return" : "One Way") : "Recurring"} Trip Api response =============", response.body);

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          postTripApiModel = postTripApiModelFromJson(response.body);
          if (postTripApiModel!.result == "true") {
            Get.toNamed(
              Routes.TRIP_PREVIEW_SCREEN,
              arguments: {
                "tripId" : "${postTripApiModel!.parentTripIds!.first}",
                "postTrip" : true,
              },
            );
            debugPrint("-------------- parent_trip_ids -------------- ${postTripApiModel!.parentTripIds!.first}");
            postDataEmpty();
            isLoading = false;
            update();
            return data;
          }
          showToastMessage("${data["ResponseMsg"]}");
          return data;
        } else {
          showToastMessage("${data["ResponseMsg"]}");
        }
      } else {
        showToastMessage("Somthing went wrong!.....");
      } 
    } catch (e) {
      log(name: "============== ${rideSchedule == "one_time" ? (returnDate != "" ? "Return" : "One Way") : "Recurring"} Trip Api Error =============", "$e");
    } finally {
      isLoading = false;
      update();
    }
  }

  Future editTripsApi({required String tripId}) async {
    isLoading = true;
    update();
    Map body = {
      "uid": "${getData.read("userLogin")["id"]}",
      "trip_id": tripId,
      "origin_address": originAddress,
      "origin_lat": originLat,
      "origin_long": originLong,
      "desti_address": destiAddress,
      "desti_lat": destiLat,
      "desti_long": destiLong,
      "ride_schedule": rideSchedule,
      "start_date": startDate,
      "start_time": startTime,
      "seat_price": seatPrice,
      "total_seat": totalSeat,
      "skip_vehicle": skipVehicle,
      "vehicle_id": vehicleId,
      "luggage_id": luggageId,
      "back_row_id": backRowId,
      "restriction_list": restrictionList,
      "stopdata": stopData,
    };

    try {
      String url = Confing.baseurl + Confing.editPostTrip;

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(name: "========== edit Trip Api Api url ===========", url);
      log(name: "========== edit Trip Api Api body ==========", "$body");
      log(name: "======== edit Trip Api Api response ========", response.body);

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          showToastMessage("${data["ResponseMsg"]}");
          Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN, arguments: 2);
          postDataEmpty();
          return data;
        } else {
          showToastMessage("${data["ResponseMsg"]}");
          return data;
        }
      } else {
        showToastMessage("Somthing went wrong!.....");
      }
    } catch (e) {
      log(name: "========== edit Trip Api Api Error ==========", "$e");
    } finally {
      isLoading = false;
      update();
    }
  }

  postDataEmpty(){
    originAddress = "";
    originLat = "";
    originLong = "";
    destiAddress = "";
    destiLat = "";
    destiLong = "";
    rideSchedule = "one_time";
    startDate = "";
    startTime = "";
    returnDate = "";
    returnTime = "";
    skipVehicle = "";
    vehicleId = "";
    luggageId = "";
    backRowId = "";
    restrictionList = "";
    totalSeat = "";
    seatPrice = "";
    tripDescription = "";
    requestId = "0";
    stopData.clear();
    update();
  }
}