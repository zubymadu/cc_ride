import 'dart:convert';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/models/payout_history_api_model.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class PayoutHistoryScreenController extends GetxController {


  @override
  void onInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      payoutHistoryApi();
    });
    super.onInit();
  }

  PayoutHistoryApiModel? payoutHistoryApiModel;

  final _isLoading = true.obs;
  get isLoading => _isLoading.value;
  set isLoading(value) => _isLoading.value = value;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
  };

  Future payoutHistoryApi() async {
    isLoading = true;
    update();
    Map body = {"uid": "${getData.read("userLogin")["id"]}"};

    try {
      String url = Confing.baseurl + Confing.payoutList;

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      debugPrint("============= Payout History Api url ============== $url");
      debugPrint("============= Payout History Api body ============= $body");
      debugPrint("=========== Payout History Api response =========== ${response.body}");

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          payoutHistoryApiModel = payoutHistoryApiModelFromJson(response.body);
          update();
          if (payoutHistoryApiModel!.result == "true") {
            isLoading = false;
            update();
            return data;
          } else {
            showToastMessage("${payoutHistoryApiModel!.responseMsg}");
            return data;
          }
        } else {
          showToastMessage("${data["ResponseMsg"]}");
          return data;
        }
      } else {
        showToastMessage("Somthing went wrong!.....");
      }
    } catch (e) {
      debugPrint("============= Payout History Api Error =============  $e");
    }
  }

  paymentRecetpitBottomSheet(String proof) {
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        decoration: BoxDecoration(color: ccSurface,),
        child: Column(
          children: [
            SizedBox(height: 45),
            Expanded(
              child: Scaffold(
                backgroundColor: ccSurface,
                appBar: AppBar(backgroundColor: ccSurface),
                body: Center(
                  child: FadeInImage.assetNetwork(
                    placeholder: "assets/image/ezgif.com-crop.gif",
                    image: "${Confing.imageurl}$proof",
                    imageErrorBuilder: (context, error, stackTrace) => Image.asset("assets/image/ezgif.com-crop.gif", fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}