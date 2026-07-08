// import 'package:carride/app/data/confing.dart';
// import 'package:carride/app/data/data_store.dart';
// import 'package:carride/app/modules/controllers/trips_controllers/seating_plan_screen_controller.dart';
// import 'package:carride/app/routes/app_pages.dart';
// import 'package:flutter/material.dart';

// import 'package:get/get.dart';
// import 'package:intl/intl.dart';

// import '../../controllers/trips_controllers/bookings_screen_controller.dart';
// import 'package:carride/utils/cc_ds.dart';

// class BookingsScreenView extends GetView<BookingsScreenController> {
//   const BookingsScreenView({super.key});
//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.find<BookingsScreenController>();
//     return GetBuilder<BookingsScreenController>(
//       initState: (state) {
//         controller.tripPreviewScreenController.tripDetailsApi(tripId: Get.arguments["tripId"]).then((value) {
//           debugPrint("------------- tripDetailsApi value ------------- $value");
//           if (value != null) {
//             controller.tripPreviewScreenController.setTripData(controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!);
//             controller.tripPreviewScreenController.generateRoute();
//             controller.tripPreviewScreenController.update();
//             controller.update();
//           }
//         });
//       },
//       builder: (bookingsScreenController) {
//         return Scaffold(
//           appBar: AppBar(
//             title: Text("Bookings".tr),
//             actions: [
//               Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Obx(
//                     () => controller.tripPreviewScreenController.isLoading
//                     ? SizedBox()
//                     : InkWell(
//                         onTap: () {
//                           Get.toNamed(
//                             Routes.SETTINGS_SCREEN,
//                             arguments: "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripId}",
//                           );
//                         },
//                         child: Text(
//                           "Settings".tr,
//                           style: TextStyle(
//                             color: ccNavyText,
//                             fontFamily: 'Inter', fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                   ),
//                 ],
//               ),
//               SizedBox(width: 10),
//             ],
//           ),
//           body: Obx(
//             () => controller.tripPreviewScreenController.isLoading
//                 ? Center(child: controller.tripPreviewScreenController.circularProgressIndicator)
//                 : Column(
//                     children: [
//                       controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers!.isNotEmpty
//                           ? GetBuilder<SeatingPlanScreenController>(
//                               init: SeatingPlanScreenController(),
//                               initState: (_) {},
//                               builder: (seatingPlanScreenController) {
//                                 return Expanded(
//                                   child: Padding(
//                                     padding: EdgeInsets.all(10),
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       mainAxisAlignment: MainAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           "${"Inquiries".tr}(${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers!.length})",
//                                           style: TextStyle(
//                                             color: ccNavyText,
//                                             fontFamily: 'Inter', fontWeight: FontWeight.w700,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                         SizedBox(height: 20),
//                                         Expanded(
//                                           child: GridView.builder(
//                                             shrinkWrap: true,
//                                             itemCount: controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers!.length,
//                                             physics: BouncingScrollPhysics(),
//                                             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                                               crossAxisCount: 4,
//                                               mainAxisSpacing: 10,
//                                               crossAxisSpacing: 10,
//                                               mainAxisExtent: 120,
//                                             ),
//                                             itemBuilder: (context, index) {
//                                               return InkWell(
//                                                 onTap: () async {
//                                                   if ("${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.userId}" == "${getData.read("userLogin")["id"]}") {
//                                                     if ("${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].bookStatus}" != "Completed") {
//                                                       seatingPlanScreenController.bookedUsersBottomSheet(ind: index).then((value) => controller.update());
//                                                     }
//                                                   }
//                                                 },
//                                                 child: Column(
//                                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                                   children: [
//                                                     Container(
//                                                       width: 75,
//                                                       height: 75,
//                                                       decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ccNavyText, width: 2)),
//                                                       child: ClipOval(
//                                                         child: FadeInImage.assetNetwork(
//                                                           placeholder: "assets/image/ezgif.com-crop.gif",
//                                                           width: 75,
//                                                           height: 75,
//                                                           image: "${Confing.imageurl}${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].profilePic}",
//                                                           fit: BoxFit.cover,
//                                                           imageErrorBuilder: (context, error, stackTrace) => Image.asset("assets/image/ezgif.com-crop.gif", fit: BoxFit.cover),
//                                                         ),
//                                                       ),
//                                                     ),
//                                                     Text(
//                                                       "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].userName}",
//                                                       textAlign: TextAlign.center,
//                                                       overflow: TextOverflow.ellipsis,
//                                                       style: TextStyle(
//                                                         fontFamily: 'Inter', fontWeight: FontWeight.w700,
//                                                         fontSize: 16,
//                                                         color: ccNavyText,
//                                                       ),
//                                                     ),
//                                                     Text(
//                                                       "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].bookStatus}",
//                                                       style: TextStyle(
//                                                         fontFamily: 'Inter', fontWeight: FontWeight.w500,
//                                                         fontSize: 14,
//                                                         color: ccSecondaryText,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               );
//                                             },
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 );
//                               },
//                             )
//                           // ? Expanded(
//                           //     child: Container(
//                           //       width: Get.width,
//                           //       padding: EdgeInsets.all(10),
//                           //       child: Column(
//                           //         crossAxisAlignment: CrossAxisAlignment.start,
//                           //         mainAxisAlignment: MainAxisAlignment.start,
//                           //         children: [
//                           //           Text(
//                           //             "${"Inquiries".tr}(${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers!.length})",
//                           //             style: TextStyle(
//                           //               color: ccNavyText,
//                           //               fontFamily: 'Inter', fontWeight: FontWeight.w700,
//                           //               fontSize: 16,
//                           //             ),
//                           //           ),
//                           //           SizedBox(height: 10),
//                           //           ListView.separated(
//                           //             itemCount: controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers!.length,
//                           //             shrinkWrap: true,
//                           //             itemBuilder: (context, index) {
//                           //               return InkWell(
//                           //                 onTap: () {
//                           //                   // Get.toNamed(
//                           //                   //   Routes.MESSAGE_SCREEN,
//                           //                   //   arguments: {
//                           //                   //     "reciverId" : controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].userId,
//                           //                   //     "profilePic" : controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].profilePic,
//                           //                   //     "userName" : controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].userName,
//                           //                   //   },
//                           //                   // );
//                           //                   Get.toNamed(
//                           //                     Routes.MESSAGE_SCREEN,
//                           //                     arguments: {
//                           //                       "reciverId" : controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].userId,
//                           //                       "profilePic" : controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].profilePic,
//                           //                       "userName" : controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].userName,
//                           //                       "originAddress" : controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.originAddress,
//                           //                       "originLat" : controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.originLat,
//                           //                       "originLong" : controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.originLong,
//                           //                       "destiAddress" : controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.destiAddress,
//                           //                       "destiLat" : controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.destiLat,
//                           //                       "destiLong" : controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.destiLong,
//                           //                       "stopPoint" : controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.stopsDetails,
//                           //                     },
//                           //                   );
//                           //                 },
//                           //                 child: Row(
//                           //                   children: [
//                           //                     Container(
//                           //                       decoration: BoxDecoration(),
//                           //                       height: 40,
//                           //                       width: 40,
//                           //                       child: ClipOval(
//                           //                         child: FadeInImage.assetNetwork(
//                           //                           placeholder: "assets/image/ezgif.com-crop.gif",
//                           //                           image: "${Confing.imageurl}${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].profilePic}",
//                           //                           fit: BoxFit.cover,
//                           //                           imageErrorBuilder: (context, error, stackTrace) {
//                           //                             return Image.asset(
//                           //                               "assets/image/ezgif.com-crop.gif",
//                           //                               fit: BoxFit.cover,
//                           //                             );
//                           //                           },
//                           //                         ),
//                           //                       ),
//                           //                     ),
//                           //                     SizedBox(width: 10),
//                           //                     Expanded(
//                           //                       child: Column(
//                           //                         crossAxisAlignment: CrossAxisAlignment.start,
//                           //                         children: [
//                           //                           Text(
//                           //                             "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].userName}",
//                           //                             style: TextStyle(
//                           //                               color: ccNavyText,
//                           //                               fontFamily: 'Inter', fontWeight: FontWeight.w700,
//                           //                               fontSize: 18,
//                           //                             ),
//                           //                           ),
//                           //                           Text(
//                           //                             "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.originAddress.toString().split(", ").first}, ${DateFormat('EEE, MMM d \'at\' h:mma').format(DateTime.parse("${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripStartDate.toString().split(" ").first} at ${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripStartTime.toString().split(" ").first}".replaceAll(" at ", " ").toLowerCase()))}",
//                           //                             style: TextStyle(
//                           //                               color: ccSecondaryText,
//                           //                               fontFamily: 'Inter', fontWeight: FontWeight.w500,
//                           //                             ),
//                           //                           ),
//                           //                         ],
//                           //                       ),
//                           //                     ),
//                           //                   ],
//                           //                 ),
//                           //               );
//                           //             },
//                           //             separatorBuilder: (BuildContext context, int index) => SizedBox(height: 15),
//                           //           ),
//                           //         ],
//                           //       ),
//                           //     ),
//                           //   )
//                           : Expanded(
//                               child: SizedBox(
//                                 width: Get.width,
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.center,
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     SizedBox(
//                                       width: Get.width / 1.5,
//                                       child: Text(
//                                         "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.originAddress}",
//                                         textAlign: TextAlign.center,
//                                         style: TextStyle(
//                                           fontFamily: 'Inter', fontWeight: FontWeight.w500,
//                                           color: ccNavyText,
//                                         ),
//                                       ),
//                                     ),
//                                     Text(
//                                       "to".tr,
//                                       style: TextStyle(
//                                         fontFamily: 'Inter', fontWeight: FontWeight.w700,
//                                         fontSize: 20,
//                                         color: ccNavyText,
//                                       ),
//                                     ),
//                                     SizedBox(
//                                       width: Get.width / 1.5,
//                                       child: Text(
//                                         "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.destiAddress}",
//                                         textAlign: TextAlign.center,
//                                         style: TextStyle(
//                                           fontFamily: 'Inter', fontWeight: FontWeight.w500,
//                                           color: ccNavyText,
//                                         ),
//                                       ),
//                                     ),
//                                     SizedBox(height: 10),
//                                     Text(
//                                       DateFormat('EEE, MMM d \'at\' h:mma').format(DateTime.parse("${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripStartDate.toString().split(" ").first} at ${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripStartTime.toString().split(" ").first}".replaceAll(" at ", " "))),
//                                       style: TextStyle(
//                                         fontSize: 16,
//                                         fontFamily: 'Inter', fontWeight: FontWeight.w700,
//                                         color: ccNavyText,
//                                       ),
//                                     ),
//                                     SizedBox(height: 30),
//                                     Text(
//                                       "No activity, yet".tr,
//                                       style: TextStyle(
//                                         color: ccSecondaryText,
//                                         fontSize: 16,
//                                         fontFamily: 'Inter', fontWeight: FontWeight.w500,
//                                         fontStyle: FontStyle.italic,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                     ],
//                   ),
//           ),
//         );
//       }
//     );
//   }
// }
