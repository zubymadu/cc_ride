import 'package:get/get.dart';

import '../../controllers/auth/forget_password_screen_controller.dart';

class ForgetPasswordScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForgetPasswordScreenController>(
      () => ForgetPasswordScreenController(),
    );
  }
}
