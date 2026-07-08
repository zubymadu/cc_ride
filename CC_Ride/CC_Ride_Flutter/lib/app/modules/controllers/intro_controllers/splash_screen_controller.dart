// ignore_for_file: deprecated_member_use

import 'package:carride/theme/theme_colores.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:permission_handler/permission_handler.dart';
  
  final RxDouble _lat = 0.00.obs;
  double get lat => _lat.value;
  set lat(double value) => _lat.value = value;

  final RxDouble _long = 0.00.obs;
  double get long => _long.value;
  set long(double value) => _long.value = value;

class SplashScreenController extends GetxController {
  ThemeColores themeColores = Get.put(ThemeColores());

  @override
  void onInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Never let location acquisition block navigation — GPS can take
      // minutes indoors and geocoding needs network. Fire and forget.
      getCurrentLatAndLong().catchError((e) {
        debugPrint("-------- Splash location skipped: $e");
      });
      initialization();
    });
    super.onInit();
  }
  
  final RxBool _isLogin = false.obs;
  bool get isLogin => _isLogin.value;
  set isLogin(bool value) => _isLogin.value = value;

  final RxBool _isFirstuser = false.obs;
  bool get isFirstuser => _isFirstuser.value;
  set isFirstuser(bool value) => _isFirstuser.value = value;

  void initialization() async {
    isLogin = getData.read("isUserLogin") ?? false;
    isFirstuser = getData.read("Firstuser") ?? false;
    update();
    debugPrint("--------------- isLogin ----------- $isLogin");
    debugPrint("-------------- Firstuser ---------- $isFirstuser");
    await Future.delayed(Duration(seconds: 3),
      () {
        if (isLogin) {
          Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN);
        } else {
          if (isFirstuser) {
            Get.offAllNamed(Routes.LOGIN_SCREEN);
          } else {
            Get.offAllNamed(Routes.ONBOARDING_SCREEN);
          }
        }
      },
    );
  }

  Future<Position> locateUser() async {
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future getCurrentLatAndLong() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint("-------- Location permission denied — continuing without GPS");
      return;
    }
    // Bounded wait: indoors a high-accuracy fix can take minutes
    var currentLocation = await locateUser().timeout(const Duration(seconds: 8));

    lat = currentLocation.latitude;
    long = currentLocation.longitude;
    debugPrint("-------- USER CURRENT Latitude --------- : $lat");
    debugPrint("-------- USER CURRENT Longitude -------- : $long");

    // Reverse geocoding is best-effort only (needs network + Google services)
    try {
      List<Placemark> addresses = await placemarkFromCoordinates(lat, long)
          .timeout(const Duration(seconds: 5));
      debugPrint("-------- USER CURRENT addresses -------- : ${addresses.firstOrNull}");
    } catch (e) {
      debugPrint("-------- Reverse geocoding skipped: $e");
    }
    update();
  }
}
