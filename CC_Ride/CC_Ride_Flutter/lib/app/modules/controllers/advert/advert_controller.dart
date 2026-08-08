import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class Advert {
  final String id;
  final String imageUrl;
  final String title;
  final String body;
  final String linkUrl;

  Advert({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.body,
    required this.linkUrl,
  });

  factory Advert.fromJson(Map<String, dynamic> json) => Advert(
        id: '${json["id"]}',
        imageUrl: '${json["image_url"]}',
        title: '${json["title"]}',
        body: '${json["body"] ?? ''}',
        linkUrl: '${json["link_url"] ?? ''}',
      );
}

// Shared by both the passenger home (search_screen_view.dart) and the
// driver home (post_screen_view.dart) — a single fetch, both screens read
// the same singleton rather than duplicating the API call.
class AdvertController extends GetxController {
  final RxList<Advert> _adverts = <Advert>[].obs;
  List<Advert> get adverts => _adverts;

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    fetchAdverts();
  }

  Future<void> fetchAdverts() async {
    _isLoading.value = true;
    update();
    try {
      final response = await http.get(
        Uri.parse(Confing.baseurl + Confing.adverts),
        headers: {
          "Content-type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer ${getData.read('token') ?? ''}",
        },
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (data["Result"] == "true") {
        final list = (data["Data"] as List? ?? [])
            .map((e) => Advert.fromJson(e))
            .toList();
        _adverts.assignAll(list);
      }
    } catch (e) {
      log(name: "=========== fetchAdverts error ===========", "$e");
    } finally {
      _isLoading.value = false;
      update();
    }
  }
}
