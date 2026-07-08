import 'dart:io';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/utils/string.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/textfield/custom_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/account_controllers/profile_controllers/personal_details_controller.dart';

class PersonalDetailsView extends GetView<PersonalDetailsController> {
  const PersonalDetailsView({super.key});

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
        title: const Text(
          "Personal Details",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ccNavyText,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: ccInputBorder),
        ),
      ),
      bottomNavigationBar: Container(
        color: ccSurface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Obx(() => CCButton(
              label: "Update Profile",
              loading: controller.isLoading,
              onPressed: () {
                if (controller.formKey.currentState!.validate()) {
                  if (controller.phoneController.text.isNotEmpty &&
                      controller.emailController.text.isNotEmpty &&
                      controller.nameController.text.isNotEmpty &&
                      controller.dobController.text.isNotEmpty &&
                      controller.bioController.text.isNotEmpty &&
                      controller.ccode.isNotEmpty) {
                    if (controller.selectImage != null) {
                      controller
                          .updateProfileImage(img: controller.base64Url.value)
                          .then((_) {
                        controller.updateProfile(
                          name: controller.nameController.text,
                          email: controller.emailController.text,
                          phone: controller.phoneController.text,
                          dob: controller.dobController.text,
                          bio: controller.bioController.text,
                          password: controller.passwordController.text,
                          isDriver: controller.isDriver,
                        );
                      });
                    } else {
                      controller.updateProfile(
                        name: controller.nameController.text,
                        email: controller.emailController.text,
                        phone: controller.phoneController.text,
                        dob: controller.dobController.text,
                        bio: controller.bioController.text,
                        password: controller.passwordController.text,
                        isDriver: controller.isDriver,
                      );
                    }
                  } else {
                    showToastMessage(MyString.toastfill);
                  }
                }
              },
            )),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile photo ──────────────────────────────────────────
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Obx(() => Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ccIceBlue,
                            border:
                                Border.all(color: ccInputBorder, width: 2),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: controller.selectImage == null
                              ? getData.read("userLogin")["profile_pic"] ==
                                      null
                                  ? Center(
                                      child: Text(
                                        getData.read("userLogin")["name"][0]
                                            .toString()
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 36,
                                          fontWeight: FontWeight.w700,
                                          color: ccPrimary,
                                        ),
                                      ),
                                    )
                                  : FadeInImage.assetNetwork(
                                      placeholder:
                                          "assets/image/ezgif.com-crop.gif",
                                      image:
                                          "${Confing.imageurl}${getData.read("userLogin")["profile_pic"]}",
                                      fit: BoxFit.cover,
                                    )
                              : Image.file(
                                  File(controller.selectImage!.path),
                                  fit: BoxFit.cover,
                                ),
                        )),
                    GestureDetector(
                      onTap: () => controller.selectImageBottomsheet(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ccPrimary,
                          border: Border.all(color: ccSurface, width: 2),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Form fields ────────────────────────────────────────────
              _label("Full Name"),
              _ProfileField(
                hintText: "Enter your full name",
                controller: controller.nameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name is required' : null,
              ),

              const SizedBox(height: 16),
              _label("Phone Number"),
              customPhoneField(
                hintText: "801 234 5678",
                controller: controller.phoneController,
                textInputAction: TextInputAction.next,
                readOnly:
                    getData.read("userLogin")["is_mobile_verify"] == "1",
                borderRadius: BorderRadius.circular(CCRadius.input),
                onTap: () {
                  if (getData.read("userLogin")["is_mobile_verify"] == "1") {
                    showToastMessage(
                        "Your phone number has been verified and cannot be updated.");
                  }
                },
                onCountryChanged: (v) => controller.ccode = "+${v.dialCode}",
              ),

              const SizedBox(height: 16),
              _label("Email Address"),
              _ProfileField(
                hintText: "name@company.com",
                controller: controller.emailController,
                readOnly: getData.read("userLogin")["is_email_verify"] == "1",
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onTap: () {
                  if (getData.read("userLogin")["is_email_verify"] == "1") {
                    showToastMessage(
                        "Your email has been verified and cannot be updated.");
                  }
                },
                validator: (v) => controller.validateEmail(v),
              ),

              const SizedBox(height: 16),
              _label("Password"),
              Obx(() => _ProfileField(
                    hintText: "New password (leave blank to keep current)",
                    controller: controller.passwordController,
                    obscureText: controller.showPassword,
                    suffixIcon: InkWell(
                      onTap: () {
                        controller.showPassword = !controller.showPassword;
                      },
                      child: Icon(
                        controller.showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: ccSecondaryText,
                        size: 20,
                      ),
                    ),
                  )),

              const SizedBox(height: 16),
              _label("Date of Birth"),
              _ProfileField(
                readOnly: true,
                hintText: "Select date of birth",
                controller: controller.dobController,
                prefixIcon: const Icon(Icons.calendar_today_outlined,
                    color: ccPrimary, size: 18),
                onTap: () => controller.selectDate(context).then((value) {
                  if (value != null) controller.dobController.text = value;
                }),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Date of birth is required' : null,
              ),

              const SizedBox(height: 16),
              _label("Bio"),
              _ProfileField(
                hintText: "Tell us about yourself",
                maxLines: 4,
                controller: controller.bioController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Bio is required' : null,
              ),

              // ── Driver toggle ──────────────────────────────────────────
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ccSurface,
                  borderRadius: BorderRadius.circular(CCRadius.card),
                  boxShadow: CCShadow.card,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: ccIceBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.directions_car_rounded,
                          color: ccPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("I'm a driver",
                              style: CCText.titleMd),
                          Text("Enable to post trips and earn",
                              style: CCText.bodyMd),
                        ],
                      ),
                    ),
                    Obx(() => CupertinoSwitch(
                          value: controller.isDriver,
                          activeColor: ccPrimary,
                          onChanged: (v) => controller.isDriver = v,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: ccNavyText,
          ),
        ),
      );
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    this.hintText,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.validator,
  });

  final TextEditingController controller;
  final String? hintText;
  final bool readOnly;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onTap: onTap,
      validator: validator,
      style: const TextStyle(fontFamily: 'Inter', color: ccNavyText),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle:
            const TextStyle(fontFamily: 'Inter', color: ccSecondaryText),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: ccSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CCRadius.input),
          borderSide: const BorderSide(color: ccInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CCRadius.input),
          borderSide: const BorderSide(color: ccInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CCRadius.input),
          borderSide: const BorderSide(color: ccPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CCRadius.input),
          borderSide: const BorderSide(color: ccError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CCRadius.input),
          borderSide: const BorderSide(color: ccError, width: 1.5),
        ),
      ),
    );
  }
}
