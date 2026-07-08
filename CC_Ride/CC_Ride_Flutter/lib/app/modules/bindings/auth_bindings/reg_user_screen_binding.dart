import 'package:get/get.dart';

import '../../controllers/auth/reg_user_screen_controller.dart';

class RegUserScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegUserScreenController>(
      () => RegUserScreenController(),
    );
  }
}
