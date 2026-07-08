import 'dart:convert';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class PayStackApiController extends GetxController implements GetxService {

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json"
  };

  Future payStackApi({
    required String email,
    required String amount,
  }) async {
    Map body = {
      "uid": getData.read("userLogin")?["id"],
      "email": email,
      "amount": amount,
    };

    String url = Confing.imageurl + Confing.payStack;

    try {
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );
  
      debugPrint("----------- Pay Stack url ------------ $url");
      debugPrint("----------- Pay Stack body ----------- $body");
      debugPrint("--------- Pay Stack response --------- ${response.body}");
  
      var data = jsonDecode(response.body);
  
      if (response.statusCode == 200) {
        showToastMessage("${data["message"]}");
        return data;
      } else {
        showToastMessage("Something Went Wrong!");
      }
    } catch (e) {
      debugPrint("------------ Pay Stack error ----------- $e");
    }
  }
}