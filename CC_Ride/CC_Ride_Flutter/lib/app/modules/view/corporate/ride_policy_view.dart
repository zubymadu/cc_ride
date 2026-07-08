// ignore_for_file: deprecated_member_use

import 'package:carride/app/modules/controllers/corporate_controllers/ride_policy_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RidePolicyView extends GetView<RidePolicyController> {
  const RidePolicyView({super.key});

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
          'Ride Policies',
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
          'New Policy',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      body: GetBuilder<RidePolicyController>(
        builder: (c) => c.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ccPrimary))
            : RefreshIndicator(
                onRefresh: c.fetchPolicies,
                color: ccPrimary,
                child: c.policies.isEmpty
                    ? _emptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: c.policies.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) =>
                            _policyCard(c, c.policies[i]),
                      ),
              ),
      ),
    );
  }

  Widget _policyCard(RidePolicyController c, policy) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ccSurface,
          borderRadius: BorderRadius.circular(CCRadius.card),
          boxShadow: CCShadow.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ccIceBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_outlined,
                    color: ccPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(policy.name, style: CCText.titleMd),
                    Text(policy.department,
                        style:
                            CCText.labelSm.copyWith(color: ccSecondaryText)),
                  ],
                ),
              ),
              Switch(
                value: policy.isActive,
                onChanged: (v) => c.togglePolicy(policy.id, policy.isActive),
                activeColor: ccPrimary,
              ),
            ]),
            const SizedBox(height: 14),
            const Divider(color: ccInputBorder, height: 1),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ruleChip(Icons.calendar_today_outlined, policy.daysLabel),
                if (policy.allowedTimeFrom != null &&
                    policy.allowedTimeTo != null)
                  _ruleChip(Icons.access_time_outlined,
                      '${policy.allowedTimeFrom} – ${policy.allowedTimeTo}'),
                if (policy.maxFarePerTrip != null)
                  _ruleChip(Icons.receipt_outlined,
                      'Max ₦${_fmt(policy.maxFarePerTrip!)}/trip'),
                if (policy.maxMonthlySpend != null)
                  _ruleChip(Icons.trending_up_outlined,
                      'Max ₦${_fmt(policy.maxMonthlySpend!)}/month'),
                if (policy.maxVehicleType != null)
                  _ruleChip(Icons.directions_car_outlined,
                      'Up to ${policy.maxVehicleType}'),
              ],
            ),
            if (!policy.isActive) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9900).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(children: [
                  Icon(Icons.pause_circle_outline,
                      size: 14, color: Color(0xFFFF9900)),
                  SizedBox(width: 6),
                  Text('Policy is currently disabled',
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Inter',
                          color: Color(0xFFFF9900))),
                ]),
              ),
            ],
          ],
        ),
      );

  Widget _ruleChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ccBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ccInputBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: ccSecondaryText),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Inter',
                  color: ccNavyText)),
        ]),
      );

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: ccIceBlue, shape: BoxShape.circle),
              child: const Icon(Icons.shield_outlined,
                  color: ccPrimary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('No ride policies', style: CCText.headlineMd),
            const SizedBox(height: 8),
            Text(
              'Create policies to control how employees book rides',
              textAlign: TextAlign.center,
              style: CCText.bodyMd.copyWith(color: ccSecondaryText),
            ),
          ],
        ),
      );
}
