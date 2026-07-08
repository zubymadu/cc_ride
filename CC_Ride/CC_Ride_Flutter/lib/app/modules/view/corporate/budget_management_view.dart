// ignore_for_file: deprecated_member_use

import 'package:carride/app/modules/controllers/corporate_controllers/budget_management_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BudgetManagementView extends GetView<BudgetManagementController> {
  const BudgetManagementView({super.key});

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
          "Budgets",
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.showCreateSheet,
        backgroundColor: ccPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Budget',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      body: GetBuilder<BudgetManagementController>(
        builder: (c) => c.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ccPrimary))
            : RefreshIndicator(
                onRefresh: c.fetchBudgets,
                color: ccPrimary,
                child: c.budgets.isEmpty
                    ? _emptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: c.budgets.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) =>
                            _budgetCard(c, c.budgets[i]),
                      ),
              ),
      ),
    );
  }

  Widget _budgetCard(BudgetManagementController c, budget) {
    final color = c.barColor(budget.spendPercent);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ccSurface,
        borderRadius: BorderRadius.circular(CCRadius.card),
        boxShadow: CCShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ccIceBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: ccPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.department,
                      style: CCText.titleMd,
                    ),
                    Text(
                      c.periodLabel(budget),
                      style: CCText.labelSm
                          .copyWith(color: ccSecondaryText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: budget.isActive ? ccSuccessLight : ccErrorLight,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  budget.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: budget.isActive ? ccSuccess : ccError,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _amountCell('Budget', c.formatNaira(budget.allocatedAmount)),
              _divider(),
              _amountCell('Spent', c.formatNaira(budget.spentAmount),
                  valueColor: color),
              _divider(),
              _amountCell(
                  'Remaining', c.formatNaira(budget.remainingAmount)),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (budget.spendPercent / 100).clamp(0.0, 1.0),
                  backgroundColor: ccInputBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    '${budget.spendPercent.toStringAsFixed(0)}% used',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Alert at ${budget.alertThreshold.toInt()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'Inter',
                      color: ccSecondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountCell(String label, String value, {Color? valueColor}) =>
      Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: valueColor ?? ccNavyText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'Inter',
                color: ccSecondaryText,
              ),
            ),
          ],
        ),
      );

  Widget _divider() => Container(
        width: 1,
        height: 32,
        color: ccInputBorder,
        margin: const EdgeInsets.symmetric(horizontal: 8),
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
              child: const Icon(Icons.account_balance_wallet_outlined,
                  color: ccPrimary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('No budgets yet', style: CCText.headlineMd),
            const SizedBox(height: 8),
            Text(
              'Create a budget to track department spending',
              style: CCText.bodyMd.copyWith(color: ccSecondaryText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
