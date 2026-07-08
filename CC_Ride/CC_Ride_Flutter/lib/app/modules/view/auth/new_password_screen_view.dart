import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/utils/string.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/textfield/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/new_password_screen_controller.dart';

class NewPasswordScreenView extends GetView<NewPasswordScreenController> {
  const NewPasswordScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments ?? {};

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
          label: "Save New Password",
          loading: controller.isLoading,
          onPressed: () => _handleSave(context, args),
        )),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // ── Icon ──────────────────────────────────────────────
                Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(
                    color: ccIceBlue, shape: BoxShape.circle),
                  child: const Icon(Icons.lock_outline_rounded,
                    color: ccPrimary, size: 36),
                ),
                const SizedBox(height: 24),

                // ── Heading ────────────────────────────────────────────
                const Text("Set New Password",
                  style: TextStyle(
                    fontFamily: 'Inter', fontSize: 26,
                    fontWeight: FontWeight.w700, color: ccNavyText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text("Create a strong password for your account.",
                  style: CCText.bodyLg),

                // ── Fields ─────────────────────────────────────────────
                const SizedBox(height: 32),
                const Text("New Password", style: _labelStyle),
                const SizedBox(height: 6),
                Obx(() => customTextFormField(
                  hintText: "Enter new password",
                  controller: controller.passwordController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: controller.isObscureText,
                  errorStyle: const TextStyle(fontSize: 0),
                  borderRadius: BorderRadius.circular(CCRadius.input),
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: ccPrimary, size: 20),
                  suffixIcon: InkWell(
                    onTap: () {
                      controller.isObscureText = !controller.isObscureText;
                      controller.update();
                    },
                    child: Icon(
                      controller.isObscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: ccSecondaryText, size: 20,
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Password is required' : null,
                )),

                const SizedBox(height: 16),
                const Text("Confirm Password", style: _labelStyle),
                const SizedBox(height: 6),
                Obx(() => customTextFormField(
                  hintText: "Re-enter new password",
                  controller: controller.conformPasswordController,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: controller.isNewObscureText,
                  errorStyle: const TextStyle(fontSize: 0),
                  borderRadius: BorderRadius.circular(CCRadius.input),
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: ccPrimary, size: 20),
                  suffixIcon: InkWell(
                    onTap: () {
                      controller.isNewObscureText = !controller.isNewObscureText;
                      controller.update();
                    },
                    child: Icon(
                      controller.isNewObscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: ccSecondaryText, size: 20,
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Please confirm your password' : null,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSave(BuildContext context, Map args) {
    if (!controller.formKey.currentState!.validate()) {
      showToastMessage(MyString.toastfill);
      return;
    }
    if (controller.passwordController.text != controller.conformPasswordController.text) {
      showToastMessage("Passwords do not match");
      return;
    }
    if (controller.isLoading) return;
    controller.isLoading = true;
    controller.update();

    controller.forgetPasswordApi(
      mobile: args["mobile"],
      ccode: args["ccode"],
      password: controller.conformPasswordController.text,
    ).then((value) {
      controller.isLoading = false;
      controller.update();
      if (value != null && value["Result"] == "true") {
        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CCRadius.card)),
            backgroundColor: ccSurface,
            contentPadding: const EdgeInsets.all(28),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(
                    color: ccIceBlue, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_outline_rounded,
                    color: ccSuccess, size: 40),
                ),
                const SizedBox(height: 20),
                const Text("Password Updated!",
                  textAlign: TextAlign.center,
                  style: CCText.headlineMd),
                const SizedBox(height: 8),
                const Text(
                  "Your password has been updated successfully.",
                  textAlign: TextAlign.center,
                  style: CCText.bodyMd,
                ),
                const SizedBox(height: 24),
                CCButton(
                  label: "Back to Login",
                  onPressed: () => Get.offAllNamed(Routes.LOGIN_SCREEN),
                ),
              ],
            ),
          ),
        );
      }
    });
  }
}

const TextStyle _labelStyle = TextStyle(
  fontFamily: 'Inter', fontSize: 13,
  fontWeight: FontWeight.w500, color: ccNavyText,
);
