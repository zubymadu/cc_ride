import 'package:carride/app/data/data_store.dart';
import 'package:carride/utils/color.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeColores extends GetxController {
  @override
  void onInit() {
    super.onInit();
    isDark = getData.read("ThemeData") ?? false;
    update();
  }

  final RxBool _isDark = false.obs;
  bool get isDark => _isDark.value;
  set isDark(bool value) => _isDark.value = value;

  ThemeMode get theme => isDark ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme({required bool dark}) {
    isDark = dark;
    Get.changeThemeMode(theme);
    save("ThemeData", isDark);
    update();
  }

  // ─── Semantic colour tokens ─────────────────────────────────────────────────
  // Light mode  → blue on white
  // Dark mode   → white/light-blue on deep navy

  /// Primary text
  Color get themeText => isDark ? ccWhite : ccNavy;

  /// Page / scaffold background
  Color get themebgColor => isDark ? ccBlueDarker : ccWhite;

  /// Card / section background (slightly off the main bg)
  Color get themelightbgColor => isDark ? const Color(0xFF0D2060) : ccBg;

  /// Subtle borders
  Color get themeborder => isDark ? const Color(0xFF1E3A7A) : ccBlueBorder;

  /// Blue border used on interactive elements
  Color get themeBlueBorder => isDark ? const Color(0xFF2B5ADF) : ccBlueBorder;

  /// Icon / highlight colour (the brand blue in light, white in dark)
  Color get themecolor => isDark ? ccWhite : ccBlue;

  /// CTA / button background — always brand blue
  Color get themebuttoncolor => ccBlue;

  /// Light blue fill for avatar backgrounds, tag chips, etc.
  Color get blueTextFille => isDark ? const Color(0xFF102050) : ccBlueGhost;

  /// Progress / spinner
  CircularProgressIndicator get circularProgressIndicator =>
      isDark ? circularProgressLight : circularProgressDark;
}
