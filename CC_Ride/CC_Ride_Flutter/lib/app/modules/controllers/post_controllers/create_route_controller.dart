import 'dart:convert';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/driver_mode/driver_mode_controller.dart';
import 'package:carride/app/modules/controllers/search_controllers/map_suggetion_controlle.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class NearbyRequestSummary {
  final String fromAddress;
  final String toAddress;
  final String seatRequire;
  final String userTitle;

  NearbyRequestSummary({
    required this.fromAddress,
    required this.toAddress,
    required this.seatRequire,
    required this.userTitle,
  });

  factory NearbyRequestSummary.fromJson(Map<String, dynamic> json) =>
      NearbyRequestSummary(
        fromAddress: '${json["from_address"]}',
        toAddress: '${json["to_address"]}',
        seatRequire: '${json["seat_require"]}',
        userTitle: '${json["user_title"]}',
      );
}

class CreateRouteController extends GetxController {
  final MapSuggetionControlle mapSuggetionControlle =
      Get.put(MapSuggetionControlle());

  final TextEditingController originController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController seatController = TextEditingController(text: "3");
  final TextEditingController fareController = TextEditingController();

  String originAddress = '';
  String originLat = '';
  String originLong = '';
  String destinationAddress = '';
  String destinationLat = '';
  String destinationLong = '';

  // 1=Mon .. 7=Sun display order, stored as 0=Sun..6=Sat to match the
  // backend's daysOfWeek convention (JS Date.getDay()).
  static const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final RxSet<int> selectedDays = <int>{}.obs;

  final Rx<TimeOfDay> departureTime = TimeOfDay.now().obs;

  final RxBool isPoolDriverMode = false.obs;
  final RxList<Map<String, String>> vehicles = <Map<String, String>>[].obs;
  final RxnString selectedVehicleId = RxnString();

  final RxList<NearbyRequestSummary> nearbyRequests =
      <NearbyRequestSummary>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;

  // Opt-in only — off by default so a driver's booking behaviour doesn't
  // silently change. When on, passenger requests for this route sit pending
  // until confirmed/declined from My Routes instead of auto-confirming.
  final RxBool manualApproval = false.obs;

  // Set only when reached via "Edit" on an existing route (see My Routes) —
  // routes submit() at a different endpoint and skips the day/vehicle reset
  // that create mode doesn't need.
  String? editRouteId;

  Map<String, String> get _headers => {
        "Content-type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer ${getData.read('token') ?? ''}",
      };

  @override
  void onInit() {
    _loadVehicles();
    ever(selectedVehicleId, (_) => estimateFareApi());
    final args = Get.arguments;
    if (args is Map) {
      if (args["origin_lat"] != null) {
        setOrigin(
          address: '${args["origin_address"]}',
          lat: double.tryParse('${args["origin_lat"]}') ?? 0,
          long: double.tryParse('${args["origin_long"]}') ?? 0,
        );
      }
      if (args["desti_lat"] != null) {
        setDestination(
          address: '${args["desti_address"]}',
          lat: double.tryParse('${args["desti_lat"]}') ?? 0,
          long: double.tryParse('${args["desti_long"]}') ?? 0,
        );
      }

      // Editing an existing route (see My Routes' edit action) — pre-fill
      // everything else too, and remember the route id so submit() updates
      // it instead of publishing a new one. A plain "adopt this route" tap
      // (from an unserviced nearby-route card) only ever sets origin/desti
      // above and leaves editRouteId null, still creating a new route.
      if (args["edit_route_id"] != null) {
        editRouteId = '${args["edit_route_id"]}';
        if (args["departure_time"] != null) {
          final parts = '${args["departure_time"]}'.split(':');
          if (parts.length == 2) {
            departureTime.value = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 0,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        }
        if (args["days_of_week"] is List) {
          selectedDays.assignAll((args["days_of_week"] as List)
              .map((d) => int.tryParse('$d') ?? 0));
        }
        if (args["seat_capacity"] != null) {
          seatController.text = '${args["seat_capacity"]}';
        }
        if (args["fare"] != null) {
          fareController.text = '${args["fare"]}';
        }
        if (args["book_preference"] != null) {
          manualApproval.value = '${args["book_preference"]}' == 'Manual';
        }
        // Vehicle selection is applied once _loadVehicles() populates the
        // list (below) — stash it for that callback rather than setting it
        // here, since the list may not be ready yet.
        _pendingVehicleId = args["vehicle_id"] != null &&
                '${args["vehicle_id"]}'.isNotEmpty
            ? '${args["vehicle_id"]}'
            : null;
      }
    }
    super.onInit();
  }

  String? _pendingVehicleId;

  Future<void> _loadVehicles() async {
    final driverMode = Get.isRegistered<DriverModeController>()
        ? Get.find<DriverModeController>()
        : null;
    isPoolDriverMode.value = driverMode?.mode == 'pool';

    if (isPoolDriverMode.value) {
      vehicles.assignAll(driverMode!.poolVehicles);
      if (driverMode.vehicleId != null) {
        selectedVehicleId.value = driverMode.vehicleId;
      }
      return;
    }

    isLoading.value = true;
    try {
      final url = Confing.baseurl + Confing.vehicleList;
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({"uid": "${getData.read("userLogin")?["id"]}"}),
      );
      final data = jsonDecode(response.body);
      if (data["Result"] == "true") {
        final list = (data["VehicleData"] as List? ?? [])
            .where((v) => '${v["status"]}' == 'approved')
            .map<Map<String, String>>((v) => {
                  'id': '${v["id"]}',
                  'title': '${v["model_title"]} (${v["license_plate"]})',
                })
            .toList();
        vehicles.assignAll(list);
        final matchesPending =
            list.any((v) => v['id'] == _pendingVehicleId);
        if (_pendingVehicleId != null && matchesPending) {
          selectedVehicleId.value = _pendingVehicleId;
        } else if (list.isNotEmpty) {
          selectedVehicleId.value = list.first['id'];
        }
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void setOrigin({
    required String address,
    required double lat,
    required double long,
  }) {
    originAddress = address;
    originLat = lat.toStringAsFixed(6);
    originLong = long.toStringAsFixed(6);
    originController.text = address;
    update();
    _fetchNearbyRequests();
    estimateFareApi();
  }

  void setDestination({
    required String address,
    required double lat,
    required double long,
  }) {
    destinationAddress = address;
    destinationLat = lat.toStringAsFixed(6);
    destinationLong = long.toStringAsFixed(6);
    destinationController.text = address;
    update();
    estimateFareApi();
  }

  // Advisory only, same as the one-off trip and passenger booking screens —
  // never blocks route creation, and only meaningful once the super-admin
  // has switched pricing_model to platform_computed.
  final RxBool hasEstimate = false.obs;
  final RxDouble estimatedFare = 0.0.obs;

  Future<void> estimateFareApi() async {
    if (originLat.isEmpty || destinationLat.isEmpty) return;
    try {
      final body = {
        "origin_lat": originLat,
        "origin_long": originLong,
        "desti_lat": destinationLat,
        "desti_long": destinationLong,
        if (selectedVehicleId.value != null) "vehicle_id": selectedVehicleId.value,
      };
      final response = await http
          .post(
            Uri.parse(Confing.baseurl + Confing.estimateFare),
            body: jsonEncode(body),
            headers: {
              "Content-type": "application/json",
              "Accept": "application/json",
              "Authorization": "Bearer ${getData.read('token') ?? ''}",
            },
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["Result"] == "true") {
        final model = data["data"]?["pricing_model"] ?? 'driver_set';
        estimatedFare.value = double.tryParse("${data["data"]?["estimated_fare"] ?? 0}") ?? 0;
        hasEstimate.value = model == 'platform_computed' && estimatedFare.value > 0;
      }
    } catch (_) {
      // Advisory only — silently leave hasEstimate as-is on failure.
    }
  }

  Future<void> _fetchNearbyRequests() async {
    if (originLat.isEmpty) return;
    try {
      final url = Confing.baseurl + Confing.nearbyRequestsRoute;
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({"origin_lat": originLat, "origin_long": originLong}),
      );
      final data = jsonDecode(response.body);
      if (data["Result"] == "true") {
        final list = (data["Data"] as List? ?? [])
            .map((e) => NearbyRequestSummary.fromJson(e))
            .toList();
        nearbyRequests.assignAll(list);
      }
    } catch (_) {}
  }

  void toggleDay(int day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
    } else {
      selectedDays.add(day);
    }
  }

  Future<bool> submit() async {
    if (originLat.isEmpty || destinationLat.isEmpty) {
      showToastMessage("Please set both origin and destination");
      return false;
    }
    if (selectedDays.isEmpty) {
      showToastMessage("Select at least one day of the week");
      return false;
    }
    if (seatController.text.isEmpty || fareController.text.isEmpty) {
      showToastMessage("Enter seat capacity and fare");
      return false;
    }
    if (isPoolDriverMode.value && vehicles.isEmpty) {
      showToastMessage("No pool vehicle assigned to you yet");
      return false;
    }

    isSubmitting.value = true;
    try {
      final hh = departureTime.value.hour.toString().padLeft(2, '0');
      final mm = departureTime.value.minute.toString().padLeft(2, '0');
      final isEditing = editRouteId != null;
      final url = Confing.baseurl +
          (isEditing ? Confing.driverRouteEdit : Confing.driverRouteCreate);
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({
          if (isEditing) "route_id": editRouteId,
          "origin_address": originAddress,
          "origin_lat": originLat,
          "origin_long": originLong,
          "desti_address": destinationAddress,
          "desti_lat": destinationLat,
          "desti_long": destinationLong,
          "departure_time": "$hh:$mm",
          "days_of_week": selectedDays.toList(),
          "seat_capacity": seatController.text,
          "fare": fareController.text,
          "vehicle_id": selectedVehicleId.value,
          "book_preference": manualApproval.value ? "Manual" : "Auto",
        }),
      );
      final data = jsonDecode(response.body);
      if (data["Result"] == "true") {
        showToastMessage(isEditing ? "Route updated" : "Route published");
        return true;
      } else {
        showToastMessage("${data["ResponseMsg"] ?? "Something went wrong"}");
        return false;
      }
    } catch (_) {
      showToastMessage("Something went wrong");
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
