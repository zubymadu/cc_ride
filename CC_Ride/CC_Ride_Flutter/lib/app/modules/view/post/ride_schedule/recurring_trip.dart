// ignore_for_file: deprecated_member_use

import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../../controllers/post_controllers/ride_schedule_screen_controller.dart';

class RecurringTrip extends GetView<RideScheduleScreenController> {
  const RecurringTrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 50),
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ccBackground,
            borderRadius: BorderRadius.circular(CCRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select dates',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: ccNavyText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your trip repeats every day starting from the earliest date you pick — tap any date to set that start.',
                style: CCText.bodyMd.copyWith(color: ccSecondaryText),
              ),
              const SizedBox(height: 10),
              Container(
                width: Get.width / 1.2,
                decoration: BoxDecoration(
                  border: Border.all(color: ccInputBorder),
                  borderRadius: BorderRadius.circular(CCRadius.card),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(CCRadius.card),
                  child: SfDateRangePicker(
                    selectionMode:
                        DateRangePickerSelectionMode.multiple,
                    enablePastDates: false,
                    selectionColor: ccPrimary,
                    selectionShape:
                        DateRangePickerSelectionShape.rectangle,
                    headerStyle: const DateRangePickerHeaderStyle(
                      textAlign: TextAlign.center,
                      textStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: ccNavyText,
                      ),
                    ),
                    selectionTextStyle: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                    showNavigationArrow: true,
                    monthCellStyle: const DateRangePickerMonthCellStyle(
                      textStyle: TextStyle(
                        color: ccNavyText,
                        fontFamily: 'Inter',
                      ),
                      todayTextStyle: TextStyle(
                        color: ccPrimary,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                      todayCellDecoration: BoxDecoration(
                        color: ccIceBlue,
                        borderRadius:
                            BorderRadius.all(Radius.circular(10)),
                        border: Border.fromBorderSide(
                            BorderSide(color: ccPrimary)),
                      ),
                      disabledDatesTextStyle: TextStyle(
                        color: ccSecondaryText,
                        fontFamily: 'Inter',
                      ),
                    ),
                    monthViewSettings: const DateRangePickerMonthViewSettings(
                      viewHeaderStyle: DateRangePickerViewHeaderStyle(
                        textStyle: TextStyle(
                          color: ccSecondaryText,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      dayFormat: 'EEE',
                    ),
                    onSelectionChanged: (args) {
                      final selected = args.value as List<DateTime>;
                      controller.selectedDates = selected;
                      if (selected.isNotEmpty) {
                        selected.sort((a, b) => a.compareTo(b));
                        final dateFormat = DateFormat('yyyy-MM-dd');
                        // The backend's recurring model is "starts on one
                        // date, repeats every day indefinitely from there"
                        // (scheduleType: recurring_daily — see
                        // materializeRecurringRidesForDate) — it has no
                        // concept of specific non-consecutive dates. Sending
                        // the full comma-joined selection here used to feed
                        // straight into the backend's `new Date(...)` call
                        // and produce an Invalid Date, silently corrupting
                        // every recurring trip with more than one date
                        // picked. Only the earliest date is actually
                        // meaningful to the backend.
                        final anchor = dateFormat.format(controller.selectedDates.first);
                        controller.postTripController.startDate = anchor;
                        controller.postTripController.returnDate = anchor;
                      } else {
                        controller.postTripController.startDate = '';
                        controller.postTripController.returnDate = '';
                      }
                      controller.update();
                    },
                    initialSelectedRange: PickerDateRange(
                      DateTime.now(),
                      DateTime.now().add(const Duration(days: 3)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Leaving at',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: ccSecondaryText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        controller.selectTimeField(
                          width: Get.width / 2.8,
                          onTap: () {
                            controller
                                .selectTime(context)
                                .then((value) {
                              if (value != null) {
                                final picked = value;
                                if (picked != controller.selectedTime) {
                                  final now = DateTime.now();
                                  controller.selectedTime = picked;
                                  // hour/minute are always 24-hour
                                  // internally — format(context) is
                                  // locale-dependent and splitting off the
                                  // AM/PM marker silently produces the
                                  // wrong time.
                                  controller.postTripController
                                          .startTime =
                                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                  controller.originTime = DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                      picked.hour,
                                      picked.minute);
                                  controller.update();
                                }
                              }
                            });
                          },
                          time: controller.selectedTime == null
                              ? 'Time'.tr
                              : (controller.selectedTime
                                      ?.format(context) ??
                                  'Time'.tr),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'Returning at'.tr} ${'(same day)'.tr}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: ccSecondaryText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        controller.selectTimeField(
                          width: Get.width / 2.8,
                          onTap: () {
                            controller
                                .selectTime(context)
                                .then((value) {
                              if (value != null) {
                                final picked = value;
                                final now = DateTime.now();
                                controller.selectedTime1 = picked;
                                // Same fix as departure time above.
                                controller.postTripController
                                        .returnTime =
                                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                controller.originTime1 = DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                    picked.hour,
                                    picked.minute);
                                controller.update();
                              }
                            });
                          },
                          time: controller.selectedTime == null
                              ? 'Time'.tr
                              : controller.selectedTime1
                                      ?.format(context) ??
                                  'Time'.tr,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
