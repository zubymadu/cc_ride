import 'package:carride/app/modules/controllers/trips_controllers/seating_plan_screen_controller.dart';
import 'package:get/get.dart';

import '../../controllers/post_controllers/trip_preview_screen_controller.dart';

class TripPreviewScreenBinding extends Bindings {
  @override
  void dependencies() {
    // Get.lazyPut<TripPreviewScreenController>(
    //   () => TripPreviewScreenController(),
    // );
    // Get.lazyPut<SeatingPlanScreenController>(
    //   () => SeatingPlanScreenController(),
    // );
    Get.put(TripPreviewScreenController());
    Get.put(SeatingPlanScreenController());
  }
}
