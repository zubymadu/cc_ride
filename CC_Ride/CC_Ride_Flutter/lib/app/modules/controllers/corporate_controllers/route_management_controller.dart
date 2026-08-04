import 'dart:convert';
import 'dart:developer';
import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/corporate_models.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class RouteManagementController extends GetxController {
  final Map<String, String> _headers = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  // ─── State ─────────────────────────────────────────────────────────────────

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool v) => _isLoading.value = v;

  final RxBool _isSaving = false.obs;
  bool get isSaving => _isSaving.value;
  set isSaving(bool v) => _isSaving.value = v;

  final RxList<RouteModel> _routes = <RouteModel>[].obs;
  List<RouteModel> get routes => _routes;

  final RxList<RouteScheduleModel> _schedules = <RouteScheduleModel>[].obs;
  List<RouteScheduleModel> get schedules => _schedules;

  final RxList<dynamic> _poolVehicles = <dynamic>[].obs;
  List<dynamic> get poolVehicles => _poolVehicles;

  final RxList<EmployeeModel> _employees = <EmployeeModel>[].obs;
  List<EmployeeModel> get employees => _employees;

  // Create-route form
  final TextEditingController codeCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController originCtrl = TextEditingController();
  final TextEditingController destinationCtrl = TextEditingController();

  // Create-schedule form
  final TextEditingController timeCtrl = TextEditingController();
  final TextEditingController fareCtrl = TextEditingController();
  final TextEditingController seatCtrl = TextEditingController();
  final RxString scheduleVehicleId = ''.obs;
  final RxString scheduleDriverId = ''.obs;
  final RxList<int> scheduleDays = <int>[].obs;

  // Whether the "New Route" sheet also collects a first schedule, so route
  // + schedule (where seat capacity actually lives) can be created in one
  // step — matching the driver-side app's one-step flow — instead of always
  // forcing a separate "Add Schedule" step afterwards.
  final RxBool _setupScheduleNow = false.obs;
  bool get setupScheduleNow => _setupScheduleNow.value;
  set setupScheduleNow(bool value) => _setupScheduleNow.value = value;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    fetchRoutes();
  }

  @override
  void onClose() {
    codeCtrl.dispose();
    nameCtrl.dispose();
    originCtrl.dispose();
    destinationCtrl.dispose();
    timeCtrl.dispose();
    fareCtrl.dispose();
    seatCtrl.dispose();
    super.onClose();
  }

  // ─── API ───────────────────────────────────────────────────────────────────

  Future<void> fetchRoutes() async {
    try {
      isLoading = true;
      update();
      final companyId = getData.read('companyId') ?? '';
      final url = '${Confing.baseurl}${Confing.corporateRoutes}?company_id=$companyId';
      final response = await http.get(Uri.parse(url), headers: _headers);
      log(name: '=== Routes ===', response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Result'] == 'true') {
          _routes.value =
              (data['data'] as List).map((e) => RouteModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      log(name: '=== Routes error ===', '$e');
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> createRoute() async {
    if (codeCtrl.text.trim().isEmpty ||
        nameCtrl.text.trim().isEmpty ||
        originCtrl.text.trim().isEmpty ||
        destinationCtrl.text.trim().isEmpty) {
      showToastMessage('Please fill in all fields');
      return;
    }
    if (setupScheduleNow &&
        (timeCtrl.text.trim().isEmpty ||
            fareCtrl.text.trim().isEmpty ||
            seatCtrl.text.trim().isEmpty ||
            scheduleVehicleId.value.isEmpty ||
            scheduleDriverId.value.isEmpty ||
            scheduleDays.isEmpty)) {
      showToastMessage('Fill in the schedule fields, or turn off "Set up first schedule now"');
      return;
    }
    try {
      isSaving = true;
      update();
      final body = {
        "company_id": getData.read('companyId') ?? '',
        "code": codeCtrl.text.trim(),
        "name": nameCtrl.text.trim(),
        "origin_name": originCtrl.text.trim(),
        "origin_lat": 0.0,
        "origin_lng": 0.0,
        "destination_name": destinationCtrl.text.trim(),
        "destination_lat": 0.0,
        "destination_lng": 0.0,
        "stops": [],
        // Optional — creates route + its first schedule (where seat
        // capacity lives) together, matching the driver-side app's
        // one-step flow, instead of always forcing a separate step.
        if (setupScheduleNow)
          "schedule": {
            "departure_time": timeCtrl.text.trim(),
            "days_of_week": scheduleDays.toList(),
            "driver_id": scheduleDriverId.value,
            "vehicle_id": scheduleVehicleId.value,
            "seat_capacity": int.tryParse(seatCtrl.text.trim()) ?? 4,
            "fare": double.tryParse(fareCtrl.text.trim()) ?? 0,
          },
      };
      final response = await http.post(
        Uri.parse('${Confing.baseurl}${Confing.corporateRoutes}'),
        headers: _headers,
        body: jsonEncode(body),
      );
      log(name: '=== CreateRoute ===', response.body);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['Result'] == 'true') {
        showToastMessage('Route created');
        codeCtrl.clear();
        nameCtrl.clear();
        originCtrl.clear();
        destinationCtrl.clear();
        timeCtrl.clear();
        fareCtrl.clear();
        seatCtrl.clear();
        scheduleVehicleId.value = '';
        scheduleDriverId.value = '';
        scheduleDays.clear();
        setupScheduleNow = false;
        Get.back();
        fetchRoutes();
      } else {
        showToastMessage(data['ResponseMsg'] ?? 'Failed to create route');
      }
    } catch (e) {
      showToastMessage('Error: $e');
    } finally {
      isSaving = false;
      update();
    }
  }

  Future<void> fetchSchedules(String routeId) async {
    try {
      isLoading = true;
      update();
      final companyId = getData.read('companyId') ?? '';
      final url =
          '${Confing.baseurl}${Confing.corporateRouteSchedules}/$routeId/schedules?company_id=$companyId';
      final response = await http.get(Uri.parse(url), headers: _headers);
      log(name: '=== RouteSchedules ===', response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Result'] == 'true') {
          _schedules.value = (data['data'] as List)
              .map((e) => RouteScheduleModel.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      log(name: '=== RouteSchedules error ===', '$e');
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> fetchPoolVehicles() async {
    try {
      final companyId = getData.read('companyId') ?? '';
      final url = '${Confing.baseurl}${Confing.corporatePoolVehicles}?company_id=$companyId';
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Result'] == 'true') {
          _poolVehicles.value = data['data'] as List;
          update();
        }
      }
    } catch (e) {
      log(name: '=== PoolVehicles error ===', '$e');
    }
  }

  Future<void> fetchEmployees() async {
    try {
      final companyId = getData.read('companyId') ?? '';
      final url = '${Confing.baseurl}${Confing.corporateEmployees}?company_id=$companyId';
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Result'] == 'true') {
          _employees.value = (data['data'] as List)
              .map((e) => EmployeeModel.fromJson(e))
              .toList();
          update();
        }
      }
    } catch (e) {
      log(name: '=== Employees error ===', '$e');
    }
  }

  Future<void> createSchedule(String routeId) async {
    if (timeCtrl.text.trim().isEmpty ||
        fareCtrl.text.trim().isEmpty ||
        seatCtrl.text.trim().isEmpty ||
        scheduleVehicleId.value.isEmpty ||
        scheduleDriverId.value.isEmpty ||
        scheduleDays.isEmpty) {
      showToastMessage('Please fill in all schedule fields');
      return;
    }
    try {
      isSaving = true;
      update();
      final body = {
        "company_id": getData.read('companyId') ?? '',
        "departure_time": timeCtrl.text.trim(),
        "days_of_week": scheduleDays.toList(),
        "driver_id": scheduleDriverId.value,
        "vehicle_id": scheduleVehicleId.value,
        "seat_capacity": int.tryParse(seatCtrl.text.trim()) ?? 4,
        "fare": double.tryParse(fareCtrl.text.trim()) ?? 0,
      };
      final response = await http.post(
        Uri.parse('${Confing.baseurl}${Confing.corporateRouteSchedules}/$routeId/schedules'),
        headers: _headers,
        body: jsonEncode(body),
      );
      log(name: '=== CreateSchedule ===', response.body);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['Result'] == 'true') {
        showToastMessage('Schedule created');
        timeCtrl.clear();
        fareCtrl.clear();
        seatCtrl.clear();
        scheduleVehicleId.value = '';
        scheduleDriverId.value = '';
        scheduleDays.clear();
        Get.back();
        fetchSchedules(routeId);
        fetchRoutes();
      } else {
        showToastMessage(data['ResponseMsg'] ?? 'Failed to create schedule');
      }
    } catch (e) {
      showToastMessage('Error: $e');
    } finally {
      isSaving = false;
      update();
    }
  }

  void toggleScheduleDay(int day) {
    if (scheduleDays.contains(day)) {
      scheduleDays.remove(day);
    } else {
      scheduleDays.add(day);
    }
  }
}
