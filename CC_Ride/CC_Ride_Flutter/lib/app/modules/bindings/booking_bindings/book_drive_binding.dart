import 'package:get/get.dart';

import '../../controllers/booking_controllers/book_drive_controller.dart';

class BookDriveBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookDriveController>(
      () => BookDriveController(),
    );
  }
}
