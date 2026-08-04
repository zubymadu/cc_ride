// ignore_for_file: deprecated_member_use

import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/driver_mode/driver_mode_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

postTripBottomsheet() {
  return Get.bottomSheet(
    backgroundColor: ccSurface,
    isScrollControlled: true,
    enableDrag: false,
    isDismissible: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CCRadius.sheet)),
    ),
    Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Heading Somewhere?'.tr,
                  style: CCText.headlineMd,
                ),
              ),
              InkWell(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: ccIceBlue,
                  ),
                  child: const Icon(Icons.close, color: ccNavyText, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Tell us what you're doing right now so we take you to the right place.",
            style: CCText.bodyMd.copyWith(color: ccSecondaryText),
          ),
          const SizedBox(height: 20),
          _ChoiceCard(
            icon: Icons.directions_car_filled_rounded,
            iconColor: ccPrimary,
            title: "I'm driving",
            subtitle: "Post your route, schedule, and price for others to book.",
            buttonColor: ccPrimary,
            onTap: () => _handleChoice(isDriving: true),
          ),
          const SizedBox(height: 12),
          _ChoiceCard(
            icon: Icons.person_pin_circle_rounded,
            iconColor: const Color(0xFF4A46E6),
            title: "I need a ride",
            subtitle: "Search for a trip that matches yours, or request one.",
            buttonColor: const Color(0xFF4A46E6),
            onTap: () => _handleChoice(isDriving: false),
          ),
        ],
      ),
    ),
  );
}

void _handleChoice({required bool isDriving}) {
  Get.back();
  final user = getData.read('userLogin');
  if (user == null) {
    Get.toNamed(Routes.LOGIN_SCREEN);
    return;
  }
  if (user['is_mobile_verify'] != '1' || user['is_email_verify'] != '1') {
    Get.toNamed(Routes.PROFILE_SCREEN);
    showToastMessage('Mobile and email verification is not completed.');
    return;
  }

  if (isDriving) {
    // A passenger-mode user choosing "I'm driving" here needs
    // DriverModeController updated too, or the bottom nav stays stuck on
    // passenger tabs after this. Vehicle selection happens asynchronously in
    // the background; it only needs to land before the vehicle-preferences
    // step further down the post-trip flow, not before this navigation.
    if (Get.isRegistered<DriverModeController>()) {
      Get.find<DriverModeController>().switchToDriving();
    }
    Get.toNamed(Routes.MULTIPOLYLINE_MAP_SCREEN);
  } else {
    // A driver-mode user choosing "I need a ride" here is switching intent
    // mid-session — reconcile DriverModeController so the bottom nav (and
    // the Home tab it renders) reflects passenger mode instead of silently
    // staying on driver tabs.
    if (Get.isRegistered<DriverModeController>()) {
      Get.find<DriverModeController>().switchToPassenger();
    }
    // Route to the same search-first flow as the Home tab's "Book a Ride"
    // button — not straight to the manual request-posting form
    // (POST_REQUEST_SCREEN). That screen files a standing request with no
    // search step at all, a different experience from every other "I need a
    // ride" entry point, which search first and only fall back to a request
    // if nothing matches. POST_REQUEST_SCREEN remains reachable separately
    // for editing an already-posted request.
    Get.toNamed(Routes.TRIP_PLAN_SCREEN);
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color buttonColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CCRadius.card),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CCRadius.card),
          border: Border.all(color: ccInputBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: buttonColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: ccNavyText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: buttonColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
