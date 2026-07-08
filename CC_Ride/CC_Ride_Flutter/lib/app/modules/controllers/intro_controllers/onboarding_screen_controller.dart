import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingScreenController extends GetxController {
  PageController pageController = PageController();
  @override
  void onInit() {
    pageController = PageController();
    super.onInit();
  }

  final RxInt _currentPage = 0.obs;
  int get currentPage => _currentPage.value;
  set currentPage(int value) => _currentPage.value = value;

  void controllervalueincrement() {
    if (currentPage < contents.length - 1) {
      pageController.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      update();
    } else {
      Get.offAllNamed(Routes.LOGIN_SCREEN);
    }
  }

  AnimatedContainer buildDots({int? index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        shape: currentPage == index ? BoxShape.rectangle : BoxShape.rectangle,
        color: currentPage == index ? black : Colors.grey,
      ),
      curve: Curves.easeIn,
      height: 8,
      width: 8,
    );
  }
}

class OnBoarding {
  final String title;
  final String image;
  final String desc;

  OnBoarding({
    required this.title,
    required this.image,
    required this.desc,
  });
}

List<OnBoarding> contents = [
  OnBoarding(
    title: "Book Your Corporate Ride",
    image: "assets/image/Group7105.png",
    desc: "Seamless ride booking charged directly to your company account. No personal payment needed.",
  ),
  OnBoarding(
    title: "Share Your Daily Commute",
    image: "assets/image/Group7104.png",
    desc: "Publish your regular route and let colleagues heading the same way book a seat with you.",
  ),
  OnBoarding(
    title: "Full Company Oversight",
    image: "assets/image/Group7103.png",
    desc: "HR and finance teams manage budgets, approve rides, and export reports — all in one place.",
  ),
];

class SizeConfig {
  static MediaQueryData? _mediaQueryData;
  static double? screenW;
  static double? screenH;
  static double? blockH;
  static double? blockV;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenW = _mediaQueryData!.size.width;
    screenH = _mediaQueryData!.size.height;
    blockH = screenW! / 100;
    blockV = screenH! / 100;
  }
}
