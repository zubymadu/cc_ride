import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/models/find_trip_api_model.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class FindTripController extends GetxController {
  Findtripmodel? findAllmodel;
  Findtripmodel? findTripsmodel;
  Findtripmodel? findRequestsmodel;
  
  final _allIsLoading = true.obs;
  get allIsLoading => _allIsLoading.value;
  set allIsLoading(value) => _allIsLoading.value = value;

  final _tripIsLoading = true.obs;
  get tripIsLoading => _tripIsLoading.value;
  set tripIsLoading(value) => _tripIsLoading.value = value;

  final _requestIsLoading = true.obs;
  get requestIsLoading => _requestIsLoading.value;
  set requestIsLoading(value) => _requestIsLoading.value = value;

  // Without this, every "Book a Ride" / nearby-route search hit find_trip.php
  // as an anonymous request (optionalAuth saw no token → req.user stayed
  // null) — which silently broke self-trip exclusion (driverId !== userId
  // always true) and the zero-results auto-queue-as-request path (guarded by
  // `userId && userId !== '0'`), so unmatched searches never actually
  // notified drivers despite the app claiming they would.
  Map<String, String> get userHeader => {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  Future findtripApi({
    required String originLat,
    required String originLong,
    required String destinationLat,
    required String destinationLong,
    required String tripDate,
    required String status,
    String originAddress = '',
    String destinationAddress = '',
  }) async {
    // requestIsLoading = true;
    // update();
    Map body = {
      "uid":  getData.read("userLogin") == null ? "0" :  getData.read("userLogin")["id"],
      // "uid": "7",
      "origin_lat": originLat,
      "origin_long": originLong,
      "destination_lat": destinationLat,
      "destination_long": destinationLong,
      "origin_address": originAddress,
      "destination_address": destinationAddress,
      "trip_date": tripDate,
      "status": status
    };

    try {
      String url = Confing.baseurl + Confing.findTrip;

      log(name: "============== find trip url =============", url);
      log(name: "============== find trip body ============", "$body");

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(name: "============= find trip respon ===========", response.body);
      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (status == "All") {
          findAllmodel = findtripmodelFromJson(response.body);
          allIsLoading = false;
          update();
        } else if (status == "Trip") {
          findTripsmodel = findtripmodelFromJson(response.body);
          tripIsLoading = false;
          update();
        } else if (status == "Requests") {
          findRequestsmodel = findtripmodelFromJson(response.body);
          requestIsLoading = false;
          update();
        }
        return data;
        // if (data["Result"] == "true") {
        // } else {
        //   showToastMessage("${data["ResponseMsg"]}");
        //   return data;
        // }
      } else {
        showToastMessage("Somthing went wrong!.....");
        return data;
      }
    } catch (e) {
      log(name: "============= find trip error ===========", "$e");
    }
  }
}