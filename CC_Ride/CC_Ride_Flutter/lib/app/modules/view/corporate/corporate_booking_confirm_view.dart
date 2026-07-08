// ignore_for_file: deprecated_member_use

import 'package:carride/app/modules/controllers/corporate_controllers/corporate_booking_flow_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CorporateBookingConfirmView
    extends GetView<CorporateBookingFlowController> {
  const CorporateBookingConfirmView({super.key});

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
          'Book on Company Account',
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
      bottomNavigationBar: _bottomBar(),
      body: Obx(() {
        if (controller.isLoadingProfile) {
          return const Center(
              child: CircularProgressIndicator(color: ccPrimary));
        }
        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _companyCard(),
                  const SizedBox(height: 16),
                  _tripSummaryCard(),
                  const SizedBox(height: 16),
                  _costCentreCard(),
                  const SizedBox(height: 16),
                  _policyCard(),
                  const SizedBox(height: 16),
                  _driverMessageCard(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            if (controller.isBooking)
              Container(
                color: ccIceBlue.withOpacity(0.7),
                child: Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: ccPrimary,
                    size: 28,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  // ─── Company card ───────────────────────────────────────────────────────────

  Widget _companyCard() => _card(
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ccIceBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                controller.companyName.value.isNotEmpty
                    ? controller.companyName.value[0].toUpperCase()
                    : 'C',
                style: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    color: ccPrimary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.companyName.value,
                  style: CCText.titleMd,
                ),
                Text(
                  _roleLabel(controller.employeeRole.value),
                  style: CCText.labelSm.copyWith(color: ccSecondaryText),
                ),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('Monthly budget',
                style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Inter',
                    color: ccSecondaryText)),
            Text(
              controller.monthlySpendLimit.value > 0
                  ? controller.formatNaira(controller.remainingBudget)
                  : 'Unlimited',
              style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  color: controller.monthlySpendLimit.value > 0 &&
                          controller.fareExceedsLimit
                      ? ccError
                      : ccSuccess),
            ),
            const Text('remaining',
                style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'Inter',
                    color: ccSecondaryText)),
          ]),
        ]),
      );

  // ─── Trip summary ───────────────────────────────────────────────────────────

  Widget _tripSummaryCard() {
    final trip = controller.tripCtrl.tripDetailsApiModel?.tripData;
    final pricing = controller.pricingCtrl;
    final nf = NumberFormat('#,##0', 'en_US');
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('Trip Summary'),
        const SizedBox(height: 12),
        _routeRow(Icons.radio_button_checked, ccSuccess,
            trip?.originAddress ?? '—'),
        _routeDots(),
        _routeRow(Icons.location_on, ccError, trip?.destiAddress ?? '—'),
        const SizedBox(height: 14),
        const Divider(color: ccInputBorder, height: 1),
        const SizedBox(height: 14),
        Row(children: [
          _summaryItem('Seats', '${pricing.counter}'),
          _summaryItem('Subtotal', '₦${nf.format(pricing.subTotal)}'),
          _summaryItem('Booking fee', '₦${nf.format(pricing.bookfee)}'),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: ccIceBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Text('Total charged to company',
                style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    color: ccNavyText)),
            const Spacer(),
            Text(
              '₦${nf.format(pricing.totalAmount)}',
              style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  color: ccPrimary),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _summaryItem(String label, String value) => Expanded(
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  color: ccNavyText)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'Inter',
                  color: ccSecondaryText)),
        ]),
      );

  // ─── Cost centre ────────────────────────────────────────────────────────────

  Widget _costCentreCard() => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Billing Details'),
            const SizedBox(height: 12),
            _billingRow(
                Icons.business_outlined,
                'Department',
                controller.departmentName.value.isEmpty
                    ? 'Not assigned'
                    : controller.departmentName.value),
            const SizedBox(height: 10),
            _billingRow(
                Icons.tag_outlined,
                'Cost Centre',
                controller.costCentreName.value.isEmpty
                    ? 'Not assigned'
                    : controller.costCentreName.value),
            if (controller.costCentres.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Change cost centre',
                  style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      color: ccPrimary)),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.costCentres
                        .map((cc) => GestureDetector(
                              onTap: () => controller.selectCostCentre(
                                  cc['id']!, cc['name']!),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: controller.costCentreId.value ==
                                          cc['id']
                                      ? ccPrimary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color:
                                          controller.costCentreId.value ==
                                                  cc['id']
                                              ? ccPrimary
                                              : ccInputBorder),
                                ),
                                child: Text(
                                  '${cc['code']} · ${cc['name']}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      color: controller.costCentreId.value ==
                                              cc['id']
                                          ? Colors.white
                                          : ccNavyText),
                                ),
                              ),
                            ))
                        .toList(),
                  )),
            ],
          ],
        ),
      );

  Widget _billingRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 16, color: ccSecondaryText),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'Inter',
                  color: ccSecondaryText)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  color: ccNavyText)),
        ],
      );

  // ─── Policy card ─────────────────────────────────────────────────────────

  Widget _policyCard() => Obx(() {
        final result = controller.policyResult.value;
        if (result.status == PolicyStatus.unchecked) return const SizedBox();
        if (result.status == PolicyStatus.checking) {
          return _card(
            child: const Row(children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: ccPrimary),
              ),
              SizedBox(width: 12),
              Text('Checking ride policy…',
                  style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Inter',
                      color: ccSecondaryText)),
            ]),
          );
        }

        final color = result.status == PolicyStatus.allowed
            ? ccSuccess
            : result.status == PolicyStatus.requiresApproval
                ? const Color(0xFFFF9900)
                : ccError;
        final icon = result.status == PolicyStatus.allowed
            ? Icons.check_circle_outline
            : result.status == PolicyStatus.requiresApproval
                ? Icons.pending_actions_outlined
                : Icons.block_outlined;
        final title = result.status == PolicyStatus.allowed
            ? 'Ride is within policy'
            : result.status == PolicyStatus.requiresApproval
                ? 'Approval required'
                : 'Ride blocked by policy';

        return _card(
          borderColor: color.withOpacity(0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
                if (result.policyName != null)
                  Text(result.policyName!,
                      style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'Inter',
                          color: ccSecondaryText)),
              ]),
              if (result.reason != null) ...[
                const SizedBox(height: 8),
                Text(result.reason!,
                    style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'Inter',
                        color: ccSecondaryText)),
              ],
              if (result.status == PolicyStatus.requiresApproval &&
                  result.approverName != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9900).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: Color(0xFFFF9900)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Will be sent to ${result.approverName} for approval',
                        style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Inter',
                            color: Color(0xFFFF9900)),
                      ),
                    ),
                    if (result.expiryHours != null)
                      Text('${result.expiryHours}h window',
                          style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFFF9900))),
                  ]),
                ),
              ],
            ],
          ),
        );
      });

  // ─── Driver message ──────────────────────────────────────────────────────

  Widget _driverMessageCard() => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Message for driver'),
            const SizedBox(height: 10),
            TextField(
              controller: controller.messageController,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'Inter', color: ccNavyText),
              decoration: InputDecoration(
                hintText:
                    'e.g. Travelling to client site for a 9 AM meeting.',
                hintStyle: const TextStyle(
                    fontFamily: 'Inter', color: ccSecondaryText, fontSize: 13),
                filled: true,
                fillColor: ccBackground,
                contentPadding: const EdgeInsets.all(14),
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
        ),
      );

  // ─── Bottom bar ─────────────────────────────────────────────────────────

  Widget _bottomBar() => Obx(() {
        if (controller.isLoadingProfile) return const SizedBox(height: 1);

        final result = controller.policyResult.value;
        final isBlocked = result.status == PolicyStatus.blocked;
        final needsApproval = result.status == PolicyStatus.requiresApproval;
        final isChecking = result.status == PolicyStatus.checking;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.fareExceedsLimit)
                  _warningBanner(
                      'Fare exceeds your remaining monthly limit',
                      const Color(0xFFFF9900)),
                if (isBlocked)
                  _warningBanner(
                      result.reason ??
                          'This ride is blocked by company policy',
                      ccError),
                const SizedBox(height: 8),
                controller.isBooking
                    ? const SizedBox(
                        height: 52,
                        child: Center(
                            child: CircularProgressIndicator(
                                color: ccPrimary)))
                    : SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            if (!isBlocked && !isChecking) {
                              controller.submitBooking();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isBlocked
                                ? ccSecondaryText
                                : needsApproval
                                    ? const Color(0xFFFF9900)
                                    : ccPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(CCRadius.btn)),
                          ),
                          child: Text(
                            isChecking
                                ? 'Checking policy…'
                                : needsApproval
                                    ? 'Submit for Approval'
                                    : 'Book on Company Account',
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.white),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      });

  Widget _warningBanner(String message, Color color) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Icon(Icons.warning_amber_outlined, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 12, fontFamily: 'Inter', color: color)),
          ),
        ]),
      );

  // ─── Shared helpers ──────────────────────────────────────────────────────

  Widget _card({required Widget child, Color? borderColor}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ccSurface,
          borderRadius: BorderRadius.circular(CCRadius.card),
          border: borderColor != null
              ? Border.all(color: borderColor)
              : null,
          boxShadow: CCShadow.card,
        ),
        child: child,
      );

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 12,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          color: ccSecondaryText,
          letterSpacing: 0.5));

  Widget _routeRow(IconData icon, Color color, String address) => Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(address,
                style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    color: ccNavyText),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );

  Widget _routeDots() => Padding(
        padding: const EdgeInsets.only(left: 7, top: 3, bottom: 3),
        child: Column(
          children: List.generate(
              3,
              (_) => Container(
                    width: 2,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 3),
                    color: ccInputBorder,
                  )),
        ),
      );

  String _roleLabel(String role) {
    switch (role) {
      case 'manager':
        return 'Manager';
      case 'company_admin':
        return 'Company Admin';
      case 'company_finance':
        return 'Finance';
      default:
        return 'Employee';
    }
  }
}
