// import 'package:carride/app/data/confing.dart';
// import 'package:carride/app/data/data_store.dart';
// import 'package:carride/utils/cc_ds.dart';
// import 'package:flutter/material.dart';

// import 'package:get/get.dart';

// import '../../controllers/trips_controllers/seating_plan_screen_controller.dart';

// class SeatingPlanScreenView extends GetView<SeatingPlanScreenController> {
//   const SeatingPlanScreenView({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Seating plan".tr)),
//       body: GetBuilder<SeatingPlanScreenController>(
//         init: SeatingPlanScreenController(),
//         initState: (_) {},
//         builder: (_) {
//           return Padding(
//             padding: EdgeInsets.all(10),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 Text(
//                   "Meet your carpool crew".tr,
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontFamily: 'Inter',
//                     fontWeight: FontWeight.w700,
//                     color: ccNavyText,
//                   ),
//                 ),
//                 SizedBox(height: 5),
//                 Text(
//                   "Here is everyone who will be joining your trip".tr,
//                   style: TextStyle(
//                     fontFamily: 'Inter',
//                     fontWeight: FontWeight.w500,
//                     color: ccSecondaryText,
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 Expanded(
//                   child: GridView.builder(
//                     shrinkWrap: true,
//                     itemCount: controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers!.length,
//                     physics: BouncingScrollPhysics(),
//                     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 4,
//                       mainAxisSpacing: 10,
//                       crossAxisSpacing: 10,
//                       mainAxisExtent: 120,
//                     ),
//                     itemBuilder: (context, index) {
//                       return InkWell(
//                         onTap: () {
//                           if ("${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.userId}" == "${getData.read("userLogin")["id"]}") {
//                             if ("${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].bookStatus}" != "Completed") {
//                               controller.bookedUsersBottomSheet(ind: index).then((value) => controller.update());
//                             }
//                           }
//                         },
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Container(
//                               width: 75,
//                               height: 75,
//                               decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ccNavyText, width: 2)),
//                               child: ClipOval(
//                                 child: FadeInImage.assetNetwork(
//                                   placeholder: "assets/image/ezgif.com-crop.gif",
//                                   width: 75,
//                                   height: 75,
//                                   image: "${Confing.imageurl}${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].profilePic}",
//                                   fit: BoxFit.cover,
//                                   imageErrorBuilder: (context, error, stackTrace) => Image.asset("assets/image/ezgif.com-crop.gif", fit: BoxFit.cover),
//                                 ),
//                               ),
//                             ),
//                             Text(
//                               "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].userName}",
//                               textAlign: TextAlign.center,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 fontFamily: 'Inter',
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 16,
//                                 color: ccNavyText,
//                               ),
//                             ),
//                             Text(
//                               "${controller.tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].bookStatus}",
//                               style: TextStyle(
//                                 fontFamily: 'Inter',
//                                 fontWeight: FontWeight.w500,
//                                 fontSize: 14,
//                                 color: ccSecondaryText,
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
