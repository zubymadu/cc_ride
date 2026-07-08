import 'package:get/get.dart';

import '../../controllers/post_controllers/vehicles_screen_controller.dart';

class VehiclesScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VehiclesScreenController>(
      () => VehiclesScreenController(),
    );
  }
}
