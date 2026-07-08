// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:carride/app/modules/controllers/find_trip_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../data/confing.dart';

class SearchResultsScreenController extends GetxController with GetSingleTickerProviderStateMixin {

  late TabController tabController = TabController(length: 3, vsync: this);

  // final _isLoading = true.obs;
  // get isLoading => _isLoading.value;
  // set isLoading(value) => _isLoading.value = value;

  final _currentPage = 0.obs;
  get currentPage => _currentPage.value;
  set currentPage(value) => _currentPage.value = value;

  @override
  void onInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("---------- Get.arguments ---------- ${Get.arguments}");
      debugPrint("------------ originLat ------------ ${Get.arguments["originLat"]}");
      debugPrint("------------ originLong ----------- ${Get.arguments["originLong"]}");
      debugPrint("---------- destinationLat --------- ${Get.arguments["destinationLat"]}");
      debugPrint("--------- destinationLong --------- ${Get.arguments["destinationLong"]}");
      debugPrint("------------- tripDate ------------ ${Get.arguments["tripDate"]}");
      findTripController.allIsLoading = false;
      update();
      findTripController.findtripApi(
        originLat: "${Get.arguments["originLat"]}",
        originLong: "${Get.arguments["originLong"]}",
        destinationLat: "${Get.arguments["destinationLat"]}",
        destinationLong: "${Get.arguments["destinationLong"]}",
        tripDate: "${Get.arguments["tripDate"]}",
        status: "All",
      ).then((value) {
        findTripController.allIsLoading = false;
        update();
      });
      super.onInit();
    });
  }

  FindTripController findTripController = Get.put(FindTripController());

  final RxList _tabText = ["All", "Trips", "Request"].obs;
  List get tabText => _tabText;
  set tabText(List value) => _tabText.value = value;

  Widget findTripDetailsData({
    required VoidCallback onTap,
    required List date,
    required List addresstype,
    required List address,
    required String profilePic,
    required String seatPrice,
    required String totalSeat,
    required String profileName,
    required String tripIsReturn,
    required String totalRate,
    required String totalDriven,
  }) {
    List image = [
      "assets/image/svg/arrow-down-circle-filled.svg",
      "assets/image/svg/locationpinfilled.svg",
    ];
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: ccBackground,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for(int i = 0; i < address.length; i++)...[
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: ccInputBorder),
                        ),
                        child: SvgPicture.asset(
                          image[i],
                          color: i == 0 ? ccPrimary : ccNavyText,
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
                                    address[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: ccNavyText,
                                      fontFamily: 'Inter', fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (i == 0)...[
                                  SizedBox(width: 5),
                                  Text(
                                    "$currency $seatPrice",
                                    style: TextStyle(
                                      color: ccNavyText,
                                      fontFamily: 'Inter', fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            i == 0
                              ? SizedBox(height: 3)
                              : SizedBox(),
                            Row(
                              children: [
                                i == 0
                                    ? Expanded(
                                        child: Text(
                                          date[i],
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: ccSecondaryText,
                                            fontFamily: 'Inter', fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      )
                                    : SizedBox(),
                                if (i == 0)...[
                                  SizedBox(width: 5),
                                  Text(
                                    "$totalSeat Seats",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontFamily: 'Inter', fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 3),
                            Text(
                              i == 0 ? "Pickup point" : "Destination",
                              style: TextStyle(
                                color: ccSecondaryText,
                                fontFamily: 'Inter', fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if(i != 0)
                      if(tripIsReturn != "0")
                      SvgPicture.asset(
                        "assets/image/svg/returenarrow.svg",
                        color: ccNavyText,
                        height: 20,
                      ),
                    ],
                  ),
                  if(i != address.length - 1)
                  SizedBox(
                    width: 55,
                    child: buildDashedLine(),
                  ),
                ],
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Divider(color: ccInputBorder, thickness: 1),
            ),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ccIceBlue,
                  ),
                  child: profilePic.isEmpty
                    ? Center(
                        child: SvgPicture.asset(
                          "assets/image/svg/user-filled.svg",
                          color: ccNavyText,
                        ),
                      )
                    : ClipOval(
                        child: FadeInImage.assetNetwork(
                          placeholder: "assets/image/ezgif.com-crop.gif",
                          image: "${Confing.imageurl}$profilePic",
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
                        profileName,
                        style: TextStyle(
                          color: ccNavyText,
                          fontFamily: 'Inter', fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          SvgPicture.asset(
                            "assets/image/svg/star-filled.svg",
                            height: 20,
                            color: yellowColor,
                          ),
                          SizedBox(width: 5),
                          Text(
                            totalRate,
                            style: TextStyle(
                              color: ccNavyText,
                              fontFamily: 'Inter', fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 7),
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: ccNavyText,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            "$totalDriven km driven",
                            style: TextStyle(
                              color: ccNavyText,
                              fontFamily: 'Inter', fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget findRequestDetailsData({
    required VoidCallback onTap,
    required String date,
    required List address,
    required String profilePic,
    required String totalSeat,
    required String profileName,
    required String totalRate,
    required String ridesTaken,
  }) {
    List image = [
      "assets/image/svg/arrow-down-circle-filled.svg",
      "assets/image/svg/locationpinfilled.svg",
    ];
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: ccBackground,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for(int i = 0; i < address.length; i++)...[
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: ccInputBorder),
                        ),
                        child: SvgPicture.asset(
                          image[i],
                          color: i == 0 ? ccPrimary : ccNavyText,
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
                                    address[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: ccNavyText,
                                      fontFamily: 'Inter', fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (i == 0)...[
                                  SizedBox(width: 5),
                                  Text(
                                    "$totalSeat Seat needed",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontFamily: 'Inter', fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if(i == 0)...[
                              SizedBox(height: 3),
                              Text(
                                date,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ccSecondaryText,
                                  fontFamily: 'Inter', fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            SizedBox(height: 3),
                            Text(
                              i == 0 ? "Pickup point" : "Destination",
                              style: TextStyle(
                                color: ccSecondaryText,
                                fontFamily: 'Inter', fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if(i != address.length - 1)
                  SizedBox(
                    width: 55,
                    child: buildDashedLine(),
                  ),
                ],
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Divider(color: ccInputBorder, thickness: 1),
            ),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ccIceBlue,
                  ),
                  child: profilePic.isEmpty
                    ? Center(
                        child: SvgPicture.asset(
                          "assets/image/svg/user-filled.svg",
                          color: ccNavyText,
                        ),
                      )
                    : ClipOval(
                        child: FadeInImage.assetNetwork(
                          placeholder: "assets/image/ezgif.com-crop.gif",
                          image: "${Confing.imageurl}$profilePic",
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
                        profileName,
                        style: TextStyle(
                          color: ccNavyText,
                          fontFamily: 'Inter', fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          SvgPicture.asset(
                            "assets/image/svg/star-filled.svg",
                            height: 20,
                            color: yellowColor,
                          ),
                          SizedBox(width: 5),
                          Text(
                            totalRate,
                            style: TextStyle(
                              color: ccNavyText,
                              fontFamily: 'Inter', fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 7),
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: ccNavyText,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            "$ridesTaken Rides taken",
                            style: TextStyle(
                              color: ccNavyText,
                              fontFamily: 'Inter', fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
            child: Container(width: 2, height: 4, color: ccSecondaryText),
          ),
        ),
      ),
    );
  }

  double calculateDistance({required double lat1, required double lon1, required double lat2, required double lon2}) {
    const R = 6371; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }
  double _deg2rad(double deg) => deg * (pi / 180);
}
