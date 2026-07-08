import 'package:get/get.dart';

import '../../controllers/account_controllers/refer_screen_controller.dart';

class ReferAndEarnScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReferAndEarnScreenController>(
      () => ReferAndEarnScreenController(),
    );
  }
}
