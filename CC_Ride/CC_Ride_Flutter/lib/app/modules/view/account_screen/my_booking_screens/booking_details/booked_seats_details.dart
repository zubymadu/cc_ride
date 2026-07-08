import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/account_controllers/my_booking_controllers/booking_datails_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class BookedSeatsDetails extends GetView<BookingDatailsController> {
  const BookedSeatsDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final users =
        controller.bookTripDetailsApiModel!.tripData!.bookedUsers ?? [];
    final myId =
        num.parse("${getData.read("userLogin")["id"]}");

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
          const Text(
            "Booked Seats Details",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ccNavyText,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int index = 0; index < users.length; index++) ...[
                  if (users[index].userId! == myId) ...[
                    _SeatCard(
                      controller: controller,
                      index: index,
                      width: users.length <= 1
                          ? Get.width - 64
                          : Get.width - 80,
                    ),
                    if (index != users.length - 1) const SizedBox(width: 12),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatCard extends StatelessWidget {
  const _SeatCard({
    required this.controller,
    required this.index,
    required this.width,
  });
  final BookingDatailsController controller;
  final int index;
  final double width;

  Color _statusBg(String s) {
    switch (s) {
      case 'Pending':
        return const Color(0xFFFFFAEB);
      case 'Booked':
        return const Color(0xFFECFDF3);
      case 'Processing':
        return ccIceBlue;
      case 'Cancelled':
        return const Color(0xFFFEF3F2);
      default:
        return const Color(0xFFECFDF3);
    }
  }

  Color _statusText(String s) {
    switch (s) {
      case 'Pending':
        return const Color(0xFFDC6803);
      case 'Booked':
        return const Color(0xFF067647);
      case 'Processing':
        return const Color(0xFF0047C8);
      case 'Cancelled':
        return const Color(0xFFB42318);
      default:
        return const Color(0xFF2A7E3B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = controller.bookTripDetailsApiModel!.tripData!.bookedUsers!;
    final u = users[index];
    final bookStatus = "${u.bookStatus}";
    final hasPic = u.profilePic != null &&
        u.profilePic!.isNotEmpty &&
        u.profilePic != 'null';

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: ccBackground,
        borderRadius: BorderRadius.circular(CCRadius.card - 2),
        border: Border.all(color: ccInputBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Passenger badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: ccPrimary,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  "Passenger ${index + 1}",
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Avatar + name + status
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ccInputBorder, width: 1.5),
                  color: ccIceBlue,
                ),
                clipBehavior: Clip.antiAlias,
                child: hasPic
                    ? FadeInImage.assetNetwork(
                        placeholder:
                            "assets/image/ezgif.com-crop.gif",
                        image:
                            "${Confing.imageurl}${u.profilePic}",
                        fit: BoxFit.cover,
                        imageErrorBuilder: (_, __, ___) =>
                            Image.asset("assets/image/ezgif.com-crop.gif",
                                fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          u.userName != null && u.userName!.isNotEmpty
                              ? u.userName![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: ccPrimary),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${u.userName}",
                        style: CCText.titleMd,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusBg(bookStatus),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bookStatus,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _statusText(bookStatus),
                        ),
                      ),
                    ),
                    if (u.isRate != 0) ...[
                      const SizedBox(height: 4),
                      RatingBar(
                        initialRating:
                            double.parse("${u.totalRate}"),
                        minRating: 0,
                        allowHalfRating: true,
                        direction: Axis.horizontal,
                        itemCount: 5,
                        itemSize: 16,
                        glow: false,
                        ratingWidget: RatingWidget(
                          full: SvgPicture.asset(
                              "assets/image/svg/star-filled.svg",
                              colorFilter: const ColorFilter.mode(
                                  Color(0xFFF59E0B), BlendMode.srcIn)),
                          half: SvgPicture.asset(
                              "assets/image/svg/star-half.svg",
                              colorFilter: const ColorFilter.mode(
                                  Color(0xFFF59E0B), BlendMode.srcIn)),
                          empty: SvgPicture.asset(
                              "assets/image/svg/star.svg",
                              colorFilter: const ColorFilter.mode(
                                  ccInputBorder, BlendMode.srcIn)),
                        ),
                        ignoreGestures: true,
                        onRatingUpdate: (_) {},
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                "$currency${(num.parse("${u.totalAmount}") + num.parse("${u.wallAmt}")).toStringAsFixed(0)}",
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ccNavyText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: ccInputBorder, height: 1),
          const SizedBox(height: 12),

          // Price breakdown
          _row("Payment Method", "${u.paymentTitle}"),
          if (u.transactionId != null && u.transactionId!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _row("Transaction ID", "${u.transactionId}"),
          ],
          const SizedBox(height: 8),
          _row("Seats", "${u.totalSeat}"),
          const SizedBox(height: 8),
          _row(
              "Seat Price",
              "$currency${u.subtotal}",
              sub:
                  "(${u.totalSeat} × ${controller.bookTripDetailsApiModel!.tripData!.seatPrice})"),
          const SizedBox(height: 8),
          _row("Booking Fee", "+ $currency${u.bookingFees}"),
          if (u.couAmt != null && u.couAmt! > 0) ...[
            const SizedBox(height: 8),
            _row("Coupon", "- $currency${u.couAmt}",
                valueColor: ccSuccess),
          ],
          if (u.wallAmt != null && u.wallAmt! > 0) ...[
            const SizedBox(height: 8),
            _row("Wallet", "- $currency${u.wallAmt}",
                valueColor: ccSuccess),
          ],
          const SizedBox(height: 8),
          const Divider(color: ccInputBorder, height: 1),
          const SizedBox(height: 8),
          _row(
              "Total",
              "$currency${num.parse("${u.totalAmount}").toStringAsFixed(0)}",
              bold: true),

          // OTP boxes
          if (bookStatus == "Booked") ...[
            const SizedBox(height: 12),
            _OtpRow(title: "Pickup OTP", otp: "${u.pickupOtp}"),
          ],
          if (bookStatus == "Processing") ...[
            const SizedBox(height: 12),
            _OtpRow(title: "Drop OTP", otp: "${u.dropOtp}"),
          ],

          // Action buttons
          if (bookStatus != "Cancelled" && u.isRate == 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (bookStatus != "Completed" &&
                    u.isApprove != 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => makingPhoneCall(
                          number:
                              "${controller.bookTripDetailsApiModel!.tripData!.userMobile}"),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: ccInputBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(CCRadius.btn)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Call",
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ccNavyText)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (u.isApprove == 0) {
                        controller.cancelSeatBottomsheet(
                            bookid: "${u.bookId}");
                      } else {
                        if (bookStatus != "Completed") {
                          Get.toNamed(Routes.MESSAGE_SCREEN, arguments: {
                            "reciverId":
                                "${controller.bookTripDetailsApiModel!.tripData!.userId}",
                            "profilePic":
                                "${controller.bookTripDetailsApiModel!.tripData!.userProfile}",
                            "userName":
                                "${controller.bookTripDetailsApiModel!.tripData!.userTitle}",
                            "originAddress":
                                "${controller.bookTripDetailsApiModel!.tripData!.originAddress}",
                            "originLat":
                                "${controller.bookTripDetailsApiModel!.tripData!.originLat}",
                            "originLong":
                                "${controller.bookTripDetailsApiModel!.tripData!.originLong}",
                            "destiAddress":
                                "${controller.bookTripDetailsApiModel!.tripData!.destiAddress}",
                            "destiLat":
                                "${controller.bookTripDetailsApiModel!.tripData!.destiLat}",
                            "destiLong":
                                "${controller.bookTripDetailsApiModel!.tripData!.destiLong}",
                            "stopPoint": controller
                                .bookTripDetailsApiModel!
                                .tripData!
                                .stopsDetails,
                          });
                        } else {
                          controller.reviewcontroller.clear();
                          controller.update();
                          controller.bookSeatDetailsBottomsheet(
                              index: index);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          u.isApprove == 0 ? ccError : ccPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(CCRadius.btn)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      u.isApprove == 0
                          ? "Cancel"
                          : bookStatus != "Completed"
                              ? "Chat"
                              : "Review",
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Driver message
          if ("${u.driverAlertInfo}".isNotEmpty &&
              "${u.driverAlertInfo}" != "null") ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ccIceBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      color: ccPrimary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text("${u.driverAlertInfo}",
                        style: CCText.bodyMd
                            .copyWith(color: ccNavyText)),
                  ),
                ],
              ),
            ),
          ],

          // Approval message
          if ("${u.approvalMessage}".isNotEmpty &&
              "${u.approvalMessage}" != "") ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.schedule_rounded,
                      color: Color(0xFFB45309), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text("${u.approvalMessage}",
                        style: CCText.bodyMd.copyWith(
                            color: const Color(0xFF92400E))),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String title, String value,
      {String? sub, Color? valueColor, bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: CCText.bodyMd
                      .copyWith(color: ccSecondaryText)),
              if (sub != null)
                Text(sub,
                    style: CCText.labelSm
                        .copyWith(color: ccSecondaryText)),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight:
                bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? ccNavyText,
          ),
        ),
      ],
    );
  }
}

class _OtpRow extends StatelessWidget {
  const _OtpRow({required this.title, required this.otp});
  final String title;
  final String otp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ccIceBlue,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ccPrimary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ccNavyText,
                )),
          ),
          Row(
            children: [
              for (int i = 0; i < otp.length; i++) ...[
                Container(
                  width: 28,
                  height: 30,
                  decoration: BoxDecoration(
                    color: ccSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: ccPrimary, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      otp[i],
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ccPrimary,
                      ),
                    ),
                  ),
                ),
                if (i != otp.length - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

