// ignore_for_file: deprecated_member_use
import 'dart:ui' as ui;

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/modules/controllers/find_trip_controller.dart';
import 'package:carride/app/modules/controllers/search_controllers/map_suggetion_controlle.dart';


import 'package:carride/theme/theme_colores.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchScreenController extends GetxController {
  final ThemeColores themeColores = Get.put(ThemeColores());

  // ======================  OTHER CONTROLLERS  ======================
  final MapSuggetionControlle mapSuggetionControlle = Get.put(MapSuggetionControlle());
  FindTripController findTripController = Get.put(FindTripController());

  // ======================  TEXT / FOCUS  ======================
  TextEditingController originController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  TextEditingController dateController = TextEditingController();

  // ======================  MAP STATE  ======================
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;
  final RxList<List<LatLng>> allRoutes = <List<LatLng>>[].obs;
  final RxList<LatLng> waypoints = <LatLng>[].obs;

  // ======================  COORDINATE OBSERVABLES  ======================
  final RxString _originLat = "".obs;
  String get originLat => _originLat.value;
  set originLat(String value) => _originLat.value = value;

  final RxString _originLong = "".obs;
  String get originLong => _originLong.value;
  set originLong(String value) => _originLong.value = value;

  final RxString _addresshome = "".obs;
  String get addresshome => _addresshome.value;
  set addresshome(String value) => _addresshome.value = value;

  final RxString _destinationLat = "".obs;
  String get destinationLat => _destinationLat.value;
  set destinationLat(String value) => _destinationLat.value = value;

  final RxString _destinationLong = "".obs;
  String get destinationLong => _destinationLong.value;
  set destinationLong(String value) => _destinationLong.value = value;

  final RxString _tripDate = "".obs;
  String get tripDate => _tripDate.value;
  set tripDate(String value) => _tripDate.value = value;

  // ======================  UI STATE  ======================
  FocusNode focus = FocusNode();
  FocusNode focus2 = FocusNode();
  final formKey = GlobalKey<FormState>();

  final RxBool _showSuggestions = true.obs;
  bool get showSuggestions => _showSuggestions.value;
  set showSuggestions(bool value) => _showSuggestions.value = value;

  final RxBool _isSearch = false.obs;
  bool get isSearch => _isSearch.value;
  set isSearch(bool value) => _isSearch.value = value;

  // ======================  MAP CONTROLLER & API  ======================
  GoogleMapController? mapController;
  String googleAPIKey = Confing.mapkey;
  final PolylinePoints polylinePoints = PolylinePoints(apiKey: Confing.mapkey);

  // ======================  CUSTOM MARKER ICONS  ======================
  BitmapDescriptor? startIcon;
  BitmapDescriptor? endIcon;
  BitmapDescriptor? currentIcon;

  // Icon size = 100
  static const double _iconSize = 100.0;

  // Default zoom level
  static const double defaultZoom = 14.0;

  double? lat;
  double? long;

  // =======================  SAFE IMAGE LOADER  =====================
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
      debugPrint("Failed to load icon: $path → $e");
      return null;
    }
  }

  Future<void> loadCustomIcons() async {
    final Uint8List? pickup = await getBytesFromAsset('assets/image/pickup.png', _iconSize);
    final Uint8List? drop = await getBytesFromAsset('assets/image/drop.png', _iconSize);
    final Uint8List? current = await getBytesFromAsset('assets/image/current.png', _iconSize);

    startIcon = pickup != null ? BitmapDescriptor.fromBytes(pickup) : null;
    endIcon = drop != null ? BitmapDescriptor.fromBytes(drop) : null;
    currentIcon = current != null ? BitmapDescriptor.fromBytes(current) : null;

    update();
    mapSuggetionControlle.update();
  }

  // ===========================  MAP THEME  ==========================
  Future<void> setMapTheme({
    required GoogleMapController controller,
    required bool isDarkMode,
  }) async {
    if (isDarkMode) {
      String darkMapStyle = await rootBundle.loadString("assets/image/lottie/map_dark.json");
      controller.setMapStyle(darkMapStyle);
    } else {
      String lightMapStyle = await rootBundle.loadString("assets/image/lottie/map_light.json");
      controller.setMapStyle(lightMapStyle);
    }
  }

  // ===========================  DATE PICKER  ========================
  Future<DateTime?> selectDate(BuildContext context) async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ccPrimary,
              onPrimary: ccSurface,
              onSurface: ccNavyText,
            ),
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CCRadius.card)),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: ccPrimary),
            ),
            dialogTheme: const DialogThemeData(backgroundColor: ccSurface),
          ),
          child: child!,
        );
      },
    );
  }

  // =======================  CURRENT LOCATION  ======================
  Future<void> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      Get.snackbar("Error", "Location permission denied");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      lat = position.latitude;
      long = position.longitude;
      addCurrentLocationMarker(position);
      update();
      mapSuggetionControlle.update();
    } catch (e) {
      Get.snackbar("Error", "Failed to get location");
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
    update();
    mapSuggetionControlle.update();

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(currentPos, defaultZoom),
    );
    update();
    mapSuggetionControlle.update();
  }

  // ===========================  SWAP  ==============================
  void swapLocations() {
    final tempText = originController.text;
    originController.text = destinationController.text;
    destinationController.text = tempText;

    final tempLat = originLat;
    originLat = destinationLat;
    destinationLat = tempLat;

    final tempLong = originLong;
    originLong = destinationLong;
    destinationLong = tempLong;

    generateRoute(swapFromTo: true);
  }

  void clearMapIfNoPins() {
    if (markers.isEmpty || waypoints.isEmpty) {
      polylines.clear();
      allRoutes.clear();
      update();
      mapSuggetionControlle.update();
    }
  }

  // ======================= NEARBY CHECK (TOLERANCE) =====================
  bool _isNear(LatLng a, LatLng b, {double tolerance = 0.0001}) {
    return (a.latitude - b.latitude).abs() < tolerance && (a.longitude - b.longitude).abs() < tolerance;
  }

  // ======================= DISTANCE HELPER =====================
  double _calculateDistance(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() + (a.longitude - b.longitude).abs();
  }

  // ======================= POLYLINE GENERATOR (FIXED) =====================
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
        debugPrint("Polyline Error: $e");
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

  // ===========================  BOUNDS HELPER  ======================
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double? x1, x2, y1, y2;
    for (final latLng in list) {
      if (x1 == null || latLng.latitude < x1) x1 = latLng.latitude;
      if (x2 == null || latLng.latitude > x2) x2 = latLng.latitude;
      if (y1 == null || latLng.longitude < y1) y1 = latLng.longitude;
      if (y2 == null || latLng.longitude > y2) y2 = latLng.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(x1!, y1!),
      northeast: LatLng(x2!, y2!),
    );
  }

  // =======================  SAFE MARKER ADD  =======================
  void addMarkerIfValid({
    required String id,
    required LatLng position,
    required BitmapDescriptor? icon,
    required String title,
    double zIndex = 5.0,
    Offset anchor = const Offset(0.5, 1.0),
  }) {
    if (icon == null) {
      debugPrint("Skipping marker '$id': icon not loaded");
      return;
    }

    markers.add(
      Marker(
        markerId: MarkerId(id),
        position: position,
        icon: icon,
        anchor: anchor,
        infoWindow: InfoWindow(title: title),
        zIndex: zIndex,
      ),
    );
  }

  // Helper method to get LatLng from stored lat/long strings or fallback to geocoding
  Future<LatLng?> _getLatLngFromAddressOrCoords(String address, {required bool isOrigin}) async {
    // Check if lat/long are already stored (from suggestion selection)
    String latStr = isOrigin ? originLat : destinationLat;
    String longStr = isOrigin ? originLong : destinationLong;

    if (latStr.isNotEmpty && longStr.isNotEmpty) {
      try {
        final lat = double.parse(latStr);
        final lng = double.parse(longStr);
        debugPrint("Using stored coords for $address: Lat: $lat, Long: $lng");
        return LatLng(lat, lng);
      } catch (e) {
        debugPrint("Invalid stored coords for $address: $e");
        // Fall back to geocoding if parsing fails
      }
    }

    // Fallback to geocoding
    try {
      debugPrint("Geocoding address: $address");
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final pos = locations.first;
        // Optionally store the geocoded coords back to observables for future use
        if (isOrigin) {
          originLat = pos.latitude.toString();
          originLong = pos.longitude.toString();
        } else {
          destinationLat = pos.latitude.toString();
          destinationLong = pos.longitude.toString();
        }
        return LatLng(pos.latitude, pos.longitude);
      } else {
        debugPrint("No locations found for $address via geocoding");
      }
    } catch (e) {
      debugPrint("Geocoding error for $address: $e");
    }

    return null; // No position found
  }

  // ===========================  ROUTE (FIXED ZOOM) ===================
  Future<void> generateRoute({bool swapFromTo = false}) async {
    List<String> addresses = [
      originController.text,
      destinationController.text,
    ];

    if (swapFromTo && addresses.length > 1) {
      final temp = addresses[0];
      addresses[0] = addresses.last;
      addresses[addresses.length - 1] = temp;
    }

    final currentLocationMarker = markers.firstWhereOrNull((m) => m.markerId.value == 'current_location');
    markers.clear();
    waypoints.clear();
    allRoutes.clear();
    if (currentLocationMarker != null) markers.add(currentLocationMarker);

    for (int i = 0; i < addresses.length; i++) {
      final address = addresses[i].trim();
      debugPrint("-------------- address ----------- $address");
      if (address.isEmpty) continue;

      // Use helper to get LatLng preferring stored coords
      final pos = await _getLatLngFromAddressOrCoords(address, isOrigin: i == 0);
      debugPrint("------------- originLat.---------- $originLat");
      debugPrint("------------ originLong.---------- $originLong");

      if (pos == null) {
        debugPrint("No position found for $address, skipping");
        continue;
      }

      waypoints.add(pos);

      final BitmapDescriptor? icon = i == 0
          ? startIcon
          : endIcon;

      final String title = i == 0
          ? "Start: $address"
          : "End: $address";

      final anchor = i == addresses.length - 1
          ? const Offset(0.5, 1.0)
          : const Offset(0.5, 0.5);

      addMarkerIfValid(
        id: 'route_marker_$i',
        position: pos,
        icon: icon,
        title: title,
        anchor: anchor,
      );
    }

    if (waypoints.isEmpty) {
      polylines.clear();
      allRoutes.clear();
      update();
      return;
    }

    await generatePolylines(waypoints);

    if (mapController == null || waypoints.isEmpty) {
      update();
      return;
    }

    if (waypoints.length == 1) {
      // 1 Pin → Fixed zoom
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(waypoints.first, defaultZoom),
      );
    } else {
      // 2+ Pins → Safe fit bounds
      try {
        final bounds = _boundsFromLatLngList(waypoints);
        final distance = _calculateDistance(bounds.southwest, bounds.northeast);

        if (distance < 0.0001) {
          // Too close → fallback
          mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(waypoints.first, defaultZoom),
          );
        } else {
          await mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 100),
          );
        }
      } catch (e) {
        debugPrint("Zoom error: $e → Using fallback");
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(waypoints.first, defaultZoom),
        );
      }
    }
    update();
  }

  @override
  void onReady() {
    super.onReady();
    _resetScreen();
  }

  void _resetScreen() {
    originController.clear();
    destinationController.clear();
    dateController.clear();

    markers.clear();
    polylines.clear();
    waypoints.clear();

    // Also clear stored coords
    originLat = "";
    originLong = "";
    destinationLat = "";
    destinationLong = "";

    showSuggestions = true;

    getCurrentLocation();
    update();
  }

}
