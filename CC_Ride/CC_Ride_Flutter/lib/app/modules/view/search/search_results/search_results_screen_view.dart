import 'package:carride/utils/color.dart';
import 'package:carride/app/modules/view/search/search_results/post_trip_bottomsheet.dart';
import 'package:carride/app/modules/view/search/search_results/search_all.dart';
import 'package:carride/app/modules/view/search/search_results/search_request.dart';
import 'package:carride/app/modules/view/search/search_results/search_trip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/search_controllers/search_results_screen_controller.dart';

class SearchResultsScreenView extends GetView<SearchResultsScreenController> {
  const SearchResultsScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SearchResultsScreenController>();

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
          "Search Results",
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
      floatingActionButton: Obx(() {
        bool showFab = false;
        if (c.currentPage == 0) {
          showFab = !(c.findTripController.allIsLoading) &&
              c.findTripController.findAllmodel?.result != "false";
        } else if (c.currentPage == 1) {
          showFab = !(c.findTripController.tripIsLoading) &&
              c.findTripController.findTripsmodel?.result != "false";
        } else {
          showFab = !(c.findTripController.requestIsLoading) &&
              c.findTripController.findRequestsmodel?.result != "false";
        }
        if (!showFab) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: postTripBottomsheet,
          backgroundColor: ccPrimary,
          icon: const Icon(Icons.add, color: ccSurface),
          label: const Text(
            "Post a trip",
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: ccSurface,
            ),
          ),
        );
      }),
      body: Column(
        children: [
          // ── Tab switcher ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
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
                  c.currentPage = value;
                  final args = Get.arguments ?? {};
                  final status =
                      value == 0 ? "All" : value == 1 ? "Trip" : "Requests";
                  _reloadTab(c, args, status, value);
                },
                tabs: [
                  for (int i = 0; i < c.tabText.length; i++)
                    Tab(text: "${c.tabText[i]}".tr),
                ],
              ),
            ),
          ),

          // ── Tab content ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: c.tabController,
              children: const [SearchAll(), SearchTrip(), SearchRequest()],
            ),
          ),
        ],
      ),
    );
  }

  void _reloadTab(SearchResultsScreenController c, Map args, String status,
      int tabIndex) {
    if (tabIndex == 0) {
      c.findTripController.allIsLoading = true;
    } else if (tabIndex == 1) {
      c.findTripController.tripIsLoading = true;
    } else {
      c.findTripController.requestIsLoading = true;
    }
    c.findTripController.update();
    c.findTripController
        .findtripApi(
      originLat: "${args["originLat"]}",
      originLong: "${args["originLong"]}",
      destinationLat: "${args["destinationLat"]}",
      destinationLong: "${args["destinationLong"]}",
      tripDate: "${args["tripDate"]}",
      status: status,
    )
        .then((_) {
      if (tabIndex == 0) {
        c.findTripController.allIsLoading = false;
      } else if (tabIndex == 1) {
        c.findTripController.tripIsLoading = false;
      } else {
        c.findTripController.requestIsLoading = false;
      }
      c.findTripController.update();
      c.update();
    });
  }
}
