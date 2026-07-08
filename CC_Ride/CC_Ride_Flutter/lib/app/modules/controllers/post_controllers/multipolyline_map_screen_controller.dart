// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures
import 'dart:ui' as ui;

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/modules/controllers/post_controllers/post_trip_controller.dart';
import 'package:carride/app/modules/controllers/search_controllers/map_suggetion_controlle.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

extension LatLngExtensions on LatLng {
  bool isCloseTo(LatLng other, {double tolerance = 0.0001}) {
    return (latitude - other.latitude).abs() < tolerance && (longitude - other.longitude).abs() < tolerance;
  }
}

class MultipolylineMapScreenController extends GetxController {
// -------------------------------------------------------------------
void removeStopAt(int index) {
  if (index < stopControllers.length) stopControllers.removeAt(index);
  if (index < focusNode.length) focusNode.removeAt(index);
  if (index < postTripController.stopData.length) postTripController.stopData.removeAt(index);

  markers.clear();
  for (int i = 0; i < waypoints.length; i++) {
    markers.add(Marker(markerId: MarkerId("marker_$i"), position: waypoints[i]));
  }

  generateRoute();
}
// -------------------------------------------------------------------

  // ====================== THEME & OTHER CONTROLLERS ======================
  final MapSuggetionControlle mapSuggetionControlle = Get.put(MapSuggetionControlle());
  final PostTripController postTripController = Get.put(PostTripController());

  // ====================== TEXT / FOCUS ======================
  final TextEditingController originController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  final RxList<TextEditingController> _stopControllers = <TextEditingController>[].obs;
  List<TextEditingController> get stopControllers => _stopControllers;
  set stopControllers(List<TextEditingController> value) => _stopControllers.value = value;

  final RxList<FocusNode> _focusNode = <FocusNode>[].obs;
  List<FocusNode> get focusNode => _focusNode;
  set focusNode(List<FocusNode> value) => _focusNode.value = value;

  // ====================== MAP STATE ======================
  final RxList<LatLng> _waypoints = <LatLng>[].obs;
  List<LatLng> get waypoints => _waypoints;
  set waypoints(List<LatLng> value) => _waypoints.value = value;

  final Rx<Set<Polyline>> _polylines = Rx<Set<Polyline>>(<Polyline>{});
  Set<Polyline> get polylines => _polylines.value;
  set polylines(Set<Polyline> value) => _polylines.value = value;

  final Rx<Set<Marker>> _markers = Rx<Set<Marker>>(<Marker>{});
  Set<Marker> get markers => _markers.value;
  set markers(Set<Marker> value) => _markers.value = value;

  final RxList<List<LatLng>> _allRoutes = <List<LatLng>>[].obs;
  List<List<LatLng>> get allRoutes => _allRoutes;
  set allRoutes(List<List<LatLng>> value) => _allRoutes.value = value;

  // ====================== MAP CONTROLLER & API ======================
  GoogleMapController? mapController;
  final String googleAPIKey = Confing.mapkey;
  final FocusNode focus = FocusNode();
  final FocusNode focus2 = FocusNode();
  late final formKey = GlobalKey<FormState>();

  // ====================== CUSTOM MARKER ICONS ======================
  BitmapDescriptor? startIcon;
  BitmapDescriptor? endIcon;
  BitmapDescriptor? stopIcon;
  BitmapDescriptor? currentIcon;
  static const double _iconSize = 100.0;

  // Default zoom level
  static const double defaultZoom = 14.0;

  final RxBool _iconsLoaded = false.obs;
  bool get iconsLoaded => _iconsLoaded.value;

  double? lat;
  double? long;
  

  // =========================== LIFECYCLE =============================
  // @override
  // void onInit() async {
  //   super.onInit();

  //   // Load custom icons first
  //   await loadCustomIcons();
  //     debugPrint("----------- Get.argument ------------- ${Get.arguments}");

  //   if (Get.arguments != null) {

  //     // Origin
  //     originController.text = Get.arguments["origin_address"].toString().split(',').first.trim();
  //     postTripController.originAddress = Get.arguments["origin_address"];
  //     postTripController.originLat = Get.arguments["origin_lat"];
  //     postTripController.originLong = Get.arguments["origin_long"];

  //     debugPrint("📍 ORIGIN ADDRESS : ${postTripController.originAddress}");
  //     debugPrint("📍 ORIGIN LAT     : ${postTripController.originLat}");
  //     debugPrint("📍 ORIGIN LONG    : ${postTripController.originLong}");

  //     // Destination
  //     destinationController.text = Get.arguments["desti_address"].toString().split(',').first.trim();
  //     postTripController.destiAddress = Get.arguments["desti_address"];
  //     postTripController.destiLat = Get.arguments["desti_lat"];
  //     postTripController.destiLong = Get.arguments["desti_long"];

  //     debugPrint("🏁 DESTI ADDRESS  : ${postTripController.destiAddress}");
  //     debugPrint("🏁 DESTI LAT      : ${postTripController.destiLat}");
  //     debugPrint("🏁 DESTI LONG     : ${postTripController.destiLong}");

  //     // Stops
  //     postTripController.stopData = Get.arguments["stopdata"] ?? [];
  //     debugPrint("🛑 STOP DATA COUNT: ${postTripController.stopData.length}");
  //     debugPrint("🛑 STOP DATA RAW  : ${postTripController.stopData}");

  //     if (Get.arguments["request_id"] != null) {
  //       postTripController.requestId = Get.arguments["request_id"];
  //     } else {
  //       postTripController.requestId = "0";
  //     }
  //     debugPrint("🆔 REQUEST ID     : ${postTripController.requestId}");

  //     // ================= STOP CONTROLLERS =================
  //     for (int i = 0; i < postTripController.stopData.length; i++) {
  //       final stop = postTripController.stopData[i];

  //       final controller = TextEditingController(
  //         text: stop["stop_address"].toString().split(',').first.trim(),
  //       );

  //       stopControllers.add(controller);
  //       focusNode.add(FocusNode());

  //       debugPrint("🛑 STOP $i ADDRESS : ${stop["stop_address"]}");
  //       debugPrint("🛑 STOP $i LAT     : ${stop["stop_lat"]}");
  //       debugPrint("🛑 STOP $i LONG    : ${stop["stop_long"]}");
  //     }

  //     // Generate route after icons loaded
  //     await generateRoute();
  //   }

  //   update();
  // }

  @override
  void onClose() {
    originController.dispose();
    destinationController.dispose();
    for (var c in stopControllers) c.dispose();
    for (var f in focusNode) f.dispose();
    mapController?.dispose();
    super.onClose();
  }

  // ======================= CUSTOM ICON LOADER (WITH FALLBACK) =======================
  Future<void> loadCustomIcons() async {
    try {
      final Uint8List? pickupBytes = await getBytesFromAsset('assets/image/pickup.png', _iconSize);
      final Uint8List? dropBytes = await getBytesFromAsset('assets/image/drop.png', _iconSize);
      final Uint8List? stopBytes = await getBytesFromAsset('assets/image/stoppoint.png', _iconSize);

      startIcon = pickupBytes != null
          ? BitmapDescriptor.fromBytes(pickupBytes)
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

      endIcon = dropBytes != null
          ? BitmapDescriptor.fromBytes(dropBytes)
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

      stopIcon = stopBytes != null
          ? BitmapDescriptor.fromBytes(stopBytes)
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);

      debugPrint("Icons loaded → Custom: ${pickupBytes != null}/${dropBytes != null}/${stopBytes != null}");
    } catch (e) {
      debugPrint("Icon loading failed: $e → Using default markers");
      startIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      endIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      stopIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    } finally {
      _iconsLoaded.value = true;
      update();
    }
  }

  Future<Uint8List?> getBytesFromAsset(String path, double size) async {
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: size.toInt(),
        targetHeight: size.toInt(),
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Asset load failed: $path → $e");
      return null;
    }
  }

  // ======================= SAFE MARKER ADD (NEVER SKIP) =======================
  void addMarkerIfValid({
    required String id,
    required LatLng position,
    required BitmapDescriptor? icon,
    required String title,
    double zIndex = 10.0,
    Offset anchor = const Offset(0.5, 0.5),
  }) {
    // If custom icon null → use appropriate default
    final BitmapDescriptor finalIcon = icon ??
        (id.contains('0') || title.contains('Pickup')
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : id.contains('end') || title.contains('Drop')
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
                : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure));

    markers.add(
      Marker(
        markerId: MarkerId(id),
        position: position,
        icon: finalIcon,
        anchor: anchor,
        infoWindow: InfoWindow(title: title),
        zIndex: zIndex,
      ),
    );
  }

  // ======================= BOUNDS HELPER ========================
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double? swLat, swLng, neLat, neLng;
    for (final p in list) {
      if (swLat == null || p.latitude < swLat) swLat = p.latitude;
      if (swLng == null || p.longitude < swLng) swLng = p.longitude;
      if (neLat == null || p.latitude > neLat) neLat = p.latitude;
      if (neLng == null || p.longitude > neLng) neLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(swLat!, swLng!),
      northeast: LatLng(neLat!, neLng!),
    );
  }

  // ======================= CURRENT LOCATION ======================
  Future<void> getCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        Get.snackbar("Permission", "Location access denied");
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      lat = position.latitude;
      long = position.longitude;
      addCurrentLocationMarker(position);
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat!, long!), 15));
    } catch (e) {
      Get.snackbar("Error", "Failed to get location: $e");
    }
  }

  void addCurrentLocationMarker(Position position) {
    final LatLng currentPos = LatLng(position.latitude, position.longitude);

    markers.removeWhere((m) => m.markerId.value == 'current_location');

    if (currentIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: currentPos,
          icon: currentIcon!,
          anchor: const Offset(0.5, 0.5),
          infoWindow: const InfoWindow(title: 'You are here'),
          zIndex: 10,
        ),
      );
    }

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(currentPos, defaultZoom),
    );
    update();
  }

  // ======================= SWAP LOCATIONS =========================
  void swapLocations() {
    final tempText = originController.text;
    originController.text = destinationController.text;
    destinationController.text = tempText;

    final tempAddr = postTripController.originAddress;
    final tempLat = postTripController.originLat;
    final tempLong = postTripController.originLong;

    postTripController.originAddress = postTripController.destiAddress;
    postTripController.originLat = postTripController.destiLat;
    postTripController.originLong = postTripController.destiLong;

    postTripController.destiAddress = tempAddr;
    postTripController.destiLat = tempLat;
    postTripController.destiLong = tempLong;

    generateRoute(swapFromTo: true);
  }

  // ======================= ADD STOP ===============================
  void addStop() {
    stopControllers.add(TextEditingController());
    focusNode.add(FocusNode());
    update();
  }

  // ======================= NEARBY CHECK (TOLERANCE) =====================
  bool _isNear(LatLng a, LatLng b, {double tolerance = 0.0001}) {
    return (a.latitude - b.latitude).abs() < tolerance && (a.longitude - b.longitude).abs() < tolerance;
  }

  // ======================= GENERATE POLYLINES =====================
  Future<void> generatePolylines(List<LatLng> points) async {
    if (points.length < 2) {
      polylines.clear();
      allRoutes.clear();
      update();
      return;
    }

    polylines.clear();
    allRoutes.clear();

    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];

      final url = "https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$googleAPIKey&mode=driving";

      try {
        final response = await GetConnect().get(url);
        if (response.statusCode == 200 && response.body["status"] == "OK") {
          final List<LatLng> routeCoords = [];
          final steps = response.body["routes"][0]["legs"][0]["steps"] as List;
          for (var step in steps) {
            final decoded = PolylinePoints.decodePolyline(step["polyline"]["points"]);
            routeCoords.addAll(decoded.map((p) => LatLng(p.latitude, p.longitude)));
          }

          // if (routeCoords.isNotEmpty) {
          //   if ((routeCoords.first.latitude - start.latitude).abs() > 0.0001 ||
          //       (routeCoords.first.longitude - start.longitude).abs() > 0.0001) {
          //     routeCoords.insert(0, start);
          //   }
          //   if ((routeCoords.last.latitude - end.latitude).abs() > 0.0001 ||
          //       (routeCoords.last.longitude - end.longitude).abs() > 0.0001) {
          //     routeCoords.add(end);
          //   }
          // }

          if (routeCoords.isNotEmpty) {
            if (!_isNear(routeCoords.first, start)) {
              routeCoords.insert(0, start);
            }
            if (!_isNear(routeCoords.last, end)) {
              routeCoords.add(end);
            }
          } else {
            routeCoords.addAll([start, end]);
          }

          polylines.add(
            Polyline(
              polylineId: PolylineId("route_$i"),
              color: ccPrimary.withOpacity(0.85),
              width: 6,
              points: routeCoords,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
          allRoutes.add(routeCoords);
        }
      } catch (e) {
        debugPrint("Polyline error (segment $i): $e");
        polylines.add(
          Polyline(
            polylineId: PolylineId("fallback_$i"),
            color: ccPrimary.withOpacity(0.6),
            width: 5,
            points: [start, end],
          ),
        );
      }
    }
    update();
  }

  // ======================= GENERATE ROUTE (MAIN) ===================
  Future<void> generateRoute({bool swapFromTo = false}) async {
    // Wait for icons to load
    while (!_iconsLoaded.value) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    markers.clear();
    waypoints.clear();

    final List<String> addresses = [
      originController.text.trim(),
      ...stopControllers.map((c) => c.text.trim()),
      destinationController.text.trim(),
    ];

    update();

    debugPrint("----------- adress -------- $addresses");
    debugPrint("----------- originLat -------- ${postTripController.originLat}");
    debugPrint("----------- originLong -------- ${postTripController.originLong}");
    debugPrint("----------- destiLat -------- ${postTripController.destiLat}");
    debugPrint("----------- stopControllers -------- ${stopControllers.length}");

    if (swapFromTo && addresses.length > 1) {
      final temp = addresses[0];
      addresses[0] = addresses.last;
      addresses[addresses.length - 1] = temp;
    }

    for (int i = 0; i < addresses.length; i++) {
      final address = addresses[i];
      if (address.isEmpty) continue;

      LatLng? pos;

      // Priority: Use stored lat/long from PostTripController
      if (i == 0) {
        pos = LatLng(
          double.tryParse(postTripController.originLat) ?? 0.0,
          double.tryParse(postTripController.originLong) ?? 0.0,
        );
      } else if (i == addresses.length - 1) {
        pos = LatLng(
          double.tryParse(postTripController.destiLat) ?? 0.0,
          double.tryParse(postTripController.destiLong) ?? 0.0,
        );
      } else if (i > 0 && i < addresses.length - 1) {
        final stopIndex = i - 1;
        if (stopIndex < postTripController.stopData.length) {
          final stop = postTripController.stopData[stopIndex];
          pos = LatLng(
            double.tryParse(stop["stop_lat"].toString()) ?? 0.0,
            double.tryParse(stop["stop_long"].toString()) ?? 0.0,
          );
        }
      }

      // Fallback: Geocoding
      if (pos == null || (pos.latitude == 0.0 && pos.longitude == 0.0)) {
        try {
          debugPrint("---------- address ------ $address");

          final locations = await locationFromAddress(address);
          debugPrint("---------- locations ------ $locations");
            pos = LatLng(double.parse(postTripController.originLat), double.parse(postTripController.originLong));
          if (locations.isNotEmpty) {
            pos = LatLng(locations.first.latitude, locations.first.longitude);
          } else {
            Get.snackbar("Not Found", "Location not found: $address");
            continue;
          }
        } catch (e) {
          debugPrint("Geocoding error: $e");
          Get.snackbar("Error", "Failed to locate: $address");
          continue;
        }
      }

      waypoints.add(pos);

      final BitmapDescriptor? customIcon = i == 0
          ? startIcon
          : i == addresses.length - 1
              ? endIcon
              : stopIcon;

      final String title = i == 0
          ? "Pickup"
          : i == addresses.length - 1
              ? "Drop"
              : "Stop $i";

      final Offset anchor = i == addresses.length - 1
          ? const Offset(0.5, 1.0)
          : const Offset(0.5, 0.5);

      addMarkerIfValid(
        id: 'marker_$i',
        position: pos,
        icon: customIcon,
        title: "$title: ${address.split(',').first}",
        anchor: anchor,
        zIndex: 10,
      );
    }

    if (waypoints.isEmpty) {
      polylines.clear();
      update();
      return;
    }

    await generatePolylines(waypoints);

    // Fit camera
    if (mapController != null) {
      if (waypoints.length == 1) {
        mapController!.animateCamera(CameraUpdate.newLatLngZoom(waypoints.first, 14.0));
      } else {
        try {
          final bounds = _boundsFromLatLngList(waypoints);
          await mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
        } catch (e) {
          mapController!.animateCamera(CameraUpdate.newLatLngZoom(waypoints.first, 14.0));
        }
      }
    }

    update();
  }
}
