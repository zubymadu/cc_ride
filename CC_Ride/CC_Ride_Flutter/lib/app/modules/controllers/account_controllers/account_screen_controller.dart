import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/account_controllers/language_screen_controller.dart';
import 'package:carride/app/modules/models/page_list_api_model.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/theme/theme_colores.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class AccountScreenController extends GetxController {
  ThemeColores themeColores = Get.put(ThemeColores());
  LanguageScreenController languageScreenController = Get.put(LanguageScreenController());

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pageListApi();
    });
  }

  final RxList _proferencesIcon = [
    "assets/image/svg/profile.svg",
    "assets/image/svg/steering.svg",
    "assets/image/svg/calendar1.svg",
    "assets/image/svg/Card1.svg",
    "assets/image/svg/Invoice.svg",
    "assets/image/svg/question-circle-filled.svg",
    "assets/image/svg/Restrooms.svg",
    "assets/image/svg/setting.svg",
  ].obs;
  List get proferencesIcon => _proferencesIcon;
  set proferencesIcon(List value) => _proferencesIcon.value = value;

  final RxList _proferences = [
    "Profile Update",
    "Vehicles",
    "My Booking",
    "Wallet",
    "Earning",
    "Help",
    "Refer a friend",
    "Language",
  ].obs;
  List get proferences => _proferences;
  set proferences(List value) => _proferences.value = value;

  final RxList _accountSecurityIcon = [
    "assets/image/svg/LogOut.svg",
    "assets/image/svg/delete.svg",
  ].obs;
  List get accountSecurityIcon => _accountSecurityIcon;
  set accountSecurityIcon(List value) => _accountSecurityIcon.value = value;

  final RxList _accountSecurity = [
    "Log Out",
    "Close your account",
  ].obs;
  List get accountSecurity => _accountSecurity;
  set accountSecurity(List value) => _accountSecurity.value = value;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  PageListApiModel? pageListApiModel;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
  };

  Future pageListApi() async {
    isLoading = true;
    update();
    String url = Confing.baseurl + Confing.pagelist;
    try {
      var response = await http.get(
        Uri.parse(url),
        headers: userHeader,
      );
      debugPrint("============ Page List Api url ============= $url");
      debugPrint("========== Page List Api response ========== ${response.body}");
      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          pageListApiModel = pageListApiModelFromJson(response.body);
          update();
          if (pageListApiModel!.result == "true") {
            isLoading = false;
            update();
            return data;
          } else {
            showToastMessage("${pageListApiModel!.responseMsg}");
          }
        } else {
          showToastMessage("${data["ResponseMsg"]}");
          isLoading = false;
          update();
          return data;
        }
      } else {
        showToastMessage("Something went wrong!");
      }
    } catch (e) {
      debugPrint("============ Page List Api Error ============ $e");
    }
  }

  final _deleteAccountLoder = false.obs;
  get deleteAccountLoder => _deleteAccountLoder.value;
  set deleteAccountLoder(value) => _deleteAccountLoder.value = value;
  
  Future deleteAccountApi() async {
    deleteAccountLoder = true;
    update();
    Map body = {"uid": "${getData.read("userLogin")["id"]}"};
    String url = Confing.baseurl + Confing.accDelete;
    try {
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(name: "============= Delete Account Api url ==============", url);
      log(name: "============= Delete Account Api body =============", "$body");
      log(name: "=========== Delete Account Api response ===========", response.body);

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          final storage = GetStorage();
          storage.erase();
          themeColores.toggleTheme(dark: false);
          languageScreenController.updateLanguage(Locale('en', 'US'));
          themeColores.update();
          update();
          Get.offAllNamed(Routes.LOGIN_SCREEN);
          deleteAccountLoder = false;
          update();
          return data;
        } else {
          deleteAccountLoder = false;
          update();
          showToastMessage("${data["ResponseMsg"]}");
        }
      } else {
        deleteAccountLoder = false;
        update();
        showToastMessage("Something went wrong!");
      }
    } catch (e) {
      deleteAccountLoder = false;
      update();
      log(name: "============= Delete Account Api Error =============", "$e");
    }
  }

  profileListMenuTile({
    required String image,
    required String title,
    required VoidCallback onTap,
    Widget? child,
  }){
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border.fromBorderSide(BorderSide(color: ccInputBorder)),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              image,
              color: ccNavyText,
              height: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: ccNavyText,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          child ?? const Icon(
                Icons.arrow_forward_ios,
                color: ccNavyText,
                size: 20,
              ),
        ],
      ),
    );
  }
}
