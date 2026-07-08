import 'package:get/get.dart';

import '../../../controllers/account_controllers/profile_controllers/personal_details_controller.dart';

class PersonalDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PersonalDetailsController>(
      () => PersonalDetailsController(),
    );
  }
}
