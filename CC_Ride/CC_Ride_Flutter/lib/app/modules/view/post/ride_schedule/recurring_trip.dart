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
                        controller.postTripController.startDate =
                            controller.selectedDates
                                .map((date) =>
                                    dateFormat.format(date))
                                .join(',');
                        controller.postTripController.returnDate =
                            controller.selectedDates
                                .map((date) =>
                                    dateFormat.format(date))
                                .join(',');
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
                                  controller.postTripController
                                          .startTime =
                                      picked
                                          .format(context)
                                          .toString()
                                          .split(' ')
                                          .first;
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
                                controller.postTripController
                                        .returnTime =
                                    picked
                                        .format(context)
                                        .toString()
                                        .split(' ')
                                        .first;
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
