// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/payment/payment_gateway_list_controller.dart';
import 'package:carride/app/modules/models/wallet_report_api_model.dart';
import 'package:carride/app/modules/payment_getway/input_format.dart';
import 'package:carride/app/modules/payment_getway/paymentcard.dart';
import 'package:carride/app/modules/payment_getway/razor_pay.dart';
import 'package:carride/app/modules/payment_getway/web_view.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/textfield/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WalletScreenController extends GetxController {

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        razorPayClass.initiateRazorPay(
          handlePaymentSuccess: handlePaymentSuccess,
          handlePaymentError: handlePaymentError,
          handleExternalWallet: handleExternalWallet,
        );
      } catch (e) {
        debugPrint("initiateRazorPay error (non-fatal): $e");
      }
      walletReportApi();
      paymentGatewayListController.paymentGatewayListApi();
    });
  }

  final RxString _paymentId = "0".obs;
  String get paymentId => _paymentId.value;
  set paymentId(String value) => _paymentId.value = value;
 
  final RxString _walletAount = "0".obs;
  String get walletAount => _walletAount.value;
  set walletAount(String value) => _walletAount.value = value;

  final RxBool _addWalletLodar = false.obs;
  bool get addWalletLodar => _addWalletLodar.value;
  set addWalletLodar(bool value) => _addWalletLodar.value = value;

  WalletReportApiModel? walletReportApiModel;
  
  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  Future walletReportApi() async {
    isLoading = true;
    update();
    Map body = {"uid": "${getData.read("userLogin")["id"]}"};

    try {
      String url = Confing.baseurl + Confing.walletreport;
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );
      log(name: "============ Wallet Report Api url =============", url);
      log(name: "============ Wallet Report Api body ============", "$body");
      log(name: "========== Wallet Report Api response ==========", response.body);
      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          walletReportApiModel = walletReportApiModelFromJson(response.body);
          update();
          if (walletReportApiModel!.result == "true") {
            isLoading = false;
            update();
            return data;
          } else {
            showToastMessage(walletReportApiModel!.responseMsg!);
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
      log(name: "============ Wallet Report Api Error ============", "$e");
    }
  }

  final RxBool _walletUpadtLoader = false.obs;
  bool get walletUpadtLoader => _walletUpadtLoader.value;
  set walletUpadtLoader(bool value) => _walletUpadtLoader.value = value;

  // The server verifies this reference against Paystack directly and credits
  // the amount Paystack confirms was paid — it no longer trusts a
  // client-declared amount. `reference` must be the Paystack transaction
  // reference (the `trxref`/`reference` query param on the callback URL).
  Future walletUpdateApi({required String reference}) async {
    Map body = {
      "payment_id": reference,
    };

    try {
      String url = Confing.baseurl + Confing.walletUp;

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(name: "============ Wallet Update Api url =============", url);
      log(name: "============ Wallet Update Api body ============", "$body");
      log(name: "========== Wallet Update Api response ==========", response.body);

      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          walletReportApi();
          Get.back();
          addWalletLodar = false;
          update();
          showToastMessage("${data["ResponseMsg"]}");
          return data;
        } else {
          showToastMessage("${data["ResponseMsg"]}");
          addWalletLodar = false;
          update();
          return data;
        }
      } else {
        showToastMessage("Something went wrong!");
      }
    } catch (e) {
      log(name: "============ Wallet Update Api Error ============", "$e");
    }
  }

// -------------------------- razorPay --------------------------
  RazorPayClass razorPayClass = RazorPayClass();

  void handlePaymentSuccess(PaymentSuccessResponse response) {
    // Razorpay has no matching backend verification in this build (only
    // Paystack does) — this call will be correctly rejected server-side
    // rather than crediting an unverified amount. Wire up Razorpay
    // verification server-side before re-enabling this path for real.
    if (response.paymentId != null) {
      walletUpdateApi(reference: response.paymentId!);
    }
    debugPrint("+++++++++++++++++++++++++++ walletAount : $walletAount");
    debugPrint("++++++++++++++++++++++++ transaction Id : ${response.paymentId}");
  }

  void handlePaymentError(PaymentFailureResponse response) {
    addWalletLodar = false;
    update();
    debugPrint("++++++++++++++++++++++++ Payment failed : $response");
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    addWalletLodar = false;
    update();
    debugPrint("++++++++++++++++++++++++ Payment wallet : $response");
  }

  PaymentGatewayListController paymentGatewayListController = Get.put(PaymentGatewayListController());

  webViewPaymentMethod({
    required String initialUrl,
    required String status1,
    required String status2,
    required String tId,
  }) {
    Get.to(() => PaymentWebVIew(
      initialUrl: initialUrl,
      navigationDelegate: (request) async {
        final uri = Uri.parse(request.url);
        debugPrint("************ URL *****:--- $initialUrl");
        debugPrint("************ Navigating to URL: ${request.url}");
        debugPrint("************ Parsed URI: $uri");
        debugPrint("************ 2435243254: ${uri.queryParameters[status1]}");
        debugPrint("************ queryParamiter: ${uri.queryParametersAll}");
        debugPrint("************ queryParamiter url: ${uri.queryParameters[tId]}");
        final status = uri.queryParameters[status1];
        debugPrint(" /*/*/*/*/*/*/*/*/*/*/*/*/*/ Status ---- $status");
        if (status == null) {
          debugPrint("No status parameter found.");
          walletUpadtLoader = false;
          update();
        } else {
          debugPrint("Status parameter: $status");
          if (status == status2) {
            debugPrint("Purchase successful.");
            final reference = uri.queryParameters[tId];
            if (reference == null || reference.isEmpty) {
              walletUpadtLoader = false;
              update();
              showToastMessage("Unable to confirm payment reference");
              return NavigationDecision.navigate;
            }
            walletUpdateApi(reference: reference);
            return NavigationDecision.navigate;
          } else {
            walletUpadtLoader = false;
            update();
            debugPrint("Purchase failed with status: $status.");
            Get.back();
            showToastMessage(status);
            return NavigationDecision.navigate;
          }
        }
        return NavigationDecision.navigate;
      },
    ));
  }

  // Form key
  final formKey = GlobalKey<FormState>();

  // Controllers
  final numberController = TextEditingController();

  // Payment Card model
  final paymentCard = PaymentCard();

  // Autovalidate mode (reactive)
  final Rx<AutovalidateMode> _autoValidateMode = AutovalidateMode.disabled.obs;
  AutovalidateMode get autoValidateMode => _autoValidateMode.value;
  set autoValidateMode(AutovalidateMode value) => _autoValidateMode.value = value;

  final card = PaymentCard();

  stripePaymentGetWay({required String totalAmt}) {
    return Get.bottomSheet(
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(20))),
      backgroundColor: ccSurface,
      isScrollControlled: true,
      Container(
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(),
        child: GetBuilder<WalletScreenController>(
          init: WalletScreenController(),
          initState: (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              walletUpadtLoader = false;
              update();
              String input = CardUtils.getCleanedNumber(numberController.text);
              CardType cardType = CardUtils.getCardTypeFrmNumber(input);
              paymentCard.type = cardType;
              update();
            });
          },
          builder: (_) {
            return Form(
              key: formKey,
              autovalidateMode: autoValidateMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Add Your Card information".tr,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: ccNavyText,
                    ),
                  ),
                  const SizedBox(height: 15),
                  customTextFormField(
                    hintText: "What number is written on card?".tr,
                    labelText: "Number".tr,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(19),
                      CardNumberInputFormatter(),
                    ],
                    controller: numberController,
                    onChanged: (val) {
                      CardType cardType = CardUtils.getCardTypeFrmNumber(val);
                      paymentCard.number = CardUtils.getCleanedNumber(val);
                      card.name = cardType.toString();
                      paymentCard.type = cardType;
                      update();
                    },
                    prefixIcon: SizedBox(
                      height: 10,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                        child: CardUtils.getCardIcon(paymentCard.type),
                      ),
                    ),
                    validator: CardUtils.validateCardNum,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: customTextFormField(
                          hintText: "Number behind the card".tr,
                          labelText: "CVV".tr,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          validator: CardUtils.validateCVV,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            paymentCard.cvv = int.parse(value);
                          },
                          prefixIcon: Container(
                            height: 10,
                            width: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            child: Image.asset(
                              "assets/image/card_cvv.png",
                              color: ccPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: customTextFormField(
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            CardMonthInputFormatter()
                          ],
                          prefixIcon: Container(
                            height: 10,
                            width: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            child: SvgPicture.asset(
                              "assets/image/svg/calendar.svg",
                              color: ccPrimary,
                            ),
                          ),
                          hintText: "MM/YY".tr,
                          labelText: "Expiry Date".tr,
                          validator: CardUtils.validateDate,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            List<int> expiryDate = CardUtils.getExpiryDate(value);
                            if (expiryDate.length >= 2) {
                              paymentCard.month = expiryDate[0];
                              paymentCard.year = expiryDate[1];
                            } else {
                              paymentCard.month = 0;
                              paymentCard.year = 0;
                            }
                            update();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  walletUpadtLoader
                    ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: ccPrimary)))
                    : CCButton(
                        label: "Pay Now".tr,
                        onPressed: () {
                          debugPrint("------- number -------- ${paymentCard.number}");
                          debugPrint("-------- cvv ---------- ${paymentCard.cvv}");
                          debugPrint("------- month --------- ${paymentCard.month}");
                          debugPrint("-------- year --------- ${paymentCard.year}");
                          if (formKey.currentState?.validate() ?? false) {
                            if (walletUpadtLoader == false) {
                              addWalletLodar = true;
                              walletUpadtLoader = true;
                              update();
                              Get.back();
                              webViewPaymentMethod(
                                initialUrl: "${Confing.imageurl + Confing.stripe}name=${getData.read("userLogin")["name"]}&email=${getData.read("userLogin")["email"]}&cardno=${paymentCard.number}&cvc=${paymentCard.cvv}&amt=$totalAmt&mm=${paymentCard.month}&yyyy=${paymentCard.year}",
                                status1: "status",
                                status2: "success",
                                tId: "Transaction_id",
                              );
                            }
                          }
                        },
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
