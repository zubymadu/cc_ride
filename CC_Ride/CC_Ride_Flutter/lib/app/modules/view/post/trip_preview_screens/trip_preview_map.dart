// ignore_for_file: deprecated_member_use

import 'package:carride/app/modules/controllers/intro_controllers/splash_screen_controller.dart';
import 'package:carride/app/modules/controllers/post_controllers/trip_preview_screen_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripPreviewMap extends GetView<TripPreviewScreenController> {
  const TripPreviewMap({super.key});
  @override
  Widget build(BuildContext context) {
    return GetBuilder<TripPreviewScreenController>(
      builder: (tripPreviewScreenController) {
        return Container(
          height: Get.height / 2.5,
          width: Get.width,
          decoration: BoxDecoration(
            color: ccBackground,
            borderRadius: BorderRadius.circular(CCRadius.card),
          ),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(CCRadius.card),
                child: GoogleMap(
                  gestureRecognizers: {
                    Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer())
                  },
                  initialCameraPosition:
                      CameraPosition(target: LatLng(lat, long), zoom: 14),
                  mapType: MapType.normal,
                  myLocationButtonEnabled: true,
                  compassEnabled: true,
                  zoomGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  zoomControlsEnabled: false,
                  markers: controller.markers,
                  polylines: controller.polylines,
                  onMapCreated: controller.onMapCreated,
                ),
              ),
              InkWell(
                onTap: () {
                  if (controller.tripDetailsApiModel!.tripData!.stopsDetails!
                      .isNotEmpty) {
                    controller.openGoogleMapWithRoute(
                      pickupLat:
                          controller.tripDetailsApiModel!.tripData!.originLat!,
                      pickupLng:
                          controller.tripDetailsApiModel!.tripData!.originLong!,
                      dropLat: controller.tripDetailsApiModel!.tripData!
                          .stopsDetails!.first.lat!,
                      dropLng: controller.tripDetailsApiModel!.tripData!
                          .stopsDetails!.first.long!,
                    );
                  } else {
                    controller.openGoogleMapWithRoute(
                      pickupLat:
                          controller.tripDetailsApiModel!.tripData!.originLat!,
                      pickupLng:
                          controller.tripDetailsApiModel!.tripData!.originLong!,
                      dropLat:
                          controller.tripDetailsApiModel!.tripData!.destiLat!,
                      dropLng:
                          controller.tripDetailsApiModel!.tripData!.destiLong!,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ccPrimary,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/image/svg/Rectangle.svg',
                        color: Colors.white,
                        height: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Go online & navigate',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
