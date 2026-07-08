import 'package:get/get.dart';

import '../../controllers/post_controllers/post_screen_controller.dart';

class PostScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostScreenController>(
      () => PostScreenController(),
    );
  }
}
