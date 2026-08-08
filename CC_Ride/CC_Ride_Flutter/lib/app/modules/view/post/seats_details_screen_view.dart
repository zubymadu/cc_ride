import 'package:carride/utils/cc_ds.dart';
import 'package:carride/utils/string.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/post_controllers/post_trip_controller.dart';
import '../../controllers/post_controllers/seats_details_screen_controller.dart';

class SeatsDetailsScreenView extends GetView<SeatsDetailsScreenController> {
  const SeatsDetailsScreenView({super.key});

  @override
  Widget build(BuildContext context) {
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
          "Empty Seats",
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
        child: Obx(
          () => controller.postTripController.isLoading
              ? const SizedBox(
                  height: 52,
                  child: Center(
                    child: CircularProgressIndicator(color: ccPrimary),
                  ),
                )
              : CCButton(
                  label: "Post a Trip".tr,
                  icon: Icons.check_rounded,
                  onPressed: () {
                    if (controller.formKey.currentState!.validate() &&
                        controller.postTripController.totalSeat != "") {
                      if (Get.arguments != null) {
                        if (Get.arguments["trip_id"] != null) {
                          controller.postTripController
                              .editTripsApi(tripId: Get.arguments["trip_id"]);
                        } else {
                          controller.postTripController.posttripApi();
                        }
                      } else {
                        controller.postTripController.posttripApi();
                      }
                    } else {
                      showToastMessage(MyString.toastfill);
                    }
                  },
                ),
        ),
      ),
      body: GetBuilder<SeatsDetailsScreenController>(
        initState: (state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.arguments != null) {
              if (Get.arguments["seat_price"] != null) {
                controller.postTripController.seatPrice =
                    "${Get.arguments["seat_price"]}";
                controller.seatpricecontroller.text =
                    controller.postTripController.seatPrice;
              }
              controller.postTripController.totalSeat =
                  "${Get.arguments["total_seat"]}";
              if (Get.arguments["trip_description"] != null) {
                controller.postTripController.tripDescription =
                    "${Get.arguments["trip_description"]}";
                controller.tripdescriptioncontroller.text =
                    controller.postTripController.tripDescription;
              }
            } else {
              controller.postTripController.totalSeat = "";
              // Pool drivers have no price UI — onInit already set seatPrice
              // to "0" so the (hidden) field still passes validation. Wiping
              // it back to "" here raced with that and made every pool-driver
              // post-trip submission fail with "Required fields missing".
              if (!controller.isPoolDriverMode) {
                controller.postTripController.seatPrice = "";
              }
              controller.postTripController.tripDescription = "";
            }
            controller.update();
          });
        },
        builder: (_) => Form(
          key: controller.formKey,
          child: Obx(
            () => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Seat count ─────────────────────────────────────────
                  _SectionCard(
                    title: "Number of Available Seats",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select how many passengers can join your ride",
                          style:
                              CCText.bodyMd.copyWith(color: ccSecondaryText),
                        ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              for (int i = 1; i <= 12; i++) ...[
                                Obx(() {
                                  final sel = controller
                                          .postTripController.totalSeat ==
                                      i.toString();
                                  return GestureDetector(
                                    onTap: () => controller
                                        .postTripController.totalSeat =
                                        i.toString(),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: sel ? ccPrimary : ccSurface,
                                        border: Border.all(
                                          color: sel
                                              ? ccPrimary
                                              : ccInputBorder,
                                        ),
                                        boxShadow:
                                            sel ? CCShadow.card : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          i.toString(),
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: sel
                                                ? ccSurface
                                                : ccNavyText,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                if (i != 12) const SizedBox(width: 10),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Price per seat ─────────────────────────────────────
                  // A pool driver drives their organisation's car for
                  // organisation points, never cash — there's no
                  // passenger-facing price for them to see or set at all,
                  // only a behind-the-scenes computation for analytics.
                  if (!controller.isPoolDriverMode) ...[
                  _SectionCard(
                    title: "Price Per Seat",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GetBuilder<PostTripController>(
                          init: controller.postTripController,
                          builder: (postTripController) {
                            if (postTripController.isEstimating) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: ccPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Estimating a fair price…",
                                      style: CCText.labelSm
                                          .copyWith(color: ccSecondaryText),
                                    ),
                                  ],
                                ),
                              );
                            }
                            if (!postTripController.hasRouteEstimate) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: ccIceBlue,
                                borderRadius:
                                    BorderRadius.circular(CCRadius.input),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.auto_awesome_rounded,
                                      size: 16, color: ccPrimary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Suggested price: $currency${postTripController.routeEstimatedFare.toStringAsFixed(0)}"
                                      "${postTripController.routeDistanceKm > 0 ? ' · ${postTripController.routeDistanceKm.toStringAsFixed(1)} km' : ''}",
                                      style: CCText.labelSm.copyWith(
                                          color: ccNavyText,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      final suggested = postTripController
                                          .routeEstimatedFare
                                          .toStringAsFixed(0);
                                      controller.seatpricecontroller.text =
                                          suggested;
                                      postTripController.seatPrice =
                                          suggested;
                                      controller.update();
                                    },
                                    child: Text(
                                      "Use this".tr,
                                      style: CCText.labelSm.copyWith(
                                          color: ccPrimary,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        TextFormField(
                      controller: controller.seatpricecontroller,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price'.tr;
                        }
                        return null;
                      },
                      onChanged: (value) {
                        controller.postTripController.seatPrice = value;
                        controller.update();
                      },
                      style: const TextStyle(
                          fontFamily: 'Inter', color: ccNavyText),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: const TextStyle(
                            fontFamily: 'Inter', color: ccSecondaryText),
                        prefixIcon: SizedBox(
                          width: 44,
                          child: Center(
                            child: Text(
                              currency,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                color: ccNavyText,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 44),
                        filled: true,
                        fillColor: ccBackground,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(CCRadius.input),
                          borderSide: const BorderSide(color: ccInputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(CCRadius.input),
                          borderSide: const BorderSide(color: ccInputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(CCRadius.input),
                          borderSide: const BorderSide(
                              color: ccPrimary, width: 1.5),
                        ),
                      ),
                    ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  ],

                  // ── Route preview + description ────────────────────────
                  _SectionCard(
                    title: "Route & Description",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < 2; i++) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ccIceBlue,
                                ),
                                child: Icon(
                                  i == 0
                                      ? Icons.my_location_rounded
                                      : Icons.flag_rounded,
                                  color: i == 0 ? ccPrimary : ccNavyText,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      i == 0
                                          ? controller.postTripController
                                              .originAddress
                                          : controller.postTripController
                                              .destiAddress,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: CCText.bodyMd,
                                    ),
                                    Text(
                                      i == 0
                                          ? "Pickup point"
                                          : "Destination",
                                      style: CCText.labelSm
                                          .copyWith(color: ccSecondaryText),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (i == 0) ...[
                            for (int si = 0;
                                si <
                                    controller.postTripController.stopData
                                        .length;
                                si++) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 17),
                                child: SizedBox(
                                  width: 2,
                                  height: 36,
                                  child: controller.buildDashedLine(),
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFFFEBEE),
                                    ),
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: Color(0xFFEA4335),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          controller.postTripController
                                              .stopData[si]["stop_address"],
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: CCText.bodyMd,
                                        ),
                                        Text(
                                          "Stop ${si + 1}",
                                          style: CCText.labelSm.copyWith(
                                              color: ccSecondaryText),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                          if (i != 1)
                            Padding(
                              padding: const EdgeInsets.only(left: 17),
                              child: SizedBox(
                                width: 2,
                                height: 36,
                                child: controller.buildDashedLine(),
                              ),
                            ),
                        ],

                        const SizedBox(height: 14),
                        const Divider(color: ccInputBorder, height: 1),
                        const SizedBox(height: 14),

                        Obx(() {
                          if (!controller.hasEstimate) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: ccIceBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    color: ccPrimary, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${"Platform-suggested fare".tr}: $currency${controller.estimatedFare.toStringAsFixed(0)} ${"per seat — you can still set your own".tr}",
                                    style: CCText.bodyMd
                                        .copyWith(color: ccPrimary),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: controller.tripdescriptioncontroller,
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Description cannot be empty'.tr;
                            }
                            return null;
                          },
                          onChanged: (value) {
                            controller.postTripController.tripDescription =
                                value;
                            controller.update();
                          },
                          style: const TextStyle(
                              fontFamily: 'Inter', color: ccNavyText),
                          decoration: InputDecoration(
                            hintText:
                                'We recommend writing the exact pick-up and drop-off locations in your description'
                                    .tr,
                            hintStyle: const TextStyle(
                                fontFamily: 'Inter',
                                color: ccSecondaryText,
                                fontSize: 13),
                            filled: true,
                            fillColor: ccBackground,
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(CCRadius.input),
                              borderSide:
                                  const BorderSide(color: ccInputBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(CCRadius.input),
                              borderSide:
                                  const BorderSide(color: ccInputBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(CCRadius.input),
                              borderSide: const BorderSide(
                                  color: ccPrimary, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
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
          Text(title, style: CCText.titleMd),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
