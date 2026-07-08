import 'package:get/get.dart';

import '../../controllers/booking_controllers/booking_service_controller.dart';

class BookingServiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookingServiceController>(
      () => BookingServiceController(),
    );
  }
}
