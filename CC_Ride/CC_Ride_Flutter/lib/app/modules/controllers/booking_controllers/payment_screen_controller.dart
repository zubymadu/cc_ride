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
  // Whether the employee wants to charge this ride to their company.
  final RxBool useCorpAccount = false.obs;

  // ── Multi-company wallets ───────────────────────────────────────────────
  // A rider can be an active employee at more than one company at once —
  // each shows up as its own selectable "card" alongside personal payment
  // methods below. `selectedCompanyId` null means "not paying on a company
  // account"; a non-null value is the id of the card currently picked and is
  // what CORPORATE_BOOKING_CONFIRM reads (via a temporary override of the
  // 'companyId' key that flow already keys off of).
  final RxList<Map<String, dynamic>> companyWallets = <Map<String, dynamic>>[].obs;
  final RxnString selectedCompanyId = RxnString();
  final RxBool isLoadingWallets = false.obs;

  // Company ids the rider has an outstanding (pending) wallet-access request
  // for, and the id currently mid-submit — drives the "Request access" /
  // "Request pending" state on a disabled wallet card. A card only ever
  // reaches "disabled" here because wallet_access_enabled is false (the
  // admin hasn't granted it at all); a wallet that's enabled but merely
  // outside its allowed hours is a separate, non-requestable state (nothing
  // to ask for — it'll just work again inside the window).
  final RxSet<String> pendingWalletAccessRequests = <String>{}.obs;
  final RxnString requestingAccessFor = RxnString();

  @override
  void onInit() {
    super.onInit();
    // useCorpAccount/selectedCompanyId are now only ever set together, by
    // selectCompanyWallet — driven by the real backend-confirmed wallet
    // list (fetchCompanyWalletsApi, called below), not this old
    // company-membership-only proxy. Auto-selection of a single usable
    // wallet already happens inside fetchCompanyWalletsApi.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading = false;
      razorPayClass.initiateRazorPay(
        handlePaymentSuccess: handlePaymentSuccess,
        handlePaymentError: handlePaymentError,
        handleExternalWallet: handleExternalWallet,
      );
      paymentGatewayListController.paymentGatewayListApi();
      fetchCompanyWalletsApi();
      update();
    });
  }

  Future<void> fetchCompanyWalletsApi() async {
    isLoadingWallets.value = true;
    try {
      final response = await http
          .get(Uri.parse(Confing.baseurl + Confing.companyWallets), headers: userHeader)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["Result"] == "true") {
        final list = (data["data"] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        companyWallets.assignAll(list);
        // Pre-select the single wallet that's actually usable right now, if
        // there's exactly one — mirrors the old single-company auto-on
        // default without guessing when a rider has several.
        final usable = list.where((w) => w["wallet_available_now"] == true).toList();
        if (usable.length == 1) {
          selectCompanyWallet("${usable.first["company_id"]}");
        }
        fetchPendingAccessRequests();
      }
    } catch (e) {
      log(name: "=========== fetch company wallets error ===========", "$e");
    } finally {
      isLoadingWallets.value = false;
      update();
    }
  }

  Future<void> fetchPendingAccessRequests() async {
    final notEnabled = companyWallets.where((w) => w["wallet_access_enabled"] != true);
    for (final w in notEnabled) {
      final companyId = "${w["company_id"]}";
      try {
        final response = await http
            .get(Uri.parse('${Confing.baseurl}${Confing.corporateAccessRequestsMine}?company_id=$companyId'), headers: userHeader)
            .timeout(const Duration(seconds: 15));
        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data["Result"] == "true") {
          final requests = (data["data"] as List? ?? []);
          final hasPending = requests.any((r) => r["request_type"] == "wallet_payment" && r["status"] == "pending");
          if (hasPending) pendingWalletAccessRequests.add(companyId);
        }
      } catch (e) {
        log(name: "=========== fetch access requests error ===========", "$e");
      }
    }
    update();
  }

  Future<void> requestWalletAccess(String companyId) async {
    requestingAccessFor.value = companyId;
    update();
    try {
      final response = await http
          .post(
            Uri.parse(Confing.baseurl + Confing.corporateAccessRequests),
            body: jsonEncode({"company_id": companyId, "request_type": "wallet_payment"}),
            headers: userHeader,
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["Result"] == "true") {
        pendingWalletAccessRequests.add(companyId);
        showToastMessage("${data["ResponseMsg"] ?? "Request sent to your company admin"}");
      } else {
        showToastMessage("${data["ResponseMsg"] ?? "Could not send request"}");
      }
    } catch (e) {
      log(name: "=========== request wallet access error ===========", "$e");
      showToastMessage("Could not send request — check your connection");
    } finally {
      requestingAccessFor.value = null;
      update();
    }
  }

  void selectCompanyWallet(String? companyId) {
    if (selectedCompanyId.value == companyId) {
      // Tapping the already-selected card deselects it — back to personal
      // payment methods.
      selectedCompanyId.value = null;
      useCorpAccount.value = false;
      return;
    }
    selectedCompanyId.value = companyId;
    useCorpAccount.value = companyId != null;
    if (companyId != null) {
      // CORPORATE_BOOKING_CONFIRM and the whole corporate-controller layer
      // read a single static 'companyId'/'companyName' pair out of local
      // storage rather than taking one as a navigation argument — override
      // it here to whichever card the rider picked for this booking.
      Map<String, dynamic>? wallet;
      for (final w in companyWallets) {
        if ("${w["company_id"]}" == companyId) { wallet = w; break; }
      }
      getData.write('companyId', companyId);
      getData.write('companyName', wallet?["company_name"] ?? 'Company');
      bookPricingController.walletCalculation(false);
    }
    update();
  }

  BookPricingController bookPricingController = Get.put(BookPricingController());
  PaymentGatewayListController paymentGatewayListController = Get.put(PaymentGatewayListController());
  // Reuse the instance populated by trip_preview_screen_view.dart's API call —
  // Get.put() here would replace it with a blank controller and wipe the data.
  TripPreviewScreenController tripPreviewScreenController =
      Get.isRegistered<TripPreviewScreenController>()
          ? Get.find<TripPreviewScreenController>()
          : Get.put(TripPreviewScreenController());

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
      couponCode: bookPricingController.couponCode,
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
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  Future bookSeatApi({
    required String tripId,
    required String totalSeat,
    required String bookMethod,
    required String subtotal,
    required String totalAmount,
    required String couAmt,
    String couponCode = '',
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
      "coupon_code": couponCode,
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
          showOrderSuccess(waitlisted: data["waitlisted"] == true);
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

  void showOrderSuccess({bool waitlisted = false}) {
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
              Text(
                waitlisted ? "Joined Waitlist" : "Booking Confirmed",
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: ccNavyText,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: Get.width * 0.8,
                child: Text(
                  waitlisted
                      ? "This route is fully booked. You've been added to the waitlist and will be notified if a seat opens up."
                      : "Your booking has been confirmed. Our Team will reach to you soon.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
