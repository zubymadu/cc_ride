import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/auth_firebase.dart';
import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/auth/email_check_controller.dart';
import 'package:carride/app/modules/controllers/auth/mobile_check_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/main.dart';
import 'package:carride/theme/theme_colores.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class LoginScreenController extends GetxController with GetSingleTickerProviderStateMixin {
  ThemeColores themeColores = Get.put(ThemeColores());

  @override
  void onInit() {
    save("Firstuser", true);
    tabController = TabController(length: 2, vsync: this);
    themeColores.isDark = false;
    themeColores.update();
    update();
    debugPrint("--------------- Firstuser ------------ ${getData.read("Firstuser")}");
    super.onInit();
  }

  TextEditingController passwordController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  MobileCheckController mobileCheckController = Get.put(MobileCheckController());
  EmailCheckController emailCheckController = Get.put(EmailCheckController());

  late TabController tabController;

  final formKey = GlobalKey<FormState>();

  final RxString _ccode = "".obs;
  String get ccode => _ccode.value;
  set ccode(String value) => _ccode.value = value;

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  final RxInt _selectedTab = 0.obs;
  int get selectedTab => _selectedTab.value;
  set selectedTab(int value) => _selectedTab.value = value;

  final RxBool _isRemember = false.obs;
  bool get isRemember => _isRemember.value;
  set isRemember(bool value) => _isRemember.value = value;

  final RxBool _showPassword = true.obs;
  bool get showPassword => _showPassword.value;
  set showPassword(bool value) => _showPassword.value = value;

  final RxBool _useEmail = false.obs;
  bool get useEmail => _useEmail.value;
  set useEmail(bool value) => _useEmail.value = value;

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      showToastMessage("Please enter your email".tr);
      return 'Please enter your email'.tr;
    }

    // Regular expression for email validation
    String pattern = r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
    RegExp regex = RegExp(pattern);

    if (!regex.hasMatch(value)) {
      showToastMessage("Enter a valid email address".tr);
      return 'Enter a valid email address'.tr;
    }
    return null; // valid
  }

  FirebaseAuthService authService = Get.put(FirebaseAuthService());

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json"
  };

  Future loginApi({
    required String loginId,
    required String password,
    String? ccode,
  }) async {
    isLoading = true;
    update();
    Map body = {
      "mobile": loginId,
      "ccode": ccode,
      "password": password,
    };

    String url = Confing.baseurl + Confing.login;

    try {
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(name: "================ Login Api url =================", url);
      log(name: "================ Login Api body ================", "$body");
      log(name: "============== Login Api response ==============", response.body);

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          initPlatformState(key: Confing.oneSignalKey, loginId: "${data["UserLogin"]["id"]}");
          save("userLogin", data["UserLogin"]);
          // JWT + company for the corporate module (Node backend)
          save("token", data["token"] ?? "");
          save("companyId", data["company_id"] ?? "");
          save("isUserLogin", true);
          authService.firebaseStoreData(
            uid: "${data["UserLogin"]["id"]}",
            name: "${data["UserLogin"]["name"]}",
            email: "${data["UserLogin"]["email"]}",
            number: "${data["UserLogin"]["mobile"]}",
            proPicPath: "${data["UserLogin"]["profile_pic"]}",
          );
          Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN);
          return data;
        } else {
          showToastMessage(data["ResponseMsg"] ?? "Login failed.");
          return data;
        }
      } else {
        showToastMessage("Something went wrong");
      }
    } catch (e) {
      log(name: "================ Login Api Error ================", "$e");
      showToastMessage("Login failed. Please check your connection and try again.");
    } finally {
      isLoading = false;
      update();
    }
  }
}
