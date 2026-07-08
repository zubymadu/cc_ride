import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class SmsTypeController extends GetxController {
  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
  };

  Future getMsgtype() async {
    String url = Confing.baseurl + Confing.smsType;
    var request = await http.get(
      Uri.parse(url),
      headers: userHeader
    );

    log(name: "============== get Msg type api url ===============", url);
    log(name: "============ get Msg type api response ============", request.body);

    if (request.statusCode == 200) {
      jsonDecode(request.body);
      return jsonDecode(request.body);
    } else {
      showToastMessage("Something went wrong!");
    }
  }
}