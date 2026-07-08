import 'package:carride/app/modules/view/search/search_results/post_trip_bottomsheet.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/post_controllers/post_screen_controller.dart';

class PostScreenView extends GetView<PostScreenController> {
  const PostScreenView({super.key});

  static const _steps = [
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

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    "Post trips for colleagues and earn on every seat. OTP pickups, verified drivers, bank payouts.",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
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
                      for (int i = 0; i < _steps.length; i++) ...[
                        _StepTile(
                          number: i + 1,
                          icon: _steps[i].$1,
                          title: _steps[i].$2,
                          desc: _steps[i].$3,
                        ),
                        if (i < _steps.length - 1)
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: CCButton(
                label: "Post a Ride",
                icon: Icons.add_road_rounded,
                onPressed: postTripBottomsheet,
              ),
            ),
          ],
        ),
      ),
    );
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
