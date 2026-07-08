import 'package:get/get.dart';

import '../../controllers/post_controllers/ride_schedule_screen_controller.dart';

class RideScheduleScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RideScheduleScreenController>(
      () => RideScheduleScreenController(),
    );
  }
}
