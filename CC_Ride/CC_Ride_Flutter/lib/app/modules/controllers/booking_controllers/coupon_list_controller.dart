import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/modules/controllers/booking_controllers/book_pricing_controller.dart';
import 'package:carride/app/modules/models/coupon_list_api_model.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:http/http.dart' as http;

class CouponListController extends GetxController {

  BookPricingController bookPricingController = Get.put(BookPricingController());

  @override
  void onInit() {
    super.onInit();
    couponListApi().then((value) {
      if (value["Result"] == "true") {
        isCouponCheckLoading = List.filled(couponListApiModel!.couponlist!.length, false);
      } 
    });
    cartTotalAmount = Get.arguments["totalAmount"];
    // couponCode = Get.arguments["couponCode"];
    // couponAmount = Get.arguments["couponAmount"];
    update();
    debugPrint("----------- totap Price --------- ${Get.arguments}");
    debugPrint("--------- cartTotalAmount ------- $cartTotalAmount");
  }

  // final RxString _couponCode = "".obs;
  // String get couponCode => _couponCode.value;
  // set couponCode(String value) => _couponCode.value = value;
  
  // final RxDouble _couponAmount = 0.0.obs;
  // double get couponAmount => _couponAmount.value;
  // set couponAmount(double value) => _couponAmount.value = value;

  final RxDouble _cartTotalAmount = 0.0.obs;
  double get cartTotalAmount => _cartTotalAmount.value;
  set cartTotalAmount(double value) => _cartTotalAmount.value = value;

  CouponListApiModel? couponListApiModel;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;
  
  final RxList _isCouponCheckLoading = [].obs;
  List get isCouponCheckLoading => _isCouponCheckLoading;
  set isCouponCheckLoading(List value) => _isCouponCheckLoading.value = value;
  
  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  Future couponListApi() async {
    Map body = {
      "uid": int.parse("${getData.read("userLogin")["id"]}"),
    };

    try {
      String url = Confing.baseurl + Confing.couponlist;
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log("============== Coupon List Api url =============== $url");
      log("============== Coupon List Api body ============== $body");
      log("============ Coupon List Api response ============ ${response.body}");

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        couponListApiModel = couponListApiModelFromJson(response.body);
        if (data["Result"] == "true") {
          if (couponListApiModel!.result == "true") {
            isLoading = false;
            update();
            return data;
          } else {
            showToastMessage("${couponListApiModel!.responseMsg}");
          }
        } else {
          showToastMessage("${data["ResponseMsg"]}");
        }
      } else {
        showToastMessage("Something went wrong!");
      }
    } catch (e) {
      log("============== Coupon List Api Error ============== $e");
    }
  }

  Future couponCheckApi({required int cid}) async {
    Map body = {
      "uid": int.parse("${getData.read("userLogin")["id"]}"),
      "cid": cid,
    };

    try {
      String url = Confing.baseurl + Confing.checkcoupon;
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log("============== Coupon Check Api url =============== $url");
      log("============== Coupon Check Api body ============== $body");
      log("============ Coupon Check Api response ============ ${response.body}");

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          update();
          return data;
        } else {
          showToastMessage("${data["ResponseMsg"]}");
        }
      } else {
        showToastMessage("Something went wrong!");
      }
    } catch (e) {
      log("============== Coupon Check Api Error ============== $e");
    }
  }

  couponText({required String title, required String subtitle, Color? subTextColor}){
    return RichText(
      text: TextSpan(
        text: title,
        style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: ccNavyText),
        children: [
          const TextSpan(text: " : "),
          TextSpan(
            text: subtitle,
            style: TextStyle(
              color: subTextColor ?? ccPrimary,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
