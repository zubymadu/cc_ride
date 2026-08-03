import 'dart:convert';
import 'dart:developer';
import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/corporate_models.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class EmployeeManagementController extends GetxController {

  final Map<String, String> _headers = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  // ─── State ─────────────────────────────────────────────────────────────────

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool v) => _isLoading.value = v;

  final RxBool _isInviting = false.obs;
  bool get isInviting => _isInviting.value;
  set isInviting(bool v) => _isInviting.value = v;

  final RxBool _isImportingEmployees = false.obs;
  bool get isImportingEmployees => _isImportingEmployees.value;

  final RxBool _isImportingDepartments = false.obs;
  bool get isImportingDepartments => _isImportingDepartments.value;

  final RxList<EmployeeModel> _employees = <EmployeeModel>[].obs;
  List<EmployeeModel> get employees => _employees;

  final RxList<EmployeeModel> _filtered = <EmployeeModel>[].obs;
  List<EmployeeModel> get filtered => _filtered;

  final RxList<DepartmentModel> _departments = <DepartmentModel>[].obs;
  List<DepartmentModel> get departments => _departments;

  final RxString _searchQuery = ''.obs;
  String get searchQuery => _searchQuery.value;

  final RxString _filterRole = 'all'.obs;
  String get filterRole => _filterRole.value;
  set filterRole(String v) {
    _filterRole.value = v;
    _applyFilter();
  }

  // Invite form fields
  final TextEditingController inviteEmailCtrl = TextEditingController();
  final TextEditingController inviteNameCtrl = TextEditingController();
  final RxString inviteDeptId = ''.obs;
  final RxString inviteRole = 'employee'.obs;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    fetchEmployees();
    fetchDepartments();
  }

  @override
  void onClose() {
    inviteEmailCtrl.dispose();
    inviteNameCtrl.dispose();
    super.onClose();
  }

  // ─── API ───────────────────────────────────────────────────────────────────

  Future<void> fetchEmployees() async {
    try {
      isLoading = true;
      update();
      final companyId = getData.read('companyId') ?? '';
      final url = '${Confing.baseurl}${Confing.corporateEmployees}?company_id=$companyId';
      final response = await http.get(Uri.parse(url), headers: _headers);
      log(name: '=== Employees ===', response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Result'] == 'true') {
          _employees.value = (data['data'] as List)
              .map((e) => EmployeeModel.fromJson(e))
              .toList();
          _applyFilter();
        }
      }
    } catch (e) {
      log(name: '=== Employees error ===', '$e');
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> fetchDepartments() async {
    try {
      final companyId = getData.read('companyId') ?? '';
      final url = '${Confing.baseurl}${Confing.corporateDepartments}?company_id=$companyId';
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Result'] == 'true') {
          _departments.value = (data['data'] as List)
              .map((e) => DepartmentModel.fromJson(e))
              .toList();
          update();
        }
      }
    } catch (e) {
      log(name: '=== Departments error ===', '$e');
    }
  }

  Future<void> inviteEmployee() async {
    if (inviteEmailCtrl.text.trim().isEmpty || inviteNameCtrl.text.trim().isEmpty) {
      showToastMessage('Please fill in name and email');
      return;
    }
    try {
      isInviting = true;
      update();
      final body = {
        "company_id": getData.read('companyId') ?? '',
        "name": inviteNameCtrl.text.trim(),
        "email": inviteEmailCtrl.text.trim(),
        "department_id": inviteDeptId.value,
        "role": inviteRole.value,
      };
      final response = await http.post(
        Uri.parse('${Confing.baseurl}${Confing.corporateInviteEmployee}'),
        headers: _headers,
        body: jsonEncode(body),
      );
      log(name: '=== InviteEmployee ===', response.body);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['Result'] == 'true') {
        showToastMessage('Invitation sent successfully');
        inviteEmailCtrl.clear();
        inviteNameCtrl.clear();
        inviteDeptId.value = '';
        inviteRole.value = 'employee';
        Get.back();
        fetchEmployees();
      } else {
        showToastMessage(data['ResponseMsg'] ?? 'Failed to send invitation');
      }
    } catch (e) {
      showToastMessage('Error: $e');
    } finally {
      isInviting = false;
      update();
    }
  }

  Future<void> deactivateEmployee(String employeeId, String name) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: ccSurface,
        title: const Text('Deactivate Employee',
            style: TextStyle(
                color: ccNavyText,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700)),
        content: Text('Remove $name from the corporate account?',
            style: const TextStyle(color: ccSecondaryText, fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel',
                style: TextStyle(color: ccSecondaryText, fontFamily: 'Inter')),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Deactivate',
                style: TextStyle(color: ccError, fontFamily: 'Inter')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      isLoading = true;
      update();
      final body = {
        "company_id": getData.read('companyId') ?? '',
        "employee_id": employeeId,
      };
      final response = await http.post(
        Uri.parse('${Confing.baseurl}${Confing.corporateDeactivateEmployee}'),
        headers: _headers,
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      showToastMessage(data['ResponseMsg'] ?? 'Done');
      fetchEmployees();
    } catch (e) {
      showToastMessage('Error: $e');
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> reactivateEmployee(String employeeId, String name) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: ccSurface,
        title: const Text('Reinstate Employee',
            style: TextStyle(
                color: ccNavyText,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700)),
        content: Text(
            'Reinstate $name and resend them an activation email?',
            style: const TextStyle(color: ccSecondaryText, fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel',
                style: TextStyle(color: ccSecondaryText, fontFamily: 'Inter')),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Reinstate',
                style: TextStyle(color: ccPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      isLoading = true;
      update();
      final body = {
        "company_id": getData.read('companyId') ?? '',
        "employee_id": employeeId,
      };
      final response = await http.post(
        Uri.parse('${Confing.baseurl}${Confing.corporateReactivateEmployee}'),
        headers: _headers,
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      showToastMessage(data['ResponseMsg'] ?? 'Done');
      fetchEmployees();
    } catch (e) {
      showToastMessage('Error: $e');
    } finally {
      isLoading = false;
      update();
    }
  }

  // ─── CSV import ────────────────────────────────────────────────────────────

  Future<void> importEmployeesCsv() => _importCsv(
        isEmployees: true,
        endpoint: Confing.corporateEmployeesImport,
        onStart: () { _isImportingEmployees.value = true; update(); },
        onDone: () { _isImportingEmployees.value = false; update(); fetchEmployees(); },
      );

  Future<void> importDepartmentsCsv() => _importCsv(
        isEmployees: false,
        endpoint: Confing.corporateDepartmentsImport,
        onStart: () { _isImportingDepartments.value = true; update(); },
        onDone: () { _isImportingDepartments.value = false; update(); fetchDepartments(); },
      );

  Future<void> _importCsv({
    required bool isEmployees,
    required String endpoint,
    required VoidCallback onStart,
    required VoidCallback onDone,
  }) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null || file.bytes == null) return;

    onStart();
    try {
      final uri = Uri.parse('${Confing.baseurl}$endpoint');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer ${getData.read('token') ?? ''}'
        ..fields['company_id'] = getData.read('companyId') ?? ''
        ..files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      log(name: '=== ImportCsv ===', response.body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['Result'] == 'true') {
        final result = ImportResultModel.fromJson(data['data']);
        _showImportResult(isEmployees ? 'Employees' : 'Departments', result);
      } else {
        showToastMessage(data['ResponseMsg'] ?? 'Import failed');
      }
    } catch (e) {
      showToastMessage('Error: $e');
      log(name: '=== ImportCsv error ===', '$e');
    } finally {
      onDone();
    }
  }

  void _showImportResult(String label, ImportResultModel result) {
    Get.dialog(
      AlertDialog(
        backgroundColor: ccSurface,
        title: Text('$label imported',
            style: const TextStyle(
                color: ccNavyText, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${result.created} created, ${result.skipped} skipped',
                  style: const TextStyle(color: ccNavyText, fontFamily: 'Inter')),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 10),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: result.errors
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• $e',
                                  style: const TextStyle(
                                      color: ccSecondaryText, fontFamily: 'Inter', fontSize: 12)),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK',
                style: TextStyle(color: ccPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── Filter / Search ───────────────────────────────────────────────────────

  void onSearch(String query) {
    _searchQuery.value = query;
    _applyFilter();
  }

  void _applyFilter() {
    var list = _employees.toList();
    if (_filterRole.value != 'all') {
      list = list.where((e) => e.role == _filterRole.value).toList();
    }
    if (_searchQuery.value.isNotEmpty) {
      final q = _searchQuery.value.toLowerCase();
      list = list
          .where((e) =>
              e.name.toLowerCase().contains(q) ||
              e.email.toLowerCase().contains(q) ||
              e.department.toLowerCase().contains(q))
          .toList();
    }
    _filtered.value = list;
    update();
  }

  // ─── Invite Bottom Sheet ───────────────────────────────────────────────────

  void showInviteSheet() {
    inviteEmailCtrl.clear();
    inviteNameCtrl.clear();
    inviteDeptId.value = departments.isNotEmpty ? departments.first.id : '';
    inviteRole.value = 'employee';

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: ccSurface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(CCRadius.sheet)),
      ),
      Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 24,
        ),
        child: GetBuilder<EmployeeManagementController>(
          builder: (c) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ccInputBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Invite Employee',
                  style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: ccNavyText)),
              const SizedBox(height: 16),
              _sheetField('Full Name', inviteNameCtrl, 'e.g. Amina Bello'),
              const SizedBox(height: 12),
              _sheetField(
                  'Work Email', inviteEmailCtrl, 'e.g. amina@company.com',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              const Text('Department',
                  style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      color: ccNavyText)),
              const SizedBox(height: 6),
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: ccSurface,
                      border: Border.all(color: ccInputBorder),
                      borderRadius: BorderRadius.circular(CCRadius.input),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: ccSurface,
                        value: inviteDeptId.value.isEmpty
                            ? null
                            : inviteDeptId.value,
                        hint: const Text('Select department',
                            style: TextStyle(
                                color: ccSecondaryText, fontFamily: 'Inter')),
                        items: departments
                            .map((d) => DropdownMenuItem(
                                  value: d.id,
                                  child: Text(d.name,
                                      style: const TextStyle(
                                          color: ccNavyText,
                                          fontFamily: 'Inter')),
                                ))
                            .toList(),
                        onChanged: (v) => inviteDeptId.value = v ?? '',
                      ),
                    ),
                  )),
              const SizedBox(height: 12),
              const Text('Role',
                  style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      color: ccNavyText)),
              const SizedBox(height: 6),
              Obx(() => Row(
                    children: ['employee', 'manager', 'company_finance']
                        .map((role) => Expanded(
                              child: GestureDetector(
                                onTap: () => inviteRole.value = role,
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  decoration: BoxDecoration(
                                    color: inviteRole.value == role
                                        ? ccPrimary
                                        : Colors.transparent,
                                    border: Border.all(
                                        color: inviteRole.value == role
                                            ? ccPrimary
                                            : ccInputBorder),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _roleLabel(role),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500,
                                        color: inviteRole.value == role
                                            ? Colors.white
                                            : ccNavyText,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  )),
              const SizedBox(height: 20),
              Obx(() => c.isInviting
                  ? const SizedBox(
                      height: 52,
                      child: Center(
                          child: CircularProgressIndicator(color: ccPrimary)),
                    )
                  : CCButton(
                      label: 'Send Invitation',
                      onPressed: inviteEmployee,
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                color: ccNavyText)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(color: ccNavyText, fontFamily: 'Inter'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: ccSecondaryText, fontFamily: 'Inter'),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: ccSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CCRadius.input),
              borderSide: const BorderSide(color: ccInputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CCRadius.input),
              borderSide: const BorderSide(color: ccInputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CCRadius.input),
              borderSide: const BorderSide(color: ccPrimary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'manager':
        return 'Manager';
      case 'company_finance':
        return 'Finance';
      default:
        return 'Employee';
    }
  }

  String roleChipLabel(String role) => _roleLabel(role);

  Color roleChipColor(String role) {
    switch (role) {
      case 'company_admin':
        return const Color(0xFF6C3DE0);
      case 'manager':
        return const Color(0xFF0047FF);
      case 'company_finance':
        return const Color(0xFF00B894);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}
