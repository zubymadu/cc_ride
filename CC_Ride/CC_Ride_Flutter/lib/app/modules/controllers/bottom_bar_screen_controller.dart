import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/driver_mode/driver_mode_controller.dart';
import 'package:carride/app/modules/controllers/help_controller/help_screen_controller.dart';
import 'package:carride/app/modules/view/account_screen/account_screen_view.dart';
import 'package:carride/app/modules/view/account_screen/my_booking_screens/my_booking_list/my_bookings_tab_view.dart';
import 'package:carride/app/modules/view/post/post_screen_view.dart';
import 'package:carride/app/modules/view/search/search_screen_view.dart';
import 'package:carride/app/modules/view/trips/trip_list/post_trip/trip_screen_view.dart';
import 'package:carride/theme/theme_colores.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomBarScreenController extends GetxController {
  ThemeColores themeColores = Get.put(ThemeColores());
  HelpScreenController helpScreenController = Get.put(HelpScreenController());
  DriverModeController driverModeController = Get.put(DriverModeController());

  @override
  void onInit() {
    super.onInit();
    debugPrint("---------- argument ----------: ${Get.arguments}");
    debugPrint("--------- userLogin ----------: ${getData.read("userLogin")}");
    helpScreenController.faqListApi();
    _applyModePages();
    // Passenger, Pool driver, and Own-car driver are genuinely distinct
    // workflows — Home and the middle tab must serve different screens per
    // mode, not the same ones with different data. Re-applied the instant
    // the mode-prompt is answered (not just on next app restart).
    ever(driverModeController.modeRx, (_) => _applyModePages());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      driverModeController.promptIfNeeded();
    });
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

  void _applyModePages() {
    final isDriver = driverModeController.isDriverMode;
    // Explicit <Widget> element type matters here, not just style — without
    // it, this list literal infers as List<dynamic> (the setter parameter
    // below gives type inference nothing to anchor to), while _bottomBarPage
    // itself infers as RxList<StatelessWidget> from its own initializer.
    // Assigning a List<dynamic> into an RxList<StatelessWidget> throws
    // "type 'List<dynamic>' is not a subtype of type 'List<StatelessWidget>'"
    // the instant mode is re-applied — i.e. on every login.
    bottomBarPage = <Widget>[
      isDriver ? const PostScreenView() : const SearchScreenView(),
      isDriver ? const TripScreenView() : const MyBookingsTabView(),
      const AccountScreenView(),
    ];
    text = <String>[
      "Home",
      isDriver ? "My Rides" : "Bookings",
      "My Account",
    ];
    update();
  }

  final RxInt _index = 0.obs;
  int get index => _index.value;
  set index(int value) => _index.value = value;

  final RxList<String> _text = <String>[
    "Home",
    "Bookings",
    "My Account",
  ].obs;
  List<String> get text => _text;
  set text(List<String> value) => _text.value = value;

  final RxList<Widget> _bottomBarPage = <Widget>[
    const SearchScreenView(),
    const MyBookingsTabView(),
    const AccountScreenView(),
  ].obs;
  List<Widget> get bottomBarPage => _bottomBarPage;
  set bottomBarPage(List<Widget> value) => _bottomBarPage.value = value;
}
