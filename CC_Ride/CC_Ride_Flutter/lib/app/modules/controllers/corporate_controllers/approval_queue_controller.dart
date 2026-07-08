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

class ApprovalQueueController extends GetxController {
  final Map<String, String> _headers = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  // ─── State ─────────────────────────────────────────────────────────────────

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool v) => _isLoading.value = v;

  final RxBool _isDeciding = false.obs;
  bool get isDeciding => _isDeciding.value;
  set isDeciding(bool v) => _isDeciding.value = v;

  final RxList<ApprovalRequestModel> _pending = <ApprovalRequestModel>[].obs;
  List<ApprovalRequestModel> get pending => _pending;

  final RxList<ApprovalRequestModel> _history = <ApprovalRequestModel>[].obs;
  List<ApprovalRequestModel> get history => _history;

  final RxInt _tabIndex = 0.obs;
  int get tabIndex => _tabIndex.value;
  set tabIndex(int v) => _tabIndex.value = v;

  final TextEditingController noteCtrl = TextEditingController();

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    fetchApprovals();
  }

  @override
  void onClose() {
    noteCtrl.dispose();
    super.onClose();
  }

  // ─── API ───────────────────────────────────────────────────────────────────

  Future<void> fetchApprovals() async {
    try {
      isLoading = true;
      update();
      final companyId = getData.read('companyId') ?? '';
      final approverId = getData.read('userLogin')?['id'] ?? '';
      final url =
          '${Confing.baseurl}${Confing.corporateApprovals}?company_id=$companyId&approver_id=$approverId';
      final response = await http.get(Uri.parse(url), headers: _headers);
      log(name: '=== Approvals ===', response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Result'] == 'true') {
          final all = (data['data'] as List)
              .map((e) => ApprovalRequestModel.fromJson(e))
              .toList();
          _pending.value = all.where((a) => a.status == 'pending').toList();
          _history.value = all.where((a) => a.status != 'pending').toList();
        }
      }
    } catch (e) {
      log(name: '=== Approvals error ===', '$e');
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> decide({
    required String approvalId,
    required String action, // 'approved' | 'rejected'
    String? note,
  }) async {
    try {
      isDeciding = true;
      update();
      final body = {
        "approval_id": approvalId,
        "action": action,
        "decision_note": note ?? '',
        "approver_id": getData.read('userLogin')?['id'] ?? '',
      };
      final response = await http.post(
        Uri.parse('${Confing.baseurl}${Confing.corporateApprovalDecide}'),
        headers: _headers,
        body: jsonEncode(body),
      );
      log(name: '=== ApprovalDecide ===', response.body);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['Result'] == 'true') {
        showToastMessage(
            action == 'approved' ? 'Ride approved' : 'Ride rejected');
        Get.back();
        fetchApprovals();
      } else {
        showToastMessage(data['ResponseMsg'] ?? 'Could not process decision');
      }
    } catch (e) {
      showToastMessage('Error: $e');
    } finally {
      isDeciding = false;
      update();
    }
  }

  // ─── Detail Bottom Sheet ───────────────────────────────────────────────────

  void showApprovalDetail(ApprovalRequestModel req) {
    noteCtrl.clear();
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
        child: GetBuilder<ApprovalQueueController>(
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
              Row(children: [
                Expanded(
                  child: Text('Ride Approval',
                      style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          color: ccNavyText)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(req.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    req.status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        color: _statusColor(req.status)),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              // Requester info
              Row(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: ccIceBlue,
                  child: Text(
                    req.requesterName.isNotEmpty ? req.requesterName[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        color: ccPrimary,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(req.requesterName,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: ccNavyText,
                            fontSize: 15)),
                    Text(req.requesterDept,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            color: ccNavyText.withOpacity(0.6),
                            fontSize: 13)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(formatNaira(req.estimatedFare),
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          color: ccPrimary,
                          fontSize: 16)),
                  Text('Est. fare',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          color: ccNavyText.withOpacity(0.5),
                          fontSize: 11)),
                ]),
              ]),
              const SizedBox(height: 16),
              _divider(),
              const SizedBox(height: 16),
              // Trip details
              _tripRow('From', req.origin),
              const SizedBox(height: 10),
              _tripRow('To', req.destination),
              const SizedBox(height: 10),
              _tripRow('Scheduled', _formatDate(req.scheduledAt)),
              const SizedBox(height: 10),
              _tripRow('Expires', _formatDate(req.expiresAt)),
              if (req.status == 'pending') ...[
                const SizedBox(height: 16),
                _divider(),
                const SizedBox(height: 16),
                const Text('Note (optional)',
                    style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        color: ccNavyText)),
                const SizedBox(height: 6),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  style: const TextStyle(
                      color: ccNavyText,
                      fontFamily: 'Inter'),
                  decoration: InputDecoration(
                    hintText: 'Reason for decision...',
                    hintStyle: TextStyle(
                        color: ccNavyText.withOpacity(0.4),
                        fontFamily: 'Inter'),
                    contentPadding: const EdgeInsets.all(12),
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
                const SizedBox(height: 16),
                Obx(() => c.isDeciding
                    ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: ccPrimary)))
                    : Row(children: [
                        Expanded(
                          child: CCButton(
                            label: 'Reject',
                            onPressed: () => decide(
                                approvalId: req.id,
                                action: 'rejected',
                                note: noteCtrl.text.trim()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CCButton(
                            label: 'Approve',
                            onPressed: () => decide(
                                approvalId: req.id,
                                action: 'approved',
                                note: noteCtrl.text.trim()),
                          ),
                        ),
                      ])),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _divider() => const Divider(color: ccInputBorder, height: 1);

  Widget _tripRow(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 80,
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                color: ccNavyText.withOpacity(0.5))),
      ),
      Expanded(
        child: Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                color: ccNavyText)),
      ),
    ],
  );

  String formatNaira(double amount) {
    final f = NumberFormat('#,##0', 'en_US');
    return '₦${f.format(amount)}';
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('EEE dd MMM, h:mm a').format(dt);
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF00B894);
      case 'rejected':
        return Colors.red;
      case 'escalated':
        return Colors.orange;
      default:
        return const Color(0xFF0047FF);
    }
  }

  Color statusColor(String status) => _statusColor(status);
}
