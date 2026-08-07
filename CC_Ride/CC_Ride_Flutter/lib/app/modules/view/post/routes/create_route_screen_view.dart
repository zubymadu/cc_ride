import 'package:carride/app/modules/models/map_api_model.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/textfield/custom_text_field.dart';
import 'package:carride/widgets/textfield/suggestion_testfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/post_controllers/create_route_controller.dart';

class CreateRouteScreenView extends GetView<CreateRouteController> {
  const CreateRouteScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get.put() unconditionally here would recreate the controller (and its
    // TextEditingControllers/MapSuggetionControlle) on every rebuild of this
    // widget — wiping the origin/destination text, any selected coordinates,
    // and the day/vehicle selections mid-interaction. Same bug class as
    // bottom_bar_screen_view.dart earlier this session; reuse the existing
    // instance instead of recreating it — UNLESS we're arriving with fresh
    // arguments (edit an existing route, or adopt a suggested corridor).
    // onInit() only ever runs once per instance, so reusing a stale
    // controller here would silently skip the new pre-fill entirely.
    if (Get.arguments != null && Get.isRegistered<CreateRouteController>()) {
      Get.delete<CreateRouteController>();
    }
    final c = Get.isRegistered<CreateRouteController>()
        ? Get.find<CreateRouteController>()
        : Get.put(CreateRouteController());
    final isEditing = c.editRouteId != null;
    return Scaffold(
      backgroundColor: ccBackground,
      appBar: AppBar(
        backgroundColor: ccSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
          onPressed: () {
            Get.delete<CreateRouteController>();
            Get.back();
          },
        ),
        title: Text(
          isEditing ? "Edit Route" : "Create a Route",
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ccNavyText,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: ccSurface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Obx(() => CCButton(
              label: isEditing ? "Save Changes" : "Publish Route",
              icon: isEditing ? Icons.check_rounded : Icons.route_rounded,
              loading: c.isSubmitting.value,
              onPressed: () async {
                final ok = await c.submit();
                if (ok) {
                  Get.delete<CreateRouteController>();
                  Get.back(result: true);
                }
              },
            )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing
                  ? "Update your route's details below."
                  : "Publish a route you regularly drive so passengers can find and book it directly.",
              style: const TextStyle(
                fontFamily: 'Inter',
                color: ccSecondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            suggestionsTextField(
              controller: c.originController,
              title: "Origin",
              builder: (context, ctrl, focusNode) => customTextFormField(
                hintText: "Where does the route start?",
                controller: ctrl,
                focusNode: focusNode,
                prefixIcon: const Icon(Icons.trip_origin_rounded,
                    color: ccSuccess, size: 20),
              ),
              suggestionsCallback: (pattern) async {
                if (pattern.trim().isEmpty) return [];
                await c.mapSuggetionControlle.mapApi(suggestkey: pattern);
                return c.mapSuggetionControlle.mapApiModel?.results ?? [];
              },
              onSelected: (Result result) {
                if (result.geometry?.location?.lat == null ||
                    result.geometry?.location?.lng == null) {
                  return;
                }
                c.setOrigin(
                  address: result.name ?? "${result.formattedAddress}",
                  lat: result.geometry!.location!.lat!,
                  long: result.geometry!.location!.lng!,
                );
              },
            ),
            const SizedBox(height: 14),

            suggestionsTextField(
              controller: c.destinationController,
              title: "Destination",
              builder: (context, ctrl, focusNode) => customTextFormField(
                hintText: "Where does the route end?",
                controller: ctrl,
                focusNode: focusNode,
                prefixIcon: const Icon(Icons.location_on_rounded,
                    color: ccPrimary, size: 20),
              ),
              suggestionsCallback: (pattern) async {
                if (pattern.trim().isEmpty) return [];
                await c.mapSuggetionControlle.mapApi(suggestkey: pattern);
                return c.mapSuggetionControlle.mapApiModel?.results ?? [];
              },
              onSelected: (Result result) {
                if (result.geometry?.location?.lat == null ||
                    result.geometry?.location?.lng == null) {
                  return;
                }
                c.setDestination(
                  address: result.name ?? "${result.formattedAddress}",
                  lat: result.geometry!.location!.lat!,
                  long: result.geometry!.location!.lng!,
                );
              },
            ),

            const SizedBox(height: 20),
            const Text("Days you drive this route",
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    color: ccNavyText)),
            const SizedBox(height: 10),
            Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < CreateRouteController.dayLabels.length; i++)
                      GestureDetector(
                        // Backend daysOfWeek is 0=Sun..6=Sat (JS convention);
                        // dayLabels displays Mon-first for a natural weekly
                        // reading order, so the stored value is offset by one.
                        onTap: () => c.toggleDay((i + 1) % 7),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: c.selectedDays.contains((i + 1) % 7)
                                ? ccPrimary
                                : ccSurface,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: c.selectedDays.contains((i + 1) % 7)
                                  ? ccPrimary
                                  : ccInputBorder,
                            ),
                          ),
                          child: Text(
                            CreateRouteController.dayLabels[i],
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: c.selectedDays.contains((i + 1) % 7)
                                  ? ccSurface
                                  : ccNavyText,
                            ),
                          ),
                        ),
                      ),
                  ],
                )),

            const SizedBox(height: 20),
            const Text("Departure time",
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    color: ccNavyText)),
            const SizedBox(height: 10),
            Obx(() => GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: c.departureTime.value,
                    );
                    if (picked != null) c.departureTime.value = picked;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: ccSurface,
                      borderRadius: BorderRadius.circular(CCRadius.input),
                      border: Border.all(color: ccInputBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 18, color: ccSecondaryText),
                        const SizedBox(width: 8),
                        Text(
                          c.departureTime.value.format(context),
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: ccNavyText),
                        ),
                      ],
                    ),
                  ),
                )),

            const SizedBox(height: 20),
            Obx(() {
              // A pool driver drives their organisation's car for
              // organisation points, never cash — no passenger-facing price
              // for them to see or set, only a behind-the-scenes
              // computation for analytics.
              if (c.isPoolDriverMode.value) {
                return customTextFormField(
                  hintText: "Seats",
                  title: "Seat capacity",
                  controller: c.seatController,
                  keyboardType: TextInputType.number,
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: customTextFormField(
                      hintText: "Seats",
                      title: "Seat capacity",
                      controller: c.seatController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: customTextFormField(
                      hintText: "0.00",
                      title: "Seat price",
                      controller: c.fareController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              );
            }),

            Obx(() {
              if (c.isPoolDriverMode.value || !c.hasEstimate.value) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: ccIceBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: ccPrimary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${"Platform-suggested fare".tr}: $currency${c.estimatedFare.value.toStringAsFixed(0)} ${"per seat — you can still set your own".tr}",
                          style: CCText.bodyMd.copyWith(color: ccPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),
            const Text("Vehicle",
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    color: ccNavyText)),
            const SizedBox(height: 10),
            Obx(() {
              if (c.isLoading.value) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(color: ccPrimary),
                ));
              }
              if (c.vehicles.isEmpty) {
                return Text(
                  c.isPoolDriverMode.value
                      ? "No pool vehicle assigned to you yet."
                      : "No approved vehicle on your account yet.",
                  style: const TextStyle(
                      fontFamily: 'Inter', color: ccSecondaryText),
                );
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: ccSurface,
                  borderRadius: BorderRadius.circular(CCRadius.input),
                  border: Border.all(color: ccInputBorder),
                ),
                child: DropdownButton<String>(
                  value: c.selectedVehicleId.value,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: c.vehicles
                      .map((v) => DropdownMenuItem(
                            value: v['id'],
                            child: Text(v['title'] ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => c.selectedVehicleId.value = v,
                ),
              );
            }),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ccSurface,
                borderRadius: BorderRadius.circular(CCRadius.card),
                border: Border.all(color: ccInputBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Manually approve requests",
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                color: ccNavyText)),
                        const SizedBox(height: 2),
                        const Text(
                          "Off: bookings confirm instantly. On: you review and confirm/decline each request from My Routes.",
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: ccSecondaryText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Obx(() => Switch(
                        value: c.manualApproval.value,
                        activeThumbColor: ccPrimary,
                        onChanged: (v) => c.manualApproval.value = v,
                      )),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Obx(() {
              if (c.nearbyRequests.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nearby passenger requests",
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          color: ccNavyText)),
                  const SizedBox(height: 4),
                  const Text(
                    "For your information only — publishing this route won't automatically match these.",
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: ccSecondaryText),
                  ),
                  const SizedBox(height: 10),
                  for (final r in c.nearbyRequests)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ccSurface,
                        borderRadius: BorderRadius.circular(CCRadius.card),
                        border: Border.all(color: ccInputBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${r.fromAddress.split(',').first} → ${r.toAddress.split(',').first}",
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                color: ccNavyText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${r.userTitle} • ${r.seatRequire} seat(s)",
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: ccSecondaryText),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
