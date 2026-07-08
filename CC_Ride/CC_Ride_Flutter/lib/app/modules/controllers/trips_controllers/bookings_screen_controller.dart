import 'package:carride/app/modules/controllers/post_controllers/trip_preview_screen_controller.dart';
import 'package:carride/theme/theme_colores.dart';
import 'package:get/get.dart';

class BookingsScreenController extends GetxController {
  ThemeColores themeColores = Get.put(ThemeColores());

  TripPreviewScreenController tripPreviewScreenController = Get.put(TripPreviewScreenController());
}
