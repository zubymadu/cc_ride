// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:math';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/account_controllers/my_booking_controllers/my_booking_screen_controller.dart';
import 'package:carride/app/modules/controllers/trips_controllers/seating_plan_screen_controller.dart';
import 'package:carride/app/modules/models/book_trip_details_api_model.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/utils/color.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/textfield/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class BookingDatailsController extends GetxController {
  BookTripDetailsApiModel? bookTripDetailsApiModel;

  SeatingPlanScreenController seatingPlanScreenController = Get.put(SeatingPlanScreenController());
  MyBookingScreenController myBookingScreenController = Get.put(MyBookingScreenController());

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  final RxInt _seatIndex = 0.obs;
  int get seatIndex => _seatIndex.value;
  set seatIndex(int value) => _seatIndex.value = value;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
  };

  final _bookSeatLegnth = 0.obs;
  get bookSeatLegnth => _bookSeatLegnth.value;
  set bookSeatLegnth(value) => _bookSeatLegnth.value = value;

  Future bookTripDetailsApi({
    required String tripId,
    required String ownerId,
  }) async {
    bookSeatLegnth = 0;
    isLoading = true;
    update();
    Map body = {
      "uid": ownerId,
      "book_uid": "${getData.read("userLogin")["id"]}",
      "trip_id": tripId,
    };

    // try {
    String url = Confing.baseurl + Confing.bookTripDetails;
    var response = await http.post(
      Uri.parse(url),
      body: jsonEncode(body),
      headers: userHeader,
    );
    debugPrint("============ Book Trip Details Api url ============= $url");
    debugPrint("============ Book Trip Details Api body ============ $body");
    debugPrint("========== Book Trip Details Api response ========== ${response.body}");
    var data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data["Result"] == "true") {
        bookTripDetailsApiModel = bookTripDetailsApiModelFromJson(response.body);
        update();
        if (bookTripDetailsApiModel!.result == "true") {
          for (int i = 0; i < bookTripDetailsApiModel!.tripData!.bookedUsers!.length; i++) {
            if ("${bookTripDetailsApiModel!.tripData!.bookedUsers![i].userId}" == "${getData.read("userLogin")["id"]}") {
              if (bookTripDetailsApiModel!.tripData!.bookedUsers![i].isApprove! == 0) {
                seatIndex = i;
              }
              if(bookTripDetailsApiModel!.tripData!.bookedUsers![i].userId! == num.parse("${getData.read("userLogin")["id"]}")){
                bookSeatLegnth++;
              }
            }
          }
          debugPrint("-------------- seat index ----------- $seatIndex");
          debugPrint("------------ bookSeatLegnth --------- $bookSeatLegnth");
          isLoading = false;
          update();
          return data;
        } else {
          showToastMessage(bookTripDetailsApiModel!.responseMsg!);
        }
      } else {
        showToastMessage("${data["ResponseMsg"]}");
        return data;
      }
    } else {
      showToastMessage("Something went wrong!");
    }
    // } catch (e) {
    //   log(name: "============ Book Trip Details Api Error ============", "$e");
    // }
  }

  final RxBool _ratingLoading = false.obs;
  bool get ratingLoading => _ratingLoading.value;
  set ratingLoading(bool value) => _ratingLoading.value = value;

  Future rateUpdateApi({
    required String bookId,
    required String totalRate,
    required String rateDesc,
  }) async {
    ratingLoading = true;
    update();
    Map body = {
      "uid": getData.read("userLogin")["id"],
      "book_id": bookId,
      "total_rate": totalRate,
      "rate_desc": rateDesc,
    };

    try {
      String url = Confing.baseurl + Confing.rateUpdate;
      var response = await http.post(
        Uri.parse(url),
        headers: userHeader,
        body: jsonEncode(body),
      );

      debugPrint("============ rate Update Api url ============= $url");
      debugPrint("============ rate Update Api body ============ $body");
      debugPrint("========== rate Update Api response ========== ${response.body}");

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          Get.back();
          bookTripDetailsApi(
            ownerId: "${Get.arguments["owner_id"]}",
            tripId: "${Get.arguments["trip_id"]}",
          ).then((value) {
            ratingLoading = false;
            update();
          });
          return data;
        } else {
          showToastMessage("${data["ResponseMsg"]}");
          ratingLoading = false;
          update();
        }
      } else {
        showToastMessage("Somthing went wrong");
        ratingLoading = false;
        update();
      }
    } catch (e) {
      debugPrint("========== rate Update Api Error ========== $e");
      ratingLoading = false;
      update();
    }
  }

  final RxBool _isCancelLoading = false.obs;
  bool get isCancelLoading => _isCancelLoading.value;
  set isCancelLoading(bool value) => _isCancelLoading.value = value;

  final RxBool _isCancel = false.obs;
  bool get isCancel => _isCancel.value;
  set isCancel(bool value) => _isCancel.value = value;

  Future cancelSeat({required String bookId}) async {
    try {
      isCancelLoading = true;
      update();

      Map body = {"uid": getData.read("userLogin")["id"], "book_id": bookId};

      String url = Confing.baseurl + Confing.cancleSeat;

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      debugPrint("========== Cancel Seat Api url =========== $url");
      debugPrint("========== Cancel Seat Api body ========== $body");
      debugPrint("======== Cancel Saet Api response ======== ${response.body}");

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["status"] == "success") {
          myBookingScreenController.myBookingListApi(status: "current").then((
            value,
          ) {
            myBookingScreenController.isLoading = false;
            Get.close(2);
          });
          showToastMessage("${data["message"]}");
          return data;
        } else {
          showToastMessage("${data["message"]}");
          return data;
        }
      } else {
        showToastMessage("Something went wrong");
      }
    } catch (e) {
      showToastMessage("Error: $e");
    } finally {
      isCancelLoading = false;
      update();
    }
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

  buillData({required String title, String? text, required String subTitle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              text: title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: ccNavyText,
              ),
              children: [
                const TextSpan(text: " "),
                TextSpan(
                  text: text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    color: ccSecondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
        Flexible(
          child: Text(
            subTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              color: ccSecondaryText,
            ),
          ),
        ),
      ],
    );
  }

  void cancelSeatBottomsheet({required String bookid}) {
    isLoading = false;
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
              "Cancel trip".tr,
              style: const TextStyle(
                color: ccNavyText,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Confirm trip cancellation".tr,
              style: const TextStyle(
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
                                    ? bookTripDetailsApiModel!.tripData!.originAddress!.split(",").first
                                    : bookTripDetailsApiModel!.tripData!.destiAddress!.split(",").first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ccNavyText,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                i == 0
                                    ? DateFormat('EEE, MMM d \'at\' h:mma').format(DateTime.parse("${bookTripDetailsApiModel!.tripData!.tripStartDate!.toIso8601String().split('T').first} at ${bookTripDetailsApiModel!.tripData!.tripStartTime}".replaceAll(" at ", " ")))
                                    : tripEndTime.value,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ccSecondaryText,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                i == 0 ? "Pickup point" : "Destination",
                                style: const TextStyle(
                                  color: ccSecondaryText,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i != 0)
                          if (bookTripDetailsApiModel!.tripData!.tripIsReturn != "0")
                            SvgPicture.asset(
                              "assets/image/svg/returenarrow.svg",
                              color: ccNavyText,
                              height: 20,
                            ),
                      ],
                    ),
                    if (i == 0)
                      for (int si = 0; si < bookTripDetailsApiModel!.tripData!.stopsDetails!.length; si++) ...[
                        SizedBox(width: 55, child: buildDashedLine()),
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
                                "assets/image/svg/Gps.svg",
                                color: ccError,
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
                                          bookTripDetailsApiModel!.tripData!.stopsDetails![si].location!.split(",").first,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: ccNavyText,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tripStopPointTime[si],
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: ccSecondaryText,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    "Stop ${si + 1}",
                                    style: const TextStyle(
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
                      ],
                    if (i != 2 - 1) SizedBox(width: 55, child: buildDashedLine()),
                  ],
                ],
              ),
            ),
            SizedBox(height: 10),
            InkWell(
              onTap: () {
                isCancel =! isCancel;
                update();
                debugPrint("-------- isCancel ----------- $isCancel");
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
                      "I confirm that I want to cancel this seat",
                      style: const TextStyle(
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
              () => isCancelLoading
                ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: ccPrimary)))
                : CCButton(
                    onPressed: () {
                      if (isCancel) {
                        cancelSeat(bookId: bookid);
                      } else {
                        showToastMessage("Please confirm you'd like to proceed".tr);
                      }
                    },
                    label: "Cancel trip".tr,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  TextEditingController reviewcontroller = TextEditingController();

  final RxDouble _ratings = 0.0.obs;
  double get ratings => _ratings.value;
  set ratings(double value) => _ratings.value = value;

  bookSeatDetailsBottomsheet({required int index}) {
    return Get.bottomSheet(
      backgroundColor: ccBackground,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(20)),
      ),
      Container(
        constraints: BoxConstraints(maxHeight: Get.height / 1.2),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          physics: BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Review Rating",
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: ccNavyText,
                    ),
                  ),
                  InkWell(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.close, color: ccNavyText),
                  ),
                ],
              ),
              if (bookTripDetailsApiModel!.tripData!.bookedUsers![index].bookStatus == "Completed")
                if (bookTripDetailsApiModel!.tripData!.bookedUsers![index].isRate == 0) ...[
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      "How did your ride go?".tr,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: ccNavyText,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Text(
                      "Give a star rating (1 to 5) for your trip experience".tr,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: ccNavyText,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: RatingBar(
                      initialRating: double.parse("${bookTripDetailsApiModel!.tripData!.bookedUsers![index].totalRate}"),
                      minRating: 0,
                      allowHalfRating: true,
                      direction: Axis.horizontal,
                      itemCount: 5,
                      itemSize: 40,
                      glow: false,
                      itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
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
                      ignoreGestures: bookTripDetailsApiModel!.tripData!.bookedUsers![index].isRate == 0
                          ? false
                          : true,
                      onRatingUpdate: (rating) {
                        ratings = rating;
                        update();
                        debugPrint("--------------- ratings ------------ $ratings");
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  customTextFormField(
                    hintText: "Enter review",
                    controller: reviewcontroller,
                  ),
                  SizedBox(height: 10),
                  Obx(
                    () => ratingLoading
                      ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: ccPrimary)))
                      : CCButton(
                          onPressed: () {
                            if (bookTripDetailsApiModel!.tripData!.bookedUsers![index].isRate == 0) {
                              if (ratings != 0.0 && reviewcontroller.text.isNotEmpty) {
                                rateUpdateApi(
                                  bookId: "${bookTripDetailsApiModel!.tripData!.bookedUsers![index].bookId}",
                                  totalRate: "$ratings",
                                  rateDesc: reviewcontroller.text,
                                );
                              }
                              debugPrint("--------------- rating ------------ ");
                            } else {
                              showToastMessage("This booking has already been rated!".tr);
                            }
                          },
                          label: "Submit",
                        ),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }

  routeText({
    required Color iconBgColor,
    required IconData icon,
    required String address,
    required String addressType,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, color: ccSurface, size: 24),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  color: ccNavyText,
                ),
              ),
              Text(
                addressType,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: ccNavyText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------  TRIP DATA  ----------------------------- //
  final Rx<TripData?> tripDatass = Rx<TripData?>(null);
  final RxString tripEndTime = "".obs;

  final RxList _tripStopPointTime = [].obs;
  List get tripStopPointTime => _tripStopPointTime;
  set tripStopPointTime(List value) => _tripStopPointTime.value = value;

  void setTripData(TripData data) {
    tripDatass.value = data;
    calculateTripEndTime();
  }

  void calculateTripEndTime() {
    if (tripDatass.value == null) return;
    tripStopPointTime.clear();
    update();

    String startDate = tripDatass.value!.tripStartDate!.toIso8601String().split('T').first;
    String startTime = tripDatass.value!.tripStartTime!;
    DateTime startDateTime = DateTime.parse("$startDate $startTime");
    debugPrint("----------- startDate ---------- $startDate");
    debugPrint("----------- startTime ---------- $startTime");
    debugPrint("--------- startDateTime -------- $startDateTime");

    double oriLat = tripDatass.value!.originLat ?? 0.0;
    double oriLong = tripDatass.value!.originLong ?? 0.0;
    double desLat = 0.0;
    double desLong = 0.0;
    if (tripDatass.value!.stopsDetails!.isNotEmpty) {
      for (var i = 0; i < tripDatass.value!.stopsDetails!.length; i++) {
        desLat = tripDatass.value!.stopsDetails![i].lat ?? 0.0;
        desLong = tripDatass.value!.stopsDetails![i].long ?? 0.0;
        debugPrint("----------- oriLat 1 -------- $oriLat");
        debugPrint("---------- oriLong 1 -------- $oriLong");
        debugPrint("----------- desLat ---------- $desLat");
        debugPrint("---------- desLong ---------- $desLong");
        update();
        final distanceKm = calculateDistance(
          lat1: oriLat,
          lon1: oriLong,
          lat2: desLat,
          lon2: desLong,
        );
        final totalMinutes = (distanceKm / 20 * 60).toInt();
        final stoptime = startDateTime.add(Duration(minutes: totalMinutes));
        tripStopPointTime.add(DateFormat('EEE, MMM d \'at\' h:mma').format(stoptime));
        update();
        debugPrint("--------- totalMinutes --------- $totalMinutes");
        debugPrint("----------- stoptime ----------- $stoptime");
        debugPrint("------- tripStopPointTime ------ $tripStopPointTime");
        oriLat = desLat;
        oriLong = desLong;
        startDateTime = DateFormat("yyyy-MM-dd HH:mm:ss.SSS").parse("$stoptime");
        debugPrint("----------- oriLat 2 -------- $oriLat");
        debugPrint("---------- oriLong 2 -------- $oriLong");
        update();
      }
    }

    final distanceKm = calculateDistance(
      lat1: oriLat,
      lon1: oriLong,
      lat2: tripDatass.value!.destiLat!,
      lon2: tripDatass.value!.destiLong!,
    );

    final totalMinutes = (distanceKm / 20 * 60).toInt();
    final endDateTime = startDateTime.add(Duration(minutes: totalMinutes));

    // tripEndTime.value = DateFormat('h:mma').format(endDateTime).toLowerCase();
    tripEndTime.value = DateFormat('EEE, MMM d \'at\' h:mma').format(endDateTime);

    debugPrint("--------- totalMinutes --------- $totalMinutes");
    debugPrint("--------- endDateTime ---------- $endDateTime");
    debugPrint("--------- tripEndTime ---------- ${tripEndTime.value}");
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
