// import 'package:carride/app/routes/app_pages.dart';
// import 'package:flutter/material.dart';

// import 'package:get/get.dart';

// import '../../controllers/trips_controllers/settings_screen_controller.dart';

// class SettingsScreenView extends GetView<SettingsScreenController> {
//   const SettingsScreenView({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(15),
//             child: Text(
//               "Settings".tr,
//               style: TextStyle(
//                 fontSize: 24,
//                 fontFamily: FontFamily.bold,
//                 color: controller.themeColores.themeText,
//               ),
//             ),
//           ),
//           SizedBox(height: 20),
//           for(
//             int i = 0;
//             i < ( controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripStatus == "Cancelled"
//                 ? 2
//                 : controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers!.isNotEmpty
//                   ? controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers!.first.isApprove == 1 ? 2
//                   : controller.titleList.length : controller.titleList.length);
//             i++)...[
//             InkWell(
//               onTap: () {
//                 if (i == 0) {
//                   Get.toNamed(
//                     Routes.TRIP_PREVIEW_SCREEN,
//                     arguments: {
//                       "tripId" : "${Get.arguments}",
//                     },
//                   );
//                 } else if (i == 1) {
//                   Get.toNamed(Routes.SEATING_PLAN_SCREEN);
//                 } else if (i == 2) {
//                   List storData = [];
//                   List restridetails = [];
//                   for (var i = 0; i < controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.stopsDetails!.length; i++) {
//                     storData.add(
//                       {
//                         "stop_address": "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.stopsDetails![i].location}",
//                         "stop_lat": "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.stopsDetails![i].lat}",
//                         "stop_long": "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.stopsDetails![i].long}",
//                       }
//                     );
//                   }
//                   for (var i = 0; i < controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.restriDetails!.length; i++) {
//                     restridetails.add("${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.restriDetails![i].title}");
//                   }
//                   debugPrint("-------------- storData ------------ $storData");
//                   debugPrint("----------- restridetails ---------- $restridetails");
//                   Get.toNamed(
//                     Routes.MULTIPOLYLINE_MAP_SCREEN,
//                     arguments: {
//                       "trip_id": "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripId}",
//                       "origin_address": "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.originAddress}",
//                       "origin_lat": "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.originLat}",
//                       "origin_long": "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.originLong}",
//                       "desti_address": "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.destiAddress}",
//                       "desti_lat": "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.destiLat}",
//                       "desti_long": "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.destiLong}",
//                       "ride_schedule": "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.rideSchedule}",
//                       "start_date": "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripStartDate}",
//                       "start_time": "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripStartTime}",
//                       "seat_price": "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.seatPrice}",
//                       "total_seat": "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.totalSeat}",
//                       "trip_is_return" : "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripIsReturn}",
//                       "luggage_details" : "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.luggageDetails}",
//                       "backrow_details" : "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.backrowDetails}",
//                       "remain_seat" : "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.remainSeat}",
//                       "vehicle_title" : "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.vehicleTitle}",
//                       "return_date": "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.returnTripDetail!.returnDate}",
//                       "return_time": "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.returnTripDetail!.returnTime}",
//                       "trip_description" : "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripDescription}",
//                       "stopdata": storData,
//                       "restri_details" : restridetails,
//                       // "isEdit" : true,
//                     },
//                   );
//                 } else if (i == 3) {
//                   controller.cancelTripBottomsheet();
//                 }
//               },
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       "${controller.titleList[i]}",
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontFamily: FontFamily.medium,
//                         color: i != controller.titleList.length - 1  ? controller.themeColores.themeText : redColor,
//                       ),
//                     ),
//                     Icon(
//                       Icons.arrow_forward_ios,
//                       color: controller.themeColores.themeText,
//                       size: 20,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             i == 2 ? SizedBox(height: 30) : (i != controller.titleList.length - 1 ? Divider(color: controller.themeColores.themeBlueBorder, thickness: 1) : SizedBox()),
//           ],
//         ],
//       ),
//     );
//   }
// }
