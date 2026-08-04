// ignore_for_file: deprecated_member_use

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/booking_controllers/payment_screen_controller.dart';
import 'package:carride/app/modules/controllers/payment/pay_stack_api_controller.dart';
import 'package:carride/app/modules/payment_getway/paypal/src/screens/paypal_screen.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

payBottomsheet({required String totalAmt}) {
  final PayStackApiController payStackApiController =
      Get.put(PayStackApiController());
  int paymentIndex = -1;
  return Get.bottomSheet(
    isScrollControlled: true,
    backgroundColor: ccSurface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(CCRadius.sheet))),
    GetBuilder<PaymentScreenController>(
      builder: (c) {
        return Container(
          constraints: BoxConstraints(maxHeight: Get.height / 1.2),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Payment Method'.tr,
                style: CCText.titleMd,
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.separated(
                  itemCount: c.paymentGatewayListController
                          .paymentGatewayListApiModel
                          ?.paymentdata
                          ?.length ??
                      0,
                  physics: const BouncingScrollPhysics(),
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final data = c.paymentGatewayListController
                        .paymentGatewayListApiModel!
                        .paymentdata![index];
                    final selected = c.paymentId == '${data.id}';
                    return InkWell(
                      onTap: () {
                        paymentIndex = index;
                        c.paymentId = '${data.id}';
                        c.update();
                      },
                      borderRadius:
                          BorderRadius.circular(CCRadius.card),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selected
                                ? ccPrimary
                                : ccInputBorder,
                            width: selected ? 2 : 1,
                          ),
                          borderRadius:
                              BorderRadius.circular(CCRadius.card),
                          color: selected ? ccIceBlue : ccSurface,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: ccInputBorder),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(8),
                                child: FadeInImage.assetNetwork(
                                  placeholder:
                                      'assets/image/ezgif.com-crop.gif',
                                  width: 56,
                                  height: 56,
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
                                    style: CCText.titleMd,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${data.subtitle}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: CCText.bodyMd.copyWith(
                                        color: ccSecondaryText),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            Radio<bool>(
                              activeColor: ccPrimary,
                              value: true,
                              groupValue: selected ? true : false,
                              onChanged: (_) {
                                paymentIndex = index;
                                c.paymentId = '${data.id}';
                                c.update();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                ),
              ),
              if (c.paymentId != '0') ...[
                const SizedBox(height: 12),
                c.isLoading
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
                            if (c.paymentId != '') {
                              if (!c.isLoading) {
                                c.isLoading = true;
                                c.update();
                                final pid = c.paymentId;
                                final selectedData = c
                                    .paymentGatewayListController
                                    .paymentGatewayListApiModel!
                                    .paymentdata![paymentIndex];
                                final attrs = selectedData.attributes;
                                final gatewayType = selectedData.gatewayType;
                                if (gatewayType == 'paystack') {
                                  payStackApiController
                                      .payStackApi(
                                          email:
                                              '${getData.read('userLogin')['email']}',
                                          amount: totalAmt)
                                      .then((value) {
                                    c.isLoading = false;
                                    c.update();
                                    if (value != null &&
                                        value['status'] == true &&
                                        value['data'] != null &&
                                        value['data']['authorization_url'] !=
                                            null) {
                                      c.webViewPaymentMethod(
                                        initialUrl:
                                            '${value['data']['authorization_url']}',
                                        status1: 'status',
                                        status2: 'success',
                                        tId: 'trxref',
                                      );
                                    } else {
                                      showToastMessage(
                                          '${value?["ResponseMsg"] ?? "Unable to start Paystack payment"}');
                                    }
                                  }).catchError((e) {
                                    c.isLoading = false;
                                    c.update();
                                    showToastMessage(
                                        'Unable to start Paystack payment');
                                  });
                                } else if (gatewayType == 'flutterwave') {
                                  c.webViewPaymentMethod(
                                    initialUrl:
                                        '${Confing.imageurl + Confing.flutterwave}amt=$totalAmt&email=${getData.read('userLogin')['email']}',
                                    status1: 'status',
                                    status2: 'successful',
                                    tId: 'transaction_id',
                                  );
                                } else if (pid == '3') {
                                  final ids =
                                      attrs.toString().split(',');
                                  paypalPayment(
                                    function: (e) {
                                      c.bookSeat(
                                          transactionID:
                                              '${e['paymentId']}');
                                    },
                                    amt: totalAmt,
                                    clientId: ids[0],
                                    secretKey: ids[1],
                                  );
                                } else if (pid == '4') {
                                  c.stripePaymentGetWay(
                                      totalAmt: totalAmt);
                                } else if (pid == '6') {
                                  payStackApiController
                                      .payStackApi(
                                          email:
                                              '${getData.read('userLogin')['email']}',
                                          amount: totalAmt)
                                      .then((value) {
                                    if (value['status'] == true) {
                                      c.webViewPaymentMethod(
                                        initialUrl:
                                            '${value['data']['authorization_url']}',
                                        status1: 'status',
                                        status2: 'success',
                                        tId: 'trxref',
                                      );
                                    }
                                  });
                                } else if (pid == '7') {
                                  c.webViewPaymentMethod(
                                    initialUrl:
                                        '${Confing.imageurl + Confing.flutterwave}amt=$totalAmt&email=${getData.read('userLogin')['email']}',
                                    status1: 'status',
                                    status2: 'successful',
                                    tId: 'transaction_id',
                                  );
                                } else if (pid == '8') {
                                  c.webViewPaymentMethod(
                                    initialUrl:
                                        '${Confing.imageurl + Confing.paytm}amt=$totalAmt&uid=${getData.read('userLogin')['id']}&mobile=${getData.read('userLogin')['mobile']}&email=${getData.read('userLogin')['email']}',
                                    status1: 'status',
                                    status2: 'successful',
                                    tId: 'transaction_id',
                                  );
                                } else if (pid == '10') {
                                  final notificationId =
                                      UniqueKey().hashCode;
                                  c.webViewPaymentMethod(
                                    initialUrl:
                                        '${Confing.imageurl}result.php?detail=Movers&amount=$totalAmt&order_id=$notificationId&name=${getData.read('userLogin')['name']}&email=${getData.read('userLogin')['email']}&phone=${getData.read('userLogin')['mobile']}',
                                    status1: 'msg',
                                    status2:
                                        'Payment_was_successful',
                                    tId: 'transaction_id',
                                  );
                                } else if (pid == '11') {
                                  c.webViewPaymentMethod(
                                    initialUrl:
                                        '${Confing.imageurl + Confing.merpago}amt=$totalAmt',
                                    status1: 'status',
                                    status2: 'successful',
                                    tId: '',
                                  );
                                } else if (pid == '12') {
                                  c.webViewPaymentMethod(
                                    initialUrl:
                                        '${Confing.imageurl + Confing.payFast}amt=$totalAmt',
                                    status1: 'status',
                                    status2: 'success',
                                    tId: 'payment_id',
                                  );
                                } else if (pid == '13') {
                                  c.webViewPaymentMethod(
                                    initialUrl:
                                        '${Confing.imageurl + Confing.midtans}name=${getData.read('userLogin')['name']}&email=${getData.read('userLogin')['email']}&phone=${getData.read('userLogin')['mobile']}&amt=$totalAmt',
                                    status1: 'status_code',
                                    status2: '200',
                                    tId: 'order_id',
                                  );
                                } else if (pid == '14') {
                                  c.webViewPaymentMethod(
                                    initialUrl:
                                        '${Confing.imageurl + Confing.checkout2}amt=$totalAmt',
                                    status1: 'status',
                                    status2: 'successful',
                                    tId: '',
                                  );
                                } else if (pid == '15') {
                                  c.webViewPaymentMethod(
                                    initialUrl:
                                        '${Confing.imageurl + Confing.khalti}amt=$totalAmt',
                                    status1: 'status',
                                    status2: 'Completed',
                                    tId: 'transaction_id',
                                  );
                                } else if (pid == '16') {
                                  c.bookSeat(transactionID: '0');
                                }
                              }
                            } else {
                              showToastMessage(
                                  'Please Select Payment Method'
                                      .tr);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ccPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    CCRadius.btn)),
                          ),
                          child: const Text('Pay Now',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.white)),
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
