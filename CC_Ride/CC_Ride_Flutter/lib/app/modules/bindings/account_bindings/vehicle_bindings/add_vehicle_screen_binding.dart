import 'package:get/get.dart';

import '../../../controllers/account_controllers/profile_controllers/vehicle_controllers/add_vehicle_screen_controller.dart';

class AddVehicleScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddVehicleScreenController>(
      () => AddVehicleScreenController(),
    );
  }
}
