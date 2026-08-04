import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/modules/models/map_api_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class MapSuggetionControlle extends GetxController {
  MapApiModel? mapApiModel;
  bool isLoading = true;

  String googleAPIKey = Confing.mapkey;

  // Biases search results toward the rider's current position so nearby
  // places rank above same-named places elsewhere. Populated best-effort on
  // init; searches still work without it, just without the proximity bias.
  double? _biasLat;
  double? _biasLng;

  // Fallback bias when we have no device position at all (permission denied,
  // GPS off, or not fixed yet) — geographic centre of Nigeria, CC Ride's only
  // market. Without any location param at all, Text Search's "region": "ng"
  // is a weak tie-breaker that same-named places abroad regularly outrank;
  // this gives every search a real anchor instead of running unbiased and
  // worldwide until a device fix arrives.
  static const double _nigeriaCenterLat = 9.0820;
  static const double _nigeriaCenterLng = 8.6753;
  static const int _nigeriaRadiusMeters = 800000; // covers the whole country

  @override
  void onInit() {
    super.onInit();
    _loadLocationBias();
  }

  Future<void> _loadLocationBias() async {
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _biasLat = lastKnown.latitude;
        _biasLng = lastKnown.longitude;
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      _biasLat = position.latitude;
      _biasLng = position.longitude;
    } catch (e) {
      log(name: "map suggestion location bias", "$e");
    }
  }

  Future mapApi({required String suggestkey}) async {
    // A 1-character query returns near-random matches (mostly irrelevant
    // businesses) and burns a full-price Places request for a result the
    // passenger was never going to pick — wait for a query long enough to be
    // meaningful instead of firing on every keystroke from character one.
    if (suggestkey.trim().length < 2) {
      mapApiModel = null;
      update();
      return;
    }

    Map<String, String> userHeader = {
      "Content-type": "application/json",
      "Accept": "application/json"
    };

    final queryParams = <String, String>{
      "query": suggestkey,
      "key": googleAPIKey,
      // Biases (not restricts) results toward Nigeria, CC Ride's market.
      "region": "ng",
    };
    if (_biasLat != null && _biasLng != null) {
      // Real device fix: bias toward it. A passenger may legitimately be
      // searching for a destination well outside this radius (a different
      // city), so this only weights ranking, never excludes anything.
      queryParams["location"] = "$_biasLat,$_biasLng";
      queryParams["radius"] = "50000";
    } else {
      // No device fix yet: anchor to Nigeria as a whole instead of running
      // completely unbiased and worldwide until one arrives.
      queryParams["location"] = "$_nigeriaCenterLat,$_nigeriaCenterLng";
      queryParams["radius"] = "$_nigeriaRadiusMeters";
    }

    final uri = Uri.https(
      "maps.googleapis.com",
      "/maps/api/place/textsearch/json",
      queryParams,
    );

    var response = await http.get(uri, headers: userHeader);

    var data = jsonDecode(response.body);

    log(name: "=============== map search Data ===============", "$data");

    if (data["status"] == "OK") {
      final parsed = mapApiModelFromJson(response.body);
      // Text Search's "location"/"radius"/"region" params only ever bias
      // ranking — Google still returns (and can rank highly) same-named
      // places outside Nigeria entirely. Drop anything outside a generous
      // bounding box around the country, which is the only real "restrict"
      // lever available on this endpoint (the stricter components/
      // strictbounds filters only exist on the Places Autocomplete API).
      parsed.results = parsed.results
          ?.where((r) => _withinNigeria(r.geometry?.location?.lat, r.geometry?.location?.lng))
          .toList();
      mapApiModel = parsed;
      isLoading = false;
      update();
    } else {}
  }

  bool _withinNigeria(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    return lat >= 4.0 && lat <= 14.0 && lng >= 2.5 && lng <= 15.0;
  }
}