// ignore_for_file: deprecated_member_use

import 'package:carride/app/modules/controllers/intro_controllers/splash_screen_controller.dart';
import 'package:carride/app/modules/models/map_api_model.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/utils/string.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/textfield/suggestion_testfield.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controllers/post_controllers/multipolyline_map_screen_controller.dart';

class MultipolylineMapScreenView
    extends GetView<MultipolylineMapScreenController> {
  const MultipolylineMapScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ccSurface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: ccSurface,
          elevation: 0,
          title: Text(
            Get.arguments != null ? 'Edit a trip'.tr : 'Post a trip'.tr,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: ccNavyText,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
            onPressed: () => Get.back(),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(color: ccInputBorder, height: 1),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (controller.formKey.currentState!.validate() &&
                  controller.postTripController.originAddress != '' &&
                  controller.postTripController.originLat != '' &&
                  controller.postTripController.originLong != '' &&
                  controller.postTripController.destiLat != '' &&
                  controller.postTripController.destiLong != '' &&
                  controller.postTripController.destiAddress != '') {
                Get.toNamed(Routes.RIDE_SCHEDULE_SCREEN,
                    arguments: Get.arguments);
              } else {
                showToastMessage(MyString.toastfill);
              }
              controller.update();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ccPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CCRadius.btn)),
            ),
            child: Text(
              'Next'.tr,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: GetBuilder<MultipolylineMapScreenController>(
        initState: (state) async {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await controller.loadCustomIcons();
            if (Get.arguments != null) {
              controller.postTripController.stopData.clear();
              controller.stopControllers.clear();

              controller.originController.text =
                  Get.arguments['origin_address']
                      .toString()
                      .split(',')
                      .first
                      .trim();
              controller.postTripController.originAddress =
                  Get.arguments['origin_address'];
              controller.postTripController.originLat =
                  Get.arguments['origin_lat'];
              controller.postTripController.originLong =
                  Get.arguments['origin_long'];

              controller.destinationController.text =
                  Get.arguments['desti_address']
                      .toString()
                      .split(',')
                      .first
                      .trim();
              controller.postTripController.destiAddress =
                  Get.arguments['desti_address'];
              controller.postTripController.destiLat =
                  Get.arguments['desti_lat'];
              controller.postTripController.destiLong =
                  Get.arguments['desti_long'];

              controller.postTripController.stopData =
                  Get.arguments['stopdata'] ?? [];

              controller.postTripController.requestId =
                  Get.arguments['request_id'] ?? '0';

              for (int i = 0;
                  i < controller.postTripController.stopData.length;
                  i++) {
                final stop = controller.postTripController.stopData[i];
                final control = TextEditingController(
                  text:
                      stop['stop_address'].toString().split(',').first.trim(),
                );
                controller.stopControllers.add(control);
                controller.focusNode.add(FocusNode());
              }

              await controller.generateRoute();
            }
            controller.update();
          });
        },
        builder: (controller) {
          return Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ccBackground,
                        borderRadius: BorderRadius.circular(CCRadius.card),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Origin field
                                  suggestionsTextField(
                                    controller: controller.originController,
                                    focusNode: controller.focus,
                                    builder: (context, ctrl, focusNode) {
                                      return _LocationField(
                                        ctrl: ctrl,
                                        focusNode: focusNode,
                                        hint: 'From'.tr,
                                        onChanged: (value) async {
                                          await controller
                                              .mapSuggetionControlle
                                              .mapApi(suggestkey: value);
                                          controller.update();
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter the Pickup point.'.tr;
                                          }
                                          controller.update();
                                          return null;
                                        },
                                        onClear: controller.originController
                                                .text.isEmpty
                                            ? null
                                            : () {
                                                controller.postTripController
                                                    .originLat = '';
                                                controller.postTripController
                                                    .originLong = '';
                                                controller.postTripController
                                                    .originAddress = '';
                                                controller.originController
                                                    .clear();
                                                controller.generateRoute();
                                                controller.update();
                                              },
                                      );
                                    },
                                    suggestionsCallback: (pattern) async {
                                      return controller.mapSuggetionControlle
                                          .mapApi(suggestkey: pattern);
                                    },
                                    onSelected: (Result result) {
                                      if (result.geometry?.location?.lat !=
                                              null &&
                                          result.geometry?.location?.lng !=
                                              null) {
                                        final lat =
                                            result.geometry!.location!.lat!;
                                        final lng =
                                            result.geometry!.location!.lng!;
                                        controller.waypoints
                                            .add(LatLng(lat, lng));
                                        controller.originController.text =
                                            result.name == null
                                                ? '${result.formattedAddress}'
                                                : '${result.name}';
                                        controller.postTripController
                                            .originAddress =
                                            '${result.name}, ${result.formattedAddress}';
                                        controller.postTripController
                                            .originLat = double.parse('$lat')
                                                .toStringAsFixed(4);
                                        controller.postTripController
                                            .originLong = double.parse('$lng')
                                                .toStringAsFixed(4);
                                        controller.focus.unfocus();
                                        controller.update();
                                        controller.generateRoute();
                                        controller.postTripController.update();
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 10),

                                  // Destination field
                                  suggestionsTextField(
                                    controller:
                                        controller.destinationController,
                                    focusNode: controller.focus2,
                                    builder: (context, ctrl, focusNode) {
                                      return _LocationField(
                                        ctrl: ctrl,
                                        focusNode: focusNode,
                                        hint: 'To'.tr,
                                        onChanged: (value) async {
                                          await controller
                                              .mapSuggetionControlle
                                              .mapApi(suggestkey: value);
                                          controller.update();
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter the Drop point!';
                                          }
                                          return null;
                                        },
                                        onClear: controller
                                                .destinationController
                                                .text
                                                .isEmpty
                                            ? null
                                            : () {
                                                controller.postTripController
                                                    .destiLat = '';
                                                controller.postTripController
                                                    .destiLong = '';
                                                controller.postTripController
                                                    .destiAddress = '';
                                                controller.destinationController
                                                    .clear();
                                                controller.focus2.unfocus();
                                                controller.generateRoute();
                                                controller.update();
                                              },
                                      );
                                    },
                                    suggestionsCallback: (pattern) async {
                                      return controller.mapSuggetionControlle
                                          .mapApi(suggestkey: pattern);
                                    },
                                    onSelected: (Result result) {
                                      if (result.geometry?.location?.lat !=
                                              null &&
                                          result.geometry?.location?.lng !=
                                              null) {
                                        final lat =
                                            result.geometry!.location!.lat!;
                                        final lng =
                                            result.geometry!.location!.lng!;
                                        controller.waypoints
                                            .add(LatLng(lat, lng));
                                        controller.destinationController.text =
                                            result.name == null
                                                ? '${result.formattedAddress}'
                                                : '${result.name}';
                                        controller.postTripController
                                            .destiAddress =
                                            '${result.name}, ${result.formattedAddress}';
                                        controller.postTripController
                                            .destiLat = '$lat';
                                        controller.postTripController
                                            .destiLong = '$lng';
                                        controller.update();
                                        controller.postTripController.update();
                                        controller.focus2.unfocus();
                                        controller.generateRoute();
                                      }
                                    },
                                  ),
                                ],
                              ),

                              // Swap button
                              InkWell(
                                onTap: () => controller.swapLocations(),
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: const BoxDecoration(
                                    color: ccPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: SvgPicture.asset(
                                    'assets/image/svg/arrow-down-arrow-up.svg',
                                    color: Colors.white,
                                    height: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Stop fields
                          ...controller.stopControllers
                              .asMap()
                              .entries
                              .map((entry) {
                            final index = entry.key;
                            final ctrl = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: suggestionsTextField(
                                controller: ctrl,
                                focusNode:
                                    controller.focusNode.length > index
                                        ? controller.focusNode[index]
                                        : null,
                                builder: (context, textCtrl, node) {
                                  return _LocationField(
                                    ctrl: textCtrl,
                                    focusNode: node,
                                    hint: 'Add bookings'.tr,
                                    onChanged: (value) async {
                                      await controller.mapSuggetionControlle
                                          .mapApi(suggestkey: value);
                                      controller.update();
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter the Drop point!'.tr;
                                      }
                                      return null;
                                    },
                                    onClear: () {
                                      controller.stopControllers
                                          .removeAt(index);
                                      if (controller.focusNode.length >
                                          index) {
                                        controller.focusNode.removeAt(index);
                                      }
                                      if (index <
                                          controller.waypoints.length) {
                                        controller.waypoints.removeAt(index);
                                      }
                                      if (index <
                                          controller.postTripController
                                              .stopData.length) {
                                        controller.postTripController.stopData
                                            .removeAt(index);
                                      }
                                      if (controller.waypoints.length < 2) {
                                        controller.polylines.clear();
                                      }
                                      controller.markers.clear();
                                      for (int i = 0;
                                          i < controller.waypoints.length;
                                          i++) {
                                        controller.markers.add(Marker(
                                            markerId:
                                                MarkerId('marker_$i'),
                                            position:
                                                controller.waypoints[i]));
                                      }
                                      controller.update();
                                      controller.mapSuggetionControlle
                                          .update();
                                      controller.postTripController.update();
                                      controller.generateRoute();
                                    },
                                  );
                                },
                                suggestionsCallback: (pattern) async {
                                  return controller.mapSuggetionControlle
                                      .mapApi(suggestkey: pattern);
                                },
                                onSelected: (Result result) {
                                  if (result.geometry?.location?.lat !=
                                          null &&
                                      result.geometry?.location?.lng !=
                                          null) {
                                    final lat =
                                        result.geometry!.location!.lat!;
                                    final lng =
                                        result.geometry!.location!.lng!;
                                    final fullAddress =
                                        '${result.name}, ${result.formattedAddress}';
                                    controller.waypoints
                                        .add(LatLng(lat, lng));
                                    ctrl.text = result.name == null
                                        ? '${result.formattedAddress}'
                                        : '${result.name}';
                                    final newStop = {
                                      'stop_address': fullAddress,
                                      'stop_lat': lat.toString(),
                                      'stop_long': lng.toString(),
                                    };
                                    final isExist = controller
                                        .postTripController.stopData
                                        .any((item) =>
                                            item['stop_address'] ==
                                                newStop['stop_address'] &&
                                            item['stop_lat'] ==
                                                newStop['stop_lat'] &&
                                            item['stop_long'] ==
                                                newStop['stop_long']);
                                    if (!isExist) {
                                      controller.postTripController.stopData
                                          .add(newStop);
                                    }
                                    controller.focusNode[index].unfocus();
                                    controller.update();
                                    controller.generateRoute();
                                  }
                                },
                              ),
                            );
                          }),

                          // Add stop
                          InkWell(
                            onTap: () {
                              controller.addStop();
                              controller.focusNode.add(FocusNode());
                              controller.update();
                            },
                            borderRadius:
                                BorderRadius.circular(CCRadius.input),
                            child: Container(
                              width: Get.width,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: ccSurface,
                                borderRadius:
                                    BorderRadius.circular(CCRadius.input),
                                border: Border.all(color: ccInputBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.add_circle_outline,
                                      color: ccPrimary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add a stop to get more bookings'.tr,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: ccNavyText,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Map
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(CCRadius.card),
                        border:
                            Border.all(color: ccInputBorder, width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                            CCRadius.card - 1.5),
                        child: GoogleMap(
                          zoomControlsEnabled: false,
                          mapType: MapType.terrain,
                          initialCameraPosition: CameraPosition(
                              target: LatLng(lat, long), zoom: 14),
                          markers: Set<Marker>.of(controller.markers),
                          polylines: Set<Polyline>.of(controller.polylines),
                          zoomGesturesEnabled: true,
                          gestureRecognizers: {
                            Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer()),
                          },
                          onMapCreated: (control) =>
                              controller.mapController = control,
                          liteModeEnabled: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.ctrl,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    required this.validator,
    required this.onClear,
  });

  final TextEditingController ctrl;
  final FocusNode? focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String> validator;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      focusNode: focusNode,
      style: const TextStyle(
        fontFamily: 'Inter',
        color: ccNavyText,
        fontSize: 14,
      ),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          color: ccSecondaryText,
          fontSize: 14,
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.location_on, color: ccPrimary, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        suffixIcon: onClear != null
            ? InkWell(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child:
                      Icon(Icons.close_rounded, color: ccSecondaryText, size: 18),
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
