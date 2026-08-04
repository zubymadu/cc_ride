import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/driver_mode/driver_mode_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/post_controllers/post_screen_controller.dart';

class PostScreenView extends GetView<PostScreenController> {
  const PostScreenView({super.key});

  // Pool drivers earn organisation-awarded points for a pool-vehicle trip,
  // never cash (see legacyBookSeat: driverEarning is forced to 0 and the
  // ride's net value becomes 100% platform/company commission when the
  // vehicle belongs to a company) — the own-car 85%-cash-split promise on
  // this screen was shown unconditionally to every driver, including pool
  // drivers it's simply false for.
  static const _stepsCash = [
    (Icons.route_rounded, "Set your route",
        "Choose origin, destination, and any stops along the way."),
    (Icons.calendar_today_rounded, "Schedule your trip",
        "Pick a date and time that works for you — one-time or recurring."),
    (Icons.directions_car_rounded, "Add vehicle & seats",
        "Select your registered vehicle and how many seats are available."),
    (Icons.payments_outlined, "Set pricing",
        "Choose a fair seat price — payouts go straight to your bank."),
    (Icons.verified_user_rounded, "OTP-verified pickups",
        "Passengers confirm boarding with a secure one-time code."),
  ];

  static const _stepsPoints = [
    (Icons.route_rounded, "Set your route",
        "Choose origin, destination, and any stops along the way."),
    (Icons.calendar_today_rounded, "Schedule your trip",
        "Pick a date and time that works for you — one-time or recurring."),
    (Icons.directions_car_rounded, "Add vehicle & seats",
        "Confirm your assigned pool vehicle and how many seats are available."),
    (Icons.payments_outlined, "Set pricing",
        "Sets the passenger fare — pool trips earn you organisation points, not cash."),
    (Icons.verified_user_rounded, "OTP-verified pickups",
        "Passengers confirm boarding with a secure one-time code."),
  ];

  @override
  Widget build(BuildContext context) {
    final isPoolDriver = Get.isRegistered<DriverModeController>() &&
        Get.find<DriverModeController>().mode == 'pool';
    final steps = isPoolDriver ? _stepsPoints : _stepsCash;
    return Scaffold(
      backgroundColor: ccBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Hero banner ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D2137), ccPrimary],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo + help
                  Row(
                    children: [
                      Image.asset(
                        "assets/image/textlogo.png",
                        height: 28,
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                        errorBuilder: (_, __, ___) => const Text(
                          "CC Ride",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.help_outline_rounded,
                            color: Colors.white70, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Headline
                  const Text(
                    "Drive with CC Ride",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPoolDriver
                        ? "Post trips for colleagues and earn organisation points on every seat. OTP pickups, verified drivers."
                        : "Post trips for colleagues and earn on every seat. OTP pickups, verified drivers, bank payouts.",
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),

                  // A pool driver is operating under an organisation's
                  // vehicle and earning points rather than cash — that
                  // needs to be unmistakable, not a quiet mode toggle
                  // buried in a menu somewhere.
                  if (isPoolDriver) ...[
                    const SizedBox(height: 16),
                    _PoolDriverBanner(
                      name: "${getData.read("userLogin")?["name"] ?? ''}",
                      companyName: "${getData.read("companyName") ?? ''}",
                      employeeNumber: "${getData.read("employeeNumber") ?? ''}",
                    ),
                  ],
                ],
              ),
            ),

            // ── How it works ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "How it Works",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: ccNavyText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(height: 2, width: 36, color: ccPrimary),
                      const SizedBox(height: 16),
                      for (int i = 0; i < steps.length; i++) ...[
                        _StepTile(
                          number: i + 1,
                          icon: steps[i].$1,
                          title: steps[i].$2,
                          desc: steps[i].$3,
                        ),
                        if (i < steps.length - 1)
                          const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // ── CTA ───────────────────────────────────────────────────────
            Container(
              color: ccSurface,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                children: [
                  CCButton(
                    label: "Post a Ride",
                    icon: Icons.add_road_rounded,
                    onPressed: _startPostTrip,
                  ),
                  const SizedBox(height: 10),
                  CCButton(
                    label: "My Routes",
                    icon: Icons.route_rounded,
                    outlined: true,
                    onPressed: () => Get.toNamed(Routes.MY_ROUTES_SCREEN),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // This screen only exists because the user already told us — via the
  // Passenger / Pool driver / Own-car driver mode prompt — that they're
  // driving right now. Re-asking "I'm driving vs I need a ride" via the
  // shared postTripBottomsheet() (built for the passenger-side search
  // screens, where that choice genuinely hasn't been made yet) would
  // contradict the mode they already picked, so this goes straight into
  // posting. Same verification gate as every other entry point into the
  // post-trip / booking flow, for consistency.
  void _startPostTrip() {
    final user = getData.read('userLogin');
    if (user == null) {
      Get.toNamed(Routes.LOGIN_SCREEN);
      return;
    }
    if (user['is_mobile_verify'] == '1' && user['is_email_verify'] == '1') {
      Get.toNamed(Routes.MULTIPOLYLINE_MAP_SCREEN);
    } else {
      Get.toNamed(Routes.PROFILE_SCREEN);
      showToastMessage('Mobile and email verification is not completed.');
    }
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.icon,
    required this.title,
    required this.desc,
  });
  final int number;
  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ccSurface,
        borderRadius: BorderRadius.circular(CCRadius.card),
        boxShadow: CCShadow.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: ccIceBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: ccPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$number. $title",
                  style: CCText.titleMd,
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PoolDriverBanner extends StatelessWidget {
  const _PoolDriverBanner({
    required this.name,
    required this.companyName,
    required this.employeeNumber,
  });
  final String name;
  final String companyName;
  final String employeeNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(CCRadius.card),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.corporate_fare_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty
                      ? "Welcome, $name — Pool Driver"
                      : "Welcome — Pool Driver",
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                if (companyName.isNotEmpty)
                  Text(
                    employeeNumber.isNotEmpty
                        ? "$companyName • Employee ID: $employeeNumber"
                        : companyName,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
