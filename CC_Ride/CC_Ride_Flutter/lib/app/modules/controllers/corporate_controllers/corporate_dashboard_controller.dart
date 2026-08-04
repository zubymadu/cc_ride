import 'dart:convert';
import 'dart:developer';
import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/corporate_models.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/theme/theme_colores.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class CorporateDashboardController extends GetxController {
  final ThemeColores themeColores = Get.put(ThemeColores());

  final Map<String, String> _headers = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  // ─── State ─────────────────────────────────────────────────────────────────

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool v) => _isLoading.value = v;

  final Rx<CorporateDashboardModel?> _dashData = Rx(null);
  CorporateDashboardModel? get dashData => _dashData.value;

  final RxInt _selectedTab = 0.obs;
  int get selectedTab => _selectedTab.value;
  set selectedTab(int v) => _selectedTab.value = v;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
  }

  // ─── API ───────────────────────────────────────────────────────────────────

  Future<void> fetchDashboard() async {
    try {
      isLoading = true;
      update();

      final companyId = getData.read('companyId') ?? '';
      final url = '${Confing.baseurl}${Confing.corporateDashboard}?company_id=$companyId';

      final response = await http.get(Uri.parse(url), headers: _headers);
      log(name: '=== CorporateDashboard ===', response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Result'] == 'true') {
          _dashData.value = CorporateDashboardModel.fromJson(data['data']);
        }
      }
    } catch (e) {
      log(name: '=== CorporateDashboard error ===', '$e');
    } finally {
      isLoading = false;
      update();
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String formatNaira(double amount) {
    final f = NumberFormat('#,##0', 'en_US');
    return '₦${f.format(amount)}';
  }

  String spendPercentLabel(double percent) => '${percent.toStringAsFixed(0)}%';

  /// Colour for a spend bar based on percent used
  Color spendBarColor(double percent) {
    if (percent >= 90) return const Color(0xFFDC3545);
    if (percent >= 75) return const Color(0xFFFF9900);
    return const Color(0xFF00B894);
  }

  void goToEmployees() => Get.toNamed(Routes.EMPLOYEE_MANAGEMENT);
  void goToBudgets() => Get.toNamed(Routes.BUDGET_MANAGEMENT);
  void goToApprovals() => Get.toNamed(Routes.APPROVAL_QUEUE);
  void goToPolicies() => Get.toNamed(Routes.RIDE_POLICY);
  void goToRoutes() => Get.toNamed(Routes.ROUTE_MANAGEMENT);

  String get pendingLabel {
    final count = dashData?.pendingApprovals ?? 0;
    return count == 0 ? 'None' : '$count pending';
  }
}
