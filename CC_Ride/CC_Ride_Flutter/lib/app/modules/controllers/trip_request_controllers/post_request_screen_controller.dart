import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/search_controllers/map_suggetion_controlle.dart';


import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class PostRequestScreenController extends GetxController {

  MapSuggetionControlle mapSuggetionControlle = Get.put(MapSuggetionControlle());

  final RxString _selectedDate = "".obs;
  String get selectedDate => _selectedDate.value;
  set selectedDate(String value) => _selectedDate.value = value;

  final RxString _fromAddress = "".obs;
  String get fromAddress => _fromAddress.value;
  set fromAddress(String value) => _fromAddress.value = value;

  final RxString _fromLat = "".obs;
  String get fromLat => _fromLat.value;
  set fromLat(String value) => _fromLat.value = value;

  final RxString _fromLong = "".obs;
  String get fromLong => _fromLong.value;
  set fromLong(String value) => _fromLong.value = value;

  final RxString _toAddress = "".obs;
  String get toAddress => _toAddress.value;
  set toAddress(String value) => _toAddress.value = value;

  final RxString _toLat = "".obs;
  String get toLat => _toLat.value;
  set toLat(String value) => _toLat.value = value;

  final RxString _toLong = "".obs;
  String get toLong => _toLong.value;
  set toLong(String value) => _toLong.value = value;
  
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  final RxInt _selectedSeat = 1.obs;
  int get selectedSeat => _selectedSeat.value;
  set selectedSeat(int value) => _selectedSeat.value = value;
  
  final RxString _addressHome = "".obs;
  String get addressHome => _addressHome.value;
  set addressHome(String value) => _addressHome.value = value;

  final RxList<LatLng> _waypoints = <LatLng>[].obs;
  List<LatLng> get waypoints => _waypoints;
  set waypoints(List<LatLng> value) => _waypoints.value = value;  

  final formKey = GlobalKey<FormState>();
  FocusNode focus = FocusNode();
  FocusNode focus2 = FocusNode();

  TextEditingController fromController = TextEditingController();
  TextEditingController toController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json"
  };

  Future triprequestApi({
    required String fromAddress,
    required String fromLat,
    required String fromLong,
    required String toAddress,
    required String toLat,
    required String toLong,
    required String departureDate,
    required String seatRequire,
    required String requestDescription,
  }) async {
    isLoading = true;
    update();
    Map body = {
      "uid": getData.read("userLogin")["id"],
      "from_address": fromAddress,
      "from_lat": fromLat,
      "from_long": fromLong,
      "to_address": toAddress,
      "to_lat": toLat,
      "to_long": toLong,
      "departure_date": departureDate,
      "seat_require": seatRequire,
      "request_description": requestDescription,
    };

    try {
      String url = Confing.baseurl + Confing.tripRequest;

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(name: "========== Trip Request Api url ===========", url);
      log(name: "========== Trip Request Api body ==========", "$body");
      log(name: "======== Trip Request Api response ========", response.body);

      var data = jsonDecode(response.body);
  
      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          showToastMessage("${data["ResponseMsg"]}");
          return data;
        } else {
          showToastMessage("${data["ResponseMsg"]}");
        }
      } else {
        showToastMessage("Somthing went wrong!.....");
      } 
    } catch (e) {
      log(name: "========== Trip Request Api Error ==========", "$e");
    } finally {
      isLoading = false;
      update();
    }
  }

  Future selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ccPrimary,
              onPrimary: ccSurface,
              onSurface: ccNavyText,
            ),
            datePickerTheme: DatePickerThemeData(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CCRadius.card))),
            textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: ccPrimary)),
            dialogTheme: const DialogThemeData(backgroundColor: ccSurface),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      return picked;
    }
  }

  Future editTriprequestApi({
    required String requestId,
    required String fromAddress,
    required String fromLat,
    required String fromLong,
    required String toAddress,
    required String toLat,
    required String toLong,
    required String departureDate,
    required String seatRequire,
    required String requestDescription,
  }) async {
    isLoading = true;
    update();
    Map body = {
      "uid": getData.read("userLogin")["id"],
      "request_id" : requestId,
      "from_address": fromAddress,
      "from_lat": fromLat,
      "from_long": fromLong,
      "to_address": toAddress,
      "to_lat": toLat,
      "to_long": toLong,
      "departure_date": departureDate,
      "seat_require": seatRequire,
      "request_description": requestDescription,
    };

    try {
      String url = Confing.baseurl + Confing.editTripRequest;

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(name: "========== Edit Trip Request Api Api url ===========", url);
      log(name: "========== Edit Trip Request Api Api body ==========", "$body");
      log(name: "======== Edit Trip Request Api Api response ========", response.body);

      var data = jsonDecode(response.body);
  
      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          showToastMessage("${data["ResponseMsg"]}");
          return data;
        } else {
          showToastMessage("${data["ResponseMsg"]}");
        }
      } else {
        showToastMessage("Somthing went wrong!.....");
      } 
    } catch (e) {
      log(name: "========== Edit Trip Request Api Api Error ==========", "$e");
    } finally {
      isLoading = false;
      update();
    }
  }
}
