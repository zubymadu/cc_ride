import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/account_controllers/wallet_screen_controller.dart';
import 'package:carride/app/modules/controllers/post_controllers/trip_preview_screen_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class BookPricingController extends GetxController {

  @override
  void onInit() {
    walletScreenController.walletReportApi().then((value) {
      if (value["Result"] == "true") {
        totalWalletAmount = double.tryParse("${walletScreenController.walletReportApiModel!.wallet}") ?? 0;
        tempWallet = totalWalletAmount;
        update();
        debugPrint("------------ totalWalletAmount ----------- $totalWalletAmount");
      }
      final priceSet = tripPreviewScreenController.tripDetailsApiModel?.tripData?.seatPrice ?? "0";
      basePrice = double.tryParse(priceSet) ?? 0;
      bookfee = double.tryParse("${getData.read("booking_fee")}") ?? 0;
      debugPrint("------------ bookfee ----------- $bookfee");
      subTotal = basePrice * counter;
      totalAmount = subTotal + bookfee;
      update();
    });
    estimateFareApi();
    super.onInit();
  }

  final Map<String, String> _userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer ${getData.read('token') ?? ''}",
  };

  // Only rendered when the super-admin has switched pricing_model to
  // platform_computed — see book_pricing_view.dart. For driver_set, the
  // seat price above is already the real, authoritative fare; showing a
  // second computed number alongside it would just be confusing.
  final RxBool _hasEstimate = false.obs;
  bool get hasEstimate => _hasEstimate.value;
  set hasEstimate(bool value) => _hasEstimate.value = value;

  final RxDouble _estimatedFare = 0.0.obs;
  double get estimatedFare => _estimatedFare.value;
  set estimatedFare(double value) => _estimatedFare.value = value;

  Future<void> estimateFareApi({int retriesLeft = 6}) async {
    try {
      final trip = tripPreviewScreenController.tripDetailsApiModel?.tripData;
      if (trip?.originLat == null || trip?.originLong == null || trip?.destiLat == null || trip?.destiLong == null) {
        // tripPreviewScreenController's own fetch may still be in flight —
        // this controller has no tripId of its own to re-fetch with, so
        // giving up on the first check (as before) left hasEstimate stuck
        // at false whenever that request hadn't resolved yet. Retrying a
        // few times over ~3s covers the normal case without retrying forever.
        if (retriesLeft > 0) {
          await Future.delayed(const Duration(milliseconds: 500));
          return estimateFareApi(retriesLeft: retriesLeft - 1);
        }
        return;
      }
      final body = {
        "origin_lat": trip!.originLat,
        "origin_long": trip.originLong,
        "desti_lat": trip.destiLat,
        "desti_long": trip.destiLong,
      };
      final response = await http
          .post(Uri.parse(Confing.baseurl + Confing.estimateFare), body: jsonEncode(body), headers: _userHeader)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["Result"] == "true") {
        final model = data["data"]?["pricing_model"] ?? 'driver_set';
        estimatedFare = double.tryParse("${data["data"]?["estimated_fare"] ?? 0}") ?? 0;
        hasEstimate = model == 'platform_computed' && estimatedFare > 0;
        update();
      }
    } catch (e) {
      log(name: "=========== Estimate Fare error ===========", "$e");
    }
  }

  WalletScreenController walletScreenController = Get.put(WalletScreenController());
  // Reuse the instance populated by trip_preview_screen_view.dart's API call —
  // Get.put() here would replace it with a blank controller and wipe the data.
  TripPreviewScreenController tripPreviewScreenController =
      Get.isRegistered<TripPreviewScreenController>()
          ? Get.find<TripPreviewScreenController>()
          : Get.put(TripPreviewScreenController());

  final RxDouble _basePrice = 0.0.obs;
  double get basePrice => _basePrice.value;
  set basePrice(double value) => _basePrice.value = value;

  final RxInt _counter = 1.obs;
  int get counter => _counter.value;
  set counter(int value) => _counter.value = value;

  final RxDouble _bookfee = 0.0.obs;
  double get bookfee => _bookfee.value;
  set bookfee(double value) => _bookfee.value = value;

  void increment() {
    int totalSeat = int.tryParse(
          "${tripPreviewScreenController.tripDetailsApiModel?.tripData?.remainSeat ?? counter}",
        ) ??
        counter;
    if (counter < totalSeat) {
      counter++;
      _recalculateForNewSeatCount();
    }
  }

  void decrement() {
    if (counter > 1) {
      counter--;
      _recalculateForNewSeatCount();
    }
  }

  // Shared by increment/decrement — recomputes the bill for the new seat
  // count, re-applying the wallet allocation against the new total if wallet
  // pay is currently on (previously this called walletCalculation(false),
  // which also flips isUseWallet off — so adjusting seat count while wallet
  // pay was enabled silently disabled it without the user touching the toggle).
  void _recalculateForNewSeatCount() {
    if (isUseWallet) {
      // Undo the previous allocation so totalWalletAmount reflects the full
      // balance again before recomputing against the new total.
      totalWalletAmount = totalWalletAmount + useWalletAmount;
      useWalletAmount = 0;
    }
    subTotal = basePrice * counter;
    totalAmount = subTotal + bookfee;
    if (isUseWallet) {
      walletCalculation(true);
    }
    totalAmount = totalAmount + couponAmount;
    couponAmount = 0;
    couponCode = "";
    update();
  }

  // -------------------------------------------------------------------------------------------------------------------
  final RxDouble _totalAmount = 0.0.obs;
  double get totalAmount => _totalAmount.value;
  set totalAmount(double value) => _totalAmount.value = value;

  final RxDouble _subTotal = 0.0.obs;
  double get subTotal => _subTotal.value;
  set subTotal(double value) => _subTotal.value = value;

  final RxString _couponCode = "".obs;
  String get couponCode => _couponCode.value;
  set couponCode(String value) => _couponCode.value = value;
  
  final RxDouble _couponAmount = 0.0.obs;
  double get couponAmount => _couponAmount.value;
  set couponAmount(double value) => _couponAmount.value = value;

  couponButton(){
    if (isUseWallet == true) {
      walletCalculation(false);
      update();
    }
    Get.toNamed(
      Routes.COUPON_LIST,
      arguments: {
        "totalAmount": totalAmount + couponAmount,
        // "couponCode": couponCode,
        // "couponAmount": couponAmount,
      },
    );
  }

  // ------------------------- wallet -----------------------------
  final RxDouble _totalWalletAmount = 0.0.obs;
  double get totalWalletAmount => _totalWalletAmount.value;
  set totalWalletAmount(double value) => _totalWalletAmount.value = value;
  
  final RxBool _isUseWallet = false.obs;
  bool get isUseWallet => _isUseWallet.value;
  set isUseWallet(bool value) => _isUseWallet.value = value;
  
  final RxDouble _useWalletAmount = 0.0.obs;
  double get useWalletAmount => _useWalletAmount.value;
  set useWalletAmount(double value) => _useWalletAmount.value = value;
  
  final RxDouble _tempWallet = 0.0.obs;
  double get tempWallet => _tempWallet.value;
  set tempWallet(double value) => _tempWallet.value = value;
  
  walletCalculation(value) {
    if (value == true) {
      if (totalAmount > totalWalletAmount) {
        tempWallet = totalAmount - totalWalletAmount;
        useWalletAmount = totalAmount - tempWallet;
        totalWalletAmount = totalWalletAmount - useWalletAmount;
        totalAmount = tempWallet;
      } else {
        tempWallet = totalWalletAmount - totalAmount;
        useWalletAmount = totalWalletAmount - tempWallet;
        totalWalletAmount = totalWalletAmount - useWalletAmount;
        totalAmount = 0;
      }
      update();
      debugPrint("------------- temp Wallet Amount ------------ $tempWallet");
      debugPrint("------------- user wallet Amount ------------ $useWalletAmount");
      debugPrint("------------- cart Total Amount ------------- $totalAmount");
      debugPrint("------------ total Wallet Amount ------------ $totalWalletAmount");
    } else {
      isUseWallet = value;
      if (totalAmount > totalWalletAmount) {
        totalAmount = tempWallet + useWalletAmount;
      } else {
        totalAmount = useWalletAmount;
      }
      totalWalletAmount = totalWalletAmount + useWalletAmount;
      useWalletAmount = 0;
      update();
      debugPrint("------------- temp Wallet Amount ------5------ $tempWallet");
      debugPrint("------------- user wallet Amount ------5------ $useWalletAmount");
      debugPrint("------------- cart Total Amount -------5------ $totalAmount");
      debugPrint("------------ total Wallet Amount ------5------ $totalWalletAmount");
    }
  }

  billsummerititle({required String title, required String subtitle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: ccNavyText,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: ccSecondaryText,
            fontSize: 15,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}
