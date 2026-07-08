import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/booking_controllers/book_pricing_controller.dart';
import 'package:carride/app/modules/controllers/post_controllers/trip_preview_screen_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ─── Policy check result ──────────────────────────────────────────────────────

enum PolicyStatus { unchecked, checking, allowed, requiresApproval, blocked }

class PolicyCheckResult {
  final PolicyStatus status;
  final String? reason;      // why it's blocked / why it needs approval
  final String? policyName;
  final String? approverName;
  final String? approverRole;
  final int?    expiryHours; // how long approval window is open

  const PolicyCheckResult({
    required this.status,
    this.reason,
    this.policyName,
    this.approverName,
    this.approverRole,
    this.expiryHours,
  });

  factory PolicyCheckResult.fromJson(Map<String, dynamic> json) {
    final raw = json['status'] as String? ?? 'allowed';
    final s = raw == 'requires_approval'
        ? PolicyStatus.requiresApproval
        : raw == 'blocked'
            ? PolicyStatus.blocked
            : PolicyStatus.allowed;
    return PolicyCheckResult(
      status: s,
      reason: json['reason'],
      policyName: json['policy_name'],
      approverName: json['approver_name'],
      approverRole: json['approver_role'],
      expiryHours: json['expiry_hours'] is int ? json['expiry_hours'] : null,
    );
  }
}

// ─── Controller ───────────────────────────────────────────────────────────────

class CorporateBookingFlowController extends GetxController {
  // Related controllers
  TripPreviewScreenController get tripCtrl =>
      Get.find<TripPreviewScreenController>();
  BookPricingController get pricingCtrl => Get.find<BookPricingController>();

  final Map<String, String> _headers = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  // ─── Employee corporate profile ──────────────────────────────────────────

  final RxString companyId    = ''.obs;
  final RxString companyName  = ''.obs;
  final RxString departmentId = ''.obs;
  final RxString departmentName = ''.obs;
  final RxString costCentreId = ''.obs;
  final RxString costCentreName = ''.obs;
  final RxString employeeRole = ''.obs;
  final RxDouble monthlySpendLimit = 0.0.obs;
  final RxDouble monthlySpentSoFar = 0.0.obs;

  // Available cost centres for this employee's dept
  final RxList<Map<String, String>> costCentres = <Map<String, String>>[].obs;

  // ─── Driver message ──────────────────────────────────────────────────────

  final TextEditingController messageController = TextEditingController();

  // ─── Policy check ────────────────────────────────────────────────────────

  final Rx<PolicyCheckResult> policyResult =
      const PolicyCheckResult(status: PolicyStatus.unchecked).obs;

  bool get policyChecked =>
      policyResult.value.status != PolicyStatus.unchecked &&
      policyResult.value.status != PolicyStatus.checking;

  bool get canBook =>
      policyResult.value.status == PolicyStatus.allowed ||
      policyResult.value.status == PolicyStatus.requiresApproval;

  bool get isBlocked => policyResult.value.status == PolicyStatus.blocked;

  // ─── Loading states ──────────────────────────────────────────────────────

  final RxBool _isLoadingProfile = true.obs;
  bool get isLoadingProfile => _isLoadingProfile.value;

  final RxBool _isCheckingPolicy = false.obs;
  bool get isCheckingPolicy => _isCheckingPolicy.value;

  final RxBool _isBooking = false.obs;
  bool get isBooking => _isBooking.value;

  // ─── Pending approval data (returned after submit) ───────────────────────

  final RxString approvalRequestId = ''.obs;
  final RxString approvalExpiresAt = ''.obs;

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }

  // ─── Profile load ────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    try {
      // First populate from GetStorage (set during login)
      companyId.value    = getData.read('companyId') ?? '';
      companyName.value  = getData.read('companyName') ?? '';
      departmentId.value = getData.read('departmentId') ?? '';
      departmentName.value = getData.read('departmentName') ?? '';
      costCentreId.value = getData.read('costCentreId') ?? '';
      costCentreName.value = getData.read('costCentreName') ?? '';
      employeeRole.value = getData.read('employeeRole') ?? 'employee';

      // Refresh from API for up-to-date spend data
      final uid = getData.read('userLogin')?['id'] ?? '';
      final url =
          '${Confing.baseurl}${Confing.corporateEmployeeProfile}?user_id=$uid&company_id=${companyId.value}';

      final response = await http.get(Uri.parse(url), headers: _headers);
      log(name: '=== CorpProfile ===', response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Result'] == 'true') {
          final d = data['data'] as Map<String, dynamic>;
          companyName.value    = d['company_name'] ?? companyName.value;
          departmentId.value   = '${d['department_id'] ?? departmentId.value}';
          departmentName.value = d['department'] ?? departmentName.value;
          costCentreId.value   = '${d['cost_centre_id'] ?? costCentreId.value}';
          costCentreName.value = d['cost_centre'] ?? costCentreName.value;
          employeeRole.value   = d['role'] ?? employeeRole.value;
          monthlySpendLimit.value =
              double.tryParse('${d['monthly_spend_limit']}') ?? 0;
          monthlySpentSoFar.value =
              double.tryParse('${d['monthly_spent']}') ?? 0;

          // Cost centres available for this employee
          if (d['cost_centres'] is List) {
            costCentres.value = (d['cost_centres'] as List)
                .map((e) => {
                      'id': '${e['id']}',
                      'name': '${e['name']}',
                      'code': '${e['code']}',
                    })
                .toList();
          }
        }
      }
    } catch (e) {
      log(name: '=== CorpProfile error ===', '$e');
    } finally {
      _isLoadingProfile.value = false;
      update();
      // Auto-run policy check once profile is loaded
      checkPolicy();
    }
  }

  // ─── Policy check ────────────────────────────────────────────────────────

  Future<void> checkPolicy() async {
    if (companyId.value.isEmpty) return;

    try {
      _isCheckingPolicy.value = true;
      policyResult.value = const PolicyCheckResult(status: PolicyStatus.checking);
      update();

      final trip = tripCtrl.tripDetailsApiModel?.tripData;
      final pricing = pricingCtrl;

      final body = {
        'company_id': companyId.value,
        'user_id': getData.read('userLogin')?['id'] ?? '',
        'department_id': departmentId.value,
        'estimated_fare': '${pricing.totalAmount}',
        'scheduled_at': '${trip?.tripStartDate?.toIso8601String().split('T').first ?? ''} ${trip?.tripStartTime ?? ''}',
        'vehicle_type_id': '${trip?.vehicleType ?? ''}',
        'origin_lat': '${trip?.originLat ?? ''}',
        'origin_lng': '${trip?.originLong ?? ''}',
      };

      final response = await http.post(
        Uri.parse('${Confing.baseurl}${Confing.corporateBookingCheckPolicy}'),
        headers: _headers,
        body: jsonEncode(body),
      );
      log(name: '=== PolicyCheck ===', response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Result'] == 'true') {
          policyResult.value =
              PolicyCheckResult.fromJson(data['data'] as Map<String, dynamic>);
        } else {
          policyResult.value = PolicyCheckResult(
            status: PolicyStatus.blocked,
            reason: data['ResponseMsg'] ?? 'Policy check failed',
          );
        }
      } else {
        // Network error — allow booking to proceed rather than blocking
        policyResult.value =
            const PolicyCheckResult(status: PolicyStatus.allowed);
      }
    } catch (e) {
      log(name: '=== PolicyCheck error ===', '$e');
      policyResult.value =
          const PolicyCheckResult(status: PolicyStatus.allowed);
    } finally {
      _isCheckingPolicy.value = false;
      update();
    }
  }

  // ─── Submit booking ───────────────────────────────────────────────────────

  Future<void> submitBooking() async {
    if (messageController.text.trim().isEmpty) {
      showToastMessage('Please add a message for the driver');
      return;
    }
    if (!canBook) return;

    try {
      _isBooking.value = true;
      update();

      final trip = tripCtrl.tripDetailsApiModel!.tripData!;
      final pricing = pricingCtrl;
      final userId = getData.read('userLogin')?['id'] ?? '';

      final body = {
        'uid': userId,
        'book_uid': userId,
        'trip_id': '${trip.tripId}',
        'total_seat': '${pricing.counter}',
        'book_method': 'Instant',
        'subtotal': '${pricing.subTotal}',
        'total_amount': '${pricing.totalAmount}',
        'cou_amt': '${pricing.couponAmount}',
        'wall_amt': '${pricing.useWalletAmount}',
        'driver_alert_info': messageController.text.trim(),
        'booking_fees': '${pricing.bookfee}',
        // Corporate metadata
        'company_id': companyId.value,
        'department_id': departmentId.value,
        'cost_centre_id': costCentreId.value,
        'requires_approval':
            policyResult.value.status == PolicyStatus.requiresApproval
                ? '1'
                : '0',
        'transaction_id': '',
        'payment_id': '0', // Company account — no gateway charge
        'request_id': '0',
      };

      final response = await http.post(
        Uri.parse('${Confing.baseurl}${Confing.corporateBookingBook}'),
        headers: _headers,
        body: jsonEncode(body),
      );
      log(name: '=== CorpBooking ===', response.body);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['Result'] == 'true') {
        if (policyResult.value.status == PolicyStatus.requiresApproval) {
          // Approval path
          approvalRequestId.value = '${data['approval_request_id'] ?? ''}';
          approvalExpiresAt.value = data['expires_at'] ?? '';
          Get.offNamed(Routes.APPROVAL_PENDING,
              arguments: {
                'approval_request_id': approvalRequestId.value,
                'expires_at': approvalExpiresAt.value,
                'approver_name':
                    policyResult.value.approverName ?? 'your manager',
                'approver_role': policyResult.value.approverRole ?? 'manager',
                'company_name': companyName.value,
                'origin':
                    trip.originAddress ?? '',
                'destination': trip.destiAddress ?? '',
                'estimated_fare': pricing.totalAmount,
              });
        } else {
          // Direct book path
          _showCorporateBookingSuccess();
        }
      } else {
        showToastMessage(data['ResponseMsg'] ?? 'Booking failed. Please try again.');
      }
    } catch (e) {
      log(name: '=== CorpBooking error ===', '$e');
      showToastMessage('Error: $e');
    } finally {
      _isBooking.value = false;
      update();
    }
  }

  // ─── Success sheet ────────────────────────────────────────────────────────

  void _showCorporateBookingSuccess() {
    Get.bottomSheet(
      isDismissible: false,
      enableDrag: false,
      backgroundColor: ccBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      PopScope(
        canPop: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFF00B894),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text('Booking Confirmed',
                  style: TextStyle(
                      fontSize: 22,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: ccNavyText)),
              const SizedBox(height: 8),
              Text(
                'Your ride has been booked and charged to ${companyName.value}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Inter',
                    color: ccNavyText.withOpacity(0.6)),
              ),
              const SizedBox(height: 8),
              _receiptChip(),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: ccInputBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Home',
                        style: TextStyle(
                            color: ccNavyText,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN);
                      Get.toNamed(Routes.MY_BOOKING_SCREEN);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ccPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('My Bookings',
                        style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptChip() {
    final pricing = pricingCtrl;
    final nf = NumberFormat('#,##0', 'en_US');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF00B894).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00B894).withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.receipt_outlined,
            color: Color(0xFF00B894), size: 16),
        const SizedBox(width: 8),
        Text(
          '₦${nf.format(pricing.totalAmount)} → ${companyName.value}',
          style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              color: Color(0xFF00B894)),
        ),
      ]),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String formatNaira(double v) {
    final f = NumberFormat('#,##0', 'en_US');
    return '₦${f.format(v)}';
  }

  double get remainingBudget =>
      (monthlySpendLimit.value - monthlySpentSoFar.value)
          .clamp(0, double.infinity);

  bool get fareExceedsLimit =>
      monthlySpendLimit.value > 0 &&
      pricingCtrl.totalAmount > remainingBudget;

  void selectCostCentre(String id, String name) {
    costCentreId.value = id;
    costCentreName.value = name;
    update();
    checkPolicy();
  }
}
