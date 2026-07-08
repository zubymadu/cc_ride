// import 'package:carride/app/routes/app_pages.dart';
// import 'package:carride/utils/cc_ds.dart';
// import 'package:flutter/material.dart';

// import 'package:get/get.dart';

// import '../../controllers/trip_request_controllers/request_settings_screen_controller.dart';

// class RequestSettingsScreenView extends GetView<RequestSettingsScreenController> {
//   const RequestSettingsScreenView({super.key});
//   @override
//   Widget build(BuildContext context) {
//     final args = Get.arguments ?? {};
//     debugPrint("---------------- Args setting: $args");
//     return Scaffold(
//       appBar: AppBar(),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
//             child: Text(
//               "Request settings".tr,
//               style: TextStyle(
//                 fontSize: 20,
//                 fontFamily: 'Inter',
//                 fontWeight: FontWeight.w700,
//                 color: ccNavyText,
//               ),
//             ),
//           ),
//           SizedBox(height: 30),
//           for(int i = 0; i < controller.titleText.length; i++)...[
//             InkWell(
//               onTap: () {
//                 if (i == 0) {
//                   Get.toNamed(
//                     Routes.POST_REQUEST_SCREEN,
//                     arguments: args,
//                   );
//                   // Get.toNamed(
//                   //   Routes.EDIT_TRIP_REQ_SCREEN,
//                   //   arguments: args,
//                   // );
//                 } else if (i == 1) {
//                   controller.showDeleteConfirmDialog();
//                 }
//               },
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       "${controller.titleText[i]}",
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontFamily: 'Inter',
//                         fontWeight: FontWeight.w500,
//                         color: i != controller.titleText.length - 1 ? ccNavyText : ccError,
//                       ),
//                     ),
//                     Icon(
//                       Icons.arrow_forward_ios,
//                       color: ccNavyText,
//                       size: 20,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             if (i != controller.titleText.length - 1) Divider(color: ccInputBorder, thickness: 1),
//           ],
//         ],
//       ),
//     );
//   }
// }
