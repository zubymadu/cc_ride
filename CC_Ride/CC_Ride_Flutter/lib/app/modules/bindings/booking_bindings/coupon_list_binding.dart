import 'package:get/get.dart';

import '../../controllers/booking_controllers/coupon_list_controller.dart';

class CouponListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CouponListController>(
      () => CouponListController(),
    );
  }
}
