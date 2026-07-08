import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/modules/controllers/auth/reg_user_screen_controller.dart';
import 'package:carride/app/modules/controllers/auth/sms_type_controller.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class OtpScreenController extends GetxController {  
  final RxBool _resendCode = false.obs;
  bool get resendCode => _resendCode.value;
  set resendCode(bool value) => _resendCode.value = value;
  
  final RxInt _counter = 30.obs;
  int get counter => _counter.value;
  set counter(int value) => _counter.value = value;
  
  
  Timer? timer;

  // Start countdown when screen opens
  void startTimer() {
    resendCode = true; // disable button
    counter = 30;
    update();
    timer?.cancel();
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (counter == 0) {
        resendCode = false; // enable button
        t.cancel();
        update();
      } else {
        update();
        counter--;
      }
      update();
    });
  }


  TextEditingController otpController = TextEditingController();
  RegUserScreenController regUserScreenController = Get.put(RegUserScreenController());
  SmsTypeController smsTypeController = Get.put(SmsTypeController());

  @override
  void onInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("--------------- argument -------- ${Get.arguments}");
      startTimer();
      if (Get.arguments != null) {
        getOtp(smsType: "${Get.arguments["smsType"]}");
      }
    });
    super.onInit();
  }

  getOtp({required String smsType}){
    resendCode = true;
    update();
    try {
      if (smsType == "Msg91") {
        msg91otp(mobile: Get.arguments["mobile"]).then((value) {
          if (value["Result"] == "true") {
            otp = "${value["otp"]}";
            otpController = TextEditingController(text: otp);
            update();
          }
        });
      } else {
        twilloOtp(mobile: Get.arguments["mobile"]).then((value) {
          if (value["Result"] == "true") {
            otp = "${value["otp"]}";
            otpController = TextEditingController(text: otp);
            update();
          }
        });
      } 
    } catch (e) {
      debugPrint("======== Error ======= $e");
    } finally {
      resendCode = false;
      update();
    }
  }

  final RxString _otp = "".obs;
  String get otp => _otp.value;
  set otp(String value) => _otp.value = value;

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json"
  };

  Future msg91otp({required String mobile}) async {
    String url = Confing.baseurl + Confing.msgOtp;
    Map body = {"mobile": mobile};

    var request = await http.post(
      Uri.parse(url),
      body: jsonEncode(body),
    );

    log(name: "============== msg91 otp api url ===============", url);
    log(name: "============== msg91 otp api body ==============", "$body");
    log(name: "============ msg91 otp api response ============", request.body);

    if (request.statusCode == 200) {
      var response = jsonDecode(request.body);
      if (response["Result"] == "true") {
        return response;
      } else {
        showToastMessage(response["ResponseMsg"]);
      }
    } else {
      showToastMessage("Something went wrong!");
    }
  }

  Future twilloOtp({required String mobile}) async {
    Map body = {"mobile": mobile};

    String url = Confing.baseurl + Confing.twilioOtp;

    var request = await http.post(
      Uri.parse(url),
      body: jsonEncode(body),
      headers: userHeader,
    );

    log(name: "============== twillo Otp api url ===============", url);
    log(name: "============== twillo Otp api body ==============", "$body");
    log(name: "============ twillo Otp api response ============", request.body);

    if (request.statusCode == 200) {
      var response = jsonDecode(request.body);
      if (response["Result"] == "true") {
        return response;
      } else {
        showToastMessage(response["ResponseMsg"]);
      }
    } else {
      showToastMessage("Something went wrong!");
    }
  }

  Future emailotp({required email}) async {
    Map body = {"email": email};
    String url = Confing.baseurl + Confing.emailOtp;

    var request = await http.post(
      Uri.parse(url),
      body: jsonEncode(body),
      headers: userHeader,
    );

    log(name: "============== email Otp api url ===============", url);
    log(name: "============== email Otp api body ==============", "$body");
    log(name: "============ email Otp api response ============", request.body);

    if (request.statusCode == 200) {
      var response = jsonDecode(request.body);
      if (response["Result"] == "true") {
        return response;
      } else {
        showToastMessage(response["ResponseMsg"]);
      }
    } else {
      showToastMessage("Something went wrong!");
    }
  }
}
