import 'package:carride/app/modules/controllers/account_controllers/account_screen_controller.dart';
import 'package:carride/app/modules/controllers/account_controllers/my_booking_controllers/my_booking_screen_controller.dart';
import 'package:carride/app/modules/controllers/account_controllers/wallet_screen_controller.dart';
import 'package:carride/app/modules/controllers/help_controller/help_screen_controller.dart';
import 'package:carride/app/modules/controllers/message_controllers/message_list_controller.dart';
import 'package:carride/app/modules/controllers/post_controllers/post_screen_controller.dart';
import 'package:carride/app/modules/controllers/search_controllers/search_screen_controller.dart';
import 'package:carride/app/modules/controllers/trips_controllers/trip_screen_controller.dart';
import 'package:get/get.dart';

import '../controllers/bottom_bar_screen_controller.dart';

class BottomBarScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BottomBarScreenController>(
      () => BottomBarScreenController(),
      fenix: true
    );
    Get.lazyPut<SearchScreenController>(
      () => SearchScreenController(),
      fenix: true
    );
    Get.lazyPut<PostScreenController>(
      () => PostScreenController(),
      fenix: true
    );
    Get.lazyPut<TripScreenController>(
      () => TripScreenController(),
      fenix: true
    );
    Get.lazyPut<MyBookingScreenController>(
      () => MyBookingScreenController(),
      fenix: true
    );
    Get.lazyPut<HelpScreenController>(
      () => HelpScreenController(),
      fenix: true
    );
    Get.lazyPut<MessageListController>(
      () => MessageListController(),
      fenix: true,
    );
    Get.lazyPut<AccountScreenController>(
      () => AccountScreenController(),
      fenix: true,
    );
    Get.lazyPut<WalletScreenController>(
      () => WalletScreenController(),
      fenix: true,
    );
  }
}
