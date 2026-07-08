import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/utils/string.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/textfield/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/forget_password_screen_controller.dart';

class ForgetPasswordScreenView extends GetView<ForgetPasswordScreenController> {
  const ForgetPasswordScreenView({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: Obx(() => CCButton(
          label: "Continue",
          loading: controller.isLoading,
          onPressed: _handleContinue,
        )),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // ── Icon ────────────────────────────────────────────────
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(
                  color: ccIceBlue, shape: BoxShape.circle),
                child: const Icon(Icons.lock_reset_rounded,
                  color: ccPrimary, size: 36),
              ),
              const SizedBox(height: 24),

              // ── Heading ──────────────────────────────────────────────
              const Text("Forgot Password",
                style: TextStyle(
                  fontFamily: 'Inter', fontSize: 26,
                  fontWeight: FontWeight.w700, color: ccNavyText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your registered phone number and we'll send a reset code.",
                style: CCText.bodyLg,
              ),

              // ── Phone card ───────────────────────────────────────────
              const SizedBox(height: 32),
              GetBuilder<ForgetPasswordScreenController>(
                builder: (c) => GestureDetector(
                  onTap: () { c.colorIndex = 0; c.update(); },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ccSurface,
                      borderRadius: BorderRadius.circular(CCRadius.card),
                      border: Border.all(
                        color: c.colorIndex == 0 ? ccPrimary : ccInputBorder,
                        width: 1.5,
                      ),
                      boxShadow: CCShadow.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: c.colorIndex == 0 ? ccPrimary : ccIceBlue,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.sms_outlined,
                                color: c.colorIndex == 0
                                    ? ccSurface : ccSecondaryText,
                                size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Via SMS",
                                  style: CCText.titleMd.copyWith(
                                    color: c.colorIndex == 0
                                        ? ccNavyText : ccSecondaryText)),
                                Text("6-digit code to your phone",
                                  style: CCText.bodyMd.copyWith(
                                    color: ccSecondaryText)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        customPhoneField(
                          hintText: "080 1234 5678",
                          showCountryFlag: true,
                          controller: controller.mobileController,
                          textInputAction: TextInputAction.done,
                          errorStyle: const TextStyle(fontSize: 0),
                          onChanged: (v) {
                            controller.ccode = v.countryCode;
                            controller.update();
                          },
                          onCountryChanged: (v) {
                            controller.ccode = v.dialCode;
                            controller.update();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleContinue() {
    if (controller.mobileController.text.isEmpty) {
      showToastMessage(MyString.toastfill);
      return;
    }
    if (controller.isLoading) return;
    controller.isLoading = true;
    controller.update();

    controller.mobileCheckController.mobileCheckApi(
      mobileCheckId: controller.mobileController.text,
      ccode: controller.ccode,
    ).then((value) {
      if (value["ResponseMsg"] == "Already Exist Mobile Number!") {
        controller.smsTypeController.getMsgtype().then((value1) {
          if (value1["Result"] == "true") {
            if (value1["otp_auth"] == "Yes") {
              Get.toNamed(Routes.OTP_SCREEN, arguments: {
                "mobile": controller.mobileController.text,
                "ccode": controller.ccode,
                "smsType": value1["SMS_TYPE"],
              });
            } else {
              Get.toNamed(Routes.NEW_PASSWORD_SCREEN, arguments: {
                "mobile": controller.mobileController.text,
                "ccode": controller.ccode,
              });
            }
          } else {
            showToastMessage("${value1["ResponseMsg"]}");
          }
          controller.isLoading = false;
          controller.update();
        });
      } else {
        showToastMessage("${value["ResponseMsg"]}");
        controller.isLoading = false;
        controller.update();
      }
    });
  }
}
