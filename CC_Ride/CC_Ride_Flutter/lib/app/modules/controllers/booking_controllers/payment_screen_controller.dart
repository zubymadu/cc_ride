// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/booking_controllers/book_pricing_controller.dart';
import 'package:carride/app/modules/controllers/payment/payment_gateway_list_controller.dart';
import 'package:carride/app/modules/controllers/post_controllers/trip_preview_screen_controller.dart';
import 'package:carride/app/modules/payment_getway/input_format.dart';
import 'package:carride/app/modules/payment_getway/paymentcard.dart';
import 'package:carride/app/modules/payment_getway/razor_pay.dart';
import 'package:carride/app/modules/payment_getway/web_view.dart';
import 'package:carride/app/routes/app_pages.dart';
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

class PaymentScreenController extends GetxController {

  // ── Corporate booking intercept ─────────────────────────────────────────
  // True when the user belongs to a company (used to decide whether to show
  // the "pay via organisation" option at all — kept for backward compat).
  bool get isCorpEmployee =>
      (getData.read('companyId') as String? ?? '').isNotEmpty;

  // True only when the user is BOTH a member of an active company
  // membership (companyId is only ever populated server-side for active
  // memberships — see legacyLogin) AND their own identity has been verified.
  // This is what actually gates whether the "pay via organisation" option is
  // tappable; isCorpEmployee alone just controls visibility of the row.
  bool get isAuthorizedForCorpPayment {
    if (!isCorpEmployee) return false;
    final user = getData.read('userLogin');
    return user != null && '${user['is_mobile_verify']}' == '1';
  }

  // Whether the employee wants to charge this ride to their company.
  final RxBool useCorpAccount = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Default to corporate only when actually authorized to use it —
    // otherwise the toggle would start "on" for a row the user can't tap.
    if (isAuthorizedForCorpPayment) useCorpAccount.value = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading = false;
      razorPayClass.initiateRazorPay(
        handlePaymentSuccess: handlePaymentSuccess,
        handlePaymentError: handlePaymentError,
        handleExternalWallet: handleExternalWallet,
      );
      paymentGatewayListController.paymentGatewayListApi();
      update();
    });
  }

  BookPricingController bookPricingController = Get.put(BookPricingController());
  PaymentGatewayListController paymentGatewayListController = Get.put(PaymentGatewayListController());
  TripPreviewScreenController tripPreviewScreenController = Get.put(TripPreviewScreenController());

  TextEditingController messageController = TextEditingController();

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  final RxString _requestId = "0".obs;
  String get requestId => _requestId.value;
  set requestId(String value) => _requestId.value = value;

  bookSeat({required String transactionID}){
    debugPrint("------------ tripId ----------- ${tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripId}");
    debugPrint("----------- counter ----------- ${bookPricingController.counter}");
    debugPrint("------------ total ------------ ${bookPricingController.subTotal}");
    debugPrint("---------- totalAmount -------- ${bookPricingController.totalAmount}");
    debugPrint("--------- couponAmount -------- ${bookPricingController.couponAmount}");
    debugPrint("------- useWalletAmount ------- ${bookPricingController.useWalletAmount}");
    debugPrint("----------- paymentId --------- $paymentId");
    debugPrint("--------- transactionId ------- $transactionID");
    isLoading = true;
    update();
    bookSeatApi(
      tripId: "${tripPreviewScreenController.tripDetailsApiModel!.tripData!.tripId}",
      totalSeat: "${bookPricingController.counter}",
      bookMethod: "Manual",
      subtotal: "${bookPricingController.subTotal}",
      totalAmount: "${bookPricingController.totalAmount}",
      couAmt: "${bookPricingController.couponAmount}",
      wallAmt: "${bookPricingController.useWalletAmount}",
      paymentId: paymentId == "0" ? "5" : paymentId,
      transactionId: transactionID,
      driverAlertInfo: messageController.text,
      bookingFees: "${bookPricingController.bookfee}",
      requestId: requestId,
    );
  }

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
  };

  Future bookSeatApi({
    required String tripId,
    required String totalSeat,
    required String bookMethod,
    required String subtotal,
    required String totalAmount,
    required String couAmt,
    required String wallAmt,
    required String paymentId,
    required String driverAlertInfo,
    required String transactionId,
    required String bookingFees,
    required String requestId,
  }) async {
     Map body = {
      "uid": getData.read("userLogin")["id"],
      "book_uid": getData.read("userLogin")["id"],
      "trip_id": tripId,
      "total_seat": totalSeat,
      "book_method": bookMethod,
      "subtotal": subtotal,
      "total_amount": totalAmount,
      "cou_amt": couAmt,
      "wall_amt": wallAmt,
      "payment_id": paymentId,
      "driver_alert_info" : driverAlertInfo,
      "transaction_id": transactionId,
      "booking_fees": bookingFees,
      "request_id" : requestId,
    };

    try {
      String url = Confing.baseurl + Confing.bookSeat;
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log("============== Book Seat Api url =============== $url");
      log("============== Book Seat Api body ============== $body");
      log("============ Book Seat Api response ============ ${response.body}");

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          Get.back();
          showOrderSuccess();
          isLoading = false;
          update();
          return data;
        } else {
          showToastMessage("${data["ResponseMsg"]}");
        }
      } else {
        showToastMessage("Something went wrong!");
      }
    } catch (e) {
      log("============== Book Seat Api Error ============== $e");
    } finally {
      isLoading = false;
      update();
    }
  }

// ----------------------- Payment ------------------------
  final RxString _paymentId = "0".obs;
  String get paymentId => _paymentId.value;
  set paymentId(String value) => _paymentId.value = value;

// -------------------------- razorPay --------------------------
  RazorPayClass razorPayClass = RazorPayClass();

  void handlePaymentSuccess(PaymentSuccessResponse response) {
    bookSeat(transactionID: "${response.paymentId}");
    debugPrint("++++++++++++++++++++++++ transaction Id : ${response.paymentId}");
  }

  void handlePaymentError(PaymentFailureResponse response) {
    isLoading = false;
    update();
    debugPrint("++++++++++++++++++++++++ Payment failed : $response");
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    isLoading = false;
    update();
    debugPrint("++++++++++++++++++++++++ Payment wallet : $response");
  }

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
        } else {
          debugPrint("Status parameter: $status");
          if (status == status2) {
            debugPrint("Purchase successful.");
            bookSeat(transactionID: "${uri.queryParameters[tId]}");
            // bookSeat(transactionID: "${response.paymentId}");
            return NavigationDecision.prevent;
          } else {
            isLoading = false;
            update();
            debugPrint("Purchase failed with status: $status.");
            Get.back();
            showToastMessage(status);
            return NavigationDecision.prevent;
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
        padding: const EdgeInsets.all(16),
        child: GetBuilder<PaymentScreenController>(
          init: PaymentScreenController(),
          initState: (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              isLoading = false;
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
                  SizedBox(height: 15),
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
                        padding: EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 6,
                        ),
                        child: CardUtils.getCardIcon(paymentCard.type),
                      ),
                    ),
                    validator: CardUtils.validateCardNum,
                  ),
                  SizedBox(height: 10),
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
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            child: Image.asset(
                              "assets/image/card_cvv.png",
                              color: ccPrimary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
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
                            margin: EdgeInsets.symmetric(horizontal: 10),
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
                  SizedBox(height: 10),
                  isLoading
                    ? const SizedBox(
                        height: 52,
                        child: Center(child: CircularProgressIndicator(color: ccPrimary)),
                      )
                    : SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            debugPrint("------- number -------- ${paymentCard.number}");
                            debugPrint("-------- cvv ---------- ${paymentCard.cvv}");
                            debugPrint("------- month --------- ${paymentCard.month}");
                            debugPrint("-------- year --------- ${paymentCard.year}");
                            if (formKey.currentState?.validate() ?? false) {
                              if (isLoading == false) {
                                isLoading = true;
                                update();
                                webViewPaymentMethod(
                                  initialUrl: "${Confing.imageurl + Confing.stripe}name=${getData.read("userLogin")["name"]}&email=${getData.read("userLogin")["email"]}&cardno=${paymentCard.number}&cvc=${paymentCard.cvv}&amt=$totalAmt&mm=${paymentCard.month}&yyyy=${paymentCard.year}",
                                  status1: "status",
                                  status2: "success",
                                  tId: "Transaction_id",
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ccPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(CCRadius.btn),
                            ),
                          ),
                          child: Text("Pay Now".tr,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            )),
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void showOrderSuccess() {
    Get.bottomSheet(
      backgroundColor: ccSurface,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(CCRadius.sheet))),
      PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN);
            Get.toNamed(Routes.MY_BOOKING_SCREEN);
          } else {
            debugPrint('Popped with result: $result');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset("assets/image/svg/success.svg", fit: BoxFit.contain),
              const SizedBox(height: 16),
              const Text(
                "Booking Confirmed",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: ccNavyText,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: Get.width * 0.8,
                child: const Text(
                  "Your booking has been confirmed. Our Team will reach to you soon.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: ccSecondaryText,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: ccNavyText,
                        side: const BorderSide(color: ccInputBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(CCRadius.btn)),
                      ),
                      child: const Text("Back To Home",
                          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN);
                        Get.toNamed(Routes.MY_BOOKING_SCREEN);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: ccPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(CCRadius.btn)),
                      ),
                      child: const Text("View Bookings",
                          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
