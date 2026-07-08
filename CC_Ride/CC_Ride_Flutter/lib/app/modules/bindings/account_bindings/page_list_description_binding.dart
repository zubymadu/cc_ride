import 'package:get/get.dart';

import '../../controllers/account_controllers/page_list_description_controller.dart';

class PageListDescriptionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PageListDescriptionController>(
      () => PageListDescriptionController(),
    );
  }
}
