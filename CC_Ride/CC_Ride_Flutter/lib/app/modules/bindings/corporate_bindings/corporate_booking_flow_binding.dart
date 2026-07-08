import 'package:get/get.dart';
import '../../controllers/corporate_controllers/corporate_booking_flow_controller.dart';

class CorporateBookingFlowBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CorporateBookingFlowController>(
      () => CorporateBookingFlowController(),
    );
  }
}
