import 'package:carride/utils/color.dart';
import 'package:carride/app/modules/view/account_screen/my_booking_screens/my_booking_list/current_booking_list.dart';
import 'package:carride/app/modules/view/account_screen/my_booking_screens/my_booking_list/past_booking_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/account_controllers/my_booking_controllers/my_booking_screen_controller.dart';

class MyBookingScreenView extends GetView<MyBookingScreenController> {
  const MyBookingScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MyBookingScreenController>();
    return GetBuilder<MyBookingScreenController>(
      init: MyBookingScreenController(),
      builder: (_) {
        return Scaffold(
          backgroundColor: ccBackground,
          appBar: AppBar(
            backgroundColor: ccSurface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
              onPressed: () => Get.back(),
            ),
            title: const Text(
              "My Bookings",
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ccNavyText,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: ccInputBorder),
            ),
          ),
          body: Obx(
            () => c.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: ccPrimary))
                : Column(
                    children: [
                      // ── Tab switcher ─────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ccIceBlue,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: TabBar(
                            physics: const NeverScrollableScrollPhysics(),
                            controller: c.tabController,
                            indicator: BoxDecoration(
                              color: ccPrimary,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: ccSurface,
                            unselectedLabelColor: ccSecondaryText,
                            labelStyle: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            dividerColor: Colors.transparent,
                            tabs: [
                              for (int i = 0; i < c.tabText.length; i++)
                                Tab(text: "${c.tabText[i]}"),
                            ],
                          ),
                        ),
                      ),

                      // ── Tab content ──────────────────────────────────
                      Expanded(
                        child: TabBarView(
                          clipBehavior: Clip.none,
                          physics: const NeverScrollableScrollPhysics(),
                          controller: c.tabController,
                          children: const [
                            CurrentBookingList(),
                            PastBookingList(),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
