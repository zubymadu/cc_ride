import 'package:get/get.dart';

import '../../../controllers/account_controllers/profile_controllers/vehicle_controllers/vehicles_list_controller.dart';

class VehiclesListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VehiclesListController>(
      () => VehiclesListController(),
    );
  }
}
