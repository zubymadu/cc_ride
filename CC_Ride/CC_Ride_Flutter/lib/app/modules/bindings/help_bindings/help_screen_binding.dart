import 'package:get/get.dart';

import '../../controllers/help_controller/help_screen_controller.dart';

class HelpScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HelpScreenController>(
      () => HelpScreenController(),
    );
  }
}
