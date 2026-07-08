import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/intro_controllers/onboarding_screen_controller.dart';

/// Onboarding — Skip top-right, illustration, bold title, grey copy,
/// dots bottom-left + circular arrow FAB bottom-right.
/// Last slide swaps to a full-width "Get Started" button.
/// Matches designs/onboarding_slide_1..3.
class OnboardingScreenView extends GetView<OnboardingScreenController> {
  const OnboardingScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip ─────────────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 20, 0),
                child: InkWell(
                  onTap: () => Get.offAllNamed(Routes.LOGIN_SCREEN),
                  child: Text(
                    "Skip".tr,
                    style: const TextStyle(
                      color: ccPrimary,
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

            // ── Illustration + copy ───────────────────────────────────────
            Expanded(
              child: PageView.builder(
                physics: const BouncingScrollPhysics(),
                controller: controller.pageController,
                onPageChanged: (value) {
                  controller.currentPage = value;
                  controller.update();
                },
                itemCount: contents.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(child: Image.asset(contents[i].image)),
                        ),
                        Text(
                          contents[i].title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF11305B),
                            fontSize: 26,
                            height: 1.2,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          contents[i].desc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: ccSecondaryText,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 36),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Bottom bar: dots + arrow FAB / Get Started ───────────────
            Obx(() {
              final isLast = controller.currentPage == contents.length - 1;
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: isLast
                    ? SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ccPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: controller.controllervalueincrement,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Get Started".tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios,
                                  color: Colors.white, size: 14),
                            ],
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Dots — active one is a wide pill
                          Row(
                            children: List.generate(contents.length, (i) {
                              final active = controller.currentPage == i;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.only(right: 8),
                                width: active ? 28 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: active
                                      ? ccPrimary
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                          // Circular arrow FAB
                          InkWell(
                            onTap: controller.controllervalueincrement,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: ccPrimary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: ccPrimary.withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.arrow_forward,
                                  color: Colors.white),
                            ),
                          ),
                        ],
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
