// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ApprovalPendingView extends StatefulWidget {
  const ApprovalPendingView({super.key});

  @override
  State<ApprovalPendingView> createState() => _ApprovalPendingViewState();
}

class _ApprovalPendingViewState extends State<ApprovalPendingView> {
  late final Map args;

  String approvalRequestId = '';
  String expiresAt = '';
  String approverName = '';
  String approverRole = '';
  String companyName = '';
  String origin = '';
  String destination = '';
  double estimatedFare = 0;

  Duration _remaining = Duration.zero;
  Timer? _timer;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    args = (Get.arguments as Map?) ?? {};

    approvalRequestId = args['approval_request_id'] ?? '';
    expiresAt         = args['expires_at'] ?? '';
    approverName      = args['approver_name'] ?? 'your manager';
    approverRole      = args['approver_role'] ?? 'manager';
    companyName       = args['company_name'] ?? '';
    origin            = args['origin'] ?? '';
    destination       = args['destination'] ?? '';
    estimatedFare     = (args['estimated_fare'] as num?)?.toDouble() ?? 0;

    _startCountdown();
  }

  void _startCountdown() {
    if (expiresAt.isEmpty) return;
    try {
      final expiry = DateTime.parse(expiresAt).toLocal();
      _remaining = expiry.difference(DateTime.now());
      if (_remaining.isNegative) _remaining = Duration.zero;

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          if (_remaining.inSeconds > 0) {
            _remaining -= const Duration(seconds: 1);
          } else {
            _timer?.cancel();
          }
        });
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdownLabel {
    if (_remaining == Duration.zero) return 'Expired';
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _cancelApproval() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: ccSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CCRadius.card)),
        title: const Text('Cancel Request',
            style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: ccNavyText)),
        content: const Text(
            'Cancel this ride request? This cannot be undone.',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: ccSecondaryText)),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Keep',
                  style: TextStyle(
                      fontFamily: 'Inter', color: ccSecondaryText))),
          TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Cancel request',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: ccError))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    try {
      final body = {
        'approval_request_id': approvalRequestId,
        'user_id': getData.read('userLogin')?['id'] ?? '',
      };
      final response = await http.post(
        Uri.parse('${Confing.baseurl}${Confing.corporateBookingCancel}'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${getData.read('token') ?? ''}',
        },
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      showToastMessage(data['ResponseMsg'] ?? 'Request cancelled');
      Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN);
    } catch (e) {
      showToastMessage('Error: $e');
    } finally {
      setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,##0', 'en_US');
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {},
      child: Scaffold(
        backgroundColor: ccBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                // ─── Icon ────────────────────────────────────────────
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9900).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pending_actions_outlined,
                      size: 42, color: Color(0xFFFF9900)),
                ),
                const SizedBox(height: 20),
                const Text('Awaiting Approval',
                    style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        color: ccNavyText)),
                const SizedBox(height: 8),
                Text(
                  'Your ride request has been sent to $approverName for approval.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      color: ccSecondaryText),
                ),
                const SizedBox(height: 24),

                // ─── Countdown ──────────────────────────────────────
                if (expiresAt.isNotEmpty) ...[
                  _infoCard(
                    child: Column(children: [
                      const Text('Response window',
                          style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Inter',
                              color: ccSecondaryText)),
                      const SizedBox(height: 6),
                      Text(
                        _countdownLabel,
                        style: TextStyle(
                            fontSize: 28,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: _remaining.inMinutes < 30
                                ? ccError
                                : const Color(0xFFFF9900)),
                      ),
                      const Text(
                        'If not approved in time, the ride is cancelled',
                        style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Inter',
                            color: ccSecondaryText),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                ],

                // ─── Trip details ─────────────────────────────────
                _infoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow(Icons.radio_button_checked, ccSuccess, origin),
                      _dotDivider(),
                      _detailRow(Icons.location_on, ccError, destination),
                      const SizedBox(height: 12),
                      const Divider(color: ccInputBorder, height: 1),
                      const SizedBox(height: 12),
                      Row(children: [
                        _chip(Icons.business_outlined, companyName,
                            ccIceBlue, ccPrimary),
                        const SizedBox(width: 8),
                        _chip(Icons.account_balance_wallet_outlined,
                            '₦${nf.format(estimatedFare)}',
                            ccSuccessLight, ccSuccess),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ─── Approver info ────────────────────────────────
                _infoCard(
                  child: Row(children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: ccIceBlue,
                      child: Text(
                        approverName.isNotEmpty
                            ? approverName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: ccPrimary,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(approverName,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  color: ccNavyText)),
                          Text(_roleLabel(approverRole),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                  color: ccSecondaryText)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9900).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Pending',
                          style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFFF9900))),
                    ),
                  ]),
                ),

                const Spacer(),

                // ─── Actions ──────────────────────────────────────
                _isCancelling
                    ? const SizedBox(
                        height: 52,
                        child: Center(
                            child: CircularProgressIndicator(color: ccPrimary)))
                    : SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _cancelApproval,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: ccError),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(CCRadius.btn)),
                          ),
                          child: const Text('Cancel Request',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  color: ccError,
                                  fontSize: 15)),
                        ),
                      ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ccIceBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CCRadius.btn)),
                    ),
                    child: const Text('Back to Home',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            color: ccPrimary,
                            fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ccSurface,
          borderRadius: BorderRadius.circular(CCRadius.card),
          boxShadow: CCShadow.card,
        ),
        child: child,
      );

  Widget _detailRow(IconData icon, Color color, String text) => Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    color: ccNavyText),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );

  Widget _dotDivider() => Padding(
        padding: const EdgeInsets.only(left: 6, top: 3, bottom: 3),
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

  Widget _chip(IconData icon, String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  color: fg)),
        ]),
      );

  String _roleLabel(String role) {
    switch (role) {
      case 'manager':
        return 'Line Manager';
      case 'company_admin':
        return 'Company Admin';
      case 'company_finance':
        return 'Finance Officer';
      default:
        return role;
    }
  }
}
