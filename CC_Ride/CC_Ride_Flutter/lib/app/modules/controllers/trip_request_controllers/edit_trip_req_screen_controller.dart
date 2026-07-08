// import 'dart:convert';
// import 'dart:developer';

// import 'package:carride/app/data/confing.dart';
// import 'package:carride/app/data/data_store.dart';
// import 'package:carride/app/modules/controllers/trips_controllers/trip_screen_controller.dart';
// import 'package:carride/theme/theme_colores.dart';
// import 'package:carride/widgets/custom_widgets.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;

// class EditTripReqScreenController extends GetxController {
//   ThemeColores themeColores = Get.put(ThemeColores());

//   TripScreenController tripScreenController = Get.put(TripScreenController());
  
//   final RxMap _tripEditData = {}.obs;
//   Map get tripEditData => _tripEditData;
//   set tripEditData(Map value) => _tripEditData.value = value;

//   TextEditingController descriptionController = TextEditingController();

//   @override
//   void onInit() {
//     tripEditData = Get.arguments;
//     tripDate = tripEditData["departureDate"].toString().split(" ").first;
//     tripSeat = int.parse(tripEditData["seatRequire"]);
//     descriptionController.text = tripEditData["requestDescription"];
//     debugPrint("========= Edit Trip Request tripEditData ========= $tripEditData");
//     debugPrint("=========== Edit Trip Request tripDate =========== $tripDate");
//     debugPrint("=========== Edit Trip Request tripSeat =========== $tripSeat");
//     debugPrint("=========== Edit Trip Request fromLat ============ ${tripEditData["fromLat"]}");
//     debugPrint("=========== Edit Trip Request fromLong =========== ${tripEditData["fromLong"]}");
//     debugPrint("============ Edit Trip Request toLat ============= ${tripEditData["toLat"]}");
//     debugPrint("============ Edit Trip Request toLong ============ ${tripEditData["toLong"]}");
//     debugPrint("========= Edit Trip Request description ========== ${descriptionController.text}");
//     super.onInit();
//   }

//   final RxString _tripDate = "".obs;
//   String get tripDate => _tripDate.value;
//   set tripDate(String value) => _tripDate.value = value;

//   final RxInt _tripSeat = 1.obs;
//   int get tripSeat => _tripSeat.value;
//   set tripSeat(int value) => _tripSeat.value = value;

//   final RxBool _isLoading = false.obs;
//   bool get isLoading => _isLoading.value;
//   set isLoading(bool value) => _isLoading.value = value;

//   Map<String, String> userHeader = {
//     "Content-type": "application/json",
//     "Accept": "application/json"
//   };

//   Future editTriprequestApi({
//     required String requestId,
//     required String fromAddress,
//     required String fromLat,
//     required String fromLong,
//     required String toAddress,
//     required String toLat,
//     required String toLong,
//     required String departureDate,
//     required String seatRequire,
//     required String requestDescription,
//   }) async {
//     isLoading = true;
//     update();
//     Map body = {
//       "uid": getData.read("userLogin")["id"],
//       "request_id" : requestId,
//       "from_address": fromAddress,
//       "from_lat": fromLat,
//       "from_long": fromLong,
//       "to_address": toAddress,
//       "to_lat": toLat,
//       "to_long": toLong,
//       "departure_date": departureDate,
//       "seat_require": seatRequire,
//       "request_description": requestDescription,
//     };

//     try {
//       String url = Confing.baseurl + Confing.editTripRequest;

//       var response = await http.post(
//         Uri.parse(url),
//         body: jsonEncode(body),
//         headers: userHeader,
//       );

//       log(name: "========== Edit Trip Request Api Api url ===========", url);
//       log(name: "========== Edit Trip Request Api Api body ==========", "$body");
//       log(name: "======== Edit Trip Request Api Api response ========", response.body);

//       var data = jsonDecode(response.body);
  
//       if (response.statusCode == 200) {
//         if (data["Result"] == "true") {
//           showToastMessage("${data["ResponseMsg"]}");
//           return data;
//         } else {
//           showToastMessage("${data["ResponseMsg"]}");
//         }
//       } else {
//         showToastMessage("Somthing went wrong!.....");
//       } 
//     } catch (e) {
//       log(name: "========== Edit Trip Request Api Api Error ==========", "$e");
//     } finally {
//       isLoading = false;
//       update();
//     }
//   }
// }
