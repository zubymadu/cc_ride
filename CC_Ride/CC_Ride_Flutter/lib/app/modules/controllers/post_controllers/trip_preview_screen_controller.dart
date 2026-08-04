// ignore_for_file: deprecated_member_use, depend_on_referenced_packages
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;
import 'dart:ui' as ui;
import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/trips_controllers/seating_plan_screen_controller.dart';
import 'package:carride/app/modules/models/trip_details_api_model.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TripPreviewScreenController extends GetxController {
  SeatingPlanScreenController seatingPlanScreenController = Get.put(SeatingPlanScreenController());
  void handleApiResponse(dynamic value) {
    if (value != null) {
      setTripData(tripDetailsApiModel!.tripData!);
      generateRoute(); // This will now properly center the map
    }
  }


  final _appBarTitel = "".obs;
  get appBarTitel => _appBarTitel.value;
  set appBarTitel(value) => _appBarTitel.value = value;

  // --------------------------- OBSERVABLES --------------------------- //
  final RxBool _backInBottombar = false.obs;
  bool get backInBottombar => _backInBottombar.value;
  set backInBottombar(bool v) => _backInBottombar.value = v;
  final RxBool _finadTrip = false.obs;
  bool get finadTrip => _finadTrip.value;
  set finadTrip(bool v) => _finadTrip.value = v;
  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool v) => _isLoading.value = v;
  final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  TripDetailsApiModel? tripDetailsApiModel;
  // ------------------------------ API -------------------------------- //
  final Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };
  Future tripDetailsApi({required String tripId}) async => commonApi(
    url: Confing.baseurl + Confing.tripDetails,
    body: {"uid":  getData.read("userLogin") == null ? "0" : "${getData.read("userLogin")["id"]}", "trip_id": tripId},
  );
  Future findTripDetailsApi({required String tripId}) async => commonApi(
    url: Confing.baseurl + Confing.findTripDetail,
    body: {"trip_id": tripId},
  );
  Future commonApi({required String url, required Map body}) async {
    isLoading = true;
    update();
    try {
      log(name: "=============== Trip Details API URL ===============", url);
      log(name: "=============== Trip Details API BODY ==============", "$body");
      final response = await http.post(
        Uri.parse(url),
        headers: userHeader,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      log(name: "============= Trip Details API RESPONSE =============", response.body,
);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["Result"] == "true") {
        tripDetailsApiModel = tripDetailsApiModelFromJson(response.body);
        if (tripDetailsApiModel!.result == "true") {
          return data;
        } else {
          showToastMessage(tripDetailsApiModel!.responseMsg!);
        }
      } else {
        showToastMessage(data["ResponseMsg"] ?? "Something went wrong");
      }
    } catch (e) {
      log(name: "API ERROR", "$e");
    } finally {
      isLoading = false;
      update();
    }
    return null;
  }
  Widget buildDashedLine() {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Column(
        children: List.generate(
          4,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: Container(width: 2, height: 4, color: Colors.grey),
          ),
        ),
      ),
    );
  }
  final Rx<TripData?> tripDatass = Rx<TripData?>(null);
  final RxString tripEndTime = "".obs;
  final RxString totalTripDuration = "".obs; // HH:mm:ss
  final RxDouble totalTripKm = 0.0.obs;

  final RxList _tripStopPointTime = [].obs;
  List get tripStopPointTime => _tripStopPointTime;
  set tripStopPointTime(List value) => _tripStopPointTime.value = value;

  final RxString _hours = "".obs;
  String get hours => _hours.value;
  set hours(String value) => _hours.value = value;

  final RxString _minutesLeft = "".obs;
  String get minutesLeft => _minutesLeft.value;
  set minutesLeft(String value) => _minutesLeft.value = value;

  final RxString _seconds = "".obs;
  String get seconds => _seconds.value;
  set seconds(String value) => _seconds.value = value;

  void setTripData(TripData data) {
    tripDatass.value = data;
    calculateTripDetails();
  }
  void calculateTripDetails() {
    if (tripDatass.value == null) return;
    _tripStopPointTime.clear();
    totalTripKm.value = 0;
    /// START DATE & TIME
    final startDate = tripDatass.value!.tripStartDate!;
    final startTime = tripDatass.value!.tripStartTime!;
    final timeParts = startTime.split(":");
    DateTime currentTime = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
      timeParts.length > 2 ? int.parse(timeParts[2]) : 0,
    );
    /// SPEED → 20 KM/H
    const double speedKmPerHour = 30;
    double oriLat = tripDatass.value!.originLat ?? 0.0;
    double oriLng = tripDatass.value!.originLong ?? 0.0;
    /// -------- STOPS --------
    if (tripDatass.value!.stopsDetails!.isNotEmpty) {
      for (final stop in tripDatass.value!.stopsDetails!) {
        final desLat = stop.lat ?? 0.0;
        final desLng = stop.long ?? 0.0;
        final distanceKm = calculateDistance(
          lat1: oriLat,
          lon1: oriLng,
          lat2: desLat,
          lon2: desLng,
        );
        totalTripKm.value += distanceKm;
        final travelSeconds = ((distanceKm / speedKmPerHour) * 3600).round();
        currentTime = currentTime.add(Duration(seconds: travelSeconds));
        _tripStopPointTime.add(DateFormat('EEE, MMM d \'at\' h:mma').format(currentTime));
        oriLat = desLat;
        oriLng = desLng;
      }
    }
    /// -------- DESTINATION --------
    final finalDistance = calculateDistance(
      lat1: oriLat,
      lon1: oriLng,
      lat2: tripDatass.value!.destiLat!,
      lon2: tripDatass.value!.destiLong!,
    );
    totalTripKm.value += finalDistance;
    final finalSeconds = ((finalDistance / speedKmPerHour) * 3600).round();
    final endDateTime = currentTime.add(Duration(seconds: finalSeconds));
    /// FINAL TIME
    tripEndTime.value = DateFormat('EEE, MMM d \'at\' h:mma').format(endDateTime);
    /// TOTAL DURATION
    final totalDuration = endDateTime.difference(
      DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        timeParts.length > 2 ? int.parse(timeParts[2]) : 0,
      ),
    );
    totalTripDuration.value = formatDuration(totalDuration);
    debugPrint("----------------- totalTripKm ${totalTripKm.value}");
    debugPrint("----------------- totalTripDuration ${totalTripDuration.value}");
    debugPrint("----------------- tripStopPointTime $tripStopPointTime");
    debugPrint("----------------- tripEndTime ${tripEndTime.value}");
    update();
  }
  /// FORMAT HH:mm:ss
  String formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    hours = two(d.inHours);
    minutesLeft = two(d.inMinutes.remainder(60));
    seconds = two(d.inSeconds.remainder(60));
    return "${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const R = 6371; // Earth radius in KM
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }
  double _deg2rad(double deg) => deg * (pi / 180);
  Future<void> openGoogleMapWithRoute({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
  }) async {
    final Uri googleMapUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&origin=$pickupLat,$pickupLng&destination=$dropLat,$dropLng&travelmode=driving');
    if (!await launchUrl(googleMapUrl, mode: LaunchMode.externalApplication)) {
      throw 'Could not open Google Maps';
    }
  }
  routeData({required String time, required String address}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              time,
              style: const TextStyle(
                color: ccNavyText,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 5),
        Text(
          address,
          style: const TextStyle(color: ccSecondaryText, fontFamily: 'Inter', fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
  // --------------------------- MAP LOGIC ----------------------------- //
  final String googleAPIKey = Confing.mapkey;
  // Observable collections
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;
  final RxList<LatLng> waypoints = <LatLng>[].obs;
  late GoogleMapController mapController;
  bool _isMapReady = false;
  // Custom Pin Bitmaps (cached)
  late Future<BitmapDescriptor> _pinStart;
  late Future<BitmapDescriptor> _pinStop;
  late Future<BitmapDescriptor> _pinEnd;
  late Future<BitmapDescriptor> _pinCurrent;
  @override
  void onReady() {
    super.onReady();
    // Pre-load custom icons
    _pinStart = _bitmapFromAsset("assets/image/pickup.png", width: 90);
    _pinStop = _bitmapFromAsset("assets/image/stoppoint.png", width: 70);
    _pinEnd = _bitmapFromAsset("assets/image/drop.png", width: 90);
    _pinCurrent = _bitmapFromAsset("assets/image/current.png", width: 90);
  }
  Future<BitmapDescriptor> _bitmapFromAsset(
    String path, {
    required int width,
  }) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final frame = await codec.getNextFrame();
    final bytes = (await frame.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(bytes);
  }
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _isMapReady = true;
    debugPrint("Map controller ready");
    if (waypoints.isNotEmpty) {
      _centerMap();
    }
  }
  // ---------------------- CURRENT LOCATION TRACKING ------------------ //
  StreamSubscription<Position>? _locationSubscription;
  void startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showToastMessage("Location services are disabled.");
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showToastMessage("Location permission denied.");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      showToastMessage("Location permission permanently denied.");
      return;
    }
    _locationSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update every 10 meters
          ),
        ).listen((Position position) {
          final newPos = LatLng(position.latitude, position.longitude);
          if (currentLocation.value == null ||
              _haversineDistance(currentLocation.value!, newPos) > 5) {
            currentLocation.value = newPos;
            _addOrUpdateCurrentMarker();
            _centerMap(); // Re-center to include user
          }
        });
  }
  double _haversineDistance(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude) / 1000; // km
  }
  Future<void> _addOrUpdateCurrentMarker() async {
    final pos = currentLocation.value;
    if (pos == null) return;
    final icon = await _pinCurrent;
    markers.removeWhere((m) => m.markerId.value == 'current_location');
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: pos,
        icon: icon,
        zIndex: 100,
        infoWindow: const InfoWindow(title: "You are here"),
        anchor: const Offset(0.5, 0.5),
      ),
    );
    update();
  }
  // ---------------------- PUBLIC GENERATE ROUTE ---------------------- //
  Future<void> generateRoute({bool swapFromTo = false}) async {
    final List<String> addresses = [
      tripDetailsApiModel!.tripData!.originAddress!,
      ...?tripDetailsApiModel!.tripData!.stopsDetails?.map((s) => s.location ?? ""),
      tripDetailsApiModel!.tripData!.destiAddress!,
    ].where((addr) => addr.trim().isNotEmpty).toList();
    if (swapFromTo && addresses.length >= 2) {
      final tmp = addresses[0];
      addresses[0] = addresses.last;
      addresses.last = tmp;
    }
    markers.clear();
    waypoints.clear();
    polylines.clear();
    for (int i = 0; i < addresses.length; i++) {
      final address = addresses[i].trim();
      if (address.isEmpty) continue;
      try {
        final locations = await locationFromAddress(address);
        if (locations.isEmpty) continue;
        final pos = LatLng(locations.first.latitude, locations.first.longitude);
        waypoints.add(pos);
        final BitmapDescriptor icon;
        if (i == 0) {
          icon = await _pinStart;
        } else if (i == addresses.length - 1) {
          icon = await _pinEnd;
        } else {
          icon = await _pinStop;
        }
        markers.add(
          Marker(
            markerId: MarkerId('marker_$i'),
            position: pos,
            icon: icon,
            infoWindow: InfoWindow(title: address),
          ),
        );
      } catch (e) {
        debugPrint("Geocode failed for '$address' → $e");
      }
    }
    await _drawPolylines();
    if (waypoints.isNotEmpty && _isMapReady) {
      _centerMap();
    }
    update();
  }
  // -------------------------- POLYLINE HELPERS ----------------------- //
  Future<void> _drawPolylines() async {
    if (waypoints.length < 2) return;
    for (int i = 0; i < waypoints.length - 1; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];
      final url = "https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$googleAPIKey&mode=driving";
      try {
        final resp = await http.get(Uri.parse(url));
        final json = jsonDecode(resp.body);
        if (json['status'] != 'OK') {
          debugPrint("Directions API failed: ${json['status']}");
          continue;
        }
        final points = PolylinePoints.decodePolyline(
          json['routes'][0]['overview_polyline']['points'],
        );
        final coords = points.map((p) => LatLng(p.latitude, p.longitude)).toList();
        polylines.add(
          Polyline(
            polylineId: PolylineId('poly_$i'),
            points: coords,
            color: ccPrimary,
            width: 5,
            zIndex: 1,
          ),
        );
      } catch (e) {
        debugPrint("Polyline error (segment $i): $e");
      }
    }
  }
  // --------------------------- CENTERING LOGIC ----------------------- //
  void _centerMap() {
    if (waypoints.isEmpty || !_isMapReady) return;
    final List<LatLng> points = List.from(waypoints);
    if (currentLocation.value != null) {
      points.add(currentLocation.value!);
    }
    try {
      final bounds = _boundsFromLatLngList(points);
      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 120));
      debugPrint("Map centered on ${points.length} points (incl. user)");
    } catch (e) {
      debugPrint("Failed to fit bounds: $e");
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(waypoints.first, 12),
      );
    }
  }
  // --------------------------- BOUNDS HELPERS ------------------------ //
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    if (list.isEmpty) throw Exception("Empty waypoint list");
    double south = list[0].latitude;
    double west = list[0].longitude;
    double north = list[0].latitude;
    double east = list[0].longitude;
    for (final p in list) {
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }
  // --------------------------- CLEANUP ------------------------------- //
  @override
  void onClose() {
    _locationSubscription?.cancel();
    mapController.dispose();
    super.onClose();
  }
  final RxBool _isCancelLoading = false.obs;
  bool get isCancelLoading => _isCancelLoading.value;
  set isCancelLoading(bool value) => _isCancelLoading.value = value;
  final RxBool _isCancel = false.obs;
  bool get isCancel => _isCancel.value;
  set isCancel(bool value) => _isCancel.value = value;
  Future cancelTripsApi({required String tripId}) async {
    isLoading = true;
    update();
    Map body = {"uid": "${getData.read("userLogin")["id"]}", "trip_id": tripId};
    try {
      String url = Confing.baseurl + Confing.cancelTrip;
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );
      log(name: "========== cancel Trip Api Api url ===========", url);
      log(name: "========== cancel Trip Api Api body ==========", "$body");
      log(name: "======== cancel Trip Api Api response ========", response.body);
      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN, arguments: 1);
          showToastMessage("${data["ResponseMsg"]}");
          return data;
        } else {
          showToastMessage("${data["ResponseMsg"]}");
          return data;
        }
      } else {
        showToastMessage("Somthing went wrong!.....");
      }
    } catch (e) {
      log(name: "========== cancel Trip Api Api Error ==========", "$e");
    } finally {
      isLoading = false;
      update();
    }
  }
  void cancelTripBottomsheet() {
    isLoading = false;
    debugPrint("---------------- Args requestId : ${tripDetailsApiModel!.tripData!.tripId}}");
    String tripId = "${tripDetailsApiModel!.tripData!.tripId}";
    Get.bottomSheet(
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      backgroundColor: ccSurface,
      Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Cancel trip".tr,
              style: const TextStyle(
                color: ccNavyText,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Confirm trip cancellation".tr,
              style: const TextStyle(
                color: ccNavyText,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10),
            Container(
              width: Get.width,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ccBackground,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < 2; i++) ...[
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ccInputBorder,
                            ),
                          ),
                          child: SvgPicture.asset(
                            i == 0
                                ? "assets/image/svg/arrow-down-circle-filled.svg"
                                : "assets/image/svg/locationpinfilled.svg",
                            color: i == 0
                                ? ccPrimary
                                : ccNavyText,
                            height: 28,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                i == 0
                                    ? tripDetailsApiModel!.tripData!.originAddress!.split(",").first
                                    : tripDetailsApiModel!.tripData!.destiAddress!.split(",").first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ccNavyText,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                i == 0
                                    ? DateFormat('EEE, MMM d \'at\' h:mma').format(DateTime.parse("${tripDetailsApiModel!.tripData!.tripStartDate!.toIso8601String().split('T').first} at ${tripDetailsApiModel!.tripData!.tripStartTime}".replaceAll(" at ", " ")))
                                    : tripEndTime.value,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ccSecondaryText,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                i == 0 ? "Pickup point" : "Destination",
                                style: const TextStyle(
                                  color: ccSecondaryText,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i != 0)
                          if (tripDetailsApiModel!.tripData!.tripIsReturn != "0")
                            SvgPicture.asset(
                              "assets/image/svg/returenarrow.svg",
                              color: ccNavyText,
                              height: 20,
                            ),
                      ],
                    ),
                    if (i == 0)
                      for (int si = 0; si < tripDetailsApiModel!.tripData!.stopsDetails!.length; si++) ...[
                        SizedBox(width: 55, child: buildDashedLine()),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: ccInputBorder,
                                ),
                              ),
                              child: SvgPicture.asset(
                                "assets/image/svg/Gps.svg",
                                color: ccError,
                                height: 28,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tripDetailsApiModel!.tripData!.stopsDetails![si].location!.split(",").first,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: ccNavyText,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tripStopPointTime[si],
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: ccSecondaryText,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    "Stop ${si + 1}",
                                    style: const TextStyle(
                                      color: ccSecondaryText,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    if (i != 2 - 1)
                      SizedBox(width: 55, child: buildDashedLine()),
                  ],
                ],
              ),
            ),
            SizedBox(height: 10),
            InkWell(
              onTap: () {
                isCancel =! isCancel;
                update();
              },
              child: Row(
                children: [
                  Obx(
                    () => SizedBox(
                      height: 20,
                      width: 20,
                      child: Checkbox(
                        value: isCancel,
                        activeColor: ccPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                        side: BorderSide(),
                        onChanged: (value) {
                          isCancel = value!;
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "I confirm that I want to cancel this trip".tr,
                      style: const TextStyle(
                        color: ccSecondaryText,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Obx(
              () => isCancelLoading
                ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: ccPrimary)))
                : CCButton(
                    label: "Cancel trip".tr,
                    onPressed: () {
                      if (isCancel) {
                        cancelTripsApi(tripId: tripId);
                      } else {
                        showToastMessage("Please confirm you'd like to proceed".tr);
                      }
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
