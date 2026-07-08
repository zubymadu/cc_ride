import 'package:carride/app/modules/controllers/post_controllers/post_trip_controller.dart';
import 'package:carride/theme/theme_colores.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SeatsDetailsScreenController extends GetxController {
  ThemeColores themeColores = Get.put(ThemeColores());
  // @override
  // void onInit() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     debugPrint("------------ arguments ------------ ${Get.arguments}");
  //     if (Get.arguments != null) {
  //       if (Get.arguments["seat_price"] != null) {
  //         postTripController.seatPrice = "${Get.arguments["seat_price"]}";
  //         seatpricecontroller.text = postTripController.seatPrice;
  //       }
  //       postTripController.totalSeat = "${Get.arguments["total_seat"]}";
  //       if (Get.arguments["trip_description"] != null) {
  //         postTripController.tripDescription = "${Get.arguments["trip_description"]}";
  //         tripdescriptioncontroller.text = postTripController.tripDescription;
  //       }
  //     } else {
  //       postTripController.totalSeat = "";
  //       postTripController.seatPrice = "";
  //       postTripController.tripDescription = "";
  //     }
  //     update();
  //   });
  //   super.onInit();
  // }

  PostTripController postTripController = Get.put(PostTripController());

  TextEditingController seatpricecontroller = TextEditingController();
  TextEditingController tripdescriptioncontroller = TextEditingController();

  final formKey = GlobalKey<FormState>();

  Widget buildDashedLine() {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Column(
        children: List.generate(
          4,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: Container(width: 2, height: 4, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
