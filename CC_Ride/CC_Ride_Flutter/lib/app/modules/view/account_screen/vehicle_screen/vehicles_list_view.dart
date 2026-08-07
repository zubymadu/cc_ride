import 'package:carride/app/data/confing.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/account_controllers/profile_controllers/vehicle_controllers/vehicles_list_controller.dart';

class VehiclesListView extends GetView<VehiclesListController> {
  const VehiclesListView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<VehiclesListController>();
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
          "My Vehicles",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ccNavyText,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: ccSecondaryText),
            onPressed: () => Get.toNamed(Routes.HELP_SCREEN),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: ccInputBorder),
        ),
      ),
      bottomNavigationBar: Container(
        color: ccSurface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: CCButton(
          label: "Add a Vehicle".tr,
          icon: Icons.add_rounded,
          onPressed: () => Get.toNamed(
            Routes.ADD_VEHICLE_SCREEN,
            arguments: {"vehicle": true},
          ),
        ),
      ),
      body: Obx(
        () => c.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ccPrimary))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Your Vehicles", style: CCText.headlineMd),
                    const SizedBox(height: 4),
                    Text(
                      "Manage your vehicle information",
                      style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                    ),
                    const SizedBox(height: 16),
                    c.vehicleListApiModel!.vehicleData!.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: const BoxDecoration(
                                      color: ccIceBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.directions_car_rounded,
                                        color: ccPrimary,
                                        size: 36),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text("No vehicles yet",
                                      style: CCText.headlineMd),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Add your first vehicle to start posting trips.".tr,
                                    textAlign: TextAlign.center,
                                    style: CCText.bodyMd
                                        .copyWith(color: ccSecondaryText),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Expanded(
                            child: ListView.separated(
                              itemCount:
                                  c.vehicleListApiModel!.vehicleData!.length,
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final v = c.vehicleListApiModel!
                                    .vehicleData![index];
                                final editArgs = {
                                  "id": v.id,
                                  "photo":
                                      "${Confing.imageurl}${v.photo}",
                                  "modelId": v.modelId,
                                  "typeId": v.typeId,
                                  "colorId": v.colorId,
                                  "year": v.year,
                                  "licensePlate": v.licensePlate,
                                  "model": v.modelTitle,
                                  "type": v.typeTitle,
                                  "color": v.colorTitle,
                                  "vehicle": true,
                                  "isedit": true,
                                };
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: ccSurface,
                                    borderRadius: BorderRadius.circular(
                                        CCRadius.card),
                                    boxShadow: CCShadow.card,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ── Vehicle info ──────────────────
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // modelTitle had no overflow
                                            // guard at all — a long vehicle
                                            // model name would wrap onto
                                            // multiple lines instead of
                                            // truncating, pushing the rest of
                                            // the card's content down out of
                                            // alignment with the fixed
                                            // 90x90 photo beside it (the
                                            // "doesn't render well" symptom).
                                            Text(
                                              "${v.modelTitle}",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: CCText.titleMd,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${v.year} · ${v.colorTitle} · ${v.typeTitle}",
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: CCText.bodyMd.copyWith(
                                                  color: ccSecondaryText),
                                            ),
                                            const SizedBox(height: 10),
                                            // Approved badge
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: ccSuccessLight,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        99),
                                              ),
                                              child: Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                      Icons
                                                          .check_circle_rounded,
                                                      color: ccSuccess,
                                                      size: 14),
                                                  const SizedBox(width: 4),
                                                  const Text(
                                                    "Approved",
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: ccSuccess,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            OutlinedButton(
                                              onPressed: () =>
                                                  Get.toNamed(
                                                Routes.ADD_VEHICLE_SCREEN,
                                                arguments: editArgs,
                                              ),
                                              style:
                                                  OutlinedButton.styleFrom(
                                                foregroundColor: ccPrimary,
                                                side: const BorderSide(
                                                    color: ccPrimary),
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          CCRadius.btn),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 8),
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: const Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.edit_rounded,
                                                      size: 14),
                                                  SizedBox(width: 6),
                                                  Text("Edit Details"),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // ── Vehicle photo ─────────────────
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: FadeInImage.assetNetwork(
                                          height: 90,
                                          width: 90,
                                          fit: BoxFit.cover,
                                          placeholder:
                                              "assets/image/ezgif.com-crop.gif",
                                          placeholderFit: BoxFit.cover,
                                          image:
                                              "${Confing.imageurl}${v.photo}",
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
      ),
    );
  }
}
