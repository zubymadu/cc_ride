// ignore_for_file: deprecated_member_use

import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../controllers/auth/otp_screen_controller.dart';

class OtpScreenView extends GetView<OtpScreenController> {
  const OtpScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments ?? {};
    final mobile = "${args["ccode"] ?? ""} ${args["mobile"] ?? ""}".trim();

    return Scaffold(
      backgroundColor: ccBackground,
      appBar: AppBar(
        backgroundColor: ccSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
          onPressed: () => Get.back(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: ccInputBorder),
        ),
      ),
      bottomNavigationBar: Container(
        color: ccSurface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => CCButton(
              label: "Verify",
              loading: controller.isLoading,
              onPressed: () => _handleVerify(args),
            )),
            const SizedBox(height: 12),
            Text(
              "By continuing, you agree to our Terms of Service and Privacy Policy.",
              textAlign: TextAlign.center,
              style: CCText.labelSm.copyWith(letterSpacing: 0),
            ),
          ],
        ),
      ),
      body: GetBuilder<OtpScreenController>(
        init: OtpScreenController(),
        initState: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (args.isNotEmpty) controller.getOtp(smsType: args["smsType"]);
          });
        },
        builder: (_) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Column(
              children: [
                // ── Icon ──────────────────────────────────────────────
                Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(
                    color: ccIceBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded,
                    color: ccPrimary, size: 36),
                ),
                const SizedBox(height: 24),

                // ── Heading ───────────────────────────────────────────
                const Text("Verify Your Number",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter', fontSize: 26,
                    fontWeight: FontWeight.w700, color: ccNavyText,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: CCText.bodyLg.copyWith(color: ccSecondaryText),
                    children: [
                      const TextSpan(text: "We sent a 6-digit code to\n"),
                      TextSpan(text: mobile.isEmpty ? "your number" : mobile,
                        style: const TextStyle(
                          color: ccNavyText, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),

                // ── OTP Pinput ────────────────────────────────────────
                const SizedBox(height: 40),
                Pinput(
                  length: 6,
                  controller: controller.otpController,
                  defaultPinTheme: PinTheme(
                    width: 52, height: 58,
                    textStyle: const TextStyle(
                      fontFamily: 'Inter', fontSize: 22,
                      fontWeight: FontWeight.w700, color: ccNavyText,
                    ),
                    decoration: BoxDecoration(
                      color: ccSurface,
                      borderRadius: BorderRadius.circular(CCRadius.btn),
                      border: Border.all(color: ccInputBorder, width: 1.5),
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 52, height: 58,
                    textStyle: const TextStyle(
                      fontFamily: 'Inter', fontSize: 22,
                      fontWeight: FontWeight.w700, color: ccPrimary,
                    ),
                    decoration: BoxDecoration(
                      color: ccIceBlue,
                      borderRadius: BorderRadius.circular(CCRadius.btn),
                      border: Border.all(color: ccPrimary, width: 2),
                    ),
                  ),
                  submittedPinTheme: PinTheme(
                    width: 52, height: 58,
                    textStyle: const TextStyle(
                      fontFamily: 'Inter', fontSize: 22,
                      fontWeight: FontWeight.w700, color: ccNavyText,
                    ),
                    decoration: BoxDecoration(
                      color: ccSurface,
                      borderRadius: BorderRadius.circular(CCRadius.btn),
                      border: Border.all(color: ccPrimary, width: 1.5),
                    ),
                  ),
                  errorText: "Invalid code",
                ),

                // ── Resend ────────────────────────────────────────────
                const SizedBox(height: 24),
                Obx(() {
                  final canResend = controller.counter == 0;
                  return Column(
                    children: [
                      if (!canResend)
                        RichText(
                          text: TextSpan(
                            style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                            children: [
                              const TextSpan(text: "Resend code in "),
                              TextSpan(
                                text: "00:${controller.counter.toString().padLeft(2, '0')}",
                                style: const TextStyle(
                                  color: ccPrimary, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: canResend ? () {
                          controller.resendCode = true;
                          controller.startTimer();
                          controller.update();
                          controller.otpController.clear();
                          controller.smsTypeController.getMsgtype().then((v) {
                            if (v["SMS_TYPE"] == "Msg91") {
                              controller.getOtp(smsType: "${v["SMS_TYPE"]}");
                            }
                          });
                        } : null,
                        child: Text("Resend Code",
                          style: CCText.titleMd.copyWith(
                            color: canResend ? ccPrimary : ccSecondaryText,
                            decoration: canResend ? TextDecoration.underline : null,
                          )),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleVerify(Map args) {
    if (controller.otp != controller.otpController.text) {
      showToastMessage("Please enter valid OTP");
      return;
    }
    if (controller.isLoading) return;
    controller.isLoading = true;
    controller.update();

    if (args["name"] != null) {
      controller.regUserScreenController.registerApi(
        name: args["name"],
        email: args["email"],
        mobile: args["mobile"],
        ccode: args["ccode"],
        password: args["password"],
        refercode: args["rcode"],
        age: args["age"],
        dob: args["dob"],
        bio: args["bio"],
        videoPaths: [args["videoPaths"]],
        isMobileVerify: "1",
      ).then((_) {
        controller.isLoading = false;
        controller.update();
      });
    } else {
      Get.toNamed(Routes.NEW_PASSWORD_SCREEN, arguments: {
        "mobile": args["mobile"],
        "ccode": args["ccode"],
      });
      controller.isLoading = false;
      controller.update();
    }
  }
}
