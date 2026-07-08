// ignore_for_file: deprecated_member_use

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/data_store.dart';
import '../controllers/bottom_bar_screen_controller.dart';

class BottomBarScreenView extends GetView<BottomBarScreenController> {
  const BottomBarScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BottomBarScreenController());
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldExit = await popScopeBack();
          if (shouldExit) SystemNavigator.pop();
        }
      },
      child: GetBuilder<BottomBarScreenController>(
        builder: (_) => Scaffold(
          backgroundColor: ccBackground,
          body: controller.bottomBarPage[controller.index],
          bottomNavigationBar: _BottomNav(controller: controller),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.controller});
  final BottomBarScreenController controller;

  static const _labels = ["Home", "Rides", "Messages", "Wallet", "Profile"];
  static const _icons = [
    Icons.home_rounded,
    Icons.directions_car_rounded,
    Icons.chat_bubble_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: ccSurface,
        border: Border(top: BorderSide(color: ccInputBorder)),
        boxShadow: CCShadow.floating,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(5, (i) {
            final active = controller.index == i;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _onTap(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Active indicator bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 2,
                      width: active ? 24 : 0,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: ccPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Icon
                    i == 4
                        ? _profileIcon(active)
                        : Icon(
                            _icons[i],
                            size: 24,
                            color: active ? ccPrimary : ccSecondaryText,
                          ),
                    const SizedBox(height: 2),
                    // Label
                    Text(
                      _labels[i],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? ccPrimary : ccSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _profileIcon(bool active) {
    final user = getData.read("userLogin");
    if (user == null) {
      return Icon(Icons.person_rounded, size: 24,
        color: active ? ccPrimary : ccSecondaryText);
    }
    final pic = user["profile_pic"];
    return Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? ccPrimary : ccInputBorder,
          width: active ? 2 : 1,
        ),
        color: ccIceBlue,
      ),
      clipBehavior: Clip.antiAlias,
      child: pic != null && pic.toString().isNotEmpty
          ? FadeInImage.assetNetwork(
              placeholder: "assets/image/ezgif.com-crop.gif",
              image: "${Confing.imageurl}$pic",
              fit: BoxFit.cover,
            )
          : Center(
              child: Text(
                user["name"] != null
                    ? user["name"].toString()[0].toUpperCase()
                    : "?",
                style: const TextStyle(
                  color: ccPrimary,
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }

  void _onTap(int i) {
    final loggedIn = getData.read("userLogin") != null;
    if (!loggedIn && (i == 2 || i == 3 || i == 4)) {
      Get.offAllNamed(Routes.LOGIN_SCREEN);
    } else {
      controller.index = i;
      controller.update();
    }
  }
}
