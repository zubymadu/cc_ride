import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class NewPasswordScreenController extends GetxController {
  TextEditingController passwordController = TextEditingController();
  TextEditingController conformPasswordController = TextEditingController();

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  final formKey = GlobalKey<FormState>();

  final RxBool _isObscureText = true.obs;
  bool get isObscureText => _isObscureText.value;
  set isObscureText(bool value) => _isObscureText.value = value;

  final RxBool _isNewObscureText = true.obs;
  bool get isNewObscureText => _isNewObscureText.value;
  set isNewObscureText(bool value) => _isNewObscureText.value = value;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
  };

  Future forgetPasswordApi({
    required String mobile,
    required String ccode,
    required String password,
  }) async {
    isLoading = true;
    update();
    try {
      Map body = {"mobile": mobile, "ccode": ccode, "password": password};

      Uri uri = Uri.parse(Confing.baseurl + Confing.forgetpassword);
      var response = await http.post(
        uri,
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(
        name: "================ Forget Password Api url =================",
        "$uri",
      );
      log(
        name: "================ Forget Password Api body ================",
        "$body",
      );
      log(
        name: "============== Forget Password Api response ==============",
        response.body,
      );

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          showToastMessage("${data["ResponseMsg"]}");
          // Get.offAllNamed(Routes.LOGIN_SCREEN);
          isLoading = false;
          update();
          return data;
        } else {
          showToastMessage("${data["ResponseMsg"]}");
          isLoading = false;
          update();
          return data;
        }
      }
    } catch (e) {
      log(
        name: "============== Forget Password Api error ==============",
        "$e",
      );
    } finally {
      isLoading = false;
      update();
    }
  }
}
