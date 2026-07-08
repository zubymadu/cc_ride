import 'package:get/get.dart';

import '../../controllers/trip_request_controllers/post_request_screen_controller.dart';

class PostRequestScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostRequestScreenController>(
      () => PostRequestScreenController(),
    );
  }
}
