import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/modules/models/map_api_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class MapSuggetionControlle extends GetxController {
  MapApiModel? mapApiModel;
  bool isLoading = true;

  String googleAPIKey = Confing.mapkey;

  Future mapApi({required String suggestkey}) async {
    Map<String, String> userHeader = {
      "Content-type": "application/json",
      "Accept": "application/json"
    };
    var response = await http.get(
      Uri.parse("https://maps.googleapis.com/maps/api/place/textsearch/json?query=$suggestkey%20pi&key=$googleAPIKey"),
      headers: userHeader,
    );

    var data = jsonDecode(response.body);

    log(name: "=============== map search Data ===============", "$data");

    if (data["status"] == "OK") {
      mapApiModel = mapApiModelFromJson(response.body);
      isLoading = false;
      update();
    } else {}
  }
}