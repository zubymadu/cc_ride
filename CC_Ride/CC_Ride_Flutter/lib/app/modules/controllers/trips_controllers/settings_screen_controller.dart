// import 'dart:convert';
// import 'dart:developer';

// import 'package:carride/app/data/confing.dart';
// import 'package:carride/app/data/data_store.dart';
// import 'package:carride/app/routes/app_pages.dart';
// import 'package:carride/theme/theme_colores.dart';
// import 'package:carride/utils/color.dart';
// import 'package:carride/utils/font_family.dart';
// import 'package:carride/widgets/custom_widgets.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';

// import '../../../modules/controllers/post_controllers/trip_preview_screen_controller.dart';
// import 'package:get/get.dart';

// class SettingsScreenController extends GetxController {
//   ThemeColores themeColores = Get.put(ThemeColores());

//   TripPreviewScreenController tripPreviewScreenController = Get.put(TripPreviewScreenController());

//   final RxBool _openTrip = true.obs;
//   bool get openTrip => _openTrip.value;
//   set openTrip(bool value) => _openTrip.value = value;

//   final RxList _titleList = [
//     "Preview trip".tr,
//     "Seating plan".tr,
//     "Edit trip details".tr,
//     "Cancel trip".tr,
//   ].obs;
//   List get titleList => _titleList;
//   set titleList(List value) => _titleList.value = value;

//   Map<String, String> userHeader = {
//     "Content-type": "application/json",
//     "Accept": "application/json",
//   };

//   final RxBool _isLoading = false.obs;
//   bool get isLoading => _isLoading.value;
//   set isLoading(bool value) => _isLoading.value = value;

//   final RxBool _isCancel = false.obs;
//   bool get isCancel => _isCancel.value;
//   set isCancel(bool value) => _isCancel.value = value;

//   Future cancelTripsApi({required String tripId}) async {
//     isLoading = true;
//     update();
//     Map body = {"uid": "${getData.read("userLogin")["id"]}", "trip_id": tripId};

//     try {
//       String url = Confing.baseurl + Confing.cancelTrip;

//       var response = await http.post(
//         Uri.parse(url),
//         body: jsonEncode(body),
//         headers: userHeader,
//       );

//       log(name: "========== cancel Trip Api Api url ===========", url);
//       log(name: "========== cancel Trip Api Api body ==========", "$body");
//       log(name: "======== cancel Trip Api Api response ========", response.body);

//       var data = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         if (data["Result"] == "true") {
//           Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN, arguments: 2);
//           showToastMessage("${data["ResponseMsg"]}");
//           return data;
//         } else {
//           showToastMessage("${data["ResponseMsg"]}");
//           return data;
//         }
//       } else {
//         showToastMessage("Somthing went wrong!.....");
//       }
//     } catch (e) {
//       log(name: "========== cancel Trip Api Api Error ==========", "$e");
//     } finally {
//       isLoading = false;
//       update();
//     }
//   }

//   void cancelTripBottomsheet() {
//     isLoading = false;
//     debugPrint("---------------- Args requestId : ${tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripId}}");
//     String tripId = "${tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripId}";
//     Get.bottomSheet(
//       isScrollControlled: true,
//       Container(
//         decoration: BoxDecoration(color: white),
//         child: Column(
//           children: [
//             SizedBox(height: 35),
//             Expanded(
//               child: Scaffold(
//                 appBar: AppBar(
//                   title: Text(
//                     "Cancel trip".tr,
//                     style: TextStyle(
//                       color: darkblueColor,
//                       fontFamily: FontFamily.medium,
//                       fontSize: 15,
//                     ),
//                   ),
//                 ),
//                 bottomNavigationBar: InkWell(
//                   onTap: () {
//                     if (isCancel) {
//                       cancelTripsApi(tripId: tripId);
//                     } else {
//                       showToastMessage("Please confirm you'd like to proceed".tr);
//                     }
//                   },
//                   child: Container(
//                     padding: EdgeInsets.all(15),
//                     decoration: BoxDecoration(
//                       border: Border(top: BorderSide(color: blueborderColor, width: 1)),
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Obx(
//                           () => Center(
//                             child: isLoading
//                               ? LoadingAnimationWidget.staggeredDotsWave(color: darkblueColor, size: 25)
//                               : Text(
//                                   "Cancel trip".tr,
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     color: darkblueColor,
//                                     fontFamily: FontFamily.bold,
//                                   ),
//                                 ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 body: Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 15,
//                     vertical: 20,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Confirm trip cancellation".tr,
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: darkblueColor,
//                           fontFamily: FontFamily.bold,
//                         ),
//                       ),
//                       Padding(
//                         padding: EdgeInsets.symmetric(vertical: 10),
//                         child: Divider(color: blueborderColor, thickness: 1),
//                       ),
//                       Row(
//                         children: [
//                           for (int i = 0; i < 2; i++) ...[
//                             Flexible(
//                               child: Text(
//                                 i == 0
//                                     ? tripPreviewScreenController.tripDetailsApiModel!.tripData!.originAddress.toString().split(", ").first
//                                     : tripPreviewScreenController.tripDetailsApiModel!.tripData!.destiAddress.toString().split(", ").first,
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: darkblueColor,
//                                   fontFamily: FontFamily.bold,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ),
//                             if (i == 0)
//                               Padding(
//                                 padding: const EdgeInsets.symmetric(horizontal: 5),
//                                 child: Text(
//                                   "to".tr,
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     color: darkblueColor,
//                                     fontFamily: FontFamily.bold,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ],
//                       ),
//                       Text(
//                         "${"On".tr} ${DateFormat("EEEE, MMMM d").format(DateTime.parse("${tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripStartDate}"))} at ${DateFormat("h:mma").format(DateTime.parse("${tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripStartDate}")).toLowerCase()}",
//                         style: TextStyle(
//                           color: bluegreyColor,
//                           fontFamily: FontFamily.medium,
//                         ),
//                       ),
//                       Padding(
//                         padding: EdgeInsets.symmetric(vertical: 10),
//                         child: Divider(color: blueborderColor, thickness: 1),
//                       ),
//                       Row(
//                         children: [
//                           Obx(
//                             () => SizedBox(
//                               height: 20,
//                               width: 20,
//                               child: Checkbox(
//                                 value: isCancel,
//                                 activeColor: darkblueColor,
//                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
//                                 side: BorderSide(),
//                                 onChanged: (value) {
//                                   isCancel = value!;
//                                 },
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: 10),
//                           Text(
//                             "I confirm that I want to cancel this trip".tr,
//                             style: TextStyle(
//                               color: bluegreyColor,
//                               fontFamily: FontFamily.medium,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
