import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/account_controllers/earning_controllers/earning_screen_controller.dart';
import 'package:carride/app/modules/controllers/post_controllers/my_routes_controller.dart';
import 'package:carride/app/modules/controllers/trips_controllers/trip_screen_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

/// Every app open, the user is asked how they're using CC Ride right now.
/// Anyone registered as a pool driver (they have at least one active pool
/// vehicle access grant from a participating organisation) sees 3 options:
/// Passenger, Pool driver, or Own-car driver. Everyone else — including
/// independent, non-corporate users — sees 2: Passenger or Own-car driver.
///
/// This is a per-session choice, not a permanent role — the same person can
/// answer differently tomorrow, and the vehicle itself is re-picked at the
/// start of each trip since pool car availability can change trip to trip.
class DriverModeController extends GetxController {
  Map<String, String> get _headers => {
        "Content-type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer ${getData.read('token') ?? ''}",
      };

  bool get _isCompanyEmployee =>
      (getData.read('companyId') as String? ?? '').isNotEmpty;

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool v) => _isLoading.value = v;

  // 'passenger' | 'pool' | 'own_car' — exposed as the Rx itself (not just a
  // getter) so other controllers (the bottom nav shell) can `ever()` it and
  // rebuild their mode-dependent content the instant the user picks a mode,
  // rather than only reflecting it after the next app restart.
  final RxnString modeRx = RxnString();
  String? get mode => modeRx.value;
  bool get isDriverMode => mode == 'pool' || mode == 'own_car';

  final RxnString _vehicleId = RxnString();
  String? get vehicleId => _vehicleId.value;

  List<Map<String, String>> poolVehicles = [];
  List<Map<String, String>> personalVehicles = [];

  bool _promptShown = false;

  /// Call once when the app's main shell (bottom nav) opens.
  Future<void> promptIfNeeded() async {
    final uid = getData.read('userLogin')?['id'];
    if (uid == null) return; // not logged in yet
    // Guards against being called more than once per app session (e.g. if
    // the bottom-nav shell's controller is ever re-created) — without this,
    // a second call re-opens the sheet right after the user just answered
    // the first one, making the prompt look like it never dismisses.
    if (_promptShown) return;
    _promptShown = true;

    isLoading = true;
    poolVehicles = _isCompanyEmployee ? await _fetchPoolVehicles() : [];
    isLoading = false;

    await _showModePrompt();
  }

  Future<List<Map<String, String>>> _fetchPoolVehicles() async {
    try {
      final companyId = getData.read('companyId') ?? '';
      final uid = getData.read('userLogin')?['id'] ?? '';
      final url =
          '${Confing.baseurl}${Confing.corporateDriverAccess}?company_id=$companyId&driver_id=$uid';
      final response = await http.get(Uri.parse(url), headers: _headers);
      final data = jsonDecode(response.body);
      if (data['Result'] == 'true' && data['data'] is List) {
        return (data['data'] as List)
            .map<Map<String, String>>((v) => {
                  'id': '${v['vehicle_id']}',
                  'title':
                      '${v['model_title']} (${v['license_plate']})',
                })
            .toList();
      }
    } catch (e) {
      log(name: '=== DriverMode pool fetch error ===', '$e');
    }
    return [];
  }

  /// Fetches every vehicle the user has registered, split into approved
  /// (drivable now) and pending (submitted, awaiting approval) — the mode
  /// prompt needs to tell those two apart to give the right feedback:
  /// "register a car" vs. "you're just waiting on approval".
  Future<({List<Map<String, String>> approved, bool hasPending})>
      _fetchPersonalVehicles() async {
    try {
      final uid = getData.read('userLogin')?['id'] ?? '';
      final url = '${Confing.baseurl}${Confing.vehicleList}';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({"uid": uid}),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (data['Result'] == 'true' && data['VehicleData'] is List) {
        final all = data['VehicleData'] as List;
        final approved = all
            .where((v) => '${v['status']}' == 'approved')
            .map<Map<String, String>>((v) => {
                  'id': '${v['id']}',
                  'title':
                      '${v['model_title']} (${v['license_plate']})',
                })
            .toList();
        final hasPending = all.any((v) => '${v['status']}' != 'approved');
        return (approved: approved, hasPending: hasPending);
      }
    } catch (e) {
      log(name: '=== DriverMode personal vehicle fetch error ===', '$e');
    }
    return (approved: <Map<String, String>>[], hasPending: false);
  }

  /// The old passenger/driver chooser bottomsheet (shown on search-results
  /// screens) still lets a driver-mode user tap "I need a ride" mid-session,
  /// which sends them into the passenger booking flow without ever telling
  /// this controller — leaving modeRx stuck on 'pool'/'own_car' while the
  /// bottom nav still renders driver-mode tabs. Call this from that flow so
  /// the two stay in sync instead of silently diverging until next app open.
  void switchToPassenger() {
    if (mode == 'passenger') return;
    _applyMode('passenger', null);
  }

  /// Mirror of switchToPassenger() for the opposite direction — the old
  /// chooser bottomsheet's "I'm driving" option sent a passenger-mode user
  /// straight into the post-trip flow without ever updating modeRx, leaving
  /// the bottom nav stuck on passenger tabs afterward. Reuses the same
  /// pool/personal vehicle-pick flow the initial mode prompt uses, just
  /// without re-asking the 3-way question (the user already answered it by
  /// tapping "I'm driving").
  Future<void> switchToDriving() async {
    if (isDriverMode) return;
    isLoading = true;
    update();
    if (poolVehicles.isEmpty && _isCompanyEmployee) {
      poolVehicles = await _fetchPoolVehicles();
    }
    isLoading = false;
    update();
    if (poolVehicles.isNotEmpty) {
      _pickPoolVehicle();
    } else {
      await _pickPersonalVehicle();
    }
  }

  void _selectMode(String mode, String? vehicleId) {
    _applyMode(mode, vehicleId);
    // Only true when this resolved without ever opening a picker sheet (e.g.
    // switchToDriving() finds exactly one vehicle) — nothing to close in that
    // case, and popping anyway would take out whatever screen the caller was
    // already on.
    if (Get.isBottomSheetOpen == true) Get.back();
  }

  void _applyMode(String mode, String? vehicleId) {
    modeRx.value = mode;
    _vehicleId.value = vehicleId;
    save('driverMode', mode);
    save('driverVehicleId', vehicleId ?? '');
    _refetchModeScopedScreens();
  }

  // Pool and own-car activity must stay visually distinct — switching modes
  // mid-session (without restarting the app) would otherwise leave whatever
  // trip/route/earnings list is already loaded showing the *previous*
  // mode's data until that screen happens to be reopened. Refetch any of
  // these that are already alive right now so they immediately reflect the
  // new mode.
  void _refetchModeScopedScreens() {
    if (Get.isRegistered<TripScreenController>()) {
      Get.find<TripScreenController>().tripListApi(status: 'Active');
    }
    if (Get.isRegistered<MyRoutesController>()) {
      Get.find<MyRoutesController>().fetchRoutes();
    }
    if (Get.isRegistered<EarningScreenController>()) {
      Get.find<EarningScreenController>().earningApi();
    }
  }

  Future<void> _showModePrompt() async {
    final isPoolDriver = poolVehicles.isNotEmpty;

    return Get.bottomSheet(
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: ccSurface,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(CCRadius.sheet))),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How are you using CC Ride right now?",
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: ccNavyText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "You'll be asked again next time you open the app.",
              style: CCText.bodyMd.copyWith(color: ccSecondaryText),
            ),
            const SizedBox(height: 20),
            _ModeTile(
              icon: Icons.person_outline_rounded,
              title: "Passenger",
              subtitle: "Just booking a ride",
              // Unlike the other two tiles, this relied solely on
              // _selectMode's `if (Get.isBottomSheetOpen == true)
              // Get.back()` guard to close the sheet — that check does not
              // reliably reflect true for a bottomSheet opened with
              // isDismissible:false/enableDrag:false, so tapping Passenger
              // left the sheet permanently stuck open. Close it
              // unconditionally first, exactly like Pool driver/Own-car
              // driver already do.
              onTap: () {
                Get.back();
                _selectMode('passenger', null);
              },
            ),
            const SizedBox(height: 10),
            if (isPoolDriver) ...[
              _ModeTile(
                icon: Icons.directions_car_filled_rounded,
                title: "Pool driver",
                subtitle: "Driving one of your organisation's cars",
                onTap: () {
                  Get.back();
                  _pickPoolVehicle();
                },
              ),
              const SizedBox(height: 10),
            ],
            _ModeTile(
              icon: Icons.time_to_leave_rounded,
              title: "Own-car driver",
              subtitle: "Driving your own vehicle",
              onTap: () async {
                Get.back();
                await _pickPersonalVehicle();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickPoolVehicle() {
    // poolVehicles was already fetched in promptIfNeeded() to decide whether
    // to show this option at all — reuse it rather than fetching twice.
    if (poolVehicles.length == 1) {
      _selectMode('pool', poolVehicles.first['id']);
      return;
    }
    _showVehiclePicker(poolVehicles, 'pool');
  }

  Future<void> _pickPersonalVehicle() async {
    isLoading = true;
    update();
    final result = await _fetchPersonalVehicles();
    personalVehicles = result.approved;
    isLoading = false;
    update();

    if (personalVehicles.isNotEmpty) {
      if (personalVehicles.length == 1) {
        _selectMode('own_car', personalVehicles.first['id']);
      } else {
        _showVehiclePicker(personalVehicles, 'own_car');
      }
      return;
    }

    // No drivable vehicle yet — resolve to Passenger immediately so the user
    // is never stuck, and tell them exactly what's going on.
    _selectMode('passenger', null);
    if (result.hasPending) {
      _showFeedback(
        title: "Application under review",
        body:
            "Your vehicle is awaiting approval from your organisation. You can continue using CC Ride as a passenger until it's approved.",
      );
    } else {
      _showFeedback(
        title: "Register a vehicle to drive",
        body:
            "You'll need to register a vehicle and get it approved before you can drive. You can continue as a passenger in the meantime.",
        actionLabel: "Register vehicle",
        onAction: () => Get.toNamed(Routes.ADD_VEHICLE_SCREEN),
      );
    }
  }

  void _showFeedback({
    required String title,
    required String body,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    Get.dialog(
      AlertDialog(
        backgroundColor: ccSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CCRadius.card)),
        title: Text(title,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: ccNavyText)),
        content: Text(body,
            style: CCText.bodyMd.copyWith(color: ccSecondaryText)),
        actions: [
          if (actionLabel != null)
            TextButton(
              onPressed: () {
                Get.back();
                onAction?.call();
              },
              child: Text(actionLabel,
                  style: const TextStyle(
                      color: ccPrimary, fontWeight: FontWeight.w600)),
            ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Continue as passenger",
                style: TextStyle(color: ccSecondaryText)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showVehiclePicker(List<Map<String, String>> vehicles, String mode) {
    Get.bottomSheet(
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: ccSurface,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(CCRadius.sheet))),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Which vehicle are you using?",
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: ccNavyText,
              ),
            ),
            const SizedBox(height: 16),
            for (final v in vehicles) ...[
              _ModeTile(
                icon: Icons.directions_car_outlined,
                title: v['title'] ?? '',
                subtitle: null,
                onTap: () => _selectMode(mode, v['id']),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ccSurface,
            borderRadius: BorderRadius.circular(CCRadius.card),
            border: Border.all(color: ccInputBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ccIceBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: ccPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ccNavyText,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: ccSecondaryText),
            ],
          ),
        ),
      ),
    );
  }
}
