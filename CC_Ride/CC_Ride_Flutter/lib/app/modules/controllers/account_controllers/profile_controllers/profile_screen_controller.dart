// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/account_controllers/profile_controllers/verification_controllers/email_varification_controller.dart';
import 'package:carride/app/modules/controllers/account_controllers/profile_controllers/verification_controllers/mobile_varification_controller.dart';
import 'package:carride/app/modules/models/user_profile_api_model.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ProfileScreenController extends GetxController {
  EmailVarificationController emailVarificationController = Get.put(EmailVarificationController());
  MobileVarificationController mobileVarificationController = Get.put(MobileVarificationController());

  @override
  void onInit() {
    debugPrint("---------- User Data ---------- ${getData.read("userLogin")}");
    debugPrint("---------- arguments ---------- ${Get.arguments}");
    userProfileApi();
    super.onInit();
  }

  final RxList _lifetimeText = [
    "People driven",
    "Average Rating",
    "Rides taken",
    "KM Shared",
  ].obs;
  List get lifetimeText => _lifetimeText;
  set lifetimeText(List value) => _lifetimeText.value = value;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  final RxInt _currentIndex = 0.obs;
  int get currentIndex => _currentIndex.value;
  set currentIndex(int value) => _currentIndex.value = value;

  UserProfileApiModel? userProfileApiModel;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  Future userProfileApi() async {
    isLoading = true;
    update();
    Map body = {
      "uid": Get.arguments ?? "${getData.read("userLogin")["id"]}",
    };

    try {
      String url = Confing.baseurl + Confing.userProfile;

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      ).timeout(const Duration(seconds: 15));

      log(name: "============= User Profile Api url ==============", url);
      log(name: "============= User Profile Api body =============", "$body");
      log(name: "=========== User Profile Api response ===========", response.body);

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          userProfileApiModel = userProfileApiModelFromJson(response.body);
          update();
          if (userProfileApiModel!.result == "true") {
            isLoading = false;
            update();
            return data;
          } else {
            showToastMessage("${userProfileApiModel!.responseMsg}");
            return data;
          }
        } else {
          showToastMessage("${data["ResponseMsg"]}");
          return data;
        }
      } else {
        showToastMessage("Somthing went wrong!.....");
      }
    } catch (e) {
      log("============= User Profile Api Error =============  $e");
    } finally {
      isLoading = false;
      update();
    }
  }

  titles({
    required String title,
    required VoidCallback onTap,
    bool? showTitle,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: ccNavyText,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          if(showTitle == true)
          InkWell(
            onTap: onTap,
            child: Text(
              "View All",
              style: TextStyle(
                color: greenColor,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDashedLine() {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Column(
        children: List.generate(
          4,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: Container(width: 2, height: 4, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  viewAllReviewBottomsheet() {
    Get.bottomSheet(
      enableDrag: false,
      isDismissible: false,
      isScrollControlled: true,
      Container(
        decoration: BoxDecoration(color: ccBackground),
        child: Column(
          children: [
            SizedBox(height: 45),
            Expanded(
              child: Scaffold(
                appBar: AppBar(title: Text("Driver review".tr)),
                body: ListView.separated(
                  itemCount: userProfileApiModel!.reviews!.length,
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  physics: BouncingScrollPhysics(),
                  separatorBuilder: (BuildContext context, int index) => SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    return reviewData(review: userProfileApiModel!.reviews![index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  reviewData({required Review review}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ccBackground,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: review.profilePic == null || review.profilePic!.isEmpty
                      ? Border.all(color: ccNavyText, width: 2)
                      : Border(),
                ),
                child: review.profilePic == null || review.profilePic!.isEmpty
                    ? Center(
                        child: Text(
                          review.name![0].toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: ccNavyText,
                          ),
                        ),
                      )
                    : ClipOval(
                        child: FadeInImage.assetNetwork(
                          placeholder: "assets/image/ezgif.com-crop.gif",
                          image: "${Confing.imageurl}${review.profilePic}",
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) => Image.asset("assets/image/ezgif.com-crop.gif", fit: BoxFit.cover),
                        ),
                      ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${review.name}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: ccNavyText,
                      ),
                    ),
                    RatingBar(
                      initialRating: double.parse("${review.totalRate}"),
                      minRating: 0,
                      allowHalfRating: true,
                      direction: Axis.horizontal,
                      itemCount: 5,
                      itemSize: 20,
                      glow: false,
                      ratingWidget: RatingWidget(
                        full: SvgPicture.asset(
                          "assets/image/svg/star-filled.svg",
                          color: yellowColor,
                        ),
                        half: SvgPicture.asset(
                          "assets/image/svg/star-half.svg",
                          color: yellowColor,
                        ),
                        empty: SvgPicture.asset(
                          "assets/image/svg/star.svg",
                          color: yellowColor,
                        ),
                      ),
                      ignoreGestures: true,
                      onRatingUpdate: (rating) {},
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Text(
            "${review.rateDesc}",
            style: TextStyle(
              color: ccSecondaryText,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  upcomingTripBottomsheet() {
    Get.bottomSheet(
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      Container(
        decoration: BoxDecoration(color: ccSurface,),
        child: Column(
          children: [
            SizedBox(height: 45),
            Expanded(
              child: Scaffold(
                backgroundColor: ccSurface,
                appBar: AppBar(
                  backgroundColor: ccSurface,
                  title: Text("Upcoming Trips".tr),
                  centerTitle: true,
                ),
                body: ListView.separated(
                  itemCount: userProfileApiModel!.upcomingTrips!.length,
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  physics: BouncingScrollPhysics(),
                  separatorBuilder: (BuildContext context, int index) => SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    return upcomingTripData(upcomingTrip: userProfileApiModel!.upcomingTrips![index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  upcomingTripData({required UpcomingTrip upcomingTrip}) {
    return InkWell(
      onTap: () {
        Get.back(); // Close the bottom sheet first
        if (Get.arguments == null) {
          Get.toNamed(
            Routes.TRIP_PREVIEW_SCREEN,
            arguments: {
              "tripId" : "${upcomingTrip.tripId}",
            },
          );
        } else {
          if (getData.read("userLogin") == null) {
            Get.toNamed(
              Routes.TRIP_PREVIEW_SCREEN,
              arguments: {
                "tripId" : "${upcomingTrip.tripId}",
                "findtrip": true,
              },
            );
          } else {
            if (Get.arguments == "${getData.read("userLogin")["id"]}") {
              Get.toNamed(
                Routes.TRIP_PREVIEW_SCREEN,
                arguments: {
                  "tripId" : "${upcomingTrip.tripId}",
                },
              );
            } else {
              Get.toNamed(
                Routes.TRIP_PREVIEW_SCREEN,
                arguments: {
                  "tripId" : "${upcomingTrip.tripId}",
                  "findtrip": true,
                },
              );
            }
          }
        }
      },
      child: Container(
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: ccBackground,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for(int i = 0; i < 2; i++)...[
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ccInputBorder),
                    ),
                    child: SvgPicture.asset(
                      i == 0
                        ? "assets/image/svg/arrow-down-circle-filled.svg"
                        : "assets/image/svg/locationpinfilled.svg",
                      color: i == 0 ? primaryColor : ccNavyText,
                      height: 28,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                i == 0
                                  ? upcomingTrip.originAddress!.split(",").first
                                  : upcomingTrip.destiAddress!.split(",").first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ccNavyText,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (i == 0)...[
                              SizedBox(width: 5),
                              Text(
                                "$currency ${upcomingTrip.seatPrice}",
                                style: TextStyle(
                                  color: ccNavyText,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if(i == 0)...[
                          SizedBox(height: 3),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "${upcomingTrip.startTime}",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: ccSecondaryText,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              SizedBox(width: 5),
                              Text(
                                "${upcomingTrip.totalSeat} Seats",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: 3),
                        Text(
                          i == 0 ? "Pickup point" : "Destination",
                          style: TextStyle(
                            color: ccSecondaryText,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if(i != 2 - 1)
              SizedBox(
                width: 55,
                child: buildDashedLine(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  final List<GlobalKey> buttonKey = List.generate(2, (_) => GlobalKey());

  OverlayEntry? overlayEntry;
  final RxBool tooltipVisible = false.obs;

  void toggleTooltip(BuildContext context) {
    tooltipVisible.value ? hideTooltip() : showTooltip(context);
  }

  void showTooltip(BuildContext context) {
    if (buttonKey[1].currentContext == null) return;

    final RenderBox renderBox = buttonKey[1].currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: hideTooltip,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            left: position.dy - 100,
            top: position.dy - 55,
            child: Material(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ccNavyText,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Verified email & phone number",
                      style: TextStyle(
                        color: ccBackground,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 53),
                    child: CustomPaint(
                      painter: DownwardTrianglePainter(),
                      child: const SizedBox(width: 15, height: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(overlayEntry!);
    tooltipVisible.value = true;
  }

  void hideTooltip() {
    overlayEntry?.remove();
    overlayEntry = null;
    tooltipVisible.value = false;
    update();
  }

  @override
  void onClose() {
    hideTooltip();
    super.onClose();
  }
}

class DownwardTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Color(0xFF1E1E1E);

    final path = Path();
    path.moveTo(size.width / 2, size.height);   // Bottom center
    path.lineTo(0, 0);                          // Top left
    path.lineTo(size.width, 0);                 // Top right
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
