import 'package:get/get.dart';

import '../../controllers/post_controllers/multipolyline_map_screen_controller.dart';

class MultipolylineMapScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MultipolylineMapScreenController>(
      () => MultipolylineMapScreenController(),
    );
  }
}
