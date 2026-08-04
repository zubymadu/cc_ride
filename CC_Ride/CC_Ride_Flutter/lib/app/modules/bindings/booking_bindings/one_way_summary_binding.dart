import 'package:get/get.dart';

import '../../controllers/booking_controllers/book_details_controller.dart';
import '../../controllers/booking_controllers/book_pricing_controller.dart';

class OneWaySummaryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookDetailsController>(
      () => BookDetailsController(),
    );
    Get.lazyPut<BookPricingController>(
      () => BookPricingController(),
    );
  }
}
