import 'package:carride/utils/color.dart';
import 'package:carride/app/modules/view/account_screen/my_booking_screens/my_booking_list/current_booking_list.dart';
import 'package:carride/app/modules/view/account_screen/my_booking_screens/my_booking_list/past_booking_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/account_controllers/my_booking_controllers/my_booking_screen_controller.dart';

/// Passenger-mode equivalent of TripScreenView (which is driver-only — posted
/// trips + join requests) — same "My Rides" bottom-nav slot, but shows the
/// rides *this* user has booked as a passenger instead. No Scaffold/AppBar of
/// its own since it's embedded directly inside the bottom bar shell, exactly
/// like TripScreenView.
class MyBookingsTabView extends StatelessWidget {
  const MyBookingsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<MyBookingScreenController>()
        ? Get.find<MyBookingScreenController>()
        : Get.put(MyBookingScreenController());

    return GetBuilder<MyBookingScreenController>(
      builder: (_) => Column(
        children: [
          Container(
            color: ccSurface,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 20,
                    right: 20,
                  ),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "My Bookings",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: ccNavyText,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                Container(height: 1, color: ccInputBorder),
              ],
            ),
          ),
          Expanded(
            child: c.isLoading
                ? const Center(child: CircularProgressIndicator(color: ccPrimary))
                : TabBarView(
                    clipBehavior: Clip.none,
                    physics: const NeverScrollableScrollPhysics(),
                    controller: c.tabController,
                    children: const [CurrentBookingList(), PastBookingList()],
                  ),
          ),
        ],
      ),
    );
  }
}
