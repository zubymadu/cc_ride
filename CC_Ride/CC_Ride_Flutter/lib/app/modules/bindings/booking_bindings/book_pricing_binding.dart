import 'package:get/get.dart';

import '../../controllers/booking_controllers/book_pricing_controller.dart';

class BookPricingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookPricingController>(
      () => BookPricingController(),
    );
  }
}
