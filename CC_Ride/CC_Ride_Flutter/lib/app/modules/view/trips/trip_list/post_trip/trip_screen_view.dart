import 'package:carride/app/modules/view/trips/trip_list/post_trip/post_trip_list_screen.dart';
import 'package:carride/app/modules/view/trips/trip_list/request_list/trip_request_list.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/trips_controllers/trip_screen_controller.dart';

class TripScreenView extends GetView<TripScreenController> {
  const TripScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TripScreenController>();

    return Scaffold(
      backgroundColor: ccBackground,
      body: GetBuilder<TripScreenController>(
        initState: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            c.isLoading = true;
            c.update();
            c.tripListApi(status: "Active");
          });
        },
        builder: (_) {
          return Column(
            children: [
              // ── Tab bar header (no separate AppBar — part of bottom bar shell)
              Obx(() => Container(
                    color: ccSurface,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 8,
                            left: 20,
                            right: 20,
                            bottom: 0,
                          ),
                          child: const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "My Rides",
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
                              isScrollable: false,
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
                              onTap: (value) {
                                c.isLoading = true;
                                c.update();
                                if (value == 0) {
                                  c.postTripTabController.index = 0;
                                  c.tripListApi(status: "Active");
                                } else {
                                  c.requestIsLoading = true;
                                  c.update();
                                  c.tripRequestListApi().then((_) {
                                    c.isLoading = false;
                                    c.update();
                                  });
                                }
                              },
                              tabs: [
                                for (final t in c.tabText)
                                  Tab(text: "$t".tr),
                              ],
                            ),
                          ),
                        ),
                        Container(height: 1, color: ccInputBorder),
                      ],
                    ),
                  )),

              // ── Tab content ────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  clipBehavior: Clip.none,
                  physics: const NeverScrollableScrollPhysics(),
                  controller: c.tabController,
                  children: const [PostTripListScreen(), TripRequestList()],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
