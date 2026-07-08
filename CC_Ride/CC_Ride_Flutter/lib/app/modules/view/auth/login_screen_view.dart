import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/textfield/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/login_controller.dart';

class LoginScreenView extends GetView<LoginScreenController> {
  const LoginScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ccBackground,
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // Logo
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: ccPrimary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset("assets/image/textlogo.png",
                        fit: BoxFit.contain),
                  ),

                  const SizedBox(height: 28),
                  const Text("Welcome back",
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 30,
                      fontWeight: FontWeight.w700, color: ccNavyText,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text("Sign in to continue",
                    style: CCText.bodyLg.copyWith(color: ccSecondaryText)),

                  const SizedBox(height: 36),

                  // Phone / Email field
                  Obx(() => _SectionLabel(
                    label: controller.useEmail ? "Email Address" : "Phone Number",
                  )),
                  const SizedBox(height: 6),
                  Obx(() => controller.useEmail
                    ? customTextFormField(
                        hintText: "name@company.com",
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        textCapitalization: TextCapitalization.none,
                        textInputAction: TextInputAction.next,
                        borderRadius: BorderRadius.circular(CCRadius.input),
                        errorStyle: const TextStyle(fontSize: 0),
                        prefixIcon: const Icon(Icons.mail_outline_rounded,
                          color: ccPrimary, size: 20),
                        validator: controller.validateEmail,
                      )
                    : customPhoneField(
                        hintText: "080 1234 5678",
                        borderRadius: BorderRadius.circular(CCRadius.input),
                        controller: controller.mobileController,
                        showCountryFlag: true,
                        textInputAction: TextInputAction.next,
                        validator: (p) => (p == null || p.number.isEmpty)
                            ? 'Required' : null,
                        onChanged: (v) => controller.ccode = v.countryCode,
                        onCountryChanged: (v) =>
                            controller.ccode = "+${v.dialCode}",
                        errorStyle: const TextStyle(fontSize: 0),
                      ),
                  ),

                  // Toggle phone ↔ email
                  const SizedBox(height: 10),
                  Obx(() => GestureDetector(
                    onTap: () => controller.useEmail = !controller.useEmail,
                    child: Text(
                      controller.useEmail
                          ? "Sign in with phone instead"
                          : "Sign in with email instead",
                      style: CCText.bodyMd.copyWith(
                        color: ccPrimary, fontWeight: FontWeight.w600),
                    ),
                  )),

                  const SizedBox(height: 20),
                  const _SectionLabel(label: "Password"),
                  const SizedBox(height: 6),
                  Obx(() => customTextFormField(
                    hintText: "••••••••",
                    borderRadius: BorderRadius.circular(CCRadius.input),
                    controller: controller.passwordController,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    errorStyle: const TextStyle(fontSize: 0),
                    obscureText: controller.showPassword,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: ccPrimary, size: 20),
                    suffixIcon: InkWell(
                      onTap: () =>
                          controller.showPassword = !controller.showPassword,
                      child: Icon(
                        controller.showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: ccSecondaryText, size: 20,
                      ),
                    ),
                  )),

                  // Forgot password
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () =>
                          Get.toNamed(Routes.FORGET_PASSWORD_SCREEN),
                      child: Text("Forgot Password?",
                        style: CCText.bodyMd.copyWith(
                          color: ccPrimary, fontWeight: FontWeight.w600)),
                    ),
                  ),

                  // Sign In
                  const SizedBox(height: 28),
                  Obx(() => CCButton(
                    label: "Sign In",
                    loading: controller.isLoading,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _handleLogin,
                  )),

                  // Guest
                  const SizedBox(height: 14),
                  CCButton(
                    label: "Continue as Guest",
                    outlined: true,
                    onPressed: () =>
                        Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN),
                  ),

                  // Register
                  const SizedBox(height: 32),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account?",
                          style: CCText.bodyMd
                              .copyWith(color: ccSecondaryText)),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () =>
                              Get.toNamed(Routes.REG_USER_SCREEN),
                          child: Text("Create one",
                            style: CCText.bodyMd.copyWith(
                              color: ccPrimary,
                              fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() {
    if (!controller.formKey.currentState!.validate()) return;
    if (controller.isLoading) return;

    final loginId = controller.useEmail
        ? controller.emailController.text.trim()
        : controller.mobileController.text.trim();

    controller.loginApi(
      loginId: loginId,
      password: controller.passwordController.text,
      ccode: controller.useEmail ? null : controller.ccode,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(label,
    style: const TextStyle(
      fontFamily: 'Inter', fontSize: 13,
      fontWeight: FontWeight.w500, color: ccNavyText,
    ));
}
