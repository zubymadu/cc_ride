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

  /// Returns the matching places for [suggestkey] directly, so callers don't
  /// need to read back the shared [mapApiModel] field — multiple location
  /// fields on the same screen (origin/destination/stops) reuse this same
  /// controller instance, and reading the shared field let a slow response
  /// for one field clobber another field's results with a stale match.
  Future<List<Result>> mapApi({required String suggestkey}) async {
    final query = suggestkey.trim();
    if (query.isEmpty) return [];

    Map<String, String> userHeader = {
      "Content-type": "application/json",
      "Accept": "application/json"
    };
    // region=ng biases (does not restrict) results towards Nigeria, since
    // that's where this app operates.
    var response = await http.get(
      Uri.parse("https://maps.googleapis.com/maps/api/place/textsearch/json?query=${Uri.encodeComponent(query)}&region=ng&key=$googleAPIKey"),
      headers: userHeader,
    );

    var data = jsonDecode(response.body);

    log(name: "=============== map search Data ===============", "$data");

    if (data["status"] == "OK") {
      mapApiModel = mapApiModelFromJson(response.body);
      isLoading = false;
      update();
      return mapApiModel?.results ?? [];
    }

    // Zero results / error — don't leave a previous query's matches showing.
    mapApiModel = null;
    isLoading = false;
    update();
    return [];
  }
}