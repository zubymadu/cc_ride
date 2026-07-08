import 'dart:convert';
import 'dart:developer';

import 'package:carride/Utils/color.dart';
import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/models/faq_list_api_model.dart';
import 'package:carride/theme/theme_colores.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class HelpScreenController extends GetxController {
  @override
  void onInit() {
    faqListApi();
    super.onInit();
  }

  ThemeColores themeColores = Get.put(ThemeColores());

  FaqListApiModel? faqListApiModel;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;
  
  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json"
  };

  Future faqListApi() async {
    Map body = {"uid": getData.read("userLogin") == null ? "0" :  getData.read("userLogin")["id"]};

    try {
      String url = Confing.baseurl + Confing.faq;

      log(name: "============= Faq List Api url ==============", url);
      log(name: "============= Faq List Api Body =============", "$body");

      var response = await http.post(
        Uri.parse(url),
        headers: userHeader,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      log(name: "=========== Faq List Api response ===========", response.body);

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        faqListApiModel = faqListApiModelFromJson(response.body);
        if (data["Result"] == "true") {
          if (faqListApiModel!.result == "true") {
            save("currency", data["currency"]);
            save("booking_fee", data["booking_fee"]);
            debugPrint("------------- currency ----------- $currency");
            debugPrint("----------- booking_fee ---------- ${getData.read("booking_fee")}");
            isLoading = false;
            update();
          } else {
            showToastMessage("${faqListApiModel!.responseMsg}");
          }
        } else {
          showToastMessage("${data["ResponseMsg"]}");
        }
        return data;
      } else {
        showToastMessage("Somthing went wrong!.....");
      }
    } catch (e) {
      log(name: "============= Faq List Api Error =============", "$e");
    } finally {
      isLoading = false;
      update();
    }
  }
}
