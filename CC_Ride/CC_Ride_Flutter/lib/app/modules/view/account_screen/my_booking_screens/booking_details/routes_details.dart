import 'package:carride/app/data/confing.dart';
import 'package:carride/app/modules/controllers/account_controllers/my_booking_controllers/booking_datails_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class RoutesDetails extends GetView<BookingDatailsController> {
  const RoutesDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final trip = controller.bookTripDetailsApiModel!.tripData!;
    final stops = trip.stopsDetails ?? [];

    String formattedStart = '';
    try {
      final raw =
          '${trip.tripStartDate!.toIso8601String().split('T').first} ${trip.tripStartTime}';
      formattedStart =
          DateFormat("EEE, MMM d 'at' h:mma").format(DateTime.parse(raw));
    } catch (_) {}

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
          // ── Origin ────────────────────────────────────────────────────
          _StopRow(
            icon: Icons.my_location_rounded,
            iconColor: ccPrimary,
            label: trip.originAddress?.split(",").first ?? '',
            sub: formattedStart,
            tag: "Pickup point",
            trailing: Text(
              "$currency ${trip.seatPrice}",
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ccNavyText,
              ),
            ),
          ),

          // ── Intermediate stops ────────────────────────────────────────
          for (int si = 0; si < stops.length; si++) ...[
            _DashedLine(),
            _StopRow(
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFFEA4335),
              label: stops[si].location?.split(",").first ?? '',
              sub: controller.tripStopPointTime.length > si
                  ? controller.tripStopPointTime[si]
                  : '',
              tag: "Stop ${si + 1}",
            ),
          ],

          // ── Destination ───────────────────────────────────────────────
          _DashedLine(),
          _StopRow(
            icon: Icons.flag_rounded,
            iconColor: ccNavyText,
            label: trip.destiAddress?.split(",").first ?? '',
            sub: controller.tripEndTime.value,
            tag: "Destination",
            trailing: trip.tripIsReturn != "0"
                ? InkWell(
                    onTap: () => Get.toNamed(Routes.TRIP_PREVIEW_SCREEN,
                        arguments: {
                          "tripId": "${trip.tripIsReturn}",
                          "findtrip": true,
                        }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: ccIceBlue,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: ccPrimary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swap_horiz_rounded,
                              color: ccPrimary, size: 16),
                          const SizedBox(width: 4),
                          const Text("Return",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ccPrimary,
                              )),
                        ],
                      ),
                    ),
                  )
                : null,
          ),

          const SizedBox(height: 12),
          const Divider(color: ccInputBorder, height: 1),
          const SizedBox(height: 12),

          // ── Driver row ────────────────────────────────────────────────
          InkWell(
            onTap: () => Get.toNamed(Routes.PROFILE_SCREEN,
                arguments: trip.userId),
            borderRadius: BorderRadius.circular(CCRadius.card),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ccIceBlue,
                    border: Border.all(color: ccInputBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: trip.userProfile != null &&
                          trip.userProfile!.isNotEmpty
                      ? FadeInImage.assetNetwork(
                          placeholder: "assets/image/ezgif.com-crop.gif",
                          image:
                              "${Confing.imageurl}${trip.userProfile}",
                          fit: BoxFit.cover,
                          imageErrorBuilder: (_, __, ___) => Image.asset(
                              "assets/image/ezgif.com-crop.gif",
                              fit: BoxFit.cover),
                        )
                      : const Center(
                          child: Icon(Icons.person_rounded,
                              color: ccPrimary, size: 22),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${trip.userTitle}",
                          style: CCText.titleMd,
                          overflow: TextOverflow.ellipsis),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 4),
                          Text("${trip.avgRating}",
                              style: CCText.bodyMd),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                                color: ccSecondaryText,
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "${trip.kmShared}km driven",
                              style: CCText.bodyMd
                                  .copyWith(color: ccSecondaryText),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: ccInputBorder),
                  ),
                  child: const Text(
                    "Profile",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ccNavyText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sub,
    required this.tag,
    this.trailing,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sub;
  final String tag;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconColor.withOpacity(0.1),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(label,
                  style: CCText.titleMd,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (sub.isNotEmpty)
                Text(sub,
                    style:
                        CCText.bodyMd.copyWith(color: ccSecondaryText)),
              Text(tag,
                  style: CCText.labelSm
                      .copyWith(color: ccSecondaryText)),
              const SizedBox(height: 4),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

class _DashedLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 40,
      child: CustomPaint(painter: _DashedPainter()),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ccInputBorder
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashH = 4.0;
    const gap = 3.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(20, y), Offset(20, y + dashH), paint);
      y += dashH + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
