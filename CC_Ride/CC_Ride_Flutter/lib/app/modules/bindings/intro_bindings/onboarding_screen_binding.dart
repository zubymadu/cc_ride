import 'package:get/get.dart';

import '../../controllers/intro_controllers/onboarding_screen_controller.dart';

class OnboardingScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingScreenController>(
      () => OnboardingScreenController(),
    );
  }
}
