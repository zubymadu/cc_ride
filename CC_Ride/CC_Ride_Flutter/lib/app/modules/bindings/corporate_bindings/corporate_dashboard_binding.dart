import 'package:get/get.dart';
import '../../controllers/corporate_controllers/corporate_dashboard_controller.dart';

class CorporateDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CorporateDashboardController>(
      () => CorporateDashboardController(),
    );
  }
}
