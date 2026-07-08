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

class RidePolicyController extends GetxController {
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

  final RxList<RidePolicyModel> _policies = <RidePolicyModel>[].obs;
  List<RidePolicyModel> get policies => _policies;

  final RxList<DepartmentModel> _departments = <DepartmentModel>[].obs;
  List<DepartmentModel> get departments => _departments;

  // Create form state
  final TextEditingController policyNameCtrl = TextEditingController();
  final TextEditingController maxFareCtrl = TextEditingController();
  final TextEditingController maxMonthlyCtrl = TextEditingController();
  final RxString createDeptId = ''.obs;
  final RxList<int> selectedDays = <int>[1, 2, 3, 4, 5].obs;
  final RxString timeFrom = '06:00'.obs;
  final RxString timeTo = '22:00'.obs;
  final RxBool hasTimeRestriction = false.obs;
  final RxBool hasFareCap = false.obs;
  final RxBool hasMonthlyLimit = false.obs;

  static const _dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    fetchPolicies();
    fetchDepartments();
  }

  @override
  void onClose() {
    policyNameCtrl.dispose();
    maxFareCtrl.dispose();
    maxMonthlyCtrl.dispose();
    super.onClose();
  }

  // ─── API ───────────────────────────────────────────────────────────────────

  Future<void> fetchPolicies() async {
    try {
      isLoading = true;
      update();
      final companyId = getData.read('companyId') ?? '';
      final response = await http.get(
        Uri.parse('${Confing.baseurl}${Confing.corporatePolicies}?company_id=$companyId'),
        headers: _headers,
      );
      log(name: '=== Policies ===', response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Result'] == 'true') {
          _policies.value =
              (data['data'] as List).map((e) => RidePolicyModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      log(name: '=== Policies error ===', '$e');
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
          update();
        }
      }
    } catch (_) {}
  }

  Future<void> savePolicy() async {
    if (policyNameCtrl.text.trim().isEmpty) {
      showToastMessage('Enter a policy name');
      return;
    }
    if (selectedDays.isEmpty) {
      showToastMessage('Select at least one allowed day');
      return;
    }
    try {
      isSaving = true;
      update();
      final body = {
        "company_id": getData.read('companyId') ?? '',
        "department_id": createDeptId.value,
        "name": policyNameCtrl.text.trim(),
        "allowed_days": selectedDays.toList(),
        "allowed_time_from": hasTimeRestriction.value ? timeFrom.value : null,
        "allowed_time_to": hasTimeRestriction.value ? timeTo.value : null,
        "max_fare_per_trip": hasFareCap.value && maxFareCtrl.text.isNotEmpty
            ? maxFareCtrl.text.trim()
            : null,
        "max_monthly_spend": hasMonthlyLimit.value && maxMonthlyCtrl.text.isNotEmpty
            ? maxMonthlyCtrl.text.trim()
            : null,
        "created_by": getData.read('userLogin')?['id'] ?? '',
      };
      final response = await http.post(
        Uri.parse('${Confing.baseurl}${Confing.corporateCreatePolicy}'),
        headers: _headers,
        body: jsonEncode(body),
      );
      log(name: '=== CreatePolicy ===', response.body);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['Result'] == 'true') {
        showToastMessage('Policy created');
        Get.back();
        fetchPolicies();
        _resetForm();
      } else {
        showToastMessage(data['ResponseMsg'] ?? 'Failed to create policy');
      }
    } catch (e) {
      showToastMessage('Error: $e');
    } finally {
      isSaving = false;
      update();
    }
  }

  Future<void> togglePolicy(String policyId, bool currentState) async {
    try {
      final body = {
        "policy_id": policyId,
        "is_active": !currentState,
        "company_id": getData.read('companyId') ?? '',
      };
      await http.post(
        Uri.parse('${Confing.baseurl}${Confing.corporateTogglePolicy}'),
        headers: _headers,
        body: jsonEncode(body),
      );
      fetchPolicies();
    } catch (e) {
      showToastMessage('Error: $e');
    }
  }

  // ─── Day selection ─────────────────────────────────────────────────────────

  void toggleDay(int day) {
    if (selectedDays.contains(day)) {
      if (selectedDays.length > 1) selectedDays.remove(day);
    } else {
      selectedDays.add(day);
      selectedDays.sort();
    }
    update();
  }

  String dayName(int day) => day >= 1 && day <= 7 ? _dayNames[day] : '';

  // ─── Create Sheet ──────────────────────────────────────────────────────────

  void showCreateSheet() {
    _resetForm();
    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: ccBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => GetBuilder<RidePolicyController>(
          builder: (c) => ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 24,
            ),
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
              Text('New Ride Policy',
                  style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: ccNavyText)),
              const SizedBox(height: 16),
              _label('Policy Name'),
              const SizedBox(height: 6),
              _textField(policyNameCtrl, 'e.g. Standard Employee Policy'),
              const SizedBox(height: 12),
              // Department
              _label('Apply to'),
              const SizedBox(height: 6),
              Obx(() => _dropdown(
                    value: createDeptId.value.isEmpty ? null : createDeptId.value,
                    hint: 'All departments',
                    items: [
                      DropdownMenuItem(value: '', child: _dropItem('All departments')),
                      ...departments.map((d) =>
                          DropdownMenuItem(value: d.id, child: _dropItem(d.name))),
                    ],
                    onChanged: (v) => createDeptId.value = v ?? '',
                  )),
              const SizedBox(height: 16),
              // Allowed days
              _label('Allowed Days'),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                    spacing: 8, runSpacing: 8,
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      final selected = selectedDays.contains(day);
                      return GestureDetector(
                        onTap: () => toggleDay(day),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? ccPrimary
                                : Colors.transparent,
                            border: Border.all(
                                color: selected
                                    ? ccPrimary
                                    : ccInputBorder),
                          ),
                          child: Center(
                            child: Text(
                              _dayNames[day].substring(0, 2),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  color: selected
                                      ? Colors.white
                                      : ccNavyText),
                            ),
                          ),
                        ),
                      );
                    }),
                  )),
              const SizedBox(height: 16),
              // Time restriction toggle
              Obx(() => _switchRow(
                    'Time Restriction',
                    'Only allow bookings within hours',
                    hasTimeRestriction.value,
                    (v) => hasTimeRestriction.value = v,
                  )),
              Obx(() => hasTimeRestriction.value
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(children: [
                        Expanded(
                            child: _timePicker(
                                'From', timeFrom.value, (v) => timeFrom.value = v)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _timePicker(
                                'To', timeTo.value, (v) => timeTo.value = v)),
                      ]),
                    )
                  : const SizedBox()),
              const SizedBox(height: 12),
              // Fare cap toggle
              Obx(() => _switchRow(
                    'Per-Trip Fare Cap',
                    'Reject rides above a fare limit',
                    hasFareCap.value,
                    (v) => hasFareCap.value = v,
                  )),
              Obx(() => hasFareCap.value
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _nairaField(maxFareCtrl, 'Max fare per trip'),
                    )
                  : const SizedBox()),
              const SizedBox(height: 12),
              // Monthly spend toggle
              Obx(() => _switchRow(
                    'Monthly Spend Limit',
                    'Cap each employee\'s monthly spending',
                    hasMonthlyLimit.value,
                    (v) => hasMonthlyLimit.value = v,
                  )),
              Obx(() => hasMonthlyLimit.value
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _nairaField(maxMonthlyCtrl, 'Max monthly spend per employee'),
                    )
                  : const SizedBox()),
              const SizedBox(height: 24),
              Obx(() => c.isSaving
                  ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: ccPrimary)))
                  : CCButton(label: 'Save Policy', onPressed: savePolicy)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _resetForm() {
    policyNameCtrl.clear();
    maxFareCtrl.clear();
    maxMonthlyCtrl.clear();
    createDeptId.value = '';
    selectedDays.value = [1, 2, 3, 4, 5];
    hasTimeRestriction.value = false;
    hasFareCap.value = false;
    hasMonthlyLimit.value = false;
    timeFrom.value = '06:00';
    timeTo.value = '22:00';
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w500, color: ccNavyText));

  Widget _dropItem(String t) => Text(t,
      style: const TextStyle(color: ccNavyText, fontFamily: 'Inter'));

  Widget _textField(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        style: const TextStyle(color: ccNavyText, fontFamily: 'Inter'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: ccNavyText.withOpacity(0.4), fontFamily: 'Inter'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      );

  Widget _nairaField(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: ccNavyText, fontFamily: 'Inter'),
        decoration: InputDecoration(
          hintText: hint,
          prefixText: '₦ ',
          prefixStyle:
              const TextStyle(color: ccNavyText, fontFamily: 'Inter', fontWeight: FontWeight.w500),
          hintStyle: TextStyle(
              color: ccNavyText.withOpacity(0.4),
              fontFamily: 'Inter'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      );

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
            borderRadius: BorderRadius.circular(10)),
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

  Widget _switchRow(
          String title, String subtitle, bool value, ValueChanged<bool> onChanged) =>
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    color: ccNavyText)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Inter',
                    color: ccNavyText.withOpacity(0.5))),
          ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: ccPrimary,
        ),
      ]);

  Widget _timePicker(String label, String value, ValueChanged<String> onChanged) =>
      GestureDetector(
        onTap: () async {
          final parts = value.split(':');
          final initial = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 6,
            minute: int.tryParse(parts[1]) ?? 0,
          );
          final picked = await showTimePicker(
            context: Get.context!,
            initialTime: initial,
          );
          if (picked != null) {
            onChanged(
                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
              border: Border.all(color: ccInputBorder),
              borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        color: ccNavyText.withOpacity(0.5))),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        color: ccNavyText)),
              ]),
            ),
            Icon(Icons.access_time, size: 18, color: ccNavyText.withOpacity(0.5)),
          ]),
        ),
      );
}
