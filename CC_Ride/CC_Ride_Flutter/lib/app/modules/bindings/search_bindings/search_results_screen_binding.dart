import 'package:get/get.dart';

import '../../controllers/search_controllers/search_results_screen_controller.dart';

class SearchResultsScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SearchResultsScreenController>(
      () => SearchResultsScreenController(),
    );
  }
}
