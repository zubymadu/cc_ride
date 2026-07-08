import 'package:get/get.dart';

import '../../controllers/trip_request_controllers/post_req_preiview_screen_controller.dart';

class PostReqPreiviewScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostReqPreiviewScreenController>(
      () => PostReqPreiviewScreenController(),
    );
  }
}
