// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/textfield/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/auth/reg_user_screen_controller.dart';

class RegUserScreenView extends GetView<RegUserScreenController> {
  const RegUserScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ccBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                      color: ccNavyText),
                    onPressed: () => Get.back(),
                  ),
                  const Spacer(),
                  // Step indicator
                  Obx(() => _StepDots(step: controller.step)),
                  const Spacer(),
                  // invisible placeholder to centre the dots
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Content ────────────────────────────────────────────────
            Expanded(
              child: Form(
                key: controller.formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Obx(() => controller.step == 0
                      ? _Step1(controller: controller)
                      : _Step2(controller: controller)),
                ),
              ),
            ),

            // ── Bottom action ──────────────────────────────────────────
            Container(
              color: ccSurface,
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() => CCButton(
                    label: controller.step == 0 ? "Continue" : "Create Account",
                    loading: controller.isLoading,
                    icon: controller.step == 0
                        ? Icons.arrow_forward_rounded
                        : Icons.check_rounded,
                    onPressed: () => _handleAction(context),
                  )),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account?",
                        style: CCText.bodyMd.copyWith(color: ccSecondaryText)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Text("Sign in",
                          style: CCText.bodyMd.copyWith(
                            color: ccPrimary, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context) {
    if (controller.isLoading) return;
    if (controller.step == 0) {
      // Validate step 1 fields
      if (!controller.formKey.currentState!.validate() ||
          controller.mobileController.text.isEmpty) {
        showToastMessage("Please fill in all required fields");
        return;
      }
      controller.step = 1;
    } else {
      // Final submit — call registerApi directly
      _submit();
    }
  }

  void _submit() {
    if (controller.isLoading) return;
    controller.isLoading = true;

    controller.registerApi(
      name: controller.nameController.text,
      email: controller.emailController.text,
      mobile: controller.mobileController.text,
      ccode: controller.ccode,
      password: controller.passwordController.text,
      refercode: "",
      age: "",
      dob: "",
      bio: "",
      videoPaths: controller.selectImage != null
          ? [controller.selectImage!.path]
          : [],
      isMobileVerify: "0",
    ).then((_) {
      controller.isLoading = false;
    }).catchError((e) {
      controller.isLoading = false;
      showToastMessage("Registration failed. Please try again.");
    });
  }
}

// ─── Step 1: Name · Phone · Password ─────────────────────────────────────────

class _Step1 extends StatelessWidget {
  const _Step1({required this.controller});
  final RegUserScreenController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text("Create Account",
          style: TextStyle(
            fontFamily: 'Inter', fontSize: 28,
            fontWeight: FontWeight.w700, color: ccNavyText,
          ),
        ),
        const SizedBox(height: 6),
        Text("Start with the basics",
          style: CCText.bodyLg.copyWith(color: ccSecondaryText)),

        const SizedBox(height: 32),
        const _Label("Full Name"),
        const SizedBox(height: 6),
        customTextFormField(
          hintText: "Your full name",
          controller: controller.nameController,
          keyboardType: TextInputType.name,
          borderRadius: BorderRadius.circular(CCRadius.input),
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.person_outline_rounded,
            color: ccPrimary, size: 20),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),

        const SizedBox(height: 20),
        const _Label("Phone Number"),
        const SizedBox(height: 6),
        customPhoneField(
          controller: controller.mobileController,
          hintText: "080 1234 5678",
          borderRadius: BorderRadius.circular(CCRadius.input),
          showCountryFlag: true,
          onChanged: (v) => controller.ccode = v.countryCode,
          onCountryChanged: (v) => controller.ccode = "+${v.dialCode}",
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: 20),
        const _Label("Password"),
        const SizedBox(height: 6),
        Obx(() => customTextFormField(
          hintText: "Create a strong password",
          controller: controller.passwordController,
          borderRadius: BorderRadius.circular(CCRadius.input),
          obscureText: controller.showPassword,
          textInputAction: TextInputAction.done,
          errorStyle: const TextStyle(fontSize: 0),
          prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: ccPrimary, size: 20),
          suffixIcon: InkWell(
            onTap: () {
              controller.showPassword = !controller.showPassword;
              controller.update();
            },
            child: Icon(
              controller.showPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: ccSecondaryText, size: 20,
            ),
          ),
          validator: (v) =>
              (v == null || v.length < 6) ? 'Min 6 characters' : null,
        )),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Step 2: Email · Photo (both optional) ───────────────────────────────────

class _Step2 extends StatelessWidget {
  const _Step2({required this.controller});
  final RegUserScreenController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text("Almost there",
          style: TextStyle(
            fontFamily: 'Inter', fontSize: 28,
            fontWeight: FontWeight.w700, color: ccNavyText,
          ),
        ),
        const SizedBox(height: 6),
        Text("These are optional — you can add them later",
          style: CCText.bodyLg.copyWith(color: ccSecondaryText)),

        // Profile photo
        const SizedBox(height: 32),
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Obx(() => Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ccInputBorder, width: 2),
                  color: ccIceBlue,
                ),
                clipBehavior: Clip.antiAlias,
                child: controller.selectImage != null
                    ? Image.file(File(controller.selectImage!.path),
                        fit: BoxFit.cover)
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: SvgPicture.asset(
                          "assets/image/svg/user-filled.svg",
                          color: ccSecondaryText,
                        ),
                      ),
              )),
              GestureDetector(
                onTap: () => controller.selectImageBottomsheet(),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ccPrimary,
                    border: Border.all(color: ccSurface, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text("Add a profile photo",
            style: TextStyle(
              fontFamily: 'Inter', fontSize: 13,
              color: ccSecondaryText,
            )),
        ),

        // Email
        const SizedBox(height: 28),
        const _Label("Work Email  "),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: ccIceBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                color: ccPrimary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Use your company email to auto-link to your corporate account",
                  style: CCText.labelSm.copyWith(color: ccPrimaryDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        customTextFormField(
          hintText: "you@company.com",
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          textCapitalization: TextCapitalization.none,
          borderRadius: BorderRadius.circular(CCRadius.input),
          textInputAction: TextInputAction.done,
          prefixIcon: const Icon(Icons.mail_outline_rounded,
            color: ccPrimary, size: 20),
        ),

        const SizedBox(height: 24),
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: CCText.labelSm.copyWith(color: ccSecondaryText),
              children: const [
                TextSpan(text: "By continuing you agree to our "),
                TextSpan(text: "Terms",
                  style: TextStyle(
                    color: ccPrimary, fontWeight: FontWeight.w600)),
                TextSpan(text: " and "),
                TextSpan(text: "Privacy Policy",
                  style: TextStyle(
                    color: ccPrimary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Shared widgets ────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(
      fontFamily: 'Inter', fontSize: 13,
      fontWeight: FontWeight.w500, color: ccNavyText,
    ));
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(2, (i) {
        final active = i == step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? ccPrimary : ccInputBorder,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
