import 'package:carride/app/modules/controllers/auth/email_check_controller.dart';
import 'package:carride/app/modules/controllers/auth/mobile_check_controller.dart';
import 'package:carride/app/modules/controllers/auth/sms_type_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgetPasswordScreenController extends GetxController {
  TextEditingController mobileController = TextEditingController();
  SmsTypeController smsTypeController = Get.put(SmsTypeController());
  MobileCheckController mobileCheckController = Get.put(MobileCheckController());
  EmailCheckController emailCheckController = Get.put(EmailCheckController());

  final RxString _ccode = "".obs;
  String get ccode => _ccode.value;
  set ccode(String value) => _ccode.value = value;

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;
  
  final RxInt _colorIndex = 0.obs;
  int get colorIndex => _colorIndex.value;
  set colorIndex(int value) => _colorIndex.value = value;
}
