import 'dart:convert';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class RouteBookingRequest {
  final String bookingId;
  final String passengerName;
  final String passengerPic;
  final String pickupAddress;
  final String dropoffAddress;
  final int seatsBooked;
  final DateTime createdAt;

  RouteBookingRequest({
    required this.bookingId,
    required this.passengerName,
    required this.passengerPic,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.seatsBooked,
    required this.createdAt,
  });

  factory RouteBookingRequest.fromJson(Map<String, dynamic> json) =>
      RouteBookingRequest(
        bookingId: '${json["booking_id"]}',
        passengerName: '${json["passenger_name"]}',
        passengerPic: '${json["passenger_pic"] ?? ''}',
        pickupAddress: '${json["pickup_address"]}',
        dropoffAddress: '${json["dropoff_address"]}',
        seatsBooked: int.tryParse('${json["seats_booked"]}') ?? 1,
        createdAt: DateTime.tryParse('${json["created_at"]}') ?? DateTime.now(),
      );
}

class RouteRequestsController extends GetxController {
  final String routeId;
  RouteRequestsController({required this.routeId});

  final RxList<RouteBookingRequest> pending = <RouteBookingRequest>[].obs;
  final RxList<RouteBookingRequest> confirmed = <RouteBookingRequest>[].obs;
  final RxList<RouteBookingRequest> declined = <RouteBookingRequest>[].obs;
  final RxBool isLoading = true.obs;
  final RxSet<String> actioningIds = <String>{}.obs;

  Map<String, String> get _headers => {
        "Content-type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer ${getData.read('token') ?? ''}",
      };

  @override
  void onInit() {
    fetchRequests();
    super.onInit();
  }

  Future<void> fetchRequests() async {
    isLoading.value = true;
    try {
      final url = Confing.baseurl + Confing.routeBookingRequests;
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({"route_id": routeId}),
      );
      final data = jsonDecode(response.body);
      if (data["Result"] == "true") {
        pending.assignAll((data["Pending"] as List? ?? [])
            .map((e) => RouteBookingRequest.fromJson(e)));
        confirmed.assignAll((data["Confirmed"] as List? ?? [])
            .map((e) => RouteBookingRequest.fromJson(e)));
        declined.assignAll((data["Declined"] as List? ?? [])
            .map((e) => RouteBookingRequest.fromJson(e)));
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> confirmRequest(String bookingId) async {
    actioningIds.add(bookingId);
    try {
      final url = Confing.baseurl + Confing.confirmBookingRequest;
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({"booking_id": bookingId}),
      );
      final data = jsonDecode(response.body);
      if (data["Result"] == "true") {
        showToastMessage("Request confirmed.");
        await fetchRequests();
      } else {
        showToastMessage("${data["ResponseMsg"] ?? "Something went wrong"}");
      }
    } catch (_) {
      showToastMessage("Something went wrong");
    } finally {
      actioningIds.remove(bookingId);
    }
  }

  Future<void> declineRequest(String bookingId) async {
    actioningIds.add(bookingId);
    try {
      final url = Confing.baseurl + Confing.declineBookingRequest;
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({"booking_id": bookingId}),
      );
      final data = jsonDecode(response.body);
      if (data["Result"] == "true") {
        showToastMessage("Request declined and refunded.");
        await fetchRequests();
      } else {
        showToastMessage("${data["ResponseMsg"] ?? "Something went wrong"}");
      }
    } catch (_) {
      showToastMessage("Something went wrong");
    } finally {
      actioningIds.remove(bookingId);
    }
  }
}
