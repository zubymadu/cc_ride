// import 'package:carride/app/routes/app_pages.dart';
// import 'package:carride/widgets/textfield/custom_text_field.dart';
// import 'package:flutter/material.dart';

// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';

// import '../../controllers/trip_request_controllers/edit_trip_req_screen_controller.dart';

// class EditTripReqScreenView extends GetView<EditTripReqScreenController> {
//   const EditTripReqScreenView({super.key});
//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.find<EditTripReqScreenController>();
//     // final args = Get.arguments ?? {};
//     // debugPrint("---------------- Args edit: $args");
//     return Scaffold(
//       appBar: AppBar(title: Text("Edit request".tr)),
//       bottomNavigationBar: InkWell(
//         onTap: () {
//           if (controller.isLoading == false) {
//             controller.editTriprequestApi(
//               requestId: "${controller.tripEditData["requestId"]}",
//               fromAddress: "${controller.tripEditData["fromAddress"]}",
//               fromLat: "${controller.tripEditData["fromLat"]}",
//               fromLong: "${controller.tripEditData["fromLong"]}",
//               toAddress: "${controller.tripEditData["toAddress"]}",
//               toLat: "${controller.tripEditData["toLat"]}",
//               toLong: "${controller.tripEditData["toLong"]}",
//               departureDate: controller.tripDate,
//               seatRequire: "${controller.tripSeat}",
//               requestDescription: controller.descriptionController.text,
//             ).then((value) {
//               if (value["Result"] == "true") {
//                 Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN, arguments: 2);
//                 // controller.isLoading = true;
//                 // controller.update();
//                 // controller.tripScreenController.tripRequestListApi().then((value) {
//                 //   controller.isLoading = false;
//                 //   controller.update();
//                 // });
//               }
//             });
//           }
//         },
//         child: Container(
//           padding: EdgeInsets.all(15),
//           decoration: BoxDecoration(border: Border(top: BorderSide(color: controller.themeColores.themeBlueBorder, width: 1))),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Obx(
//                 () => Center(
//                   child: controller.isLoading
//                       ? LoadingAnimationWidget.staggeredDotsWave(
//                           color: controller.themeColores.themeText,
//                           size: 20,
//                         )
//                       : Text(
//                           "Edit request".tr,
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontFamily: FontFamily.bold,
//                             color: controller.themeColores.themeText,
//                           ),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(15),
//         physics: BouncingScrollPhysics(),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             for (int i = 0; i < 2; i++) ...[
//               Text(
//                 i == 0 ? "From".tr : "To".tr,
//                 style: TextStyle(
//                   fontFamily: FontFamily.bold,
//                   fontSize: 18,
//                   color: controller.themeColores.themeText,
//                 ),
//               ),
//               SizedBox(height: 5),
//               Text(
//                 i == 0
//                     ? "${controller.tripEditData["fromAddress"]}"
//                     : "${controller.tripEditData["toAddress"]}",
//                 style: TextStyle(
//                   color: bluegreyColor,
//                   fontFamily: FontFamily.medium,
//                 ),
//               ),
//               if (i == 0) Container(height: 15),
//             ],
//             SizedBox(height: 20),
//             Text(
//               "Departure date".tr,
//               style: TextStyle(
//                 fontFamily: FontFamily.bold,
//                 fontSize: 18,
//                 color: controller.themeColores.themeText,
//               ),
//             ),
//             SizedBox(height: 5),
//             Text(
//               DateFormat('EEEE, MMMM d').format(DateTime.parse("${controller.tripEditData["departureDate"]}")),
//               style: TextStyle(
//                 color: bluegreyColor,
//                 fontFamily: FontFamily.medium,
//               ),
//             ),
//             SizedBox(height: 20),
//             Text(
//               "Seats required".tr,
//               style: TextStyle(
//                 fontFamily: FontFamily.bold,
//                 fontSize: 18,
//                 color: controller.themeColores.themeText,
//               ),
//             ),
//             SizedBox(height: 5),
//             Obx(
//               () => Container(
//                 padding: EdgeInsets.symmetric(horizontal: 10),
//                 width: Get.width,
//                 decoration: BoxDecoration(
//                   color: controller.themeColores.blueTextFille,
//                   borderRadius: BorderRadius.circular(14),
//                   border: Border.all(color: controller.themeColores.themeBlueBorder, width: 1.5),
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: DropdownButton<int>(
//                         value: controller.tripSeat,
//                         menuWidth: Get.width / 1.1,
//                         alignment: Alignment.center,
//                         borderRadius: BorderRadius.circular(14),
//                         underline: const SizedBox(),
//                         icon: SizedBox(),
//                         items: List.generate(12, (index) => index + 1).map(
//                           (seat) => DropdownMenuItem(
//                             value: seat,
//                             child: Text(seat.toString()),
//                           ),
//                         ).toList(),
//                         onChanged: (value) {
//                           controller.tripSeat = value!;
//                         },
//                       ),
//                     ),
//                     Icon(
//                       Icons.arrow_forward_ios,
//                       color: controller.themeColores.themeText,
//                       size: 18,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 15),
//             Text(
//               "Description".tr,
//               style: TextStyle(
//                 fontFamily: FontFamily.bold,
//                 fontSize: 18,
//                 color: controller.themeColores.themeText,
//               ),
//             ),
//             SizedBox(height: 5),
//             blueTextFilled(
//               hintText: "Tell drivers a little bit more about you and why you're travelling.".tr,
//               controller: controller.descriptionController,
//               maxLines: 5,
//               contentPadding: EdgeInsets.all(10),
//               borderRadius: BorderRadius.circular(14),
//               validator: (value) {
//                 if (value == null || value.trim().isEmpty) {
//                   return "Description cannot be empty".tr;
//                 }
//                 return null;
//               },
//               onChanged: (value) {
//                 controller.descriptionController.text = value;
//                 controller.update();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
