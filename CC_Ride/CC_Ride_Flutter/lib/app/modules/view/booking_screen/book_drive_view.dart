import 'package:carride/app/data/confing.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/booking_controllers/book_drive_controller.dart';

class BookDriveView extends GetView<BookDriveController> {
  const BookDriveView({super.key});

  @override
  Widget build(BuildContext context) {
    final tripData = controller
        .tripPreviewScreenController.tripDetailsApiModel?.tripData;

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
          "Meet the Driver",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ccNavyText,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: ccInputBorder),
        ),
      ),
      bottomNavigationBar: Container(
        color: ccSurface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: CCButton(
          label: "View Pricing",
          onPressed: () => Get.toNamed(Routes.BOOK_PRICING),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Driver card ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ccSurface,
                borderRadius: BorderRadius.circular(CCRadius.card),
                boxShadow: CCShadow.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: ccInputBorder, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FadeInImage.assetNetwork(
                          placeholder: "assets/image/ezgif.com-crop.gif",
                          image:
                              "${Confing.imageurl}${tripData?.userProfile ?? ''}",
                          fit: BoxFit.cover,
                          imageErrorBuilder: (_, __, ___) => Image.asset(
                            "assets/image/ezgif.com-crop.gif",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${tripData?.userTitle ?? ''}",
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: ccNavyText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (tripData?.userJoined != null &&
                                tripData!.userJoined!.isNotEmpty)
                              Text(
                                "${"Joined".tr} ${DateFormat('MMMM yyyy').format(DateTime.parse(tripData.userJoined!))}",
                                style: CCText.bodyMd
                                    .copyWith(color: ccSecondaryText),
                              ),
                            const SizedBox(height: 4),
                            if (tripData?.userDob != null &&
                                tripData!.userDob!.isNotEmpty)
                              Text(
                                "${controller.calculateAge(tripData.userDob!)} ${"years old".tr}",
                                style: CCText.bodyMd
                                    .copyWith(color: ccSecondaryText),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (tripData?.userBio != null &&
                      tripData!.userBio!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: ccInputBorder,
                    ),
                    const SizedBox(height: 16),
                    const Text("Bio", style: CCText.titleMd),
                    const SizedBox(height: 8),
                    Text(
                      tripData.userBio!,
                      style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                    ),
                  ],
                ],
              ),
            ),

            // ── Vehicle card ───────────────────────────────────────────
            if (tripData?.vehicleImage?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ccSurface,
                  borderRadius: BorderRadius.circular(CCRadius.card),
                  boxShadow: CCShadow.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Vehicle", style: CCText.titleMd),
                    const SizedBox(height: 12),

                    // Vehicle image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(CCRadius.btn),
                      child: SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: FadeInImage.assetNetwork(
                          placeholder: "assets/image/ezgif.com-crop.gif",
                          image:
                              "${Confing.imageurl}${tripData!.vehicleImage}",
                          fit: BoxFit.cover,
                          imageErrorBuilder: (_, __, ___) => Image.asset(
                            "assets/image/ezgif.com-crop.gif",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      tripData.vehicleTitle ?? "",
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ccNavyText,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Vehicle details grid
                    Row(
                      children: [
                        Expanded(
                          child: _VehicleDetail(
                            icon: Icons.directions_car_rounded,
                            value:
                                "${tripData.year ?? ''} ${tripData.vehicleColor ?? ''}"
                                    .trim(),
                          ),
                        ),
                        Container(
                            width: 1,
                            height: 36,
                            color: ccInputBorder),
                        Expanded(
                          child: _VehicleDetail(
                            icon: Icons.category_rounded,
                            value: tripData.vehicleType ?? "",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _VehicleDetail(
                            icon: Icons.luggage_rounded,
                            value: tripData.luggageDetails ?? "",
                          ),
                        ),
                        Container(
                            width: 1,
                            height: 36,
                            color: ccInputBorder),
                        Expanded(
                          child: _VehicleDetail(
                            icon: Icons.airline_seat_recline_normal_rounded,
                            value: tripData.backrowDetails ?? "",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VehicleDetail extends StatelessWidget {
  const _VehicleDetail({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: ccPrimary, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(value,
                style: CCText.bodyMd.copyWith(color: ccNavyText),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
