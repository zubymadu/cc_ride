import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/modules/models/payment_gateway_list_api_model.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class PaymentGatewayListController extends GetxController {
  PaymentGatewayListApiModel? paymentGatewayListApiModel;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
  };

  Future paymentGatewayListApi() async {
    String url = Confing.baseurl + Confing.paymentgateway;

    try {
      var response = await http.get(
        Uri.parse(url),
        headers: userHeader,
      );

      log(name: "============= Payment Gateway List api url ==============", url);
      log(name: "=========== Payment Gateway List api response ===========", response.body);

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        paymentGatewayListApiModel = paymentGatewayListApiModelFromJson(response.body);
        if (data["Result"] == "true") {
          if (paymentGatewayListApiModel!.result == "true") {
            isLoading = false;
            update();
            return data;
          } else {
            showToastMessage("${paymentGatewayListApiModel!.responseMsg}");
          }
        } else {
          showToastMessage("${data["ResponseMsg"]}");
        }
      } else {
        showToastMessage("Something went wrong!");
      }
    } catch (e) {
      log(name: "============= Payment Gateway List api Error =============", "$e");
    }
  }
}