import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/account_controllers/wallet_screen_controller.dart';
import 'package:carride/app/modules/controllers/post_controllers/trip_preview_screen_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    super.onInit();
  }

  WalletScreenController walletScreenController = Get.put(WalletScreenController());
  TripPreviewScreenController tripPreviewScreenController = Get.put(TripPreviewScreenController());

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
    int totalSeat = int.parse("${tripPreviewScreenController.tripDetailsApiModel!.tripData!.remainSeat!}");
    if (counter < totalSeat) {
      counter++;
      subTotal = basePrice * counter;
      totalAmount = subTotal + bookfee;
    }
    if (isUseWallet == true) {
      walletCalculation(false);
    }
    totalAmount = totalAmount + couponAmount;
    couponAmount = 0;
    couponCode = "";
    update();
  }

  void decrement() {
    if (counter > 1) {
      counter--;
      subTotal = basePrice * counter;
      totalAmount = subTotal + bookfee;
      if (isUseWallet == true) {
        walletCalculation(false);
      }
      totalAmount = totalAmount + couponAmount;
      couponAmount = 0;
      couponCode = "";
      update();
    }
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
