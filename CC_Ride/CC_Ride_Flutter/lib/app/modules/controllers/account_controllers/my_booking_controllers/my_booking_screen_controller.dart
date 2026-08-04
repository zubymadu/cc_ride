// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:math';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/models/mybook_trip_list_api_model.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class MyBookingScreenController extends GetxController with SingleGetTickerProviderMixin {
  late TabController tabController = TabController(length: 2, vsync: this);

  @override
  void onInit() {
    Future.wait([
      myBookingListApi(status: "current"),
      myBookingListApi(status: "past"),
    ]).whenComplete(() {
      isLoading = false;
      update();
    });
    super.onInit();
  }

  final RxList _tabText = ["Current".tr, "Past".tr].obs;
  List get tabText => _tabText;
  set tabText(List value) => _tabText.value = value;

  MyBookTripListApiModel? currentTripListApiModel;
  MyBookTripListApiModel? pastTripListApiModel;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  Future myBookingListApi({required String status}) async {
    Map body = {
      "uid": "${getData.read("userLogin")?["id"] ?? ""}",
      "status": status,
    };

    try {
      String url = Confing.baseurl + Confing.mybookTriplist;
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      ).timeout(const Duration(seconds: 15));
      debugPrint("============ My Booking List Api url ============= $url");
      debugPrint("============ My Booking List Api body ============ $body");
      debugPrint("========== My Booking List Api response ========== ${response.body}");
      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (status == "current") {
          currentTripListApiModel = myBookTripListApiModelFromJson(response.body);
        } else if (status == "past") {
          pastTripListApiModel = myBookTripListApiModelFromJson(response.body);
        }
        return data;
      } else {
        showToastMessage("Something went wrong!");
      }
    } catch (e) {
      debugPrint("============ My Booking List Api Err ============ $e");
    }
  }

  Widget bookDetailsData({
    required VoidCallback onTap,
    required List date,
    required List type,
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
                                    address[i],
                                    // i == 0
                                    //   ? controller.tripListActiveApiModel!.tripData![index].originAddress!.split(",").first
                                    //   : controller.tripListActiveApiModel!.tripData![index].destiAddress!.split(",").first,
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
                            SizedBox(height: 3),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    date[i],
                                    // i == 0
                                    //   ? DateFormat('EEE, MMM d \'at\' h:mma').format(DateTime.parse("${controller.tripListActiveApiModel!.tripData![index].tripStartDate} at ${controller.tripListActiveApiModel!.tripData![index].tripStartTime}".replaceAll(" at ", " ")))
                                    //   : "$tripEndTime",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: ccSecondaryText,
                                      fontFamily: 'Inter', fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
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
                  if(i != 2 - 1)
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
                        // "${"Private message to".tr} ${controller.tripListActiveApiModel!.tripData![index].userTitle}",
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
                            "${totalDriven}km driven",
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
