import 'package:get/get.dart';

import '../../controllers/booking_controllers/book_details_controller.dart';

class BookDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookDetailsController>(
      () => BookDetailsController(),
    );
  }
}
