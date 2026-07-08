import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/post_controllers/trip_preview_screen_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';

class SeatingPlanScreenController extends GetxController {
  late final TripPreviewScreenController tripPreviewScreenController;

  @override
  void onInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tripPreviewScreenController = Get.find<TripPreviewScreenController>();
    });
    super.onInit();
  }

  final RxString _buttonState = "padding".obs;
  String get buttonState => _buttonState.value;
  set buttonState(String value) => _buttonState.value = value;

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  /// Headers
  final Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
  };

  // setChatId(String senderId, String receiverId) {
  //   debugPrint("-------------- senderId --------------- $senderId");
  //   debugPrint("------------- receiverId -------------- $receiverId");
  //   List<String> ids = [senderId, receiverId]..sort();
  //   debugPrint("---------------- ids ------------------ $ids");
  //   return "${ids[0]}_${ids[1]}";
  // }

  setChatId(String senderId, String receiverId) {
    debugPrint("-------------- senderId --------------- $senderId");
    debugPrint("------------- receiverId -------------- $receiverId");

    // Convert to int, sort numerically, then back to String
    List<String> ids = [senderId, receiverId];
    ids.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    debugPrint("---------------- ids ------------------ $ids");
    return "${ids[0]}_${ids[1]}";
  }

  Future<void> deleteOnlyChatRoom(String id) async {
    final ref = FirebaseFirestore.instance.collection("CCRideChat").doc(id);
    // Delete subcollection "message"
    var msg = await ref.collection("message").get();
    for (var doc in msg.docs) {
      await ref.collection("message").doc(doc.id).delete();
    }
    // Delete the main doc
    await ref.delete();
  }

  /// API - Complete Trip
  Future completeTrip({
    required String bookId,
    required String chatId,
    required String bookUid,
  }) async {
    try {
      isLoading = true;
      update();

      Map body = {
        "uid": getData.read("userLogin")["id"], // or getData.read
        "book_id": bookId,
        "book_uid": bookUid,
      };

      String url = Confing.baseurl + Confing.completeTrip;

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(name: "========== CompleteTripApi url ===========", url);
      log(name: "========== CompleteTripApi body ==========", "$body");
      log(name: "======== CompleteTripApi response ========", response.body);
      debugPrint("--------------- chat id ------------- $chatId");

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          deleteOnlyChatRoom(chatId);
          showToastMessage("${data["ResponseMsg"]}");
          tripPreviewScreenController.tripDetailsApi(tripId: tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripId!).then((value) {
            Get.back();
            isLoading = false;
            update();
          });
        }
        showToastMessage("${data["ResponseMsg"]}");
        return data;
      } else {
        isLoading = false;
        update();
        showToastMessage("Something went wrong");
      }
    } catch (e) {
      isLoading = false;
      update();
      showToastMessage("Error: $e");
    }
  }

  /// API - Processing Trip
  Future processingTrip({
    required String bookId,
    required String bookUid,
  }) async {
    try {
      isLoading = true;
      update();

      Map body = {
        "uid": getData.read("userLogin")["id"], // or getData.read
        "book_id": bookId,
        "book_uid": bookUid,
      };

      String url = Confing.baseurl + Confing.processingTrip;

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(name: "========== Processing Trip Api url ===========", url);
      log(name: "========== Processing Trip Api body ==========", "$body");
      log(name: "======== Processing Trip Api response ========", response.body);

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          tripPreviewScreenController.tripDetailsApi(tripId: tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripId!).then((value) {
            Get.back();
            isLoading = false;
            update();
          });
          showToastMessage("${data["ResponseMsg"]}");
        } else {
          isLoading = false;
          update();
          showToastMessage("${data["ResponseMsg"]}");
        }
        return data;
      } else {
        isLoading = false;
        update();
        showToastMessage("Something went wrong");
      }
    } catch (e) {
      isLoading = false;
      update();
      showToastMessage("Error: $e");
    }
  }

  final RxBool _approve = false.obs;
  bool get approve => _approve.value;
  set approve(bool value) => _approve.value = value;

  final RxBool _reject = false.obs;
  bool get reject => _reject.value;
  set reject(bool value) => _reject.value = value;

  Future makeDecisionApi({
    required String isApprove,
    required String bookId,
    required String bookuid,
  }) async {
    Map body = {
      "is_approve": isApprove,
      "uid": "${getData.read("userLogin")["id"]}",
      "book_uid": bookuid,
      "book_id": bookId,
    };

    try {
      if (isApprove == "1") {
        approve = true;
        update();
      } else {
        reject = true;
        update();
      }

      String url = Confing.baseurl + Confing.makeDecision;

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(name: "========== Make Decision Api url ===========", url);
      log(name: "========== Make Decision Api body ==========", "$body");
      log(name: "======== Make Decision Api response ========", response.body);

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["status"] == "success") {
          tripPreviewScreenController.tripDetailsApi(
            tripId: tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripId!,
          ).then((value) {
            Get.back();
            reject = false;
            update();
            approve = false;
            update();
          });
          showToastMessage("${data["message"]}");
        } else {
          reject = false;
          update();
          approve = false;
          update();
          showToastMessage("${data["message"]}");
        }
        return data;
      } else {
        reject = false;
        update();
        approve = false;
        update();
        showToastMessage("Something went wrong");
      }
    } catch (e) {
      reject = false;
      update();
      approve = false;
      update();
      showToastMessage("Error: $e");
    }
  }

  Future bookedUsersBottomSheet({required int ind}) {
    return Get.bottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      elevation: 10,
      backgroundColor: ccBackground,
      Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Booked Users".tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ccNavyText,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Get.back(),
                  child: Icon(Icons.close, color: ccNavyText),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ccNavyText,
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: FadeInImage.assetNetwork(
                      placeholder: "assets/image/ezgif.com-crop.gif",
                      width: 70,
                      height: 70,
                      image: "${Confing.imageurl}${tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].profilePic}",
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) => Image.asset(
                        "assets/image/ezgif.com-crop.gif",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].userName!,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          color: ccNavyText,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].bookStatus!,
                        style: TextStyle(
                          color: ccSecondaryText,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].bookStatus! != "Pending") ...[
                  for (int i = 0; i < 2; i++) ...[
                    SizedBox(width: 10),
                    InkWell(
                      onTap: () {
                        Get.back();
                        if (i == 0) {
                          debugPrint("------------- mobile number ---------- ${tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].userMobile}");
                          makingPhoneCall(number: "${tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].userMobile}");
                        } else {
                          Get.toNamed(
                            Routes.MESSAGE_SCREEN,
                            arguments: {
                              "reciverId": "${tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].userId}",
                              "profilePic": tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].profilePic,
                              "userName": tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].userName,
                              "originAddress": tripPreviewScreenController.tripDetailsApiModel!.tripData!.originAddress,
                              "originLat": tripPreviewScreenController.tripDetailsApiModel!.tripData!.originLat,
                              "originLong": tripPreviewScreenController.tripDetailsApiModel!.tripData!.originLong,
                              "destiAddress": tripPreviewScreenController.tripDetailsApiModel!.tripData!.destiAddress,
                              "destiLat": tripPreviewScreenController.tripDetailsApiModel!.tripData!.destiLat,
                              "destiLong": tripPreviewScreenController.tripDetailsApiModel!.tripData!.destiLong,
                              "stopPoint": tripPreviewScreenController.tripDetailsApiModel!.tripData!.stopsDetails,
                            },
                          );
                          debugPrint("-------------- chat id --------------- ${tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].userId}_${getData.read("userLogin")["id"]}");
                          debugPrint("============ tripDetails ============= ${tripPreviewScreenController.tripDetailsApiModel!.tripData!.userId}");
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ccIceBlue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ccInputBorder,
                          ),
                        ),
                        child: SvgPicture.asset(
                          i == 0
                              ? "assets/image/svg/phone.svg"
                              : "assets/image/svg/chat-dots.svg",
                          height: 27,
                          colorFilter: ColorFilter.mode(
                            ccNavyText,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
            SizedBox(height: 10),
            if (tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].bookStatus! == "Pending") ...[
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: reject
                          ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: ccPrimary)))
                          : CCButton(
                              label: "Reject".tr,
                              onPressed: () {
                                makeDecisionApi(
                                  isApprove: "2",
                                  bookId: "${tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].bookId}",
                                  bookuid: "${tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].userId}",
                                );
                              },
                            ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: approve
                          ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: ccPrimary)))
                          : CCButton(
                              label: "Approve".tr,
                              onPressed: () {
                                makeDecisionApi(
                                  isApprove: "1",
                                  bookId: "${tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].bookId}",
                                  bookuid: "${tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].userId}",
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ] else if (tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].bookStatus! == "Booked" || tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].bookStatus! == "Processing") ...[
              Obx(
                () => isLoading
                    ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: ccPrimary)))
                    : CCButton(
                        label: tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].bookStatus! == "Booked"
                            ? "Processing...".tr
                            : "Completed".tr,
                        onPressed: () {
                          if (tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].bookStatus! == "Booked") {
                            // processingTrip(bookId: tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].bookId!);
                            Get.back();
                            otpBottomsheet(index: ind, type: "Processing");
                          } else {
                            Get.back();
                            otpBottomsheet(index: ind, type: "Completed");
                            // completeTrip(bookId: tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].bookId!);
                          }
                        },
                      ),
              ),
            ],

            if (tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].bookStatus! == "Booked") ...[
              SizedBox(height: 10),
              Obx(
                () => reject
                    ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: ccPrimary)))
                    : CCButton(
                        label: "Not Arrived – Mark No Show",
                        onPressed: () {
                          makeDecisionApi(
                            isApprove: "2",
                            bookId: "${tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].bookId}",
                            bookuid: "${tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![ind].userId}",
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  TextEditingController otpController = TextEditingController();

  otpBottomsheet({required int index, required String type}) {
    return Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: ccBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(15)),
      ),
      GetBuilder<SeatingPlanScreenController>(
        init: SeatingPlanScreenController(),
        initState: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            otpController.clear();
            update();
          });
        },
        builder: (seatingPlanScreenController) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Enter OTP Code",
                  style: TextStyle(
                    color: ccNavyText,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: Pinput(
                    length: 6,
                    controller: otpController,
                    submittedPinTheme: PinTheme(
                      width: 56,
                      height: 56,
                      textStyle: TextStyle(
                        fontSize: 20,
                        color: ccPrimary,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ccPrimary, width: 2),
                      ),
                    ),
                    defaultPinTheme: PinTheme(
                      width: 56,
                      height: 56,
                      textStyle: TextStyle(
                        fontSize: 20,
                        color: ccPrimary,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xffeeeeed), width: 2),
                      ),
                    ),
                    errorText: 'Wrong otp'.tr,
                  ),
                ),
                SizedBox(height: 10),
                Obx(
                  () => Container(
                    child: isLoading
                        ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: ccPrimary)))
                        : CCButton(
                            label: "Submit",
                            onPressed: () {
                              debugPrint("---------------- pickupOtp ------------------ ${tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].pickupOtp}");
                              debugPrint("----------------- dropOtp ------------------- ${tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].dropOtp}");
                              debugPrint("------------ otpController.text ------------- ${otpController.text}");

                              if (type == "Processing") {
                                if (tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].pickupOtp == otpController.text) {
                                  processingTrip(
                                    bookId: tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].bookId!,
                                    bookUid: "${tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].userId}",
                                  );
                                } else {
                                  showToastMessage("Please Enter valid otp..");
                                }
                              } else {
                                if (tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].dropOtp == otpController.text) {
                                  String chatId = setChatId("${getData.read("userLogin")["id"]}", "${tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].userId}");
                                  completeTrip(
                                    bookId: tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].bookId!,
                                    chatId: chatId,
                                    bookUid: "${tripPreviewScreenController.tripDetailsApiModel!.tripData!.bookedUsers![index].userId}",
                                  );
                                } else {
                                  showToastMessage("Please Enter valid otp..");
                                }
                              }
                            },
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
