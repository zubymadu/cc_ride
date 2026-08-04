// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/models/map_api_model.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/textfield/suggestion_testfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../controllers/search_controllers/search_screen_controller.dart';

class TripPlanScreenView extends StatelessWidget {
  const TripPlanScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ccBackground,
      appBar: AppBar(
        backgroundColor: ccBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
          onPressed: () => Get.back(),
        ),
      ),
      body: GetBuilder<SearchScreenController>(
        builder: (c) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Let's plan your next trip",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: ccNavyText,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              _OriginDestinationCard(controller: c),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _PickerField(
                      label: "Departure date",
                      icon: Icons.calendar_today_rounded,
                      value: DateFormat('EEE, d MMM').format(c.departureDateTime),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: c.departureDateTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          c.departureDateTime = DateTime(
                            picked.year, picked.month, picked.day,
                            c.departureDateTime.hour, c.departureDateTime.minute,
                          );
                          c.update();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerField(
                      label: "Departure time",
                      icon: Icons.access_time_rounded,
                      value: DateFormat('h:mm a').format(c.departureDateTime),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(c.departureDateTime),
                        );
                        if (picked != null) {
                          c.departureDateTime = DateTime(
                            c.departureDateTime.year, c.departureDateTime.month,
                            c.departureDateTime.day, picked.hour, picked.minute,
                          );
                          c.update();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: ccInputBorder, height: 32),
              _ToggleRow(
                title: "Enable Return trip",
                subtitle: "Coming back too? Switch this on.",
                value: c.returnTripEnabled,
                onChanged: (v) {
                  c.returnTripEnabled = v;
                  c.returnDateTime = v
                      ? c.departureDateTime.add(const Duration(hours: 8))
                      : null;
                  c.update();
                },
              ),
              if (c.returnTripEnabled) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PickerField(
                        label: "Return date",
                        icon: Icons.calendar_today_rounded,
                        value: DateFormat('EEE, d MMM').format(
                            c.returnDateTime ?? c.departureDateTime),
                        onTap: () async {
                          final base = c.returnDateTime ?? c.departureDateTime;
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: base,
                            firstDate: c.departureDateTime,
                            lastDate: DateTime.now().add(const Duration(days: 120)),
                          );
                          if (picked != null) {
                            c.returnDateTime = DateTime(
                              picked.year, picked.month, picked.day,
                              base.hour, base.minute,
                            );
                            c.update();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PickerField(
                        label: "Return time",
                        icon: Icons.access_time_rounded,
                        value: DateFormat('h:mm a').format(
                            c.returnDateTime ?? c.departureDateTime),
                        onTap: () async {
                          final base = c.returnDateTime ?? c.departureDateTime;
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(base),
                          );
                          if (picked != null) {
                            c.returnDateTime = DateTime(
                              base.year, base.month, base.day,
                              picked.hour, picked.minute,
                            );
                            c.update();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              _ToggleRow(
                title: "Subscribe to route",
                subtitle: 'Toggle ON the "Subscribe to route" button',
                value: c.subscribeToRoute,
                onChanged: (v) {
                  c.subscribeToRoute = v;
                  c.update();
                },
              ),
              GestureDetector(
                onTap: () => _showSubscribeInfo(context),
                child: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    "More info",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: ccPrimary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              c.isSearch
                  ? const SizedBox(
                      height: 52,
                      child: Center(child: CircularProgressIndicator(color: ccPrimary)),
                    )
                  : CCButton(
                      label: "Find your ride",
                      onPressed: () => _findRide(c),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubscribeInfo(BuildContext context) {
    Get.bottomSheet(
      backgroundColor: ccSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(CCRadius.sheet)),
      ),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Subscribe to route",
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: ccNavyText)),
            const SizedBox(height: 10),
            Text(
              "We'll post this trip as a standing request. Nearby drivers get "
              "notified right away, and if one posts a matching ride later, "
              "you'll be notified too — even if nothing's available yet.",
              style: CCText.bodyMd.copyWith(color: ccSecondaryText),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _findRide(SearchScreenController c) {
    if (c.destinationLat.isEmpty) {
      showToastMessage("Please enter a destination");
      return;
    }
    if (c.originLat.isEmpty) {
      showToastMessage("Please enter a pickup location");
      return;
    }
    if (c.isSearch) return;
    c.isSearch = true;
    c.update();

    // "Subscribe to route" posts a standing request up front (nearby drivers
    // are notified immediately, same as the auto-queue path when a search
    // comes up empty) — reuses the existing trip-request infrastructure
    // rather than inventing a separate subscription mechanism.
    if (c.subscribeToRoute) {
      _postStandingRequest(c);
    }

    c.findTripController
        .findtripApi(
      originLat: c.originLat,
      originLong: c.originLong,
      destinationLat: c.destinationLat,
      destinationLong: c.destinationLong,
      originAddress: c.originController.text,
      destinationAddress: c.destinationController.text,
      tripDate: c.tripDate,
      status: 'All',
    )
        .then((response) {
      c.isSearch = false;
      c.update();
      if (response is Map && response['auto_queued'] == true) {
        showToastMessage(
            "No matching route yet — we've notified nearby drivers of your request");
      }
      Get.toNamed(Routes.SEARCH_RESULTS_SCREEN, arguments: {
        "originLat": c.originLat,
        "originLong": c.originLong,
        "destinationLat": c.destinationLat,
        "destinationLong": c.destinationLong,
        "tripDate": c.tripDate,
        "initialTab": 0,
      });
    });
  }

  Future<void> _postStandingRequest(SearchScreenController c) async {
    try {
      final url = Confing.baseurl + Confing.tripRequest;
      await http.post(
        Uri.parse(url),
        headers: {
          "Content-type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer ${getData.read('token') ?? ''}",
        },
        body: jsonEncode({
          "from_address": c.originController.text,
          "from_lat": c.originLat,
          "from_long": c.originLong,
          "to_address": c.destinationController.text,
          "to_lat": c.destinationLat,
          "to_long": c.destinationLong,
          "departure_date": c.tripDate,
          "seat_require": "1",
          "trip_description": "Subscribed via trip planner",
        }),
      );
    } catch (_) {
      // Best-effort — the main search still proceeds either way.
    }
  }
}

// ── Origin / Destination card ─────────────────────────────────────────────────

class _OriginDestinationCard extends StatelessWidget {
  const _OriginDestinationCard({required this.controller});
  final SearchScreenController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: ccSurface,
        borderRadius: BorderRadius.circular(CCRadius.card),
        border: Border.all(color: ccInputBorder),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _LocationRow(
                icon: Icons.trip_origin_rounded,
                iconColor: ccSuccess,
                controller: controller.originController,
                hint: "Pickup location",
                onClear: () {
                  controller.originController.clear();
                  controller.originLat = "";
                  controller.originLong = "";
                  controller.update();
                },
                onSelected: (result) => _applySelection(
                  controller: controller,
                  textController: controller.originController,
                  result: result,
                  isOrigin: true,
                ),
              ),
              const Divider(color: ccInputBorder, height: 1),
              _LocationRow(
                icon: Icons.location_on_rounded,
                iconColor: ccPrimary,
                controller: controller.destinationController,
                hint: "Destination",
                onClear: () {
                  controller.destinationController.clear();
                  controller.destinationLat = "";
                  controller.destinationLong = "";
                  controller.update();
                },
                onSelected: (result) => _applySelection(
                  controller: controller,
                  textController: controller.destinationController,
                  result: result,
                  isOrigin: false,
                ),
              ),
            ],
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  controller.swapLocations();
                  controller.update();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: ccNavyText,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.swap_vert_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applySelection({
    required SearchScreenController controller,
    required TextEditingController textController,
    required Result result,
    required bool isOrigin,
  }) {
    if (result.geometry?.location?.lat == null ||
        result.geometry?.location?.lng == null) {
      return;
    }
    final lat = result.geometry!.location!.lat!;
    final lng = result.geometry!.location!.lng!;
    textController.text =
        result.name == null ? "${result.formattedAddress}" : "${result.name}";
    if (isOrigin) {
      controller.originLat = lat.toStringAsFixed(4);
      controller.originLong = lng.toStringAsFixed(4);
    } else {
      controller.destinationLat = lat.toStringAsFixed(4);
      controller.destinationLong = lng.toStringAsFixed(4);
    }
    controller.update();
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.iconColor,
    required this.controller,
    required this.hint,
    required this.onClear,
    required this.onSelected,
  });

  final IconData icon;
  final Color iconColor;
  final TextEditingController controller;
  final String hint;
  final VoidCallback onClear;
  final void Function(Result) onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: suggestionsTextField(
        controller: controller,
        builder: (context, ctrl, focusNode) {
          return SizedBox(
            height: 52,
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    focusNode: focusNode,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: ccNavyText,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: ccSecondaryText,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (ctrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: onClear,
                    child: Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(right: 36),
                      decoration: const BoxDecoration(
                        color: ccNavyText,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
          );
        },
        onSelected: onSelected,
        suggestionsCallback: (pattern) async {
          if (pattern.trim().isEmpty) return [];
          final mapSuggetionControlle =
              Get.find<SearchScreenController>().mapSuggetionControlle;
          await mapSuggetionControlle.mapApi(suggestkey: pattern);
          return mapSuggetionControlle.mapApiModel?.results ?? [];
        },
      ),
    );
  }
}

// ── Date / time picker field ────────────────────────────────────────────────

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ccSecondaryText)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: ccSurface,
              borderRadius: BorderRadius.circular(CCRadius.input),
              border: Border.all(color: ccInputBorder),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: ccSecondaryText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: ccNavyText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Toggle row ───────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: ccNavyText)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: CCText.bodyMd.copyWith(color: ccSecondaryText)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: ccPrimary,
        ),
      ],
    );
  }
}
