// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:carride/app/modules/models/color_type_model_list_api_model.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/textfield/suggestion_testfield.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';

import '../../../controllers/account_controllers/profile_controllers/vehicle_controllers/add_vehicle_screen_controller.dart';

class AddVehicleScreenView extends GetView<AddVehicleScreenController> {
  const AddVehicleScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AddVehicleScreenController>();
    return Scaffold(
      backgroundColor: ccBackground,
      appBar: AppBar(
        backgroundColor: ccSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
          onPressed: () => Get.back(),
        ),
        title: Text(
          c.isEdit ? "Edit Vehicle".tr : "Add Vehicle".tr,
          style: const TextStyle(
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
        child: Obx(
          () => c.isButtonLoading
              ? const SizedBox(
                  height: 52,
                  child: Center(
                      child: CircularProgressIndicator(color: ccPrimary)),
                )
              : CCButton(
                  label: c.isEdit ? "Save Changes".tr : "Add Vehicle".tr,
                  icon: c.isEdit
                      ? Icons.save_rounded
                      : Icons.check_rounded,
                  onPressed: () async {
                    final exists = c.colorTypeModelListApiModel!.modelData!
                        .any((e) => e.title!
                            .contains(c.modelListController.text));
                    if (!exists) {
                      showToastMessage("Selected model is not matched.");
                      return;
                    }
                    if (c.isEdit) {
                      if (!c.isButtonLoading) {
                        c.isButtonLoading = true;
                        c.update();
                        await c.editVehicleApi(
                          modelId: c.carModelId,
                          typeId: c.selectedtypeId ?? "",
                          colorId: c.selectedColorId ?? "",
                          year: c.yearcontroller.text,
                          licensePlate: c.licencecontroller.text,
                          status: "1",
                          photo: c.selectImage?.path ?? "",
                        );
                      }
                    } else {
                      if (c.selectedtypeId == null ||
                          c.selectedtypeId!.isEmpty) {
                        showToastMessage("Please select a car type".tr);
                        return;
                      }
                      if (c.modelListController.text.isEmpty) {
                        showToastMessage("Please enter the car model");
                        return;
                      }
                      if (c.selectedColorId == null ||
                          c.selectedColorId!.isEmpty) {
                        showToastMessage("Please select a color".tr);
                        return;
                      }
                      if (c.yearcontroller.text.isEmpty) {
                        showToastMessage("Please enter the year".tr);
                        return;
                      }
                      if (c.licencecontroller.text.isEmpty) {
                        showToastMessage(
                            "Please enter the license plate".tr);
                        return;
                      }
                      if (c.selectImage == null ||
                          c.selectImage!.path.isEmpty) {
                        showToastMessage("Please select an image".tr);
                        return;
                      }
                      if (!c.isButtonLoading) {
                        c.isButtonLoading = true;
                        c.update();
                        await c.addVehicleApi(
                          modelId: c.carModelId,
                          typeId: c.selectedtypeId ?? "",
                          colorId: c.selectedColorId ?? "",
                          year: c.yearcontroller.text,
                          licensePlate: c.licencecontroller.text,
                          status: "1",
                          photo: c.selectImage!.path,
                        );
                      }
                    }
                  },
                ),
        ),
      ),
      body: Obx(
        () => c.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ccPrimary))
            : Form(
                key: c.formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Vehicle Photo ──────────────────────────────────
                      const Text("Vehicle Photo", style: CCText.titleMd),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => c.selectImageBottomsheet(),
                        child: Obx(
                          () => Container(
                            width: double.infinity,
                            height: 190,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(CCRadius.card),
                              color: ccSurface,
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: DottedBorder(
                              dashPattern: const [6, 4],
                              borderType: BorderType.RRect,
                              color: ccInputBorder,
                              radius:
                                  const Radius.circular(CCRadius.card),
                              child: Center(
                                child: c.selectImage != null
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(
                                                CCRadius.card),
                                        child: Image.file(
                                          File(c.selectImage!.path),
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : c.isEdit
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    CCRadius.card),
                                            child:
                                                FadeInImage.assetNetwork(
                                              placeholder:
                                                  "assets/image/ezgif.com-crop.gif",
                                              placeholderFit:
                                                  BoxFit.cover,
                                              image:
                                                  "${Get.arguments["photo"]}",
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(
                                                        14),
                                                decoration:
                                                    const BoxDecoration(
                                                  color: ccIceBlue,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                    Icons.cloud_upload_rounded,
                                                    color: ccPrimary,
                                                    size: 28),
                                              ),
                                              const SizedBox(height: 10),
                                              const Text(
                                                "Tap to choose a vehicle photo",
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                  color: ccNavyText,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                "JPEG or PNG, max 1 MB",
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 12,
                                                  color: ccSecondaryText,
                                                ),
                                              ),
                                            ],
                                          ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Vehicle Information ──────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ccSurface,
                          borderRadius:
                              BorderRadius.circular(CCRadius.card),
                          boxShadow: CCShadow.card,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Vehicle Information",
                                style: CCText.titleMd),
                            const SizedBox(height: 16),

                            // Model
                            c.vehicleDetailsData(
                              title: "Model".tr,
                              child: TypeAheadField<Datum>(
                                controller: c.modelListController,
                                builder: (context, contro, focusNode) =>
                                    TextField(
                                  controller: contro,
                                  focusNode: focusNode,
                                  style: const TextStyle(
                                      fontFamily: 'Inter', color: ccNavyText),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Eco Sport',
                                    hintStyle: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: ccSecondaryText),
                                    filled: true,
                                    fillColor: ccBackground,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          CCRadius.input),
                                      borderSide: const BorderSide(
                                          color: ccInputBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          CCRadius.input),
                                      borderSide: const BorderSide(
                                          color: ccInputBorder),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          CCRadius.input),
                                      borderSide: const BorderSide(
                                          color: ccPrimary, width: 1.5),
                                    ),
                                  ),
                                ),
                                suggestionsCallback: (pattern) async {
                                  if (pattern.trim().isEmpty) return [];
                                  return c.colorTypeModelListApiModel!
                                      .modelData!
                                      .where((m) => m.title!
                                          .toLowerCase()
                                          .contains(
                                              pattern.toLowerCase()))
                                      .toList();
                                },
                                itemBuilder:
                                    (context, Datum suggestion) =>
                                        Padding(
                                          padding:
                                              const EdgeInsets.all(12),
                                          child: Text(
                                            "${suggestion.title}",
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w600,
                                              color: ccNavyText,
                                            ),
                                          ),
                                        ),
                                onSelected: (Datum suggestion) {
                                  c.modelListController.text =
                                      suggestion.title ?? '';
                                  c.carModelId =
                                      suggestion.id.toString();
                                },
                                emptyBuilder: (context) =>
                                    const SizedBox.shrink(),
                                loadingBuilder: (context) =>
                                    const SizedBox.shrink(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Type
                            c.vehicleDetailsData(
                              title: "Type".tr,
                              child: dropdownFile(
                                hintText: "e.g. SUV, Sedan",
                                value: c.selectedtype,
                                items: (c.colorTypeModelListApiModel!
                                            .carTypeData ??
                                        [])
                                    .map((type) => DropdownMenuItem<String>(
                                          onTap: () {
                                            c.selectedtypeId = type.id!;
                                            c.selectedtype = type.title!;
                                          },
                                          value: type.title,
                                          child: Text(
                                            type.title!,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              color: ccNavyText,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (_) {},
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Color
                            c.vehicleDetailsData(
                              title: "Color".tr,
                              child: dropdownFile(
                                hintText: "Select color",
                                value: c.selectedColor,
                                items: (c.colorTypeModelListApiModel
                                            ?.carColorData ??
                                        [])
                                    .map((type) => DropdownMenuItem<String>(
                                          onTap: () {
                                            c.selectedColorId = type.id;
                                            c.selectedColor = type.title!;
                                          },
                                          value: type.title,
                                          child: Text(
                                            type.title!,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              color: ccNavyText,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (_) {},
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Year
                            c.vehicleDetailsData(
                              title: "Year".tr,
                              child: _VehicleTextField(
                                hint: 'YYYY',
                                controller: c.yearcontroller,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Plate
                            c.vehicleDetailsData(
                              title: "Plate".tr,
                              child: _VehicleTextField(
                                hint: 'e.g. LAG-123-XY',
                                controller: c.licencecontroller,
                                textCapitalization:
                                    TextCapitalization.characters,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.done,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _VehicleTextField extends StatelessWidget {
  const _VehicleTextField({
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
  });

  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontFamily: 'Inter', color: ccNavyText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontFamily: 'Inter', color: ccSecondaryText),
        filled: true,
        fillColor: ccBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
      ),
    );
  }
}
