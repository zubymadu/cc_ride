import 'package:carride/app/modules/view/post/ride_schedule/one_time_trip.dart';
import 'package:carride/app/modules/view/post/ride_schedule/recurring_trip.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/utils/string.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/post_controllers/ride_schedule_screen_controller.dart';

class RideScheduleScreenView extends GetView<RideScheduleScreenController> {
  const RideScheduleScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<RideScheduleScreenController>();
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
          "Post a Ride",
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
            if (Get.arguments != null) {
              if (c.leavingDateController.text.isNotEmpty &&
                  c.selectedTime != null) {
                Get.toNamed(Routes.VEHICLES_SCREEN,
                    arguments: Get.arguments);
              } else {
                showToastMessage(MyString.toastfill);
              }
            } else {
              if (c.postTripController.rideSchedule == "one_time") {
                if (c.showTextField) {
                  if (c.leavingDateController.text.isNotEmpty &&
                      c.selectedTime != null &&
                      c.returndateController.text.isNotEmpty &&
                      c.selectedTime1 != null) {
                    Get.toNamed(Routes.VEHICLES_SCREEN);
                  } else {
                    showToastMessage(MyString.toastfill);
                  }
                } else {
                  if (c.leavingDateController.text.isNotEmpty &&
                      c.selectedTime != null) {
                    Get.toNamed(Routes.VEHICLES_SCREEN);
                  } else {
                    showToastMessage(MyString.toastfill);
                  }
                }
              } else if (c.postTripController.rideSchedule == "recurring") {
                if (c.selectedDates.isNotEmpty &&
                    c.selectedTime != null &&
                    c.selectedTime1 != null) {
                  Get.toNamed(Routes.VEHICLES_SCREEN);
                } else {
                  showToastMessage(MyString.toastfill);
                }
              }
            }
          },
        ),
      ),
      body: GetBuilder<RideScheduleScreenController>(
        initState: (state) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            c.postTripController.returnTime = "";
            c.selectedTime1 = null;
            c.originTime1 = null;
            c.postTripController.returnDate = "";
            c.returndateController.clear();
            if (Get.arguments != null) {
              if (Get.arguments["start_date"] != null) {
                c.postTripController.startDate =
                    Get.arguments["start_date"].toString().split(" ").first;
                c.leavingDateController.text =
                    c.postTripController.startDate;
              }
              if (Get.arguments["start_time"] != null) {
                final rawTime = Get.arguments["start_time"].toString();
                c.postTripController.startTime = rawTime;
                c.selectedTime = c.parseTimeOfDay(rawTime);
              }
              c.postTripController.rideSchedule =
                  Get.arguments["ride_schedule"] ?? "one_time";
              c.update();
            }
          });
        },
        builder: (c) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Schedule type tabs (only when no edit arguments) ────
                if (Get.arguments == null) ...[
                  Container(
                    height: 48,
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
                      indicatorPadding: const EdgeInsets.all(4),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: ccSurface,
                      unselectedLabelColor: ccSecondaryText,
                      labelStyle: CCText.titleMd,
                      unselectedLabelStyle: CCText.bodyMd,
                      onTap: (value) {
                        c.postTripController.rideSchedule =
                            value == 0 ? "one_time" : "recurring";
                        c.leavingDateController.clear();
                        c.returndateController.clear();
                        c.selectedTime = null;
                        c.selectedTime1 = null;
                        c.selectedDates.clear();
                      },
                      tabs: [
                        for (int i = 0; i < c.tabText.length; i++)
                          Tab(text: "${c.tabText[i]}"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Edit-mode single departure card ─────────────────────
                if (Get.arguments != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ccSurface,
                      borderRadius: BorderRadius.circular(CCRadius.card),
                      boxShadow: CCShadow.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Departure",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ccNavyText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                readOnly: true,
                                controller: c.leavingDateController,
                                onTap: () => c
                                    .selectDate(
                                      context: context,
                                      initialDate: c.leavingDateController
                                              .text.isNotEmpty
                                          ? DateTime.parse(
                                              c.leavingDateController.text)
                                          : DateTime.now(),
                                    )
                                    .then((value) {
                                  if (value != null) {
                                    c.leavingDateController.text = value;
                                    c.postTripController.startDate = value;
                                  }
                                }),
                                style: const TextStyle(
                                    fontFamily: 'Inter', color: ccNavyText),
                                decoration: InputDecoration(
                                  hintText: 'Departure date',
                                  hintStyle: const TextStyle(
                                      fontFamily: 'Inter',
                                      color: ccSecondaryText),
                                  prefixIcon: const Icon(
                                      Icons.calendar_today_outlined,
                                      color: ccPrimary,
                                      size: 18),
                                  filled: true,
                                  fillColor: ccSurface,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        CCRadius.input),
                                    borderSide: const BorderSide(
                                        color: ccInputBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        CCRadius.input),
                                    borderSide: const BorderSide(
                                        color: ccInputBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        CCRadius.input),
                                    borderSide: const BorderSide(
                                        color: ccPrimary, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text("at",
                                  style: CCText.bodyMd
                                      .copyWith(color: ccSecondaryText)),
                            ),
                            Obx(() => c.selectTimeField(
                                  onTap: () {
                                    c.selectTime(context).then((value) {
                                      if (value != null) {
                                        final now = DateTime.now();
                                        c.selectedTime = value;
                                        // TimeOfDay.format(context) is
                                        // locale-dependent ("8:00 AM" on a
                                        // 12-hour device) — splitting off the
                                        // AM/PM marker silently drops it,
                                        // turning a 3 PM departure into 3 AM
                                        // once the backend parses it as a
                                        // bare 24-hour string. hour/minute
                                        // are always 24-hour internally, so
                                        // build the string from those instead.
                                        c.postTripController.startTime =
                                            '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
                                        c.originTime = DateTime(
                                            now.year,
                                            now.month,
                                            now.day,
                                            value.hour,
                                            value.minute);
                                        c.update();
                                      }
                                    });
                                  },
                                  time: c.selectedTime == null
                                      ? 'Time'
                                      : (c.selectedTime?.format(context) ??
                                          'Time'),
                                )),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  // ── Normal schedule tab views ─────────────────────────
                  Expanded(
                    child: TabBarView(
                      clipBehavior: Clip.none,
                      physics: const NeverScrollableScrollPhysics(),
                      controller: c.tabController,
                      children: const [OneTimeTrip(), RecurringTrip()],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
