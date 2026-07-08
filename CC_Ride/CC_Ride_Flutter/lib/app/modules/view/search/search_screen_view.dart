// ignore_for_file: deprecated_member_use

import 'package:carride/app/data/chat_notification.dart';
import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/intro_controllers/splash_screen_controller.dart';
import 'package:carride/app/modules/models/map_api_model.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/textfield/suggestion_testfield.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../controllers/search_controllers/search_screen_controller.dart';

class SearchScreenView extends GetView<SearchScreenController> {
  const SearchScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = getData.read("userLogin");
    final firstName = user != null && user["name"] != null
        ? user["name"].toString().split(" ").first
        : "there";
    final company = user != null && user["company_name"] != null
        ? user["company_name"].toString()
        : null;

    return Scaffold(
      backgroundColor: ccBackground,
      body: Form(
        key: controller.formKey,
        child: GetBuilder<SearchScreenController>(
          initState: (state) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.update();
              controller.mapSuggetionControlle.update();
              controller.loadCustomIcons();
              try {
                FirebaseAccesstoken accesstoken = FirebaseAccesstoken();
                NotificationService.initialize().catchError((_) {});
                Future(() => requestPermission()).catchError((_) {});
                accesstoken.getAccessToken().catchError((_) {});
              } catch (_) {}
              controller.getCurrentLocation();
              controller.update();
              controller.mapSuggetionControlle.update();
            });
          },
          builder: (controller) {
            return Column(
              children: [
                // ── App Bar ─────────────────────────────────────────────
                _HomeAppBar(
                  user: user,
                  firstName: firstName,
                  company: company,
                ),

                // ── Map + Bottom Sheet ──────────────────────────────────
                Expanded(
                  child: Stack(
                    children: [
                      // Map fills the top portion
                      Positioned.fill(
                        child: GoogleMap(
                          zoomControlsEnabled: false,
                          mapType: MapType.terrain,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              lat == 0.0 ? 9.0765 : lat,
                              long == 0.0 ? 7.3986 : long,
                            ),
                            zoom: 14,
                          ),
                          markers: Set<Marker>.of(controller.markers),
                          polylines: Set<Polyline>.of(controller.polylines),
                          zoomGesturesEnabled: true,
                          gestureRecognizers: {
                            Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer()),
                          },
                          onMapCreated: (map) {
                            controller.mapController = map;
                            controller.setMapTheme(
                              controller: controller.mapController!,
                              isDarkMode:
                                  controller.themeColores.isDark,
                            );
                          },
                          liteModeEnabled: false,
                        ),
                      ),

                      // My location FAB
                      Positioned(
                        right: 12,
                        bottom: 240,
                        child: GestureDetector(
                          onTap: () {
                            controller.getCurrentLocation();
                            controller.update();
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: ccSurface,
                              borderRadius:
                                  BorderRadius.circular(CCRadius.btn),
                              boxShadow: CCShadow.card,
                            ),
                            child: const Icon(Icons.my_location_rounded,
                                color: ccPrimary, size: 22),
                          ),
                        ),
                      ),

                      // Bottom Sheet
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _HomeBottomSheet(controller: controller),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── App Bar ──────────────────────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar({
    required this.user,
    required this.firstName,
    required this.company,
  });

  final dynamic user;
  final String firstName;
  final String? company;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? "Good morning"
        : hour < 17
            ? "Good afternoon"
            : "Good evening";
    final pic = user != null ? user["profile_pic"] : null;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        color: ccSurface,
        border: Border(bottom: BorderSide(color: ccInputBorder)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ccInputBorder),
              color: ccIceBlue,
            ),
            clipBehavior: Clip.antiAlias,
            child: pic != null && pic.toString().isNotEmpty
                ? FadeInImage.assetNetwork(
                    placeholder: "assets/image/ezgif.com-crop.gif",
                    image: "${Confing.imageurl}$pic",
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : "?",
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ccPrimary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$greeting, $firstName",
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ccNavyText,
                  ),
                ),
                if (company != null)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: ccIceBlue,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      "#$company",
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ccPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Notification bell
          GestureDetector(
            onTap: () {}, // Notification screen to be added
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ccIceBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_outlined,
                      color: ccPrimary, size: 22),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ccPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: ccSurface, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Sheet ─────────────────────────────────────────────────────────────

class _HomeBottomSheet extends StatelessWidget {
  const _HomeBottomSheet({required this.controller});
  final SearchScreenController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ccSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: CCShadow.floating,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: ccInputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text(
            "Where are you going?",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ccNavyText,
            ),
          ),
          const SizedBox(height: 16),

          // Destination search field
          _DestinationField(controller: controller),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: "Book a Ride",
                  icon: Icons.directions_car_rounded,
                  filled: true,
                  onTap: () {
                    if (controller.destinationLat.isEmpty) {
                      showToastMessage("Please enter a destination");
                      return;
                    }
                    Get.toNamed(Routes.BOOKING_SERVICE, arguments: {
                      "originLat": controller.originLat,
                      "originLong": controller.originLong,
                      "destinationLat": controller.destinationLat,
                      "destinationLong": controller.destinationLong,
                      "origin": controller.originController.text,
                      "destination": controller.destinationController.text,
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: "Find Shared Route",
                  icon: Icons.fork_right_rounded,
                  filled: false,
                  onTap: () {
                    if (controller.destinationLat.isEmpty) {
                      showToastMessage("Please enter a destination");
                      return;
                    }
                    if (controller.isSearch) return;
                    controller.isSearch = true;
                    controller.update();
                    controller.findTripController
                        .findtripApi(
                      originLat: controller.originLat,
                      originLong: controller.originLong,
                      destinationLat: controller.destinationLat,
                      destinationLong: controller.destinationLong,
                      tripDate: controller.tripDate,
                      status: 'All',
                    )
                        .then((_) {
                      controller.isSearch = false;
                      controller.update();
                      Get.toNamed(Routes.SEARCH_RESULTS_SCREEN, arguments: {
                        "originLat": controller.originLat,
                        "originLong": controller.originLong,
                        "destinationLat": controller.destinationLat,
                        "destinationLong": controller.destinationLong,
                        "tripDate": controller.tripDate,
                      });
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Recent Places
          _RecentPlaces(controller: controller),
        ],
      ),
    );
  }
}

// ── Destination Field ─────────────────────────────────────────────────────────

class _DestinationField extends StatelessWidget {
  const _DestinationField({required this.controller});
  final SearchScreenController controller;

  @override
  Widget build(BuildContext context) {
    return suggestionsTextField(
      controller: controller.destinationController,
      focusNode: controller.focus2,
      builder: (context, ctrl, focusNode) {
        return Container(
          height: 52,
          decoration: BoxDecoration(
            color: ccSurface,
            borderRadius: BorderRadius.circular(CCRadius.input),
            border: Border.all(color: ccInputBorder, width: 1.5),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.location_on, color: ccPrimary, size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  focusNode: focusNode,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: ccNavyText,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Search destination",
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: ccSecondaryText,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) async {
                    await controller.mapSuggetionControlle
                        .mapApi(suggestkey: v);
                    controller.mapSuggetionControlle.update();
                    controller.update();
                  },
                ),
              ),
              if (controller.destinationController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    controller.destinationLat = "";
                    controller.destinationLong = "";
                    controller.destinationController.clear();
                    controller.generateRoute();
                    controller.update();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child:
                        Icon(Icons.close_rounded, color: ccSecondaryText, size: 18),
                  ),
                ),
            ],
          ),
        );
      },
      onSelected: (Result result) {
        if (result.geometry?.location?.lat != null &&
            result.geometry?.location?.lng != null) {
          final lat = result.geometry!.location!.lat!;
          final lng = result.geometry!.location!.lng!;
          final LatLng position = LatLng(lat, lng);
          controller.waypoints.add(position);
          controller.destinationLat =
              double.parse("$lat").toStringAsFixed(4);
          controller.destinationLong =
              double.parse("$lng").toStringAsFixed(4);
          controller.destinationController.text = result.name == null
              ? "${result.formattedAddress}"
              : "${result.name}";
          controller.update();
          controller.focus2.unfocus();
          controller.generateRoute();
          controller.update();
        }
      },
      suggestionsCallback: (pattern) async {
        if (!controller.showSuggestions || pattern.trim().isEmpty) return [];
        await controller.mapSuggetionControlle.mapApi(suggestkey: pattern);
        final results =
            controller.mapSuggetionControlle.mapApiModel?.results ?? [];
        return results;
      },
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: filled ? ccPrimary : ccSurface,
          borderRadius: BorderRadius.circular(CCRadius.btn),
          border: filled ? null : Border.all(color: ccPrimary, width: 1.5),
          boxShadow: filled ? CCShadow.card : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: filled ? ccSurface : ccPrimary, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: filled ? ccSurface : ccPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent Places ─────────────────────────────────────────────────────────────

class _RecentPlaces extends StatelessWidget {
  const _RecentPlaces({required this.controller});
  final SearchScreenController controller;

  @override
  Widget build(BuildContext context) {
    // Recent places are derived from waypoints/trip history.
    // This section will be populated from booking history in a future update.
    final recent = controller.waypoints.isEmpty
        ? <Map<String, String>>[]
        : controller.waypoints
            .take(3)
            .map((wp) => {
                  "name": "${wp.latitude.toStringAsFixed(4)}, ${wp.longitude.toStringAsFixed(4)}",
                  "address": "Recent location",
                })
            .toList();

    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Recent places", style: CCText.titleMd),
            GestureDetector(
              onTap: () {
                controller.waypoints.clear();
                controller.update();
              },
              child: Text(
                "Clear all",
                style: CCText.labelSm.copyWith(color: ccPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...recent.asMap().entries.map((e) {
          final isLast = e.key == recent.length - 1;
          return GestureDetector(
            onTap: () {
              // Re-use the tapped waypoint as destination
              final wp = controller.waypoints[e.key];
              controller.destinationLat =
                  wp.latitude.toStringAsFixed(4);
              controller.destinationLong =
                  wp.longitude.toStringAsFixed(4);
              controller.destinationController.text = e.value["name"]!;
              controller.generateRoute();
              controller.update();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: ccIceBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.schedule_rounded,
                        color: ccPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 10),
                      decoration: isLast
                          ? null
                          : const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: ccInputBorder),
                              ),
                            ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.value["name"]!,
                              style: CCText.titleMd,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(e.value["address"]!,
                              style: CCText.bodyMd
                                  .copyWith(color: ccSecondaryText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: ccInputBorder, size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
