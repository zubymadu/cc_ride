// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:http/http.dart' as http;


class EmailCheckController extends GetxController implements GetxService {
  Future emailCheckApi({required String emailId}) async {
    Map body = {"email": emailId};

    Map<String, String> userHeader = {
      "Content-type": "application/json",
      "Accept": "application/json"
    };

    String url = Confing.baseurl + Confing.emailcheck;

    try {
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(name: "================ emailCheck Api url =================", url);
      log(name: "================ emailCheck Api body ================", "$body");
      log(name: "============== emailCheck Api response ==============", response.body);

      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data;
      } else {
        showToastMessage("Something went wrong");
      }
    } catch (e) {
      log(name: "================ emailCheck Api Error ================", "$e");
    }
  }
}
