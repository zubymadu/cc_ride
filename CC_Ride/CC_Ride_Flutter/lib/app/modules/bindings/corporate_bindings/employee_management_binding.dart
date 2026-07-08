import 'package:get/get.dart';
import '../../controllers/corporate_controllers/employee_management_controller.dart';

class EmployeeManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmployeeManagementController>(
      () => EmployeeManagementController(),
    );
  }
}
