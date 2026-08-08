// ignore_for_file: deprecated_member_use

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/account_controllers/wallet_screen_controller.dart';
import 'package:carride/app/modules/controllers/payment/flutter_wave_api_controller.dart';
import 'package:carride/app/modules/controllers/payment/pay_stack_api_controller.dart';
import 'package:carride/app/modules/payment_getway/paypal/src/screens/paypal_screen.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

Future addWalletPaymentSheet() {
  WalletScreenController walletScreenController =
      Get.put(WalletScreenController());
  TextEditingController walletAmountController = TextEditingController();
  PayStackApiController payStackApiController =
      Get.put(PayStackApiController());
  FlutterWaveApiController flutterWaveApiController =
      Get.put(FlutterWaveApiController());
  int paymentIndex = -1;
  return Get.bottomSheet(
    isScrollControlled: true,
    backgroundColor: ccSurface,
    shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(CCRadius.sheet))),
    GetBuilder<WalletScreenController>(
      init: WalletScreenController(),
      builder: (_) {
        return Container(
          constraints: BoxConstraints(maxHeight: Get.height / 1.2),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Wallet Balance'.tr,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: ccNavyText,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: walletAmountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: ccNavyText,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter Amount'.tr,
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    color: ccSecondaryText,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SvgPicture.asset(
                      'assets/image/svg/Wallet.svg',
                      color: ccSecondaryText,
                    ),
                  ),
                  filled: true,
                  fillColor: ccBackground,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CCRadius.input),
                    borderSide: const BorderSide(color: ccInputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CCRadius.input),
                    borderSide: const BorderSide(color: ccInputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CCRadius.input),
                    borderSide:
                        const BorderSide(color: ccPrimary, width: 1.5),
                  ),
                ),
                onChanged: (value) {
                  walletScreenController.walletAount = value;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Select Payment Method'.tr,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: ccNavyText,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  itemCount: walletScreenController.paymentGatewayListController
                          .paymentGatewayListApiModel?.paymentdata?.length ??
                      0,
                  physics: const BouncingScrollPhysics(),
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (context, index) => walletScreenController
                              .paymentGatewayListController
                              .paymentGatewayListApiModel!
                              .paymentdata![index]
                              .id ==
                          '16'
                      ? const SizedBox()
                      : const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    var data = walletScreenController
                        .paymentGatewayListController
                        .paymentGatewayListApiModel!
                        .paymentdata![index];
                    return data.id == '16'
                        ? const SizedBox()
                        : InkWell(
                            onTap: () {
                              if (walletAmountController.text.isNotEmpty) {
                                paymentIndex = index;
                                walletScreenController.paymentId = '${data.id}';
                                walletScreenController.update();
                              } else {
                                showToastMessage(
                                    'Please enter the wallet amount'.tr);
                              }
                            },
                            borderRadius:
                                BorderRadius.circular(CCRadius.card),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: walletScreenController.paymentId ==
                                          '${data.id}'
                                      ? ccPrimary
                                      : ccInputBorder,
                                  width: walletScreenController.paymentId ==
                                          '${data.id}'
                                      ? 2
                                      : 1,
                                ),
                                borderRadius:
                                    BorderRadius.circular(CCRadius.card),
                                color: walletScreenController.paymentId ==
                                        '${data.id}'
                                    ? ccIceBlue
                                    : ccSurface,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: ccInputBorder),
                                      borderRadius:
                                          BorderRadius.circular(12.5),
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      child: FadeInImage.assetNetwork(
                                        placeholder:
                                            'assets/image/ezgif.com-crop.gif',
                                        width: 60,
                                        height: 60,
                                        placeholderFit: BoxFit.cover,
                                        fit: BoxFit.cover,
                                        image:
                                            '${Confing.imageurl}${data.img}',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${data.title}',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w700,
                                            color: ccNavyText,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${data.subtitle}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                            color: ccSecondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Radio<bool>(
                                    activeColor: ccPrimary,
                                    value: true,
                                    groupValue:
                                        walletScreenController.paymentId ==
                                            '${data.id}',
                                    onChanged: (value) {
                                      if (walletAmountController
                                          .text.isNotEmpty) {
                                        paymentIndex = index;
                                        walletScreenController.paymentId =
                                            '${data.id}';
                                        walletScreenController.update();
                                      } else {
                                        showToastMessage(
                                            'Please enter the wallet amount'
                                                .tr);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                  },
                ),
              ),
              if (walletScreenController.paymentId != '0' &&
                  walletAmountController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                walletScreenController.addWalletLodar
                    ? const SizedBox(
                        height: 52,
                        child: Center(
                            child: CircularProgressIndicator(
                                color: ccPrimary)))
                    : SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            if (walletAmountController.text.isNotEmpty) {
                              if (walletScreenController.paymentId != '') {
                                if (walletScreenController.addWalletLodar ==
                                    false) {
                                  walletScreenController.addWalletLodar = true;
                                  walletScreenController.update();
                                  Get.back();
                                  final selectedGateway = walletScreenController
                                      .paymentGatewayListController
                                      .paymentGatewayListApiModel!
                                      .paymentdata![paymentIndex]
                                      .gatewayType;
                                  if (selectedGateway == 'paystack') {
                                    payStackApiController
                                        .payStackApi(
                                            email:
                                                '${getData.read("userLogin")["email"]}',
                                            amount: walletAmountController.text)
                                        .then((value) {
                                      walletScreenController.addWalletLodar = false;
                                      walletScreenController.update();
                                      if (value != null &&
                                          value['status'] == true &&
                                          value['data'] != null &&
                                          value['data']['authorization_url'] != null) {
                                        walletScreenController
                                            .webViewPaymentMethod(
                                          initialUrl:
                                              '${value["data"]["authorization_url"]}',
                                          status1: 'status',
                                          status2: 'success',
                                          tId: 'trxref',
                                        );
                                      } else {
                                        showToastMessage(
                                            '${value?["message"] ?? "Unable to start Paystack payment"}');
                                      }
                                    }).catchError((e) {
                                      walletScreenController.addWalletLodar = false;
                                      walletScreenController.update();
                                      showToastMessage('Unable to start Paystack payment');
                                    });
                                  } else if (selectedGateway == 'flutterwave') {
                                    flutterWaveApiController
                                        .flutterWaveApi(
                                            email:
                                                '${getData.read("userLogin")["email"]}',
                                            amount: walletAmountController.text)
                                        .then((value) {
                                      walletScreenController.addWalletLodar = false;
                                      walletScreenController.update();
                                      if (value != null &&
                                          value['status'] == true &&
                                          value['data'] != null &&
                                          value['data']['authorization_url'] != null) {
                                        walletScreenController
                                            .webViewPaymentMethod(
                                          initialUrl:
                                              '${value["data"]["authorization_url"]}',
                                          status1: 'status',
                                          status2: 'successful',
                                          tId: 'transaction_id',
                                        );
                                      } else {
                                        showToastMessage(
                                            '${value?["message"] ?? "Unable to start Flutterwave payment"}');
                                      }
                                    }).catchError((e) {
                                      walletScreenController.addWalletLodar = false;
                                      walletScreenController.update();
                                      showToastMessage('Unable to start Flutterwave payment');
                                    });
                                  } else if (walletScreenController.paymentId ==
                                      '3') {
                                    List ids = walletScreenController
                                        .paymentGatewayListController
                                        .paymentGatewayListApiModel!
                                        .paymentdata![paymentIndex]
                                        .attributes
                                        .toString()
                                        .split(',');
                                    paypalPayment(
                                      function: (e) {
                                        // No PayPal backend verification exists in
                                        // this build (only Paystack does) — the
                                        // server will correctly reject this rather
                                        // than credit an unverified amount.
                                        final reference = '${e['paymentId']}';
                                        walletScreenController
                                            .walletUpdateApi(reference: reference);
                                      },
                                      amt: walletAmountController.text,
                                      clientId: ids[0],
                                      secretKey: ids[1],
                                    );
                                  } else if (walletScreenController.paymentId ==
                                      '4') {
                                    walletScreenController.addWalletLodar =
                                        false;
                                    walletScreenController.update();
                                    walletScreenController.stripePaymentGetWay(
                                        totalAmt: walletAmountController.text);
                                  } else if (walletScreenController.paymentId ==
                                      '6') {
                                    payStackApiController
                                        .payStackApi(
                                            email:
                                                '${getData.read("userLogin")["email"]}',
                                            amount: walletAmountController.text)
                                        .then((value) {
                                      // addWalletLodar was set true above and
                                      // never reset on this path before —
                                      // when Paystack failed to initialize
                                      // (e.g. no key configured in Settings),
                                      // this whole branch just did nothing:
                                      // no error, spinner stuck forever, "Pay
                                      // Now" effectively dead.
                                      walletScreenController.addWalletLodar = false;
                                      walletScreenController.update();
                                      if (value != null &&
                                          value['status'] == true &&
                                          value['data'] != null &&
                                          value['data']['authorization_url'] != null) {
                                        walletScreenController
                                            .webViewPaymentMethod(
                                          initialUrl:
                                              '${value["data"]["authorization_url"]}',
                                          status1: 'status',
                                          status2: 'success',
                                          tId: 'trxref',
                                        );
                                      } else {
                                        showToastMessage(
                                            '${value?["message"] ?? "Unable to start Paystack payment"}');
                                      }
                                    }).catchError((e) {
                                      walletScreenController.addWalletLodar = false;
                                      walletScreenController.update();
                                      showToastMessage('Unable to start Paystack payment');
                                    });
                                  } else if (walletScreenController.paymentId ==
                                      '7') {
                                    flutterWaveApiController
                                        .flutterWaveApi(
                                            email:
                                                '${getData.read("userLogin")["email"]}',
                                            amount: walletAmountController.text)
                                        .then((value) {
                                      walletScreenController.addWalletLodar = false;
                                      walletScreenController.update();
                                      if (value != null &&
                                          value['status'] == true &&
                                          value['data'] != null &&
                                          value['data']['authorization_url'] != null) {
                                        walletScreenController
                                            .webViewPaymentMethod(
                                          initialUrl:
                                              '${value["data"]["authorization_url"]}',
                                          status1: 'status',
                                          status2: 'successful',
                                          tId: 'transaction_id',
                                        );
                                      } else {
                                        showToastMessage(
                                            '${value?["message"] ?? "Unable to start Flutterwave payment"}');
                                      }
                                    }).catchError((e) {
                                      walletScreenController.addWalletLodar = false;
                                      walletScreenController.update();
                                      showToastMessage('Unable to start Flutterwave payment');
                                    });
                                  } else if (walletScreenController.paymentId ==
                                      '8') {
                                    walletScreenController.webViewPaymentMethod(
                                      initialUrl:
                                          '${Confing.imageurl + Confing.paytm}amt=${walletAmountController.text}&uid=${getData.read("userLogin")["id"]}&mobile=${getData.read("userLogin")["mobile"]}&email=${getData.read("userLogin")["email"]}',
                                      status1: 'status',
                                      status2: 'successful',
                                      tId: 'transaction_id',
                                    );
                                  } else if (walletScreenController.paymentId ==
                                      '10') {
                                    final notificationId =
                                        UniqueKey().hashCode;
                                    walletScreenController.webViewPaymentMethod(
                                      initialUrl:
                                          '${Confing.imageurl}result.php?detail=Movers&amount=${walletAmountController.text}&order_id=$notificationId&name=${getData.read("userLogin")["name"]}&email=${getData.read("userLogin")["email"]}&phone=${getData.read("userLogin")["mobile"]}',
                                      status1: 'msg',
                                      status2: 'Payment_was_successful',
                                      tId: 'transaction_id',
                                    );
                                  } else if (walletScreenController.paymentId ==
                                      '11') {
                                    walletScreenController.webViewPaymentMethod(
                                      initialUrl:
                                          '${Confing.imageurl + Confing.merpago}amt=${walletAmountController.text}',
                                      status1: 'status',
                                      status2: 'successful',
                                      tId: '',
                                    );
                                  } else if (walletScreenController.paymentId ==
                                      '12') {
                                    walletScreenController.webViewPaymentMethod(
                                      initialUrl:
                                          '${Confing.imageurl + Confing.payFast}amt=${walletAmountController.text}',
                                      status1: 'status',
                                      status2: 'success',
                                      tId: 'payment_id',
                                    );
                                  } else if (walletScreenController.paymentId ==
                                      '13') {
                                    walletScreenController.webViewPaymentMethod(
                                      initialUrl:
                                          '${Confing.imageurl + Confing.midtans}name=${getData.read("userLogin")["name"]}&email=${getData.read("userLogin")["email"]}&phone=${getData.read("userLogin")["mobile"]}&amt=${walletAmountController.text}',
                                      status1: 'status_code',
                                      status2: '200',
                                      tId: 'order_id',
                                    );
                                  } else if (walletScreenController.paymentId ==
                                      '14') {
                                    walletScreenController.webViewPaymentMethod(
                                      initialUrl:
                                          '${Confing.imageurl + Confing.checkout2}amt=${walletAmountController.text}',
                                      status1: 'status',
                                      status2: 'successful',
                                      tId: '',
                                    );
                                  } else if (walletScreenController.paymentId ==
                                      '15') {
                                    walletScreenController.webViewPaymentMethod(
                                      initialUrl:
                                          '${Confing.imageurl + Confing.khalti}amt=${walletAmountController.text}',
                                      status1: 'status',
                                      status2: 'Completed',
                                      tId: 'transaction_id',
                                    );
                                  }
                                }
                              } else {
                                showToastMessage(
                                    'Please Select Payment Method'.tr);
                              }
                            } else {
                              showToastMessage(
                                  'Please enter the wallet amount'.tr);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ccPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(CCRadius.btn)),
                          ),
                          child: Text(
                            'Add Wallet'.tr,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
