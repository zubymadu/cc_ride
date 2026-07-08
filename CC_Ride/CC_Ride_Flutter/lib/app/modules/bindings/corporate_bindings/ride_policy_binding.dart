import 'package:get/get.dart';
import '../../controllers/corporate_controllers/ride_policy_controller.dart';

class RidePolicyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RidePolicyController>(
      () => RidePolicyController(),
    );
  }
}
