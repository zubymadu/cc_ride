// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:math';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/find_trip_controller.dart';
import 'package:carride/app/modules/models/trip_request_list_api_model.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/utils/color.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PostReqPreiviewScreenController extends GetxController {
  FindTripController findTripController = Get.put(FindTripController());

  final RxList<TripInfo> _tripInfo = <TripInfo>[].obs;
  List<TripInfo> get tripInfo => _tripInfo;
  set tripInfo(List<TripInfo> value) => _tripInfo.value = value;

  final RxList _menu = ["Edit", "Delete"].obs;
  List get menu => _menu;
  set menu(List value) => _menu.value = value;

  final RxString tripEndTime = "".obs;

  // @override
  // void onInit() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     debugPrint("=============== arguments : ======= ${Get.arguments}");
  //     debugPrint("=============== user data : ======= ${getData.read("userLogin")}");
  //     debugPrint("============== isInvited :========= ${Get.arguments["isInvited"]}");
  //     debugPrint("=============== fromLat :========== ${Get.arguments["fromLat"]}");
  //     debugPrint("============== fromLong :========== ${Get.arguments["fromLong"]}");
  //     debugPrint("=============== toLat :============ ${Get.arguments["toLat"]}");
  //     debugPrint("=============== toLong :=========== ${Get.arguments["toLong"]}");
  //     debugPrint("============ departureDate :======= ${Get.arguments["departureDate"].toString().split(" ").first}");
  //     if (Get.arguments["findTrip"] == null) {
  //       findTripController.tripIsLoading = true;
  //       update();
  //       findTripController.findtripApi(
  //         originLat: "${Get.arguments["fromLat"]}",
  //         originLong: "${Get.arguments["fromLong"]}",
  //         destinationLat: "${Get.arguments["toLat"]}",
  //         destinationLong: "${Get.arguments["toLong"]}",
  //         tripDate: Get.arguments["departureDate"].toString().split(" ").first,
  //         status: "Trip",
  //       ).then((value) {
  //         findTripController.tripIsLoading = false;
  //         update();
  //       });
  //     }
  //     if(Get.arguments["tripInfo"] != null) {
  //       tripInfo.addAll(Get.arguments["tripInfo"]);
  //       debugPrint("------------ trip Info ------------ $tripInfo");
  //       DateTime startDateTime = DateTime.parse("${Get.arguments["departureDate"]}");
  //       final distanceKm = calculateDistance(
  //         lat1: double.parse("${Get.arguments["fromLat"]}"),
  //         lon1: double.parse("${Get.arguments["fromLong"]}"),
  //         lat2: double.parse("${Get.arguments["toLat"]}"),
  //         lon2: double.parse("${Get.arguments["toLong"]}"),
  //       );
  //       final totalMinutes = (distanceKm / 15 * 60).toInt();
  //       DateTime endDateTime = startDateTime.add(Duration(minutes: totalMinutes));
  //       tripEndTime.value = DateFormat("EEEE, d MMMM, yyy").format(endDateTime);
  //     }
  //   });
  //   super.onInit();
  // }

  tripListBottmsheet() {
    return Get.bottomSheet(
      enableDrag: false,
      isDismissible: false,
      backgroundColor: ccSurface,
      isScrollControlled: true,
      Column(
        children: [
          SizedBox(height: 35),
          Expanded(
            child: Scaffold(
              backgroundColor: ccSurface,
              appBar: AppBar(
                backgroundColor: ccSurface,
                title: Text(
                  "Matches".tr,
                  style: TextStyle(
                    color: ccNavyText,
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              body: ListView.separated(
                padding: EdgeInsets.all(10),
                shrinkWrap: true,
                itemCount: findTripController.findTripsmodel!.data!.tripData!.length,
                scrollDirection: Axis.vertical,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final RxString tripEndTime = "".obs;
                  DateTime startDateTime = DateTime.parse("${findTripController.findTripsmodel!.data!.tripData![index].tripStartDate} ${findTripController.findTripsmodel!.data!.tripData![index].tripStartTime}");
                  final distanceKm = calculateDistance(
                    lat1: findTripController.findTripsmodel!.data!.tripData![index].originLat!,
                    lon1: findTripController.findTripsmodel!.data!.tripData![index].originLong!,
                    lat2: findTripController.findTripsmodel!.data!.tripData![index].destiLat!,
                    lon2: findTripController.findTripsmodel!.data!.tripData![index].destiLong!,
                  );
                  final totalMinutes = (distanceKm / 15 * 60).toInt();
                  DateTime endDateTime = startDateTime.add(Duration(minutes: totalMinutes));
                  tripEndTime.value = DateFormat("EEE, MMM d 'at' h:mm a").format(endDateTime);
                  return findTripDetailsData(
                    onTap: () {
                      debugPrint("------------------- trip Id ----------------- ${findTripController.findTripsmodel!.data!.tripData![index].tripId}");
                      Get.toNamed(
                        Routes.TRIP_PREVIEW_SCREEN,
                        arguments: {
                          "tripId" : "${findTripController.findTripsmodel!.data!.tripData![index].tripId}",
                          "findtrip": true,
                        },
                      );
                    },
                    date: [
                      DateFormat('EEE, MMM d \'at\' h:mma').format(DateTime.parse("${findTripController.findTripsmodel!.data!.tripData![index].tripStartDate.toString().split(" ").first} at ${findTripController.findTripsmodel!.data!.tripData![index].tripStartTime.toString().split(" ").first}".replaceAll(" at ", " "))),
                      tripEndTime.value,
                    ],
                    seatPrice: "${findTripController.findTripsmodel!.data!.tripData![index].seatPrice}",
                    addresstype: ["Pickup point", "Destination"],
                    address: [
                      (findTripController.findTripsmodel!.data!.tripData![index].originAddress.toString().split(",").first),
                      (findTripController.findTripsmodel!.data!.tripData![index].destiAddress.toString().split(",").first),
                    ],
                    profilePic: "${findTripController.findTripsmodel!.data!.tripData![index].userProfile}",
                    profileName: "${findTripController.findTripsmodel!.data!.tripData![index].userTitle}",
                    totalDriven: "${findTripController.findTripsmodel!.data!.tripData![index].totalDriven}",
                    totalRate: "${findTripController.findTripsmodel!.data!.tripData![index].avgRating}",
                    totalSeat: "${findTripController.findTripsmodel!.data!.tripData![index].totalSeat}",
                    tripIsReturn: "${findTripController.findTripsmodel!.data!.tripData![index].tripIsReturn}",
                  );
                },
                separatorBuilder: (BuildContext context, int index) => SizedBox(height: 10),
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
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (i == 0)...[
                                  SizedBox(width: 5),
                                  Text(
                                    "$currency $seatPrice",
                                    style: TextStyle(
                                      color: ccNavyText,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
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
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
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
                                      color: ccSecondaryText,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
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
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
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
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
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
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
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
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
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
          borderRadius: BorderRadius.circular(15),
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
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (i == 0)...[
                                  SizedBox(width: 5),
                                  Text(
                                    "$totalSeat Seat needed",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
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
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
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
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
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
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
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
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
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

  // ------------------------------ delete ------------------------------------
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
  };

  Future deleteTriprequestApi({required String requestId}) async {
    isLoading = true;
    update();
    Map body = {
      "uid": "${getData.read("userLogin")["id"]}",
      "request_id": requestId,
    };

    try {
      String url = Confing.baseurl + Confing.deleteTripRequest;

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      debugPrint("========== Delete Trip Request Api Api url =========== $url");
      debugPrint("========== Delete Trip Request Api Api body ========== $body");
      debugPrint("======== Delete Trip Request Api Api response ======== ${response.body}");

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          showToastMessage("${data["ResponseMsg"]}");
          return data;
        } else {
          showToastMessage("${data["ResponseMsg"]}");
          return data;
        }
      } else {
        showToastMessage("Somthing went wrong!.....");
      }
    } catch (e) {
      debugPrint("========== Delete Trip Request Api Api Error ========== $e");
    } finally {
      isLoading = false;
      update();
    }
  }

  final RxBool _isCancel = false.obs;
  bool get isCancel => _isCancel.value;
  set isCancel(bool value) => _isCancel.value = value;
  void showDeleteConfirmDialog() {
    isLoading = false;
    debugPrint("---------------- Args requestId : ${Get.arguments["requestId"]}");
    String requestId = Get.arguments["requestId"];
    Get.bottomSheet(
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      backgroundColor: ccSurface,
      Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Delete Request",
              style: TextStyle(
                color: ccNavyText,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Confirm Request Delete",
              style: TextStyle(
                color: ccNavyText,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10),
            Container(
              width: Get.width,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ccBackground,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < 2; i++) ...[
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ccInputBorder,
                            ),
                          ),
                          child: SvgPicture.asset(
                            i == 0
                                ? "assets/image/svg/arrow-down-circle-filled.svg"
                                : "assets/image/svg/locationpinfilled.svg",
                            color: i == 0
                                ? ccPrimary
                                : ccNavyText,
                            height: 28,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                i == 0
                                    ? Get.arguments["fromAddress"].split(",").first
                                    : Get.arguments["fromAddress"].split(",").first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ccNavyText,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                i == 0
                                    ? DateFormat("EEEE, d MMMM, yyy").format(DateTime.parse("${Get.arguments["departureDate"]}"))
                                    : tripEndTime.value,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ccSecondaryText,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
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
                    if (i != 2 - 1)
                      SizedBox(width: 55, child: buildDashedLine()),
                  ],
                ],
              ),
            ),
            SizedBox(height: 10),
            InkWell(
              onTap: () {
                isCancel =! isCancel;
                update();
              },
              child: Row(
                children: [
                  Obx(
                    () => SizedBox(
                      height: 20,
                      width: 20,
                      child: Checkbox(
                        value: isCancel,
                        activeColor: ccPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                        side: BorderSide(),
                        onChanged: (value) {
                          isCancel = value!;
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "I confirm that I want to Delete this Request.",
                      style: TextStyle(
                        color: ccSecondaryText,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Obx(
              () => isLoading
                ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: ccPrimary)))
                : CCButton(
                    onPressed: () {
                      if (isCancel) {
                        isLoading = true;
                        deleteTriprequestApi(requestId: requestId).then((value) {
                          if (value["Result"] == "true") {
                            Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN, arguments: 2);
                          }
                        });
                      } else {
                        showToastMessage("Please confirm you'd like to proceed".tr);
                      }
                    },
                    label: "Delete Request",
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
