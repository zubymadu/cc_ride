import 'package:get/get.dart';

import '../../../controllers/account_controllers/my_booking_controllers/my_booking_screen_controller.dart';

class MyBookingScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyBookingScreenController>(
      () => MyBookingScreenController(),
    );
  }
}
