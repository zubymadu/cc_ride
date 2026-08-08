// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/modules/controllers/find_trip_controller.dart';
import 'package:carride/app/modules/controllers/search_controllers/map_suggetion_controlle.dart';
import 'package:http/http.dart' as http;


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

  // ======================  TRIP PLANNING  ======================
  // "Let's plan your next trip" screen state — departure time, return trip,
  // and route-subscription, layered on top of the origin/destination state
  // already shared with the home screen.
  final Rx<DateTime> _departureDateTime = DateTime.now().obs;
  DateTime get departureDateTime => _departureDateTime.value;
  set departureDateTime(DateTime value) {
    _departureDateTime.value = value;
    tripDate = "${value.year.toString().padLeft(4, '0')}-"
        "${value.month.toString().padLeft(2, '0')}-"
        "${value.day.toString().padLeft(2, '0')}";
  }

  final RxBool _returnTripEnabled = false.obs;
  bool get returnTripEnabled => _returnTripEnabled.value;
  set returnTripEnabled(bool value) => _returnTripEnabled.value = value;

  final Rx<DateTime?> _returnDateTime = Rx<DateTime?>(null);
  DateTime? get returnDateTime => _returnDateTime.value;
  set returnDateTime(DateTime? value) => _returnDateTime.value = value;

  final RxBool _subscribeToRoute = false.obs;
  bool get subscribeToRoute => _subscribeToRoute.value;
  set subscribeToRoute(bool value) => _subscribeToRoute.value = value;

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

  // ======================  NEARBY SHARED ROUTES  ======================
  final RxList<NearbyRoute> _nearbyRoutes = <NearbyRoute>[].obs;
  List<NearbyRoute> get nearbyRoutes => _nearbyRoutes;

  final RxBool _nearbyRoutesLoading = false.obs;
  bool get nearbyRoutesLoading => _nearbyRoutesLoading.value;
  set nearbyRoutesLoading(bool value) => _nearbyRoutesLoading.value = value;

  Future<void> fetchNearbyRoutes({required double lat, required double lng}) async {
    nearbyRoutesLoading = true;
    update();
    try {
      final response = await http.post(
        Uri.parse(Confing.baseurl + Confing.nearbyRoutes),
        headers: const {"Content-type": "application/json", "Accept": "application/json"},
        body: jsonEncode({"lat": lat, "lng": lng}),
      );
      final data = jsonDecode(response.body);
      if (data["Result"] == "true") {
        final list = (data["Data"] as List? ?? [])
            .map((e) => NearbyRoute.fromJson(e))
            .toList();
        _nearbyRoutes.assignAll(list);
      }
    } catch (e) {
      log(name: "fetchNearbyRoutes error", "$e");
    } finally {
      nearbyRoutesLoading = false;
      update();
    }
  }

  // ======================  NEARBY POSTED (ONE-OFF) RIDES  ======================
  // fetchNearbyRoutes above only ever covers recurring driver-published
  // Route corridors — an ordinary one-off ride from "Post a Trip" never
  // showed up on the home screen at all, no matter how close it was.
  final RxList<NearbyPostedRide> _nearbyPostedRides = <NearbyPostedRide>[].obs;
  List<NearbyPostedRide> get nearbyPostedRides => _nearbyPostedRides;

  final RxBool _nearbyPostedRidesLoading = false.obs;
  bool get nearbyPostedRidesLoading => _nearbyPostedRidesLoading.value;
  set nearbyPostedRidesLoading(bool value) => _nearbyPostedRidesLoading.value = value;

  Future<void> fetchNearbyPostedRides({required double lat, required double lng}) async {
    nearbyPostedRidesLoading = true;
    update();
    try {
      final response = await http.post(
        Uri.parse(Confing.baseurl + Confing.nearbyPostedRides),
        headers: const {"Content-type": "application/json", "Accept": "application/json"},
        body: jsonEncode({"lat": lat, "lng": lng}),
      );
      final data = jsonDecode(response.body);
      if (data["Result"] == "true") {
        final list = (data["Data"] as List? ?? [])
            .map((e) => NearbyPostedRide.fromJson(e))
            .toList();
        _nearbyPostedRides.assignAll(list);
      }
    } catch (e) {
      log(name: "fetchNearbyPostedRides error", "$e");
    } finally {
      nearbyPostedRidesLoading = false;
      update();
    }
  }

  // ======================  SEARCH POSTED RIDES BY PLACE  ======================
  // "Search rides in Abuja" — free-text alternative to the coordinate-only
  // corridor matching in find-trip, for browsing what's live in a place
  // generally rather than one specific origin→destination pair.
  final RxList<NearbyPostedRide> _placeSearchResults = <NearbyPostedRide>[].obs;
  List<NearbyPostedRide> get placeSearchResults => _placeSearchResults;

  final RxBool _placeSearchLoading = false.obs;
  bool get placeSearchLoading => _placeSearchLoading.value;
  set placeSearchLoading(bool value) => _placeSearchLoading.value = value;

  final RxBool _placeSearchActive = false.obs;
  bool get placeSearchActive => _placeSearchActive.value;

  Future<void> searchRidesByPlace(String query) async {
    if (query.trim().length < 2) {
      _placeSearchActive.value = false;
      _placeSearchResults.clear();
      update();
      return;
    }
    _placeSearchActive.value = true;
    placeSearchLoading = true;
    update();
    try {
      final response = await http.post(
        Uri.parse(Confing.baseurl + Confing.searchRidesByPlace),
        headers: const {"Content-type": "application/json", "Accept": "application/json"},
        body: jsonEncode({"query": query.trim()}),
      );
      final data = jsonDecode(response.body);
      if (data["Result"] == "true") {
        final list = (data["Data"] as List? ?? [])
            .map((e) => NearbyPostedRide.fromJson(e))
            .toList();
        _placeSearchResults.assignAll(list);
      }
    } catch (e) {
      log(name: "searchRidesByPlace error", "$e");
    } finally {
      placeSearchLoading = false;
      update();
    }
  }

  void clearPlaceSearch() {
    _placeSearchActive.value = false;
    _placeSearchResults.clear();
    update();
  }

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
      final currentLat = position.latitude;
      final currentLong = position.longitude;
      lat = currentLat;
      long = currentLong;
      addCurrentLocationMarker(position);
      update();
      mapSuggetionControlle.update();
      try {
        final placemarks = await placemarkFromCoordinates(currentLat, currentLong);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          // Locality + country alone (e.g. "Lagos, Nigeria") threw away all
          // street-level detail the reverse geocode actually returned, so
          // the passenger's "current location" pickup label never told them
          // which street they were on — only the coordinates (kept precise
          // via lat/long above) were accurate.
          final street = (p.street != null && p.street!.isNotEmpty)
              ? p.street!
              : [p.subThoroughfare, p.thoroughfare]
                  .where((s) => s != null && s.isNotEmpty)
                  .join(" ");
          addresshome = [street, p.subLocality, p.locality, p.country]
              .whereType<String>()
              .where((s) => s.trim().isNotEmpty)
              .toSet()
              .join(", ");
          update();
        }
      } catch (_) {}
      fetchNearbyRoutes(lat: currentLat, lng: currentLong);
      fetchNearbyPostedRides(lat: currentLat, lng: currentLong);
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

class NearbyRoute {
  final String routeId;
  final String routeCode;
  final String routeName;
  final String originName;
  final double originLat;
  final double originLong;
  final String destinationName;
  final double destinationLat;
  final double destinationLong;
  final double distanceKm;
  final String nextDeparture;
  final String seatPrice;
  // False when the driver who created this route deactivated it — the route
  // still shows as a suggestion (per design) but has no active schedule, so
  // there's nothing bookable until another driver adopts it.
  final bool isServiced;

  NearbyRoute({
    required this.routeId,
    required this.routeCode,
    required this.routeName,
    required this.originName,
    required this.originLat,
    required this.originLong,
    required this.destinationName,
    required this.destinationLat,
    required this.destinationLong,
    required this.distanceKm,
    required this.nextDeparture,
    required this.seatPrice,
    required this.isServiced,
  });

  factory NearbyRoute.fromJson(Map<String, dynamic> json) => NearbyRoute(
        routeId: '${json["route_id"]}',
        routeCode: '${json["route_code"]}',
        routeName: '${json["route_name"]}',
        originName: '${json["origin_name"]}',
        originLat: double.tryParse('${json["origin_lat"]}') ?? 0,
        originLong: double.tryParse('${json["origin_long"]}') ?? 0,
        destinationName: '${json["destination_name"]}',
        destinationLat: double.tryParse('${json["destination_lat"]}') ?? 0,
        destinationLong: double.tryParse('${json["destination_long"]}') ?? 0,
        distanceKm: double.tryParse('${json["distance_km"]}') ?? 0,
        nextDeparture: '${json["next_departure"]}',
        seatPrice: '${json["seat_price"]}',
        isServiced: json["is_serviced"] != false,
      );
}

// A one-off ride posted via "Post a Trip" (not tied to a recurring Route) —
// used for both the home-screen "nearby posted rides" feed and free-text
// place search results, hence distanceKm is nullable (place search has no
// reference point to measure distance from).
class NearbyPostedRide {
  // Exactly one of tripId/routeId is ever set — a route-corridor search
  // result (recurring, driver-published) has no real bookable Ride row
  // until someone actually books that occurrence, unlike an ad-hoc
  // "Post a Trip" ride which always is one. The card's tap handler branches
  // on which one is present: a real trip goes straight to booking, a route
  // hands off to trip-planning (same as the "Shared routes near you" cards).
  final String? tripId;
  final String? routeId;
  final String originAddress;
  final double originLat;
  final double originLong;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLong;
  final double? distanceKm;
  final String tripStartDate;
  final String tripStartTime;
  final String seatPrice;
  final int? availableSeats;

  NearbyPostedRide({
    required this.tripId,
    required this.routeId,
    required this.originAddress,
    required this.originLat,
    required this.originLong,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLong,
    required this.distanceKm,
    required this.tripStartDate,
    required this.tripStartTime,
    required this.seatPrice,
    required this.availableSeats,
  });

  factory NearbyPostedRide.fromJson(Map<String, dynamic> json) => NearbyPostedRide(
        tripId: json["trip_id"] != null ? '${json["trip_id"]}' : null,
        routeId: json["route_id"] != null ? '${json["route_id"]}' : null,
        originAddress: '${json["origin_address"]}',
        originLat: double.tryParse('${json["origin_lat"]}') ?? 0,
        originLong: double.tryParse('${json["origin_long"]}') ?? 0,
        destinationAddress: '${json["destination_address"]}',
        destinationLat: double.tryParse('${json["destination_lat"]}') ?? 0,
        destinationLong: double.tryParse('${json["destination_long"]}') ?? 0,
        distanceKm: json["distance_km"] != null ? double.tryParse('${json["distance_km"]}') : null,
        tripStartDate: '${json["trip_start_date"]}',
        tripStartTime: '${json["trip_start_time"]}',
        seatPrice: '${json["seat_price"]}',
        availableSeats: json["available_seats"] != null ? int.tryParse('${json["available_seats"]}') : null,
      );
}
