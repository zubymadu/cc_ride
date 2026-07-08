import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/help_controller/help_screen_controller.dart';
import 'package:carride/app/modules/view/account_screen/account_screen_view.dart';
import 'package:carride/app/modules/view/account_screen/wallet/wallet_screen_view.dart';
import 'package:carride/app/modules/view/message_screen/message_list_view.dart';
import 'package:carride/app/modules/view/search/search_screen_view.dart';
import 'package:carride/app/modules/view/trips/trip_list/post_trip/trip_screen_view.dart';
import 'package:carride/theme/theme_colores.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomBarScreenController extends GetxController {
  ThemeColores themeColores = Get.put(ThemeColores());
  HelpScreenController helpScreenController = Get.put(HelpScreenController());

  @override
  void onInit() {
    super.onInit();
    debugPrint("---------- argument ----------: ${Get.arguments}");
    debugPrint("--------- userLogin ----------: ${getData.read("userLogin")}");
    helpScreenController.faqListApi();
    final args = Get.arguments;
    if (args != null) {
      // Handle different argument types
      if (args is int) {
        index = args;
      } else if (args is String) {
        try {
          index = int.parse(args);
        } catch (e) {
          debugPrint("Error parsing argument to int: $e");
          index = 0;
        }
      } else {
        // If it's not int or string (e.g., a map), default to 0
        debugPrint("Argument is not int or string, defaulting index to 0");
        index = 0;
      }
    } else {
      index = 0;
    }
    debugPrint("---------- index ----------: $index");
  }

  final RxInt _index = 0.obs;
  int get index => _index.value;
  set index(int value) => _index.value = value;

  final RxList _icon = [
    "assets/image/svg/search.svg",
    "assets/image/svg/plus-square.svg",
    "assets/image/svg/location-pin.svg",
    "assets/image/svg/message-text.svg",
    // "assets/image/svg/question-circle.svg",
    "",
  ].obs;
  List get icon => _icon;
  set icon(List value) => _icon.value = value;

  final RxList _text = [
    "Search",
    "Post",
    "Trips",
    "Messages",
    "Profile",
    // "Help",
  ].obs;
  List get text => _text;
  set text(List value) => _text.value = value;

  final RxList _bottomBarPage = [
    SearchScreenView(),
    TripScreenView(),
    MessageListView(),
    WalletScreenView(),
    AccountScreenView(),
  ].obs;
  List get bottomBarPage => _bottomBarPage;
  set bottomBarPage(List value) => _bottomBarPage.value = value;
}
