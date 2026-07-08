import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class MobileCheckController extends GetxController {
  Future mobileCheckApi({
    required String mobileCheckId,
    required String ccode,
  }) async {
    Map body = {
      "mobile": mobileCheckId,
      "ccode": ccode,
    };

    Map<String, String> userHeader = {
      "Content-type": "application/json",
      "Accept": "application/json"
    };

    String url = Confing.baseurl + Confing.mobileCheck;

    try {
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(name: "================ mobileCheck Api url =================", url);
      log(name: "================ mobileCheck Api body ================", "$body");
      log(name: "============== mobileCheck Api response ==============", response.body);

      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data;
      } else {
        showToastMessage("Something went wrong");
      }
    } catch (e) {
      log(name: "================ mobileCheck Api Error ================", "$e");
    }
  }
}
