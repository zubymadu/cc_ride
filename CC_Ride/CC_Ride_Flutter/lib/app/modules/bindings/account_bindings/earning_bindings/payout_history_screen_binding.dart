import 'package:get/get.dart';

import '../../../controllers/account_controllers/earning_controllers/payout_history_screen_controller.dart';

class PayoutHistoryScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PayoutHistoryScreenController>(
      () => PayoutHistoryScreenController(),
    );
  }
}
