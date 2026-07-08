// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/models/refer_and_earn_api_model.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

class ReferAndEarnScreenController extends GetxController {

  @override
  void onInit() {
    super.onInit();
    referAndEarnApi();
    getPackage();
  }

  PackageInfo? packageInfo;
  String? appName;
  String? packageName;

  void getPackage() async {
    packageInfo = await PackageInfo.fromPlatform();
    appName = packageInfo!.appName;
    packageName = packageInfo!.packageName;
    debugPrint("--------- packge Info --------- $packageInfo");
    debugPrint("----------- appName --------- $appName");
    debugPrint("--------- packageName --------- $packageName");
  }

  ReferAndEarnApiModel? referAndEarnApiModel;
  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
  };

  Future referAndEarnApi() async {
    Map body = {"uid": "${getData.read("userLogin")["id"]}"};
    String url = Confing.baseurl + Confing.referdata;
    try {
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );
      log(name: "============= Refer And Earn Api url ==============", url);
      log(name: "============= Refer And Earn Api body =============", "$body");
      log(name: "=========== Refer And Earn Api response ===========", response.body);
      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          referAndEarnApiModel = referAndEarnApiModelFromJson(response.body);
          if (referAndEarnApiModel!.result == "true") {
            isLoading = false;
            update();
            return data;
          } else {
            showToastMessage("${referAndEarnApiModel!.responseMsg}");
          }
        } else {
          showToastMessage("${data["ResponseMsg"]}");
        }
      } else {
        showToastMessage("Something went wrong!");
      }
    } catch (e) {
      log(name: "============= Refer And Earn Api Error =============", "$e");
    }
  }

  customText({required String text}){
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Image.asset(
          "assets/image/lovef.png",
          height: 28,
          width: 28,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: ccNavyText,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> share() async {
    debugPrint("============ App Name ============ $appName");
    debugPrint("========== PackageName =========== $packageName");

    final String text =
        'Hey! Now use our app to share with your family or friends. '
        'User will get wallet amount on your 1st successful transaction. '
        'Enter my referral code & Enjoy your shopping !!!';

    final String linkUrl = 'https://play.google.com/store/apps/details?id=$packageName';

    await Share.share(
      '$text\n$linkUrl',
      subject: appName,
    );
  }
}
