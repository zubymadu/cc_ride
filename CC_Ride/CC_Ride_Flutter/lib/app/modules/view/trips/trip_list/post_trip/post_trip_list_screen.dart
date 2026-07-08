// ignore_for_file: deprecated_member_use

import 'package:carride/app/modules/controllers/trips_controllers/trip_screen_controller.dart';
import 'package:carride/app/modules/view/trips/trip_list/post_trip/active_trips.dart';
import 'package:carride/app/modules/view/trips/trip_list/post_trip/cancelled_trips.dart';
import 'package:carride/app/modules/view/trips/trip_list/post_trip/recent_trips.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostTripListScreen extends GetView<TripScreenController> {
  const PostTripListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Sub-tab (Active / Recent / Cancelled) ─────────────────────
        Obx(() => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: ccIceBlue,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: TabBar(
                  isScrollable: false,
                  physics: const NeverScrollableScrollPhysics(),
                  controller: controller.postTripTabController,
                  indicator: BoxDecoration(
                    color: ccPrimary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: ccSurface,
                  unselectedLabelColor: ccSecondaryText,
                  labelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  dividerColor: Colors.transparent,
                  onTap: (value) {
                    controller.isLoading = true;
                    controller.update();
                    if (value == 0) {
                      controller.tripListApi(status: "Active");
                    } else if (value == 1) {
                      controller.tripListApi(status: "Recent").then((_) {
                        controller.isLoading = false;
                        controller.update();
                      });
                    } else if (value == 2) {
                      controller.tripListApi(status: "Cancelled").then((_) {
                        controller.isLoading = false;
                        controller.update();
                      });
                    }
                  },
                  tabs: [
                    for (final t in controller.postTripTabText)
                      Tab(text: "$t".tr),
                  ],
                ),
              ),
            )),

        // ── Content ────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            clipBehavior: Clip.none,
            physics: const NeverScrollableScrollPhysics(),
            controller: controller.postTripTabController,
            children: const [ActiveTrips(), RecentTrips(), CancelledTrips()],
          ),
        ),
      ],
    );
  }
}
