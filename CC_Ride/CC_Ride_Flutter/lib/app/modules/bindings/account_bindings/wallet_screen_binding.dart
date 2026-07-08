import 'package:get/get.dart';

import '../../controllers/account_controllers/wallet_screen_controller.dart';

class WalletScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletScreenController>(
      () => WalletScreenController(),
    );
  }
}
