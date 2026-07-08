import 'package:carride/app/modules/controllers/post_controllers/trip_preview_screen_controller.dart';
import 'package:carride/theme/theme_colores.dart';
import 'package:get/get.dart';

class BookDriveController extends GetxController {
  TripPreviewScreenController tripPreviewScreenController = Get.put(TripPreviewScreenController());
  ThemeColores themeColores = Get.put(ThemeColores());

  int calculateAge(String dob) {
    final birthDate = DateTime.parse(dob);
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
