import 'package:get/get.dart';

import '../../controllers/post_controllers/seats_details_screen_controller.dart';

class SeatsDetailsScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SeatsDetailsScreenController>(
      () => SeatsDetailsScreenController(),
    );
  }
}
