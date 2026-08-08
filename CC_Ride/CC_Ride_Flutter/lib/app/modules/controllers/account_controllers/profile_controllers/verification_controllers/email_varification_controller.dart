// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/textfield/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';

class EmailVarificationController extends GetxController {
  TextEditingController emailController = TextEditingController();

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  Future emailOtpApi({required String email, bool? openBottomsheet}) async {
    isLoading = true;
    update();
    Map body = {"email": email};

    String url = Confing.baseurl + Confing.emailOtp;

    debugPrint("============== Email Otp Api url ============= $url");
    debugPrint("============== Email Otp Api body ============ $body");

    try {
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      debugPrint("============= Email Otp Api respon =========== ${response.body}");
      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          isLoading = false;
          update();
          showToastMessage("${data["ResponseMsg"]}");
          if (openBottomsheet == true) {
            otp = "${data["OTP"]}";
            otpController = TextEditingController(text: otp);
            emailVarificationOtpBottomsheet(email: email);
          }
          return data;
        } else {
          showToastMessage("${data["ResponseMsg"]}");
          isLoading = false;
          update();
          return data;
        }
      } else {
        showToastMessage("Something went wrong. Please try again.");
        isLoading = false;
        update();
      }
    } catch (e) {
      isLoading = false;
      update();
      debugPrint("============= Email Otp Api Error =========== $e");
    }
  }

  final RxBool _verifiIsLoading = false.obs;
  bool get verifiIsLoading => _verifiIsLoading.value;
  set verifiIsLoading(bool value) => _verifiIsLoading.value = value;

  Future verifiEmailApi() async {
    verifiIsLoading = true;
    update();

    Map body = {"otp": otpController.text};

    String url = Confing.baseurl + Confing.verifyEmail;

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
          Get.close(2);
          verifiIsLoading = false;
          update();
          return data;
        } else {
          showToastMessage("${data["ResponseMsg"]}");
          verifiIsLoading = false;
          update();
          return data;
        }
      } else {
        showToastMessage("Something went wrong. Please try again.");
        verifiIsLoading = false;
        update();
      }
    } catch (e) {
      verifiIsLoading = false;
      update();
      debugPrint("============= Verifi Email Api Error =========== $e");
    }
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      showToastMessage("Please enter your email".tr);
      return "Please enter your email".tr;
    }
    String pattern = r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      showToastMessage("Enter a valid email address".tr);
      return "Enter a valid email address".tr;
    }
    return null;
  }

  final formKey = GlobalKey<FormState>();

  Future emailVarificationBottomSheet() {
    return Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: ccSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(CCRadius.sheet)),
      ),
      GetBuilder<EmailVarificationController>(
        init: EmailVarificationController(),
        initState: (_) {
          isLoading = false;
          update();
          emailController = TextEditingController(
              text: "${getData.read("userLogin")["email"]}");
          update();
        },
        builder: (_) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Email Verification",
                    style: TextStyle(
                      color: ccNavyText,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  customTextFormField(
                    hintText: "Enter Your Email...",
                    controller: emailController,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.emailAddress,
                    textCapitalization: TextCapitalization.none,
                    readOnly: true,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.asset(
                        "assets/image/svg/envelope.svg",
                        color: ccSecondaryText,
                      ),
                    ),
                    validator: (value) {
                      validateEmail(value);
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  isLoading
                      ? const SizedBox(
                          height: 52,
                          child: Center(
                              child: CircularProgressIndicator(color: ccPrimary)),
                        )
                      : CCButton(
                          label: "Submit",
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              if (getData.read("userLogin")["email"] ==
                                  emailController.text) {
                                emailOtpApi(
                                    email: emailController.text,
                                    openBottomsheet: true);
                              } else {
                                showToastMessage("This email doesn't match....");
                              }
                            } else {
                              showToastMessage("Please Enter Valid Email...");
                            }
                          },
                        ),
                ],
              ),
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

  emailVarificationOtpBottomsheet({required String email}) {
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
      GetBuilder<EmailVarificationController>(
        init: EmailVarificationController(),
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
                  "OTP code has been sent to your email",
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
                        emailOtpApi(email: email);
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
                          // Was comparing against `otp`, which only ever
                          // gets a real value from data["OTP"] in
                          // emailOtpApi's dev-fallback branch (no SMTP
                          // configured) — in a normal production build with
                          // SMTP working, `otp` stays "", so this check was
                          // "" == <whatever the user typed>, always false.
                          // The real code the user received by email never
                          // even reached the backend; verifiEmailApi()
                          // already sends otpController.text and lets the
                          // backend be the actual source of truth, so just
                          // require something be entered and let it decide.
                          if (otpController.text.trim().isEmpty) {
                            showToastMessage("Please enter the OTP sent to your email");
                            return;
                          }
                          verifiEmailApi();
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
