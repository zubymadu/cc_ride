import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/post_controllers/my_routes_controller.dart';

class MyRoutesScreenView extends GetView<MyRoutesController> {
  const MyRoutesScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<MyRoutesController>()
        ? Get.find<MyRoutesController>()
        : Get.put(MyRoutesController());
    // onInit() only fetches once, at controller creation. A driver can reach
    // this screen again later (e.g. after adopting/publishing a route via
    // the "unserviced route" flow on the home screen, which doesn't pass
    // back through here) while the controller from an earlier, now-stale
    // visit is still registered — Get.isRegistered above then reuses it
    // as-is, showing the old list. Refetch every time this screen opens so
    // a just-created route always shows up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.fetchRoutes();
    });
    return Scaffold(
      backgroundColor: ccBackground,
      appBar: AppBar(
        backgroundColor: ccSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
          onPressed: () {
            Get.delete<MyRoutesController>();
            Get.back();
          },
        ),
        title: const Text(
          "My Routes",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ccNavyText,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ccPrimary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Create Route",
            style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        onPressed: () async {
          final result = await Get.toNamed(Routes.CREATE_ROUTE_SCREEN);
          if (result == true) c.fetchRoutes();
        },
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: ccPrimary));
        }
        if (c.routes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route_rounded,
                      size: 48, color: ccSecondaryText),
                  const SizedBox(height: 12),
                  const Text(
                    "You haven't published any routes yet.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Inter', color: ccSecondaryText),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          color: ccPrimary,
          onRefresh: c.fetchRoutes,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            itemCount: c.routes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final r = c.routes[i];
              final days = _formatDays(r.daysOfWeek);
              return InkWell(
                borderRadius: BorderRadius.circular(CCRadius.card),
                onTap: () => Get.toNamed(Routes.ROUTE_REQUESTS_SCREEN,
                    arguments: {
                      "route_id": r.routeId,
                      "route_name": r.routeName,
                    }),
                child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ccSurface,
                  borderRadius: BorderRadius.circular(CCRadius.card),
                  boxShadow: CCShadow.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: ccIceBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            r.routeCode,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: ccPrimary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => Get.toNamed(Routes.CREATE_ROUTE_SCREEN,
                              arguments: {
                                "edit_route_id": r.routeId,
                                "origin_address": r.originName,
                                "origin_lat": r.originLat,
                                "origin_long": r.originLong,
                                "desti_address": r.destinationName,
                                "desti_lat": r.destinationLat,
                                "desti_long": r.destinationLong,
                                "departure_time": r.departureTime,
                                "days_of_week": r.daysOfWeek,
                                "seat_capacity": r.seatCapacity,
                                "fare": r.fare,
                                "vehicle_id": r.vehicleId,
                                "book_preference":
                                    r.manualApproval ? "Manual" : "Auto",
                              })?.then((result) {
                            if (result == true) c.fetchRoutes();
                          }),
                          child: const Padding(
                            padding: EdgeInsets.only(right: 14),
                            child: Icon(Icons.edit_outlined,
                                color: ccSecondaryText, size: 20),
                          ),
                        ),
                        InkWell(
                          onTap: () => _confirmDeactivate(context, c, r.routeId),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: ccError, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${r.originName.split(',').first} → ${r.destinationName.split(',').first}",
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ccNavyText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "$days • ${r.departureTime}",
                      style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                    ),
                    if (r.vehicleTitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        r.vehicleTitle,
                        style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text("${r.seatCapacity} seats",
                            style: CCText.labelSm
                                .copyWith(color: ccSecondaryText)),
                        const Spacer(),
                        Text(
                          "$currency ${r.fare}",
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: ccPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  void _confirmDeactivate(
      BuildContext context, MyRoutesController c, String routeId) {
    Get.dialog(
      AlertDialog(
        backgroundColor: ccSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CCRadius.card)),
        title: const Text("Remove this route?",
            style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: ccNavyText)),
        content: const Text(
          "It'll come off your list, but the route stays visible to other drivers as a suggestion until someone adopts it.",
          style: TextStyle(fontFamily: 'Inter', color: ccSecondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel",
                style: TextStyle(color: ccSecondaryText)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              c.deactivateRoute(routeId);
            },
            child: const Text("Remove",
                style: TextStyle(color: ccError, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// daysOfWeek uses the backend's Date.getDay() convention: 0=Sun..6=Sat.
const _fullDayNames = [
  'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
];
const _shortDayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

String _formatDays(List<int> daysOfWeek) {
  final sorted = [...daysOfWeek]..sort();
  if (sorted.length == 7) return 'Every day';
  if (sorted.length == 1) return _fullDayNames[sorted.first % 7];

  // Mon..Fri (or any other single consecutive run) reads better as a range,
  // matching how a recurring weekday commute is normally described.
  final isConsecutiveRun = sorted.length > 1 &&
      List.generate(sorted.length - 1, (i) => sorted[i + 1] - sorted[i])
          .every((gap) => gap == 1);
  if (isConsecutiveRun) {
    return '${_fullDayNames[sorted.first % 7]} - ${_fullDayNames[sorted.last % 7]}';
  }
  return sorted.map((d) => _shortDayNames[d % 7]).join(', ');
}
