import 'package:get/get.dart';
import '../../controllers/corporate_controllers/budget_management_controller.dart';

class BudgetManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BudgetManagementController>(
      () => BudgetManagementController(),
    );
  }
}
