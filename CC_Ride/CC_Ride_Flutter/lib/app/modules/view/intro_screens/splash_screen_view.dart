import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/intro_controllers/splash_screen_controller.dart';

/// Splash — deep navy, centered logo, tagline, INITIALIZING ticker.
/// Matches designs/splash_screen.
class SplashScreenView extends GetView<SplashScreenController> {
  const SplashScreenView({super.key});

  static const Color _navy = Color(0xFF11305B);

  @override
  Widget build(BuildContext context) {
    // GetX instantiates controllers lazily on first access — touching it here
    // is what triggers onInit(), which owns the navigation timer.
    controller;
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            Image.asset(
              "assets/image/textlogo.png",
              width: Get.width / 1.8,
            ),
            const SizedBox(height: 18),
            const Text(
              "Your Corporate Journey, Simplified",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
            const Spacer(flex: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white38,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "I N I T I A L I Z I N G …",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
