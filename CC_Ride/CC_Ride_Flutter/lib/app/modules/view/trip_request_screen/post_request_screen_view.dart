import 'package:carride/app/modules/models/map_api_model.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/utils/string.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/textfield/suggestion_testfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../controllers/trip_request_controllers/post_request_screen_controller.dart';

class PostRequestScreenView extends GetView<PostRequestScreenController> {
  const PostRequestScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PostRequestScreenController>();
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
          Get.arguments != null ? "Edit Request".tr : "Post a Request".tr,
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
          () => c.isLoading
              ? const SizedBox(
                  height: 52,
                  child: Center(
                      child: CircularProgressIndicator(color: ccPrimary)),
                )
              : CCButton(
                  label: Get.arguments != null
                      ? "Edit Request".tr
                      : "Post a Request".tr,
                  icon: Icons.send_rounded,
                  onPressed: () {
                    if (c.fromLat.isNotEmpty &&
                        c.fromLong.isNotEmpty &&
                        c.fromAddress.isNotEmpty &&
                        c.toLat.isNotEmpty &&
                        c.toLong.isNotEmpty &&
                        c.toAddress.isNotEmpty &&
                        c.selectedDate.isNotEmpty &&
                        c.selectedSeat != 0 &&
                        c.descriptionController.text.isNotEmpty) {
                      if (!c.isLoading) {
                        if (c.formKey.currentState!.validate()) {
                          if (Get.arguments != null) {
                            c.editTriprequestApi(
                              requestId: "${Get.arguments["requestId"]}",
                              fromAddress: c.fromAddress,
                              fromLat: c.fromLat,
                              fromLong: c.fromLong,
                              toAddress: c.toAddress,
                              toLat: c.toLat,
                              toLong: c.toLong,
                              departureDate: c.selectedDate,
                              seatRequire: "${c.selectedSeat}",
                              requestDescription:
                                  c.descriptionController.text,
                            ).then((value) {
                              if (value["Result"] == "true") {
                                Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN,
                                    arguments: 2);
                              }
                            });
                          } else {
                            c.triprequestApi(
                              fromAddress: c.fromAddress,
                              fromLat: c.fromLat,
                              fromLong: c.fromLong,
                              toAddress: c.toAddress,
                              toLat: c.toLat,
                              toLong: c.toLong,
                              departureDate: c.selectedDate,
                              seatRequire: "${c.selectedSeat}",
                              requestDescription:
                                  c.descriptionController.text,
                            ).then((value) {
                              if (value["Result"] == "true") {
                                Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN,
                                    arguments: 2);
                              }
                            });
                          }
                        }
                      }
                    } else {
                      showToastMessage(MyString.toastfill);
                    }
                  },
                ),
        ),
      ),
      body: GetBuilder<PostRequestScreenController>(
        init: PostRequestScreenController(),
        initState: (state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.arguments != null) {
              c.fromLat = "${Get.arguments["fromLat"]}";
              c.fromLong = "${Get.arguments["fromLong"]}";
              c.fromAddress = "${Get.arguments["fromAddress"]}";
              c.fromController.text =
                  Get.arguments["fromAddress"].toString().split(", ").first;
              c.toLat = "${Get.arguments["toLat"]}";
              c.toLong = "${Get.arguments["toLong"]}";
              c.toAddress = "${Get.arguments["toAddress"]}";
              c.toController.text =
                  Get.arguments["toAddress"].toString().split(", ").first;
              c.descriptionController.text =
                  "${Get.arguments["requestDescription"]}";
              c.selectedSeat =
                  int.parse("${Get.arguments["seatRequire"]}");
              final picked =
                  DateTime.parse("${Get.arguments["departureDate"]}");
              c.selectedDate =
                  "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
              c.dateController.text =
                  DateFormat('EEEE, MMMM d').format(picked);
              c.update();
            }
          });
        },
        builder: (_) => Form(
          key: c.formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── From ─────────────────────────────────────────────────
                suggestionsTextField(
                  controller: c.fromController,
                  focusNode: c.focus,
                  title: "From".tr,
                  builder: (context, contro, focusNode) =>
                      _ReqLocationField(
                    ctrl: contro,
                    focusNode: focusNode,
                    hint: 'Pickup location'.tr,
                    prefixIcon: const Icon(Icons.my_location_rounded,
                        color: ccPrimary, size: 20),
                    onChanged: (value) {
                      // suggestionsCallback below already fetches (and
                      // debounces) results for this field — calling mapApi()
                      // again here fired an extra undebounced request per
                      // keystroke that could race and overwrite it with a
                      // stale response for a shorter, earlier substring.
                      c.update();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the pickup point.'.tr;
                      }
                      return null;
                    },
                    onClear: c.fromController.text.isEmpty
                        ? null
                        : () {
                            c.fromLat = '';
                            c.fromLong = '';
                            c.fromAddress = '';
                            c.fromController.clear();
                            c.update();
                          },
                  ),
                  suggestionsCallback: (pattern) async {
                    await c.mapSuggetionControlle
                        .mapApi(suggestkey: pattern);
                    return c.mapSuggetionControlle.mapApiModel?.results ??
                        [];
                  },
                  onSelected: (Result result) {
                    if (result.geometry?.location?.lat != null &&
                        result.geometry?.location?.lng != null) {
                      final lat = result.geometry!.location!.lat!;
                      final lng = result.geometry!.location!.lng!;
                      c.waypoints.add(LatLng(lat, lng));
                      c.fromLat = lat.toString();
                      c.fromLong = lng.toString();
                      c.fromAddress =
                          "${result.name}, ${result.formattedAddress}";
                      c.fromController.text = result.name ??
                          "${result.formattedAddress}";
                      c.focus.unfocus();
                      c.update();
                    }
                  },
                ),

                const SizedBox(height: 12),

                // ── To ───────────────────────────────────────────────────
                suggestionsTextField(
                  controller: c.toController,
                  focusNode: c.focus2,
                  title: "To".tr,
                  builder: (context, contro, focusNode) =>
                      _ReqLocationField(
                    ctrl: contro,
                    focusNode: focusNode,
                    hint: 'Drop-off location'.tr,
                    prefixIcon: const Icon(Icons.flag_rounded,
                        color: ccNavyText, size: 20),
                    onChanged: (value) {
                      // suggestionsCallback below already fetches (and
                      // debounces) results for this field — calling mapApi()
                      // again here fired an extra undebounced request per
                      // keystroke that could race and overwrite it with a
                      // stale response for a shorter, earlier substring.
                      c.update();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the drop point!'.tr;
                      }
                      return null;
                    },
                    onClear: c.toController.text.isEmpty
                        ? null
                        : () {
                            c.toLat = '';
                            c.toLong = '';
                            c.toAddress = '';
                            c.toController.clear();
                            c.update();
                          },
                  ),
                  suggestionsCallback: (pattern) async {
                    await c.mapSuggetionControlle
                        .mapApi(suggestkey: pattern);
                    return c.mapSuggetionControlle.mapApiModel?.results ??
                        [];
                  },
                  onSelected: (Result result) {
                    if (result.geometry?.location?.lat != null &&
                        result.geometry?.location?.lng != null) {
                      final lat = result.geometry!.location!.lat!;
                      final lng = result.geometry!.location!.lng!;
                      c.waypoints.add(LatLng(lat, lng));
                      c.toLat = lat.toString();
                      c.toLong = lng.toString();
                      c.toAddress =
                          "${result.name}, ${result.formattedAddress}";
                      c.toController.text =
                          result.name ?? "${result.formattedAddress}";
                      c.focus.unfocus();
                    }
                  },
                ),

                const SizedBox(height: 12),

                // ── Date ─────────────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Departure Date'.tr,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ccNavyText)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: c.dateController,
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date'.tr;
                        }
                        return null;
                      },
                      onTap: () {
                        c.selectDate(context).then((picked) {
                          c.selectedDate =
                              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          c.dateController.text =
                              DateFormat('EEEE, MMMM d').format(picked);
                          c.update();
                        });
                      },
                      style: const TextStyle(
                          fontFamily: 'Inter', color: ccNavyText),
                      decoration: InputDecoration(
                        hintText: 'Pick departure date'.tr,
                        hintStyle: const TextStyle(
                            fontFamily: 'Inter', color: ccSecondaryText),
                        prefixIcon: const Icon(Icons.calendar_today_rounded,
                            color: ccPrimary, size: 20),
                        filled: true,
                        fillColor: ccSurface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(CCRadius.input),
                          borderSide: const BorderSide(color: ccInputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(CCRadius.input),
                          borderSide: const BorderSide(color: ccInputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(CCRadius.input),
                          borderSide: const BorderSide(
                              color: ccPrimary, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Seats required ────────────────────────────────────────
                const Text(
                  "Seats Required",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ccNavyText,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: ccSurface,
                      borderRadius:
                          BorderRadius.circular(CCRadius.input),
                      border: Border.all(color: ccInputBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButton<int>(
                            value: c.selectedSeat,
                            menuWidth: Get.width / 1.1,
                            alignment: Alignment.centerLeft,
                            borderRadius: BorderRadius.circular(12),
                            underline: const SizedBox(),
                            icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: ccSecondaryText),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              color: ccNavyText,
                            ),
                            dropdownColor: ccSurface,
                            items: List.generate(
                                    12, (index) => index + 1)
                                .map((seat) => DropdownMenuItem(
                                      value: seat,
                                      child: Text("$seat seat${seat > 1 ? 's' : ''}"),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              c.selectedSeat = value!;
                              c.update();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Description ───────────────────────────────────────────
                const Text(
                  "About Your Trip",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ccNavyText,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: c.descriptionController,
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description cannot be empty'.tr;
                    }
                    return null;
                  },
                  onChanged: (value) {
                    c.descriptionController.text = value;
                    c.update();
                  },
                  style:
                      const TextStyle(fontFamily: 'Inter', color: ccNavyText),
                  decoration: InputDecoration(
                    hintText:
                        "Tell drivers a little bit more about you and why you're travelling."
                            .tr,
                    hintStyle: const TextStyle(
                        fontFamily: 'Inter',
                        color: ccSecondaryText,
                        fontSize: 13),
                    filled: true,
                    fillColor: ccSurface,
                    contentPadding: const EdgeInsets.all(14),
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
                      borderSide:
                          const BorderSide(color: ccPrimary, width: 1.5),
                    ),
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

class _ReqLocationField extends StatelessWidget {
  const _ReqLocationField({
    required this.ctrl,
    required this.focusNode,
    required this.hint,
    required this.prefixIcon,
    required this.onChanged,
    required this.validator,
    required this.onClear,
  });

  final TextEditingController ctrl;
  final FocusNode? focusNode;
  final String hint;
  final Widget prefixIcon;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String> validator;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      focusNode: focusNode,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(fontFamily: 'Inter', color: ccNavyText, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontFamily: 'Inter', color: ccSecondaryText, fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: prefixIcon,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        suffixIcon: onClear != null
            ? InkWell(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.close_rounded,
                      color: ccSecondaryText, size: 18),
                ),
              )
            : null,
        filled: true,
        fillColor: ccSurface,
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
