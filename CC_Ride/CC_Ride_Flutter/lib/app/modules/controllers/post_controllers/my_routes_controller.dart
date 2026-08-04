import 'dart:convert';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/driver_mode/driver_mode_controller.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class MyRoute {
  final String routeId;
  final String routeCode;
  final String routeName;
  final String originName;
  final double originLat;
  final double originLong;
  final String destinationName;
  final double destinationLat;
  final double destinationLong;
  final String departureTime;
  final List<int> daysOfWeek;
  final int seatCapacity;
  final String fare;
  final String vehicleId;
  final String vehicleTitle;
  final bool manualApproval;

  MyRoute({
    required this.routeId,
    required this.routeCode,
    required this.routeName,
    required this.originName,
    required this.originLat,
    required this.originLong,
    required this.destinationName,
    required this.destinationLat,
    required this.destinationLong,
    required this.departureTime,
    required this.daysOfWeek,
    required this.seatCapacity,
    required this.fare,
    required this.vehicleId,
    required this.vehicleTitle,
    required this.manualApproval,
  });

  factory MyRoute.fromJson(Map<String, dynamic> json) => MyRoute(
        routeId: '${json["route_id"]}',
        routeCode: '${json["route_code"]}',
        routeName: '${json["route_name"]}',
        originName: '${json["origin_name"]}',
        originLat: double.tryParse('${json["origin_lat"]}') ?? 0,
        originLong: double.tryParse('${json["origin_long"]}') ?? 0,
        destinationName: '${json["destination_name"]}',
        destinationLat: double.tryParse('${json["destination_lat"]}') ?? 0,
        destinationLong: double.tryParse('${json["destination_long"]}') ?? 0,
        departureTime: '${json["departure_time"]}',
        daysOfWeek: (json["days_of_week"] as List? ?? [])
            .map((d) => int.tryParse('$d') ?? 0)
            .toList(),
        seatCapacity: int.tryParse('${json["seat_capacity"]}') ?? 0,
        fare: '${json["fare"]}',
        vehicleId: '${json["vehicle_id"] ?? ''}',
        vehicleTitle: '${json["vehicle_title"]}',
        manualApproval: '${json["book_preference"]}' == 'Manual',
      );
}

class MyRoutesController extends GetxController {
  final RxList<MyRoute> routes = <MyRoute>[].obs;
  final RxBool isLoading = true.obs;

  Map<String, String> get _headers => {
        "Content-type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer ${getData.read('token') ?? ''}",
      };

  @override
  void onInit() {
    fetchRoutes();
    super.onInit();
  }

  Future<void> fetchRoutes() async {
    isLoading.value = true;
    try {
      // Keep pool and own-car routes separate for a driver who runs both.
      final mode = Get.isRegistered<DriverModeController>()
          ? Get.find<DriverModeController>().mode
          : null;
      final url = Confing.baseurl + Confing.driverRouteList;
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: mode != null ? jsonEncode({"mode": mode}) : null,
      );
      final data = jsonDecode(response.body);
      if (data["Result"] == "true") {
        final list = (data["Data"] as List? ?? [])
            .map((e) => MyRoute.fromJson(e))
            .toList();
        routes.assignAll(list);
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deactivateRoute(String routeId) async {
    try {
      final url = Confing.baseurl + Confing.driverRouteDeactivate;
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({"route_id": routeId}),
      );
      final data = jsonDecode(response.body);
      if (data["Result"] == "true") {
        routes.removeWhere((r) => r.routeId == routeId);
        showToastMessage("Route removed from your list.");
      } else {
        showToastMessage("${data["ResponseMsg"] ?? "Something went wrong"}");
      }
    } catch (_) {
      showToastMessage("Something went wrong");
    }
  }
}
