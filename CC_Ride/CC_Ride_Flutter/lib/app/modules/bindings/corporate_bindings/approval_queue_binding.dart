import 'package:get/get.dart';
import '../../controllers/corporate_controllers/approval_queue_controller.dart';

class ApprovalQueueBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApprovalQueueController>(
      () => ApprovalQueueController(),
    );
  }
}
