// ignore_for_file: deprecated_member_use

import 'package:carride/app/data/corporate_models.dart';
import 'package:carride/app/modules/controllers/corporate_controllers/corporate_dashboard_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CorporateDashboardView extends GetView<CorporateDashboardController> {
  const CorporateDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ccBackground,
      body: SafeArea(
        child: GetBuilder<CorporateDashboardController>(
          builder: (c) => c.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: ccPrimary))
              : RefreshIndicator(
                  onRefresh: c.fetchDashboard,
                  color: ccPrimary,
                  child: CustomScrollView(
                    slivers: [
                      _appBar(c),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _spendCard(c),
                              const SizedBox(height: 16),
                              _statsRow(c),
                              const SizedBox(height: 20),
                              _sectionHeader('Quick Actions'),
                              const SizedBox(height: 12),
                              _quickActions(c),
                              const SizedBox(height: 20),
                              _sectionHeader('Department Spend'),
                              const SizedBox(height: 12),
                              _deptSpendList(c),
                              const SizedBox(height: 20),
                              _sectionHeader('Recent Rides'),
                              const SizedBox(height: 12),
                              _recentRidesList(c),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  SliverAppBar _appBar(CorporateDashboardController c) => SliverAppBar(
        pinned: true,
        backgroundColor: ccSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.dashData?.companyName ?? 'Corporate Portal',
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: ccNavyText,
              ),
            ),
            Text(
              DateFormat('MMMM yyyy').format(DateTime.now()),
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Inter',
                color: ccSecondaryText,
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: ccInputBorder),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: c.goToApprovals,
                icon: const Icon(Icons.notifications_outlined,
                    color: ccNavyText),
              ),
              if ((c.dashData?.pendingApprovals ?? 0) > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: ccError, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        '${c.dashData!.pendingApprovals}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );

  Widget _spendCard(CorporateDashboardController c) {
    final spent = c.dashData?.monthlySpent ?? 0;
    final budget = c.dashData?.monthlyBudget ?? 1;
    final percent = c.dashData?.spendPercent ?? 0;
    final barColor = percent >= 90
        ? ccError
        : percent >= 75
            ? const Color(0xFFFF9900)
            : ccSuccess;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF001B3D), ccPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(CCRadius.card),
        boxShadow: CCShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Spend',
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            c.formatNaira(spent),
            style: const TextStyle(
              fontSize: 28,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'of ${c.formatNaira(budget)} budget',
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${percent.toStringAsFixed(0)}% used',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(CorporateDashboardController c) => Row(
        children: [
          _statCard('${c.dashData?.totalEmployees ?? 0}', 'Employees',
              Icons.people_outline, const Color(0xFF6C3DE0)),
          const SizedBox(width: 12),
          _statCard('${c.dashData?.ridesThisMonth ?? 0}', 'Rides',
              Icons.directions_car_outlined, ccSuccess),
          const SizedBox(width: 12),
          _statCard(
            '${c.dashData?.pendingApprovals ?? 0}',
            'Approvals',
            Icons.pending_actions_outlined,
            (c.dashData?.pendingApprovals ?? 0) > 0
                ? const Color(0xFFFF9900)
                : ccSecondaryText,
          ),
        ],
      );

  Widget _statCard(
          String value, String label, IconData icon, Color iconColor) =>
      Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: ccSurface,
            borderRadius: BorderRadius.circular(CCRadius.card),
            boxShadow: CCShadow.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  color: ccNavyText,
                ),
              ),
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
        ),
      );

  Widget _quickActions(CorporateDashboardController c) => GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _actionTile('Employees', Icons.people_outline,
              const Color(0xFF6C3DE0), c.goToEmployees),
          _actionTile('Budgets', Icons.account_balance_wallet_outlined,
              ccSuccess, c.goToBudgets),
          _actionTile('Approvals', Icons.pending_actions_outlined,
              const Color(0xFFFF9900), c.goToApprovals),
          _actionTile(
              'Policies', Icons.shield_outlined, ccPrimary, c.goToPolicies),
        ],
      );

  Widget _actionTile(
          String label, IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(CCRadius.btn),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  color: ccNavyText,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _deptSpendList(CorporateDashboardController c) {
    final items = c.dashData?.deptSpend ?? [];
    if (items.isEmpty) return _emptyState('No department data yet');
    return Column(
      children: items
          .map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _deptSpendRow(c, d),
              ))
          .toList(),
    );
  }

  Widget _deptSpendRow(CorporateDashboardController c, DeptSpendItem d) {
    final barColor = d.percent >= 90
        ? ccError
        : d.percent >= 75
            ? const Color(0xFFFF9900)
            : ccSuccess;
    final nf = NumberFormat('#,##0', 'en_US');
    return Container(
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(
                  d.department,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    color: ccNavyText,
                  ),
                ),
              ),
              Text(
                '₦${nf.format(d.spent)} / ₦${nf.format(d.budget)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Inter',
                  color: ccSecondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (d.percent / 100).clamp(0.0, 1.0),
              backgroundColor: ccInputBorder,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${d.percent.toStringAsFixed(0)}% used',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Inter',
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentRidesList(CorporateDashboardController c) {
    final items = c.dashData?.recentRides ?? [];
    if (items.isEmpty) return _emptyState('No rides yet this month');
    return Column(
      children: items
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _rideRow(c, r),
              ))
          .toList(),
    );
  }

  Widget _rideRow(CorporateDashboardController c, RecentRideItem r) {
    final statusColor = r.status == 'completed'
        ? ccSuccess
        : r.status == 'cancelled'
            ? ccError
            : const Color(0xFFFF9900);
    final statusBg = r.status == 'completed'
        ? ccSuccessLight
        : r.status == 'cancelled'
            ? ccErrorLight
            : const Color(0xFFFFFBEB);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ccSurface,
        borderRadius: BorderRadius.circular(CCRadius.card),
        boxShadow: CCShadow.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
                color: ccIceBlue, shape: BoxShape.circle),
            child: Center(
              child: Text(
                r.employeeName.isNotEmpty
                    ? r.employeeName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  color: ccPrimary,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.employeeName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    color: ccNavyText,
                  ),
                ),
                Text(
                  '${r.origin.split(',').first} → ${r.destination.split(',').first}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'Inter',
                    color: ccSecondaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                c.formatNaira(r.amount),
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  color: ccNavyText,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  r.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(
        title,
        style: CCText.titleMd,
      );

  Widget _emptyState(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            message,
            style: CCText.bodyMd.copyWith(color: ccSecondaryText),
          ),
        ),
      );
}
