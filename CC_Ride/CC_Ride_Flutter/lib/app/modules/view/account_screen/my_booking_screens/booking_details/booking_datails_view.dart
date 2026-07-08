import 'package:carride/app/modules/view/account_screen/my_booking_screens/booking_details/booked_seats_details.dart';
import 'package:carride/app/modules/view/account_screen/my_booking_screens/booking_details/book_car_information.dart';
import 'package:carride/app/modules/view/account_screen/my_booking_screens/booking_details/popular_car_facilities.dart';
import 'package:carride/app/modules/view/account_screen/my_booking_screens/booking_details/routes_details.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../../controllers/account_controllers/my_booking_controllers/booking_datails_controller.dart';

class BookingDatailsView extends GetView<BookingDatailsController> {
  const BookingDatailsView({super.key});

  static Color _statusColor(String? status) {
    switch (status) {
      case 'On Route':
        return ccPrimary;
      case 'Completed':
        return ccSuccess;
      default:
        return const Color(0xFFB45309);
    }
  }

  static Color _statusBg(String? status) {
    switch (status) {
      case 'On Route':
        return ccIceBlue;
      case 'Completed':
        return ccSuccessLight;
      default:
        return const Color(0xFFFFFBEB);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BookingDatailsController>(
      initState: (state) {
        controller.bookTripDetailsApi(
          ownerId: "${Get.arguments["owner_id"]}",
          tripId: "${Get.arguments["trip_id"]}",
        ).then((value) {
          if (value != null) {
            controller.setTripData(controller.bookTripDetailsApiModel!.tripData!);
            controller.update();
          }
        });
      },
      builder: (controller) {
        return Stack(
          children: [
            RefreshIndicator(
              color: ccPrimary,
              onRefresh: () {
                return Future.delayed(const Duration(seconds: 2), () {
                  controller.bookTripDetailsApi(
                    ownerId: "${Get.arguments["owner_id"]}",
                    tripId: "${Get.arguments["trip_id"]}",
                  ).then((value) {
                    if (value != null) {
                      controller.setTripData(controller.bookTripDetailsApiModel!.tripData!);
                      controller.update();
                    }
                  });
                });
              },
              child: Scaffold(
                backgroundColor: ccBackground,
                appBar: AppBar(
                  backgroundColor: ccSurface,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
                    onPressed: () => Get.back(),
                  ),
                  title: const Text(
                    "Booking Details",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: ccNavyText,
                    ),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () => Get.toNamed(Routes.HELP_SCREEN),
                      icon: const Icon(Icons.help_outline_rounded, color: ccSecondaryText),
                    ),
                  ],
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(1),
                    child: Divider(height: 1, color: ccInputBorder),
                  ),
                ),
                body: Obx(
                  () => controller.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: ccPrimary))
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              // ── Status banner ──────────────────────────────
                              _StatusBanner(controller: controller),
                              const SizedBox(height: 12),

                              // ── Content cards ──────────────────────────────
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                child: Column(
                                  children: [
                                    const BookedSeatsDetails(),
                                    const SizedBox(height: 12),
                                    const RoutesDetails(),
                                    const SizedBox(height: 12),
                                    if (controller.bookTripDetailsApiModel!
                                            .tripData!.vehicleImage!
                                            .isNotEmpty) ...[
                                      const BookCarInformation(),
                                      const SizedBox(height: 12),
                                    ],
                                    const PopularCarFacilities(),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            if (controller.isCancelLoading)
              Container(
                color: Colors.black.withOpacity(0.35),
                width: Get.width,
                height: Get.height,
                child: Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: ccSurface,
                    size: 32,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.controller});
  final BookingDatailsController controller;

  @override
  Widget build(BuildContext context) {
    final status =
        controller.bookTripDetailsApiModel!.tripData!.tripStatus ?? '';
    final col = BookingDatailsView._statusColor(status);
    final bg = BookingDatailsView._statusBg(status);

    String formattedDate = '';
    try {
      final raw =
          '${controller.bookTripDetailsApiModel!.tripData!.tripStartDate!.toIso8601String().split('T').first} ${controller.bookTripDetailsApiModel!.tripData!.tripStartTime}';
      formattedDate =
          DateFormat("EEE, MMM d 'at' h:mma").format(DateTime.parse(raw));
    } catch (_) {}

    IconData icon;
    switch (status) {
      case 'On Route':
        icon = Icons.directions_car_rounded;
        break;
      case 'Completed':
        icon = Icons.check_circle_outline_rounded;
        break;
      default:
        icon = Icons.schedule_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: col.withOpacity(0.2), width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: col.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: col, size: 28),
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: col.withOpacity(0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: col,
              ),
            ),
          ),
          if (formattedDate.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              formattedDate,
              style: CCText.bodyMd.copyWith(color: ccSecondaryText),
            ),
          ],
        ],
      ),
    );
  }
}
