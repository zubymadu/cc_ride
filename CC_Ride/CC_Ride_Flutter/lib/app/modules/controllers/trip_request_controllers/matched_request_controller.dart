import 'dart:convert';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/models/trip_request_list_api_model.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// A driver committing a trip against this passenger's request doesn't book
// them automatically (see legacyPostTrip on the backend) — the passenger
// must explicitly confirm (proceed to the normal book/pay flow for that
// trip) or decline (kill the request outright) here.
class MatchedRequestController extends GetxController {
  late final String requestId;

  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final Rx<Datum?> request = Rx<Datum?>(null);

  Map<String, String> get _headers => {
        "Content-type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer ${getData.read('token') ?? ''}",
      };

  @override
  void onInit() {
    requestId = '${Get.arguments?['request_id'] ?? ''}';
    fetchRequest();
    super.onInit();
  }

  Future<void> fetchRequest() async {
    isLoading.value = true;
    try {
      final url = Confing.baseurl + Confing.tripRequestlist;
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({"uid": "${getData.read("userLogin")?["id"]}"}),
      );
      final data = jsonDecode(response.body);
      if (data["Result"] == "true") {
        final model = tripRequestListApiModelFromJson(response.body);
        request.value = (model.data ?? [])
            .cast<Datum?>()
            .firstWhere((d) => d?.requestId == requestId, orElse: () => null);
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> confirm() async {
    isSubmitting.value = true;
    try {
      final url = Confing.baseurl + Confing.confirmMatchedRequest;
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({"request_id": requestId}),
      );
      final data = jsonDecode(response.body);
      if (data["Result"] == "true") {
        Get.offNamed(Routes.TRIP_PREVIEW_SCREEN, arguments: {
          'tripId': '${data["trip_id"]}',
          'findtrip': true,
        });
      } else {
        showToastMessage("${data["ResponseMsg"] ?? "Something went wrong"}");
      }
    } catch (_) {
      showToastMessage("Something went wrong");
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> decline() async {
    isSubmitting.value = true;
    try {
      final url = Confing.baseurl + Confing.declineMatchedRequest;
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({"request_id": requestId}),
      );
      final data = jsonDecode(response.body);
      if (data["Result"] == "true") {
        showToastMessage("Request declined");
        Get.back();
      } else {
        showToastMessage("${data["ResponseMsg"] ?? "Something went wrong"}");
      }
    } catch (_) {
      showToastMessage("Something went wrong");
    } finally {
      isSubmitting.value = false;
    }
  }
}
