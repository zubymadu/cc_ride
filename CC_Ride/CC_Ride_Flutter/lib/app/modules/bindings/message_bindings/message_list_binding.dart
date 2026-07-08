import 'package:get/get.dart';

import '../../controllers/message_controllers/message_list_controller.dart';

class MessageListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MessageListController>(
      () => MessageListController(),
    );
  }
}
