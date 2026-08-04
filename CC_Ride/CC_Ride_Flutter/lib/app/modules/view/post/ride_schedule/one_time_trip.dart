// ignore_for_file: deprecated_member_use

import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../controllers/post_controllers/ride_schedule_screen_controller.dart';

class OneTimeTrip extends GetView<RideScheduleScreenController> {
  const OneTimeTrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
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
                'Leaving',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: ccNavyText,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: controller.leavingDateController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date'.tr;
                        }
                        return null;
                      },
                      onTap: () => controller
                          .selectDate(
                            context: context,
                            initialDate: DateTime.now(),
                          )
                          .then((value) {
                        if (value != null) {
                          controller.leavingDateController.text = value;
                          controller.postTripController.startDate = value;
                        } else {
                          if (controller
                              .leavingDateController.text.isEmpty) {
                            showToastMessage('Date not Select.'.tr);
                          }
                        }
                      }),
                      style: const TextStyle(
                          fontFamily: 'Inter', color: ccNavyText),
                      decoration: InputDecoration(
                        hintText: 'Departure date'.tr,
                        hintStyle: const TextStyle(
                            fontFamily: 'Inter', color: ccSecondaryText),
                        prefixIcon: const Icon(Icons.calendar_today_rounded,
                            color: ccSecondaryText, size: 20),
                        filled: true,
                        fillColor: ccSurface,
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
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'at',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: ccSecondaryText,
                      ),
                    ),
                  ),
                  controller.selectTimeField(
                    onTap: () {
                      controller.selectTime(context).then((value) {
                        if (value != null) {
                          final picked = value;
                          if (picked != controller.selectedTime) {
                            final now = DateTime.now();
                            controller.selectedTime = picked;
                            // hour/minute are always 24-hour internally —
                            // don't use format(context) here, it's
                            // locale-dependent and splitting off the AM/PM
                            // marker silently produces the wrong time.
                            controller.postTripController.startTime =
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
                        : (controller.selectedTime?.format(context) ??
                            'Time'.tr),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              if (!controller.showTextField) ...[
                InkWell(
                  onTap: () {
                    controller.showTextField = true;
                    controller.update();
                  },
                  child: const Text(
                    'Add return trip',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      decorationColor: ccSecondaryText,
                      fontSize: 16,
                      color: ccSecondaryText,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (controller.showTextField) ...[
                const Text(
                  'Returning',
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    color: ccNavyText,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        controller: controller.returndateController,
                        onTap: () => controller
                            .selectDate(
                              context: context,
                              initialDate: DateTime.now(),
                            )
                            .then((value) {
                          controller.postTripController.returnDate = value;
                          controller.returndateController.text = value;
                          controller.update();
                        }),
                        style: const TextStyle(
                            fontFamily: 'Inter', color: ccNavyText),
                        decoration: InputDecoration(
                          hintText: 'Return date'.tr,
                          hintStyle: const TextStyle(
                              fontFamily: 'Inter', color: ccSecondaryText),
                          prefixIcon: const Icon(Icons.calendar_today_rounded,
                              color: ccSecondaryText, size: 20),
                          filled: true,
                          fillColor: ccSurface,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
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
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'at',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: ccSecondaryText,
                        ),
                      ),
                    ),
                    controller.selectTimeField(
                      onTap: () {
                        controller.selectTime(context).then((value) {
                          if (value != null) {
                            final picked = value;
                            final now = DateTime.now();
                            controller.selectedTime1 = picked;
                            // Same fix as departure time above — build from
                            // hour/minute, not the locale-dependent
                            // format(context) string.
                            controller.postTripController.returnTime =
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
                    const SizedBox(width: 5),
                    InkWell(
                      onTap: () {
                        controller.showTextField = false;
                        controller.selectedTime1 = null;
                        controller.postTripController.returnTime = '';
                        controller.originTime1 = null;
                        controller.postTripController.returnDate = '';
                        controller.returndateController.clear();
                        controller.update();
                      },
                      child: SvgPicture.asset(
                        'assets/image/svg/times-circle.svg',
                        color: ccSecondaryText,
                        height: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
