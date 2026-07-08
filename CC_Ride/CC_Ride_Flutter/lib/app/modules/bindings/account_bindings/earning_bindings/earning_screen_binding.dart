import 'package:get/get.dart';

import '../../../controllers/account_controllers/earning_controllers/earning_screen_controller.dart';

class EarningScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EarningScreenController>(
      () => EarningScreenController(),
    );
  }
}
