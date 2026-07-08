// import 'dart:convert';
// import 'dart:developer';

// import 'package:carride/app/data/confing.dart';
// import 'package:carride/app/data/data_store.dart';
// import 'package:carride/app/routes/app_pages.dart';
// import 'package:carride/theme/theme_colores.dart';
// import 'package:carride/utils/font_family.dart';
// import 'package:carride/widgets/custom_widgets.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:loading_animation_widget/loading_animation_widget.dart';

// class RequestSettingsScreenController extends GetxController {
//   ThemeColores themeColores = Get.put(ThemeColores());

//   final RxList _titleText = [
//     "Edit request".tr,
//     "Delete request".tr,
//   ].obs;
//   List get titleText => _titleText;
//   set titleText(List value) => _titleText.value = value;

//   final RxBool _isLoading = false.obs;
//   bool get isLoading => _isLoading.value;
//   set isLoading(bool value) => _isLoading.value = value;

//   Map<String, String> userHeader = {
//     "Content-type": "application/json",
//     "Accept": "application/json",
//   };

//   Future deleteTriprequestApi({required String requestId}) async {
//     isLoading = true;
//     update();
//     Map body = {
//       "uid ": "${getData.read("userLogin")["id"]}",
//       "request_id": requestId,
//     };

//     try {
//       String url = Confing.baseurl + Confing.deleteTripRequest;

//       var response = await http.post(
//         Uri.parse(url),
//         body: jsonEncode(body),
//         headers: userHeader,
//       );

//       log(name: "========== Delete Trip Request Api Api url ===========", url);
//       log(name: "========== Delete Trip Request Api Api body ==========", "$body");
//       log(name: "======== Delete Trip Request Api Api response ========", response.body);

//       var data = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         if (data["Result"] == "true") {
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
//       log(name: "========== Delete Trip Request Api Api Error ==========", "$e");
//     } finally {
//       isLoading = false;
//       update();
//     }
//   }

//   void showDeleteConfirmDialog() {
//     isLoading = false;
//     debugPrint("---------------- Args requestId : ${Get.arguments["requestId"]}");
//     String requestId = Get.arguments["requestId"];
//     Get.dialog(
//       AlertDialog(
//         backgroundColor: themeColores.themebgColor,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(15)),
//         insetPadding: EdgeInsets.all(20),
//         actionsPadding: EdgeInsets.only(bottom: 20),
//         title: Text(
//           "Confirm deletion".tr,
//           style: TextStyle(
//             fontSize: 20,
//             fontFamily: FontFamily.bold,
//             color: themeColores.themeText,
//           ),
//         ),
//         content: Text(
//           "Are you sure you want to delete this request?".tr,
//           style: TextStyle(
//             fontFamily: FontFamily.medium,
//             color: themeColores.themeText,
//           ),
//         ),
//         actions: [
//           Obx(
//             () => isLoading
//             ? Center(child: LoadingAnimationWidget.staggeredDotsWave(color: themeColores.themeText, size: 25))
//             : Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 for (int i = 0; i < 2; i++) ...[
//                   InkWell(
//                     onTap: () {
//                       if (i == 0) {
//                         isLoading = true;
//                         deleteTriprequestApi(requestId: requestId).then((value) {
//                           if (value["Result"] == "true") {
//                             Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN, arguments: 2);
//                           }
//                         });
//                       } else {
//                         Get.back(); 
//                       }
//                     },
//                     child: Text(
//                       i == 0 ? "YES".tr : "No".tr,
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: i == 0 ? Colors.green : themeColores.themeText,
//                         fontFamily: FontFamily.medium,
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//       barrierDismissible: false,
//     );
//   }
// }
