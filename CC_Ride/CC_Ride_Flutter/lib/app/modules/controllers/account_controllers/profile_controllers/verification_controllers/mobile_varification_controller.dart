// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/auth/otp_screen_controller.dart';
import 'package:carride/app/modules/controllers/auth/sms_type_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/textfield/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';

class MobileVarificationController extends GetxController {
  SmsTypeController smsTypeController = Get.put(SmsTypeController());
  OtpScreenController otpScreenController = Get.put(OtpScreenController());

  TextEditingController mobileController = TextEditingController();

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  final RxBool _verifiIsLoading = false.obs;
  bool get verifiIsLoading => _verifiIsLoading.value;
  set verifiIsLoading(bool value) => _verifiIsLoading.value = value;

  Future verifiMobileApi() async {
    final data = await _callMobileVerify();
    if (data != null && data["Result"] == "true") {
      Get.close(2); // closes the OTP bottomsheet, then the verification sheet
    }
    return data;
  }

  /// Same backend call as verifiMobileApi(), for callers that aren't nested
  /// inside the two OTP bottomsheets (e.g. the "Verify" action on Personal
  /// Details) — Get.close(2) there would pop screens the caller never opened.
  Future quickVerifyMobile() => _callMobileVerify();

  Future _callMobileVerify() async {
    verifiIsLoading = true;
    update();

    Map body = {"uid": "${getData.read("userLogin")["id"]}"};
    String url = Confing.baseurl + Confing.mobileVerify;

    try {
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          save("userLogin", data["UserLogin"]);
          showToastMessage("${data["ResponseMsg"]}");
        } else {
          showToastMessage("${data["ResponseMsg"]}");
        }
        verifiIsLoading = false;
        update();
        return data;
      } else {
        showToastMessage("Something went wrong. Please try again.");
        verifiIsLoading = false;
        update();
      }
    } catch (e) {
      verifiIsLoading = false;
      update();
      debugPrint("============= Verifi Mobile Api Error =========== $e");
    }
  }

  final formKey = GlobalKey<FormState>();

  Future mobileVarificationBottomSheet() {
    return Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: ccSurface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(CCRadius.sheet)),
      ),
      GetBuilder<MobileVarificationController>(
        init: MobileVarificationController(),
        initState: (_) {
          isLoading = false;
          update();
          mobileController = TextEditingController(
              text: "${getData.read("userLogin")["mobile"]}");
          update();
        },
        builder: (_) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Mobile Verification",
                  style: TextStyle(
                    color: ccNavyText,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                customTextFormField(
                  hintText: "Enter Your Mobile...",
                  controller: mobileController,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      "assets/image/svg/chat.svg",
                      color: ccSecondaryText,
                    ),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 14),
                isLoading
                    ? const SizedBox(
                        height: 52,
                        child: Center(
                            child:
                                CircularProgressIndicator(color: ccPrimary)),
                      )
                    : CCButton(
                        label: "Submit",
                        onPressed: () {
                          if (getData.read("userLogin")["mobile"] ==
                              mobileController.text) {
                            isLoading = true;
                            update();
                            smsTypeController.getMsgtype().then((value) {
                              if (value["SMS_TYPE"] == "Msg91") {
                                otpScreenController
                                    .msg91otp(
                                        mobile: mobileController.text)
                                    .then((value) {
                                  showToastMessage(value["ResponseMsg"]);
                                  if (value["Result"] == "true") {
                                    otp = "${value["otp"]}";
                                    mobileVarificationOtpBottomsheet(
                                        mobile: mobileController.text);
                                    otpController =
                                        TextEditingController(text: otp);
                                    isLoading = false;
                                    update();
                                  } else {
                                    isLoading = false;
                                    update();
                                  }
                                });
                              } else {
                                otpScreenController
                                    .twilloOtp(
                                        mobile: mobileController.text)
                                    .then((value) {
                                  showToastMessage(value["ResponseMsg"]);
                                  if (value["Result"] == "true") {
                                    otp = "${value["otp"]}";
                                    otpController =
                                        TextEditingController(text: otp);
                                    mobileVarificationOtpBottomsheet(
                                        mobile: mobileController.text);
                                    isLoading = false;
                                    update();
                                  } else {
                                    isLoading = false;
                                    update();
                                  }
                                });
                              }
                            });
                          } else {
                            showToastMessage("This number doesn't match....");
                          }
                        },
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  TextEditingController otpController = TextEditingController();

  final RxInt _counter = 0.obs;
  int get counter => _counter.value;
  set counter(int value) => _counter.value = value;

  Timer? timer;

  void startTimer() {
    counter = 30;
    update();
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (counter == 0) {
        t.cancel();
      } else {
        counter--;
      }
      update();
    });
  }

  String otp = "";

  mobileVarificationOtpBottomsheet({required String mobile}) {
    final submittedTheme = PinTheme(
      width: 52,
      height: 52,
      textStyle: const TextStyle(
        fontSize: 20,
        color: ccPrimary,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ccPrimary, width: 2),
      ),
    );
    final defaultTheme = PinTheme(
      width: 52,
      height: 52,
      textStyle: const TextStyle(
        fontSize: 20,
        color: ccNavyText,
        fontFamily: 'Inter',
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ccInputBorder, width: 1.5),
      ),
    );

    return Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: ccSurface,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(CCRadius.sheet))),
      GetBuilder<MobileVarificationController>(
        init: MobileVarificationController(),
        initState: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            startTimer();
            otpController = TextEditingController(text: otp);
            update();
          });
        },
        builder: (_) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Enter OTP Code",
                  style: TextStyle(
                    color: ccNavyText,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "OTP code has been sent to your mobile",
                  style: TextStyle(
                    color: ccSecondaryText,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Pinput(
                    length: 6,
                    controller: otpController,
                    submittedPinTheme: submittedTheme,
                    defaultPinTheme: defaultTheme,
                    focusedPinTheme: submittedTheme,
                    errorText: 'Wrong otp'.tr,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      if (counter == 0) {
                        startTimer();
                        otpController.clear();
                        smsTypeController.getMsgtype().then((value) {
                          if (value["SMS_TYPE"] == "Msg91") {
                            otpScreenController
                                .msg91otp(mobile: mobileController.text)
                                .then((value) {
                              showToastMessage(value["ResponseMsg"]);
                              if (value["Result"] == "true") {
                                otp = "${value["otp"]}";
                                otpController =
                                    TextEditingController(text: otp);
                              }
                            });
                          } else {
                            otpScreenController
                                .twilloOtp(mobile: mobileController.text)
                                .then((value) {
                              showToastMessage(value["ResponseMsg"]);
                              if (value["Result"] == "true") {
                                otp = "${value["otp"]}";
                                otpController =
                                    TextEditingController(text: otp);
                              }
                            });
                          }
                        });
                      }
                    },
                    child: Text(
                      counter == 0 ? "Resend code".tr : "00 : $counter",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: counter == 0 ? ccPrimary : ccSecondaryText,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                verifiIsLoading
                    ? const SizedBox(
                        height: 52,
                        child: Center(
                            child:
                                CircularProgressIndicator(color: ccPrimary)),
                      )
                    : CCButton(
                        label: "Submit",
                        onPressed: () {
                          if (otp == otpController.text) {
                            verifiMobileApi();
                          } else {
                            showToastMessage("Please Enter valid otp..");
                          }
                        },
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
