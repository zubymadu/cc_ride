import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// User-facing support ticket list + create + thread/reply — the mirror
// image of the admin console's Support.tsx, scoped to the current user's
// own tickets. Kept as plain Map<String,dynamic> rows (rather than a
// generated model) to match the lightweight pattern already used by
// book_pricing_controller/payment_screen_controller for similarly small,
// one-screen API shapes in this codebase.
class SupportTicketsController extends GetxController {
  Map<String, String> get _userHeader => {
        "Content-type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer ${getData.read('token') ?? ''}",
      };

  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> tickets = <Map<String, dynamic>>[].obs;

  final RxBool isSubmitting = false.obs;

  // ── Thread/detail state (for whichever ticket is currently open) ────────
  final RxBool isLoadingDetail = false.obs;
  final Rx<Map<String, dynamic>?> activeTicket = Rx<Map<String, dynamic>?>(null);
  final RxList<Map<String, dynamic>> activeMessages = <Map<String, dynamic>>[].obs;
  final RxBool isReplying = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTicketsApi();
  }

  Future<void> fetchTicketsApi() async {
    isLoading.value = true;
    try {
      final response = await http
          .get(Uri.parse(Confing.baseurl + Confing.supportTickets), headers: _userHeader)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["Result"] == "true") {
        tickets.assignAll((data["data"] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)));
      }
    } catch (e) {
      log(name: "=========== fetch tickets error ===========", "$e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createTicketApi({
    required String subject,
    required String description,
    required String category,
    String? bookingId,
  }) async {
    isSubmitting.value = true;
    try {
      final body = {
        "subject": subject,
        "description": description,
        "category": category,
        if (bookingId != null && bookingId.isNotEmpty) "booking_id": bookingId,
      };
      final response = await http
          .post(Uri.parse(Confing.baseurl + Confing.supportTickets),
              body: jsonEncode(body), headers: _userHeader)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["Result"] == "true") {
        showToastMessage("${data["ResponseMsg"] ?? 'Ticket submitted'}");
        await fetchTicketsApi();
        return true;
      }
      showToastMessage("${data["ResponseMsg"] ?? 'Failed to submit ticket'}");
      return false;
    } catch (e) {
      log(name: "=========== create ticket error ===========", "$e");
      showToastMessage("Failed to submit ticket");
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> fetchTicketDetailApi(String ticketId) async {
    isLoadingDetail.value = true;
    activeMessages.clear();
    try {
      final response = await http
          .get(Uri.parse("${Confing.baseurl}${Confing.supportTickets}/$ticketId"),
              headers: _userHeader)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["Result"] == "true") {
        final ticket = Map<String, dynamic>.from(data["data"] as Map);
        activeTicket.value = ticket;
        activeMessages.assignAll((ticket["messages"] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)));
      }
    } catch (e) {
      log(name: "=========== fetch ticket detail error ===========", "$e");
    } finally {
      isLoadingDetail.value = false;
    }
  }

  Future<bool> replyToTicketApi(String ticketId, String message) async {
    if (message.trim().isEmpty) return false;
    isReplying.value = true;
    try {
      final response = await http
          .post(
              Uri.parse("${Confing.baseurl}${Confing.supportTickets}/$ticketId/reply"),
              body: jsonEncode({"message": message}),
              headers: _userHeader)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["Result"] == "true") {
        await fetchTicketDetailApi(ticketId);
        return true;
      }
      showToastMessage("${data["ResponseMsg"] ?? 'Failed to send reply'}");
      return false;
    } catch (e) {
      log(name: "=========== reply to ticket error ===========", "$e");
      return false;
    } finally {
      isReplying.value = false;
    }
  }
}
