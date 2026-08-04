import 'package:get/get.dart';
import '../../controllers/corporate_controllers/route_management_controller.dart';

class RouteManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RouteManagementController>(
      () => RouteManagementController(),
    );
  }
}
