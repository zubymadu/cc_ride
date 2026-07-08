import 'package:get/get.dart';

import '../../../controllers/account_controllers/my_booking_controllers/booking_datails_controller.dart';

class BookingDatailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookingDatailsController>(
      () => BookingDatailsController(),
    );
  }
}
