import 'dart:convert';
import 'dart:developer';
import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/corporate_models.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class BudgetManagementController extends GetxController {

  final Map<String, String> _headers = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  // ─── State ─────────────────────────────────────────────────────────────────

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool v) => _isLoading.value = v;

  final RxBool _isCreating = false.obs;
  bool get isCreating => _isCreating.value;
  set isCreating(bool v) => _isCreating.value = v;

  final RxList<BudgetModel> _budgets = <BudgetModel>[].obs;
  List<BudgetModel> get budgets => _budgets;

  final RxList<DepartmentModel> _departments = <DepartmentModel>[].obs;
  List<DepartmentModel> get departments => _departments;

  // Create form
  final TextEditingController amountCtrl = TextEditingController();
  final RxString createDeptId = ''.obs;
  final RxString createPeriodType = 'monthly'.obs;
  final Rx<DateTime> createPeriodStart = DateTime.now().obs;
  final RxDouble alertThreshold = 80.0.obs;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    fetchBudgets();
    fetchDepartments();
  }

  @override
  void onClose() {
    amountCtrl.dispose();
    super.onClose();
  }

  // ─── API ───────────────────────────────────────────────────────────────────

  Future<void> fetchBudgets() async {
    try {
      isLoading = true;
      update();
      final companyId = getData.read('companyId') ?? '';
      final response = await http.get(
        Uri.parse('${Confing.baseurl}${Confing.corporateBudgets}?company_id=$companyId'),
        headers: _headers,
      );
      log(name: '=== Budgets ===', response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Result'] == 'true') {
          _budgets.value =
              (data['data'] as List).map((e) => BudgetModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      log(name: '=== Budgets error ===', '$e');
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> fetchDepartments() async {
    try {
      final companyId = getData.read('companyId') ?? '';
      final response = await http.get(
        Uri.parse('${Confing.baseurl}${Confing.corporateDepartments}?company_id=$companyId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Result'] == 'true') {
          _departments.value =
              (data['data'] as List).map((e) => DepartmentModel.fromJson(e)).toList();
          if (_departments.isNotEmpty) createDeptId.value = _departments.first.id;
          update();
        }
      }
    } catch (e) {
      log(name: '=== Depts error ===', '$e');
    }
  }

  Future<void> createBudget() async {
    if (amountCtrl.text.trim().isEmpty) {
      showToastMessage('Enter a budget amount');
      return;
    }
    try {
      isCreating = true;
      update();

      final start = createPeriodStart.value;
      late DateTime end;
      switch (createPeriodType.value) {
        case 'quarterly':
          end = DateTime(start.year, start.month + 3, start.day);
          break;
        case 'annual':
          end = DateTime(start.year + 1, start.month, start.day);
          break;
        default:
          end = DateTime(start.year, start.month + 1, start.day);
      }

      final body = {
        "company_id": getData.read('companyId') ?? '',
        "department_id": createDeptId.value,
        "period_type": createPeriodType.value,
        "period_start": DateFormat('yyyy-MM-dd').format(start),
        "period_end": DateFormat('yyyy-MM-dd').format(end),
        "allocated_amount": amountCtrl.text.trim(),
        "alert_threshold": alertThreshold.value.toString(),
        "created_by": getData.read('userLogin')?['id'] ?? '',
      };

      final response = await http.post(
        Uri.parse('${Confing.baseurl}${Confing.corporateCreateBudget}'),
        headers: _headers,
        body: jsonEncode(body),
      );
      log(name: '=== CreateBudget ===', response.body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['Result'] == 'true') {
        showToastMessage('Budget created successfully');
        amountCtrl.clear();
        Get.back();
        fetchBudgets();
      } else {
        showToastMessage(data['ResponseMsg'] ?? 'Failed to create budget');
      }
    } catch (e) {
      showToastMessage('Error: $e');
    } finally {
      isCreating = false;
      update();
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String formatNaira(double amount) {
    final f = NumberFormat('#,##0', 'en_US');
    return '₦${f.format(amount)}';
  }

  Color barColor(double percent) {
    if (percent >= 90) return const Color(0xFFDC3545);
    if (percent >= 75) return const Color(0xFFFF9900);
    return const Color(0xFF00B894);
  }

  String periodLabel(BudgetModel b) {
    final fmt = DateFormat('dd MMM yyyy');
    try {
      final s = DateTime.parse(b.periodStart);
      final e = DateTime.parse(b.periodEnd);
      return '${fmt.format(s)} – ${fmt.format(e)}';
    } catch (_) {
      return '${b.periodStart} – ${b.periodEnd}';
    }
  }

  void showCreateSheet() {
    amountCtrl.clear();
    createPeriodType.value = 'monthly';
    createPeriodStart.value = DateTime.now();
    alertThreshold.value = 80.0;
    if (departments.isNotEmpty) createDeptId.value = departments.first.id;

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: ccBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 24,
        ),
        child: GetBuilder<BudgetManagementController>(
          builder: (c) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: ccInputBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Create Budget',
                  style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter', fontWeight: FontWeight.w700,
                      color: ccNavyText)),
              const SizedBox(height: 16),
              // Department
              _label('Department'),
              const SizedBox(height: 6),
              Obx(() => _dropdown(
                    value: createDeptId.value.isEmpty ? null : createDeptId.value,
                    hint: 'Company-wide',
                    items: [
                      DropdownMenuItem(
                          value: '',
                          child: _dropItem('Company-wide')),
                      ...departments.map((d) =>
                          DropdownMenuItem(value: d.id, child: _dropItem(d.name)))
                    ],
                    onChanged: (v) => createDeptId.value = v ?? '',
                  )),
              const SizedBox(height: 12),
              // Period type
              _label('Period'),
              const SizedBox(height: 6),
              Obx(() => Row(
                    children: ['monthly', 'quarterly', 'annual']
                        .map((p) => Expanded(
                              child: GestureDetector(
                                onTap: () => createPeriodType.value = p,
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: createPeriodType.value == p
                                        ? ccPrimary
                                        : Colors.transparent,
                                    border: Border.all(
                                        color: createPeriodType.value == p
                                            ? ccPrimary
                                            : ccInputBorder),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      p[0].toUpperCase() + p.substring(1),
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Inter', fontWeight: FontWeight.w500,
                                          color: createPeriodType.value == p
                                              ? Colors.white
                                              : ccNavyText),
                                    ),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  )),
              const SizedBox(height: 12),
              // Amount
              _label('Allocated Amount (₦)'),
              const SizedBox(height: 6),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: ccNavyText, fontFamily: 'Inter'),
                decoration: InputDecoration(
                  hintText: 'e.g. 500000',
                  prefixText: '₦ ',
                  prefixStyle: const TextStyle(
                      color: ccNavyText, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                  hintStyle: TextStyle(
                      color: ccNavyText.withOpacity(0.4),
                      fontFamily: 'Inter'),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: ccInputBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: ccInputBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: ccPrimary)),
                ),
              ),
              const SizedBox(height: 12),
              // Alert threshold
              Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Alert at ${alertThreshold.value.toInt()}% spend'),
                      Slider(
                        value: alertThreshold.value,
                        min: 50, max: 95, divisions: 9,
                        activeColor: ccPrimary,
                        onChanged: (v) => alertThreshold.value = v,
                      ),
                    ],
                  )),
              const SizedBox(height: 8),
              Obx(() => c.isCreating
                  ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: ccPrimary)))
                  : CCButton(
                      label: 'Create Budget',
                      onPressed: createBudget,
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w500, color: ccNavyText));

  Widget _dropItem(String text) => Text(text,
      style: const TextStyle(color: ccNavyText, fontFamily: 'Inter'));

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: ccInputBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            dropdownColor: ccBackground,
            value: value,
            hint: Text(hint,
                style: TextStyle(
                    color: ccNavyText.withOpacity(0.5),
                    fontFamily: 'Inter')),
            items: items,
            onChanged: onChanged,
          ),
        ),
      );
}
