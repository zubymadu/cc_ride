import 'package:carride/app/modules/controllers/booking_controllers/payment_screen_controller.dart';
import 'package:carride/theme/theme_colores.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookingServiceController extends GetxController {
  ThemeColores themeColores = Get.put(ThemeColores());

  PaymentScreenController paymentScreenController = Get.put(PaymentScreenController());

  @override
  void onInit() {
    debugPrint("------------- Get.arguments dsddd ----------- ${Get.arguments}");
    if (Get.arguments is String) {
      paymentScreenController.requestId = Get.arguments;
    } else {
      paymentScreenController.requestId = "0";
    }
    debugPrint("------------- requestId ----------- ${paymentScreenController.requestId }");
    super.onInit();
  }

  final RxList _image = [
    "assets/image/love.png",
    "assets/image/booking.png",
    "assets/image/your-location.png",
    "assets/image/speech-bubble.png",
    "assets/image/luggage-scale.png",
  ].obs;
  List get image => _image;
  set image(List value) => _image.value = value;

  final RxList _text = [
    "Be Courteous",
    "Confirm the Details",
    "Meet at the Pin",
    "Use In-App Chat",
    "Light Baggage Only",
  ].obs;
  List get text => _text;
  set text(List value) => _text.value = value;

  final RxList _det = [
    "Respect the driver and other riders. Keep noise and mess minimal.",
    "Double-check the driver's name and license plate before boarding.",
    "Meet at the Pin | Be at your exact pickup spot before the scheduled time.",
    "Only communicate with the driver via the app for quick updates or delays.",
    "Space is limited. Please travel with only one small personal bag.",
  ].obs;
  List get det => _det;
  set det(List value) => _det.value = value;
  
  final RxBool _swichValue = false.obs;
  bool get swichValue => _swichValue.value;
  set swichValue(bool value) => _swichValue.value = value;
}
