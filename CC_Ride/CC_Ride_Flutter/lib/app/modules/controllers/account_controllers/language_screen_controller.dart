import 'package:carride/app/data/data_store.dart';
import 'package:carride/theme/theme_colores.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageScreenController extends GetxController {
  ThemeColores themeColores = Get.put(ThemeColores());

  @override
  void onInit() {
    super.onInit();
    debugPrint("--------------- lan1 ${getData.read("lan1")}");
    debugPrint("--------------- lan2 ${getData.read("lan2")}");
    if (getData.read("lan1") == null && getData.read("lan2") == null) {
      save("lan1", "US");
      save("lan2", "en");
      debugPrint("--------------- not select ${getData.read("lan1")}_${getData.read("lan2")}");
    } else {
      debugPrint("--------------- select");
    }
  }

  final RxList<Map<String, dynamic>> _locale = <Map<String, dynamic>>[
    {'name': 'English', 'locale': Locale('en', 'US')},
    {'name': 'Français', 'locale': Locale('fr', 'FR')},
    {'name': 'عربى', 'locale': Locale('ar', 'SA')},
  ].obs;
  List<Map<String, dynamic>> get locale => _locale;
  set locale(List<Map<String, dynamic>> newList) => _locale.value = newList;

  updateLanguage(Locale locale) {
    save("lan1", locale.countryCode);
    save("lan2", locale.languageCode);
    Get.updateLocale(locale);
    update();
    Get.back();
    // Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN, arguments: 4);
  }
}
