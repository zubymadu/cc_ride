// ignore_for_file: deprecated_member_use

import 'package:carride/app/modules/controllers/corporate_controllers/employee_management_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmployeeManagementView extends GetView<EmployeeManagementController> {
  const EmployeeManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ccBackground,
      appBar: AppBar(
        backgroundColor: ccSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Employees",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ccNavyText,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: ccInputBorder),
        ),
        actions: [
          GetBuilder<EmployeeManagementController>(
            builder: (c) => (c.isImportingEmployees || c.isImportingDepartments)
                ? const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: ccPrimary),
                    ),
                  )
                : PopupMenuButton<String>(
                    icon: const Icon(Icons.upload_file_outlined, color: ccNavyText),
                    color: ccSurface,
                    onSelected: (val) {
                      if (val == 'employees') c.importEmployeesCsv();
                      if (val == 'departments') c.importDepartmentsCsv();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'employees',
                        child: Text('Import Employees (CSV)',
                            style: TextStyle(color: ccNavyText, fontFamily: 'Inter')),
                      ),
                      PopupMenuItem(
                        value: 'departments',
                        child: Text('Import Departments (CSV)',
                            style: TextStyle(color: ccNavyText, fontFamily: 'Inter')),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.showInviteSheet,
        backgroundColor: ccPrimary,
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text(
          'Invite',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      body: Column(
        children: [
          _searchAndFilter(),
          Expanded(
            child: GetBuilder<EmployeeManagementController>(
              builder: (c) => c.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: ccPrimary))
                  : RefreshIndicator(
                      onRefresh: c.fetchEmployees,
                      color: ccPrimary,
                      child: c.filtered.isEmpty
                          ? _emptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 100),
                              itemCount: c.filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) =>
                                  _employeeCard(c, c.filtered[i]),
                            ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchAndFilter() =>
      GetBuilder<EmployeeManagementController>(
        builder: (c) => Container(
          color: ccSurface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              TextField(
                onChanged: c.onSearch,
                style: const TextStyle(
                  color: ccNavyText,
                  fontFamily: 'Inter',
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by name, email or department...',
                  hintStyle: const TextStyle(
                    color: ccSecondaryText,
                    fontFamily: 'Inter',
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(Icons.search, color: ccSecondaryText),
                  filled: true,
                  fillColor: ccBackground,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CCRadius.input),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Obx(
                  () => Row(
                    children: [
                      'all',
                      'employee',
                      'manager',
                      'company_admin',
                      'company_finance',
                    ]
                        .map((role) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => c.filterRole = role,
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: c.filterRole == role
                                        ? ccPrimary
                                        : ccSurface,
                                    borderRadius:
                                        BorderRadius.circular(99),
                                    border: Border.all(
                                      color: c.filterRole == role
                                          ? ccPrimary
                                          : ccInputBorder,
                                    ),
                                  ),
                                  child: Text(
                                    role == 'all'
                                        ? 'All'
                                        : c.roleChipLabel(role),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      color: c.filterRole == role
                                          ? ccSurface
                                          : ccNavyText,
                                    ),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _employeeCard(EmployeeManagementController c, employee) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ccSurface,
          borderRadius: BorderRadius.circular(CCRadius.card),
          boxShadow: CCShadow.card,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                  color: ccIceBlue, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  employee.name.isNotEmpty
                      ? employee.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    color: ccPrimary,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          employee.name,
                          style: CCText.titleMd,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: c
                              .roleChipColor(employee.role)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          c.roleChipLabel(employee.role),
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            color: c.roleChipColor(employee.role),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    employee.email,
                    style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.business_outlined,
                          size: 12, color: ccSecondaryText),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          employee.department.isEmpty
                              ? 'No department'
                              : employee.department,
                          style: CCText.labelSm
                              .copyWith(color: ccSecondaryText),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!employee.isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ccErrorLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Inactive',
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: ccError,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (employee.isActive)
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'deactivate') {
                    c.deactivateEmployee(employee.id, employee.name);
                  }
                },
                color: ccSurface,
                icon: const Icon(Icons.more_vert, color: ccSecondaryText),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'deactivate',
                    child: Row(
                      children: const [
                        Icon(Icons.person_off_outlined,
                            color: ccError, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Deactivate',
                          style: TextStyle(
                            color: ccNavyText,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'reactivate') {
                    c.reactivateEmployee(employee.id, employee.name);
                  }
                },
                color: ccSurface,
                icon: const Icon(Icons.more_vert, color: ccSecondaryText),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'reactivate',
                    child: Row(
                      children: const [
                        Icon(Icons.person_add_alt_outlined,
                            color: ccPrimary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Reinstate & resend email',
                          style: TextStyle(
                            color: ccNavyText,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      );

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: ccIceBlue, shape: BoxShape.circle),
              child: const Icon(Icons.people_outline,
                  color: ccPrimary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('No employees found', style: CCText.headlineMd),
            const SizedBox(height: 8),
            Text(
              'Tap + Invite to add team members',
              style: CCText.bodyMd.copyWith(color: ccSecondaryText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
