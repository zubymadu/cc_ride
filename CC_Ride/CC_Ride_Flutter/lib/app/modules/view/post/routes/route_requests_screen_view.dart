import 'package:carride/app/data/confing.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/post_controllers/route_requests_controller.dart';

class RouteRequestsScreenView extends StatelessWidget {
  const RouteRequestsScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map? ?? {};
    final routeId = '${args["route_id"]}';
    final routeName = '${args["route_name"] ?? "Route"}';

    final c = Get.isRegistered<RouteRequestsController>(tag: routeId)
        ? Get.find<RouteRequestsController>(tag: routeId)
        : Get.put(RouteRequestsController(routeId: routeId), tag: routeId);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: ccBackground,
        appBar: AppBar(
          backgroundColor: ccSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
            onPressed: () {
              Get.delete<RouteRequestsController>(tag: routeId);
              Get.back();
            },
          ),
          title: Text(
            routeName,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: ccNavyText,
            ),
          ),
          bottom: TabBar(
            labelColor: ccPrimary,
            unselectedLabelColor: ccSecondaryText,
            indicatorColor: ccPrimary,
            labelStyle: const TextStyle(
                fontFamily: 'Inter', fontWeight: FontWeight.w700),
            tabs: [
              Obx(() => Tab(text: "Pending (${c.pending.length})")),
              Obx(() => Tab(text: "Confirmed (${c.confirmed.length})")),
              Obx(() => Tab(text: "Declined (${c.declined.length})")),
            ],
          ),
        ),
        body: Obx(() {
          if (c.isLoading.value) {
            return const Center(
                child: CircularProgressIndicator(color: ccPrimary));
          }
          return RefreshIndicator(
            color: ccPrimary,
            onRefresh: c.fetchRequests,
            child: TabBarView(
              children: [
                _RequestList(c: c, requests: c.pending, showActions: true),
                _RequestList(c: c, requests: c.confirmed, showActions: false),
                _RequestList(c: c, requests: c.declined, showActions: false),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({
    required this.c,
    required this.requests,
    required this.showActions,
  });
  final RouteRequestsController c;
  final RxList<RouteBookingRequest> requests;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (requests.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Nothing here yet.",
              style: CCText.bodyMd.copyWith(color: ccSecondaryText),
            ),
          ),
        );
      }
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final r = requests[i];
          final minsAgo = DateTime.now().difference(r.createdAt).inMinutes;
          final isActioning = c.actioningIds.contains(r.bookingId);
          return Container(
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
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: ccIceBlue,
                      backgroundImage: r.passengerPic.isNotEmpty
                          ? NetworkImage("${Confing.imageurl}${r.passengerPic}")
                          : null,
                      child: r.passengerPic.isEmpty
                          ? Text(
                              r.passengerName.isNotEmpty
                                  ? r.passengerName[0].toUpperCase()
                                  : "?",
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  color: ccPrimary),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r.passengerName,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          color: ccNavyText,
                        ),
                      ),
                    ),
                    Text(
                      minsAgo < 1
                          ? "just now"
                          : minsAgo < 60
                              ? "$minsAgo mins ago"
                              : "${(minsAgo / 60).floor()}h ago",
                      style: CCText.labelSm.copyWith(color: ccSecondaryText),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.trip_origin_rounded,
                        size: 15, color: ccSuccess),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text("Pick: ${r.pickupAddress}",
                          style: CCText.bodyMd),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 15, color: ccError),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text("Drop: ${r.dropoffAddress}",
                          style: CCText.bodyMd),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${r.seatsBooked} seat(s)",
                  style: CCText.labelSm.copyWith(color: ccSecondaryText),
                ),
                if (showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CCButton(
                          label: "Confirm",
                          loading: isActioning,
                          onPressed: isActioning
                              ? null
                              : () => c.confirmRequest(r.bookingId),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isActioning
                              ? null
                              : () => c.declineRequest(r.bookingId),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: ccError),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(CCRadius.btn),
                            ),
                          ),
                          child: const Text(
                            "Decline",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              color: ccError,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      );
    });
  }
}
