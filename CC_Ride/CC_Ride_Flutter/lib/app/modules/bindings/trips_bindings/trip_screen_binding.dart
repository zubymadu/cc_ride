import 'package:get/get.dart';

import '../../controllers/trips_controllers/trip_screen_controller.dart';

class TripScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TripScreenController>(
      () => TripScreenController(),
    );
  }
}
