// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:carride/app/data/chat_notification.dart';
import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/driver_mode/driver_mode_controller.dart';
import 'package:carride/app/modules/models/map_api_model.dart';
import 'package:carride/app/modules/view/advert/advert_carousel.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/textfield/suggestion_testfield.dart';
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
    // Was reading user["company_name"] — company_name/company_id/company_logo
    // are saved by login_controller.dart under their OWN top-level storage
    // keys ("companyName" etc.), never merged into the "userLogin" object
    // this screen reads everything else from, so this was always null and
    // the company chip (and any logo) never showed on the home header.
    final companyNameRaw = getData.read("companyName") as String? ?? '';
    final company = companyNameRaw.isNotEmpty ? companyNameRaw : null;
    final companyLogoRaw = getData.read("companyLogo") as String? ?? '';
    final companyLogo = companyLogoRaw.isNotEmpty ? companyLogoRaw : null;

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
                accesstoken.getAccessToken().catchError((_) => '');
              } catch (_) {}
              controller.getCurrentLocation();
              controller.update();
              controller.mapSuggetionControlle.update();
            });
          },
          builder: (controller) {
            return SafeArea(
              child: RefreshIndicator(
                color: ccPrimary,
                onRefresh: () async => controller.getCurrentLocation(),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HomeHeader(
                        user: user,
                        firstName: firstName,
                        company: company,
                        companyLogo: companyLogo,
                        controller: controller,
                      ),
                      const SizedBox(height: 20),
                      _DestinationField(controller: controller),
                      const SizedBox(height: 16),

                      // Primary action — hands off to the trip-planning
                      // screen (date/time, return trip, subscribe to route)
                      // before searching. A single search there surfaces
                      // both ad-hoc rides and shared routes that match the
                      // trip, ranked by relevance, so there's no need for a
                      // separate "shared route" entry point.
                      SizedBox(
                        width: double.infinity,
                        child: _ActionButton(
                          label: "Book a Ride",
                          icon: Icons.directions_car_rounded,
                          filled: true,
                          onTap: () => _goToTripPlan(controller),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Replaces the old My Bookings / Wallet / Refer & Earn /
                      // Help quick-actions row directly under "Book a Ride" —
                      // those destinations are still reachable from the
                      // Bookings and Account tabs, just no longer duplicated
                      // here.
                      const AdvertCarousel(),
                      const SizedBox(height: 24),

                      // Deliberately labeled and visually separated from the
                      // "Where to?" destination field above (_DestinationField)
                      // — both are text inputs on the same screen with easily
                      // confusable purposes: that one is Google Places
                      // autocomplete for planning a specific A→B trip, this
                      // one lists already-posted, bookable rides touching a
                      // place name. Reports of "searched Abuja, got nothing"
                      // traced to no bug in the search itself (verified live
                      // against the backend) — the far more likely cause is
                      // typing into the wrong field, which an unlabeled
                      // lookalike search box further down the page invited.
                      const Text("Search posted rides", style: CCText.titleMd),
                      const SizedBox(height: 2),
                      Text(
                        "Browse rides other drivers have already posted, by city or state.",
                        style: CCText.labelSm,
                      ),
                      const SizedBox(height: 8),
                      _RideSearchBar(controller: controller),
                      const SizedBox(height: 12),

                      if (controller.placeSearchActive) ...[
                        _PlaceSearchResults(controller: controller),
                      ] else ...[
                        _NearbySharedRoutes(controller: controller),
                        _NearbyPostedRides(controller: controller),

                        // Recent Places
                        _RecentPlaces(controller: controller),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────
// Location row + greeting + quick-access icons, matching the reference app's
// home header layout (location dropdown, "Hi, Name", support + notifications).

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.user,
    required this.firstName,
    required this.company,
    required this.companyLogo,
    required this.controller,
  });

  final dynamic user;
  final String firstName;
  final String? company;
  final String? companyLogo;
  final SearchScreenController controller;

  @override
  Widget build(BuildContext context) {
    final pic = user != null ? user["profile_pic"] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location row
        GestureDetector(
          onTap: () => controller.getCurrentLocation(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_rounded,
                  color: ccPrimary, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  controller.addresshome.isNotEmpty
                      ? controller.addresshome
                      : "Detecting location...",
                  overflow: TextOverflow.ellipsis,
                  style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: ccSecondaryText, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 10),

        Row(
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
                        firstName.isNotEmpty
                            ? firstName[0].toUpperCase()
                            : "?",
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

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Hi, $firstName",
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ccNavyText,
                    ),
                  ),
                  if (company != null)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ccIceBlue,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (companyLogo != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                companyLogo!.startsWith('http')
                                    ? companyLogo!
                                    : '${Confing.imageurl}$companyLogo',
                                width: 12,
                                height: 12,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            "#$company",
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: ccPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Help
            GestureDetector(
              onTap: () => Get.toNamed(Routes.HELP_SCREEN),
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: ccIceBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.headset_mic_outlined,
                    color: ccPrimary, size: 20),
              ),
            ),

            // Notification bell
            GestureDetector(
              onTap: () => Get.toNamed(Routes.NOTIFICATION_SCREEN),
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
      ],
    );
  }
}

// ── Trip planning hand-off ─────────────────────────────────────────────────
// "Book a Ride" no longer searches immediately — it defaults the origin to
// the passenger's current location (if they haven't typed one) and today as
// the departure date, then hands off to the trip-planning screen for
// date/time/return-trip/subscribe-to-route before the actual search happens.

void _goToTripPlan(SearchScreenController controller) {
  if (controller.destinationLat.isEmpty) {
    showToastMessage("Please enter a destination");
    return;
  }
  // getCurrentLocation() only ever populates lat/long (raw doubles, used for
  // the map) and addresshome (display text) — it never touches originLat/
  // originLong/originController, which is what search/booking actually
  // reads. Default the origin to the detected current location here if the
  // passenger hasn't typed one themselves.
  if (controller.originLat.isEmpty &&
      controller.lat != null &&
      controller.long != null) {
    controller.originController.text = controller.addresshome.isNotEmpty
        ? controller.addresshome
        : "Current location";
    controller.originLat = controller.lat!.toStringAsFixed(4);
    controller.originLong = controller.long!.toStringAsFixed(4);
  }
  if (controller.tripDate.isEmpty) {
    controller.departureDateTime = DateTime.now();
  }
  controller.update();
  Get.toNamed(Routes.TRIP_PLAN_SCREEN);
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
                    // Distinct from the "Search rides by city" bar further
                    // down the page — this one plans a brand-new A→B trip,
                    // that one browses rides other people already posted.
                    // The two were easy to conflate (same look, both near
                    // the top), which repeatedly got reported as "search
                    // finds nothing" even though the ride search itself
                    // worked fine — the user was typing into this field.
                    hintText: "Where are you going? (plan a new trip)",
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: ccSecondaryText,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) {
                    // Suggestions are fetched by TypeAheadField's own
                    // (debounced) suggestionsCallback below — calling
                    // mapApi() again here fired a second, undebounced
                    // request per keystroke that raced the debounced one
                    // and could overwrite fresher results with a stale
                    // response for a shorter, earlier substring.
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

// ── Nearby Shared Routes ────────────────────────────────────────────────────
// Sleek horizontal cards for the fixed routes running near the passenger's
// current location. Tapping one searches from here toward that route's
// destination, so results shows every ride — ad-hoc or shared — whose path
// actually covers the trip, not just this one route.

class _NearbySharedRoutes extends StatelessWidget {
  const _NearbySharedRoutes({required this.controller});
  final SearchScreenController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.nearbyRoutesLoading && controller.nearbyRoutes.isEmpty) {
      return const SizedBox.shrink();
    }
    if (controller.nearbyRoutes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Shared routes near you", style: CCText.titleMd),
          const SizedBox(height: 12),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: controller.nearbyRoutes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _NearbyRouteCard(
                route: controller.nearbyRoutes[i],
                controller: controller,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyRouteCard extends StatelessWidget {
  const _NearbyRouteCard({required this.route, required this.controller});
  final NearbyRoute route;
  final SearchScreenController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!route.isServiced) {
          // No driver currently services this route — nothing to book.
          // Hand off to route creation (own-car/pool drivers only) with the
          // corridor pre-filled, so a driver can "adopt" it by publishing
          // their own copy; passengers just get told to check back later.
          final isDriver = Get.isRegistered<DriverModeController>() &&
              Get.find<DriverModeController>().isDriverMode;
          if (isDriver) {
            Get.toNamed(Routes.CREATE_ROUTE_SCREEN, arguments: {
              "origin_address": route.originName,
              "origin_lat": route.originLat,
              "origin_long": route.originLong,
              "desti_address": route.destinationName,
              "desti_lat": route.destinationLat,
              "desti_long": route.destinationLong,
            });
          } else {
            showToastMessage(
                "No driver is currently running this route — check back later.");
          }
          return;
        }
        // getCurrentLocation() only ever populates lat/long (raw doubles) and
        // addresshome (display text) — it never touches originLat/originLong,
        // which is what the search actually reads. Without defaulting it here
        // (same as _goToTripPlan does for "Book a Ride"), tapping a nearby
        // route card searched with an empty origin every time.
        if (controller.originLat.isEmpty &&
            controller.lat != null &&
            controller.long != null) {
          controller.originController.text = controller.addresshome.isNotEmpty
              ? controller.addresshome
              : "Current location";
          controller.originLat = controller.lat!.toStringAsFixed(4);
          controller.originLong = controller.long!.toStringAsFixed(4);
        }
        if (controller.tripDate.isEmpty) {
          controller.departureDateTime = DateTime.now();
        }
        controller.waypoints.add(LatLng(route.destinationLat, route.destinationLong));
        controller.destinationLat = route.destinationLat.toStringAsFixed(4);
        controller.destinationLong = route.destinationLong.toStringAsFixed(4);
        controller.destinationController.text = route.destinationName;
        controller.generateRoute();
        controller.update();
        // Hands off to the same trip-planning screen "Book a Ride" uses
        // (date/time, return trip, subscribe-to-route) instead of searching
        // immediately — a passenger picking a route card is doing the exact
        // same thing as tapping "Book a Ride" with the destination
        // pre-filled, and previously got a stripped-down flow with none of
        // those controls just because they entered through a different
        // button. Same action should mean the same flow.
        Get.toNamed(Routes.TRIP_PLAN_SCREEN);
      },
      child: Container(
        width: 210,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ccIceBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    route.routeCode,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ccPrimary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  "${route.distanceKm.toStringAsFixed(1)} km",
                  style: CCText.labelSm.copyWith(color: ccSecondaryText),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "${route.originName.split(',').first} → ${route.destinationName.split(',').first}",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ccNavyText,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                if (route.nextDeparture.isNotEmpty) ...[
                  const Icon(Icons.schedule_rounded, size: 13, color: ccSecondaryText),
                  const SizedBox(width: 4),
                  Text(route.nextDeparture,
                      style: CCText.labelSm.copyWith(color: ccSecondaryText)),
                ],
                const Spacer(),
                if (route.seatPrice.isNotEmpty)
                  Text(
                    "$currency ${route.seatPrice}",
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
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
  }
}

// ── Ride search bar (free-text place search) ────────────────────────────────

class _RideSearchBar extends StatefulWidget {
  const _RideSearchBar({required this.controller});
  final SearchScreenController controller;

  @override
  State<_RideSearchBar> createState() => _RideSearchBarState();
}

class _RideSearchBarState extends State<_RideSearchBar> {
  final _textController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _textController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Was a bare Timer whose callback called controller.searchRidesByPlace()
  // with no local setState — relying entirely on the parent GetBuilder to
  // pick up the controller's own update() call for both this field's own
  // suffix-icon state AND the results section further down. On-device
  // testing showed typing here never actually reached the backend at all
  // (confirmed via zero HTTP activity in the OS-level network log after
  // typing and waiting well past the debounce window). Rather than a
  // Timer racing against GetBuilder rebuild timing, drive this off
  // setState directly — deterministic regardless of what else in the
  // widget tree is or isn't rebuilding — and also fire immediately on
  // submit so there's a non-debounced path that doesn't depend on the
  // timer at all.
  void _onChanged(String value) {
    setState(() {}); // updates the clear (X) icon immediately
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      widget.controller.searchRidesByPlace(value);
    });
  }

  void _onSubmitted(String value) {
    _debounce?.cancel();
    widget.controller.searchRidesByPlace(value);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      onChanged: _onChanged,
      onSubmitted: _onSubmitted,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontFamily: 'Inter', color: ccNavyText),
      decoration: InputDecoration(
        hintText: "Search rides by city, e.g. Abuja".tr,
        hintStyle: const TextStyle(fontFamily: 'Inter', color: ccSecondaryText),
        prefixIcon: const Icon(Icons.search_rounded, color: ccSecondaryText),
        suffixIcon: _textController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, color: ccSecondaryText, size: 18),
                onPressed: () {
                  _textController.clear();
                  widget.controller.clearPlaceSearch();
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: ccSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CCRadius.input),
          borderSide: const BorderSide(color: ccInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CCRadius.input),
          borderSide: const BorderSide(color: ccInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CCRadius.input),
          borderSide: const BorderSide(color: ccPrimary, width: 1.5),
        ),
      ),
    );
  }
}

// ── Place search results ─────────────────────────────────────────────────────

class _PlaceSearchResults extends StatelessWidget {
  const _PlaceSearchResults({required this.controller});
  final SearchScreenController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.placeSearchLoading && controller.placeSearchResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Center(child: CircularProgressIndicator(color: ccPrimary)),
      );
    }
    if (controller.placeSearchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 24),
        child: Text(
          "No live rides found for that search yet.".tr,
          style: CCText.bodyMd.copyWith(color: ccSecondaryText),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final ride in controller.placeSearchResults) ...[
            _NearbyPostedRideCard(ride: ride, controller: controller, fullWidth: true),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ── Nearby posted (one-off) rides ────────────────────────────────────────────

class _NearbyPostedRides extends StatelessWidget {
  const _NearbyPostedRides({required this.controller});
  final SearchScreenController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.nearbyPostedRidesLoading && controller.nearbyPostedRides.isEmpty) {
      return const SizedBox.shrink();
    }
    if (controller.nearbyPostedRides.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Rides near you", style: CCText.titleMd),
          const SizedBox(height: 12),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: controller.nearbyPostedRides.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _NearbyPostedRideCard(
                ride: controller.nearbyPostedRides[i],
                controller: controller,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyPostedRideCard extends StatelessWidget {
  const _NearbyPostedRideCard({
    required this.ride,
    required this.controller,
    this.fullWidth = false,
  });
  final NearbyPostedRide ride;
  final SearchScreenController controller;
  // Place-search results render as a full-width vertical list instead of the
  // fixed-width horizontal cards the home-screen nearby feed uses.
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (ride.tripId != null) {
          // A posted ride is a specific, already-bookable instance — go
          // straight to the same trip-preview/booking screen tapping a
          // find-trip search result uses.
          Get.toNamed(Routes.TRIP_PREVIEW_SCREEN, arguments: {
            "tripId": ride.tripId,
            "findtrip": true,
          });
          return;
        }
        // A route-corridor search result (search_rides_by_place.php now
        // covers these too, not just ad-hoc trips) has no real bookable
        // Ride row until an occurrence is actually booked — hand off to
        // trip-planning with the corridor pre-filled, exactly the same way
        // tapping a "Shared routes near you" card already does (TRIP_PLAN_
        // SCREEN reads controller state, not navigation arguments).
        if (controller.originLat.isEmpty &&
            controller.lat != null &&
            controller.long != null) {
          controller.originController.text = controller.addresshome.isNotEmpty
              ? controller.addresshome
              : "Current location";
          controller.originLat = controller.lat!.toStringAsFixed(4);
          controller.originLong = controller.long!.toStringAsFixed(4);
        }
        if (controller.tripDate.isEmpty) {
          controller.departureDateTime = DateTime.now();
        }
        controller.waypoints.add(LatLng(ride.destinationLat, ride.destinationLong));
        controller.destinationLat = ride.destinationLat.toStringAsFixed(4);
        controller.destinationLong = ride.destinationLong.toStringAsFixed(4);
        controller.destinationController.text = ride.destinationAddress;
        controller.generateRoute();
        controller.update();
        Get.toNamed(Routes.TRIP_PLAN_SCREEN);
      },
      child: Container(
        width: fullWidth ? double.infinity : 210,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ccIceBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    // Route-corridor results have no real seat count until an
                    // occurrence is actually booked (see availableSeats:
                    // null in ridePreviewShape's route branch).
                    ride.availableSeats != null
                        ? "${ride.availableSeats} ${ride.availableSeats == 1 ? 'seat' : 'seats'}".tr
                        : "Recurring route".tr,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ccPrimary,
                    ),
                  ),
                ),
                const Spacer(),
                if (ride.distanceKm != null)
                  Text(
                    "${ride.distanceKm!.toStringAsFixed(1)} km",
                    style: CCText.labelSm.copyWith(color: ccSecondaryText),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "${ride.originAddress.split(',').first} → ${ride.destinationAddress.split(',').first}",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ccNavyText,
              ),
            ),
            // Was a Spacer() — needs a bounded main-axis constraint to
            // expand into. Fine for the fixed-width horizontal-scroller
            // usage of this card (bounded height there), but this same
            // card is also used full-width inside _PlaceSearchResults'
            // plain vertical list (unbounded height) — there, the card
            // silently rendered at zero height instead of throwing a
            // visible overflow error, making every place-search result
            // invisible despite the data being fetched correctly. Fixed
            // spacing works for both usages.
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 13, color: ccSecondaryText),
                const SizedBox(width: 4),
                // Neither this nor the price Text was ever bounded — with
                // both competing for a fixed 210px card width and only a
                // Spacer between them, a longer date/time string plus a
                // multi-digit price (e.g. "₦ 543600") reliably overflowed.
                // Expanded lets the date shrink/ellipsize first, so price
                // (the more important figure to a passenger) never gets
                // squeezed or clipped.
                Expanded(
                  child: Text(
                    "${ride.tripStartDate} · ${ride.tripStartTime}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CCText.labelSm.copyWith(color: ccSecondaryText),
                  ),
                ),
                if (ride.seatPrice.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    "$currency ${ride.seatPrice}",
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ccPrimary,
                    ),
                  ),
                ],
              ],
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
