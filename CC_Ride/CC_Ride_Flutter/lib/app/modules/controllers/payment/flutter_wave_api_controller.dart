import 'dart:convert';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// Mirrors PayStackApiController exactly — legacyFlutterwaveInit on the
// backend requires an authenticated request (reads req.user.id), the same
// way legacyPaystackInit does. Previously the Flutterwave call sites opened
// a raw GET webview URL directly with no backend route behind it at all
// (404) and no auth header, so "pay with Flutterwave" was dead on arrival.
class FlutterWaveApiController extends GetxController implements GetxService {
  Map<String, String> get userHeader => {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  Future flutterWaveApi({
    required String email,
    required String amount,
  }) async {
    Map body = {
      "uid": getData.read("userLogin")?["id"],
      "email": email,
      "amount": amount,
    };

    String url = Confing.imageurl + Confing.flutterwave;

    try {
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      debugPrint("----------- Flutterwave url ------------ $url");
      debugPrint("----------- Flutterwave body ----------- $body");
      debugPrint("--------- Flutterwave response --------- ${response.body}");

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        showToastMessage("${data["message"]}");
        return data;
      } else {
        showToastMessage("Something Went Wrong!");
      }
    } catch (e) {
      debugPrint("------------ Flutterwave error ----------- $e");
    }
  }
}
