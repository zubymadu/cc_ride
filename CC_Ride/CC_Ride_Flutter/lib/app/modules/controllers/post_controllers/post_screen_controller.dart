import 'package:carride/theme/theme_colores.dart';
import 'package:get/get.dart';

class PostScreenController extends GetxController {
  ThemeColores themeColores = Get.put(ThemeColores());

  // Feature benefit icons shown on the home screen
  final RxList _iconList = [
    "assets/image/svg/shield.svg",
    "assets/image/svg/coin.svg",
    "assets/image/svg/clipboard-text.svg",
    "assets/image/svg/check-circle.svg",
    "assets/image/svg/users-group-filled.svg",
  ].obs;
  List get iconList => _iconList;
  set iconList(List value) => _iconList.value = value;

  final RxList _textList = [
    "Safe & vetted drivers — every driver is background-checked",
    "Company billing — rides charged directly to your employer",
    "Instant receipts — expense-ready receipts for every trip",
    "Policy compliant — your company's travel rules enforced automatically",
    "Team visibility — HR and Finance see all trips in real time",
  ].obs;
  List get textList => _textList;
  set textList(List value) => _textList.value = value;

  // Onboarding slider images (corporate-branded illustrations)
  final RxList _sliderImga = [
    "assets/image/svg/onboarding_1.svg",
    "assets/image/svg/onboarding_2.svg",
    "assets/image/svg/onboarding_3.svg",
  ].obs;
  List get sliderImga => _sliderImga;
  set sliderImga(List value) => _sliderImga.value = value;

  // Onboarding slide titles
  final RxList _sliderTitle = [
    "Welcome to CC Ride",
    "Smart Corporate Travel",
    "Your Ride, Company Paid",
  ].obs;
  List get sliderTitle => _sliderTitle;
  set sliderTitle(List value) => _sliderTitle.value = value;

  // Onboarding slide descriptions
  final RxList _sliderText = [
    "The corporate ride-hailing platform built for Nigerian businesses. Book rides, manage budgets, and keep your team moving — all in one place.",
    "Company-funded rides with full policy controls. Set spend limits, require manager approvals, and get finance-ready reports — automatically.",
    "Book instantly or schedule ahead. Your ride is charged directly to your company account — no expense claims, no out-of-pocket costs.",
  ].obs;
  List get sliderText => _sliderText;
  set sliderText(List value) => _sliderText.value = value;

  final RxInt _currentIndex = 0.obs;
  int get currentIndex => _currentIndex.value;
  set currentIndex(int value) => _currentIndex.value = value;
}
