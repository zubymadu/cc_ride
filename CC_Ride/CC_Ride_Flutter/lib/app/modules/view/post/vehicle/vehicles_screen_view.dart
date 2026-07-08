import 'package:carride/app/modules/view/post/vehicle/vehicle.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/utils/string.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/post_controllers/vehicles_screen_controller.dart';

class VehiclesScreenView extends GetView<VehiclesScreenController> {
  const VehiclesScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<VehiclesScreenController>();
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
          "Vehicle & Preferences",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ccNavyText,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: ccInputBorder),
        ),
      ),
      bottomNavigationBar: Container(
        color: ccSurface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: CCButton(
          label: "Next",
          icon: Icons.arrow_forward_rounded,
          onPressed: () {
            if (c.postTripController.skipVehicle == "0" &&
                c.postTripController.vehicleId == "") {
              showToastMessage("Please add a vehicle first!".tr);
            } else {
              if (c.skipVehicle) {
                if (c.postTripController.luggageId.isNotEmpty &&
                    c.postTripController.backRowId.isNotEmpty &&
                    c.restrictionList.isNotEmpty) {
                  Get.toNamed(Routes.SEATS_DETAILS_SCREEN,
                      arguments: Get.arguments);
                } else {
                  showToastMessage(MyString.toastfill);
                }
              } else {
                if (c.postTripController.vehicleId.isNotEmpty &&
                    c.postTripController.luggageId.isNotEmpty &&
                    c.postTripController.backRowId.isNotEmpty &&
                    c.restrictionList.isNotEmpty) {
                  Get.toNamed(Routes.SEATS_DETAILS_SCREEN,
                      arguments: Get.arguments);
                } else {
                  showToastMessage(MyString.toastfill);
                }
              }
            }
          },
        ),
      ),
      body: GetBuilder<VehiclesScreenController>(
        initState: (state) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            c.fetchData();
          });
        },
        builder: (_) {
          return Obx(
            () => c.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: ccPrimary))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // ── Vehicle section ──────────────────────────
                        _Card(
                          title: "Your Vehicle",
                          subtitle:
                              "Help riders recognize your car and set trip expectations.",
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hide vehicle toggle
                              Row(
                                children: [
                                  Obx(() => Checkbox(
                                        checkColor: ccSurface,
                                        activeColor: ccPrimary,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        side: const BorderSide(
                                            color: ccInputBorder),
                                        value: c.skipVehicle,
                                        onChanged: (v) {
                                          c.skipVehicle = v!;
                                          c.update();
                                          if (c.skipVehicle) {
                                            c.postTripController
                                                .skipVehicle = "1";
                                            c.postTripController
                                                .vehicleId = "";
                                          } else {
                                            c.selectedIndex = 0;
                                            c.postTripController
                                                .skipVehicle = "0";
                                            c.postTripController
                                                    .vehicleId =
                                                "${c.dataGetApiModel!.vehicleData!.first.id}";
                                          }
                                        },
                                      )),
                                  const SizedBox(width: 4),
                                  const Expanded(
                                    child: Text(
                                      "Hide vehicle details from passengers",
                                      style: CCText.bodyMd,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Obx(
                                () => c.skipVehicle == false
                                    ? const Vehicle()
                                    : Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: ccIceBlue,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                                Icons
                                                    .visibility_off_rounded,
                                                color: ccSecondaryText,
                                                size: 18),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "No vehicle will be shown on your trip",
                                                style: CCText.bodyMd,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Preferences section ──────────────────────
                        _Card(
                          title: "Passenger & Luggage Preferences",
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Luggage size
                              const Text("Luggage Size",
                                  style: CCText.titleMd),
                              const SizedBox(height: 10),
                              _SegmentedPicker(
                                items: c.dataGetApiModel!.luggageData!
                                    .map((l) => "${l.title}")
                                    .toList(),
                                selectedId:
                                    c.postTripController.luggageId,
                                ids: c.dataGetApiModel!.luggageData!
                                    .map((l) => "${l.id}")
                                    .toList(),
                                onSelect: (id) {
                                  c.postTripController.luggageId = id;
                                  c.update();
                                },
                              ),

                              const SizedBox(height: 16),

                              // Back seat capacity
                              const Text("Back Seat Capacity",
                                  style: CCText.titleMd),
                              const SizedBox(height: 10),
                              _SegmentedPicker(
                                items: c.dataGetApiModel!.backSeatingData!
                                    .map((b) => "${b.title}")
                                    .toList(),
                                selectedId:
                                    c.postTripController.backRowId,
                                ids: c.dataGetApiModel!.backSeatingData!
                                    .map((b) => "${b.id}")
                                    .toList(),
                                onSelect: (id) {
                                  c.postTripController.backRowId = id;
                                  c.update();
                                },
                              ),

                              const SizedBox(height: 16),

                              // Restrictions
                              const Text("Other Options",
                                  style: CCText.titleMd),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final r in c.dataGetApiModel!
                                      .restrictionData!) ...[
                                    GestureDetector(
                                      onTap: () {
                                        if (c.restrictionList
                                            .contains(r.id)) {
                                          c.restrictionList.remove(r.id);
                                        } else {
                                          c.restrictionList.add(r.id);
                                        }
                                        c.postTripController
                                                .restrictionList =
                                            c.restrictionList.join(", ");
                                        c.update();
                                      },
                                      child: Obx(() {
                                        final sel = c.restrictionList
                                            .contains(r.id);
                                        return Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 7),
                                          decoration: BoxDecoration(
                                            color: sel
                                                ? ccPrimary
                                                : ccSurface,
                                            borderRadius:
                                                BorderRadius.circular(99),
                                            border: Border.all(
                                              color: sel
                                                  ? ccPrimary
                                                  : ccInputBorder,
                                            ),
                                          ),
                                          child: Text(
                                            "${r.title}",
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: sel
                                                  ? ccSurface
                                                  : ccNavyText,
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, this.subtitle, required this.child});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ccSurface,
        borderRadius: BorderRadius.circular(CCRadius.card),
        boxShadow: CCShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ccNavyText,
              )),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: CCText.bodyMd.copyWith(color: ccSecondaryText)),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SegmentedPicker extends StatelessWidget {
  const _SegmentedPicker({
    required this.items,
    required this.ids,
    required this.selectedId,
    required this.onSelect,
  });
  final List<String> items;
  final List<String> ids;
  final String selectedId;
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: ccInputBorder),
        borderRadius: BorderRadius.circular(CCRadius.btn),
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(
              flex: i == 0 ? 10 : 4,
              child: GestureDetector(
                onTap: () => onSelect(ids[i]),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selectedId == ids[i]
                        ? ccPrimary
                        : Colors.transparent,
                    borderRadius: BorderRadius.horizontal(
                      left: i == 0
                          ? const Radius.circular(CCRadius.btn - 1)
                          : Radius.zero,
                      right: i == items.length - 1
                          ? const Radius.circular(CCRadius.btn - 1)
                          : Radius.zero,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      items[i],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selectedId == ids[i]
                            ? ccSurface
                            : ccSecondaryText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (i < items.length - 1)
              Container(
                  width: 1, height: 36, color: ccInputBorder),
          ],
        ],
      ),
    );
  }
}
