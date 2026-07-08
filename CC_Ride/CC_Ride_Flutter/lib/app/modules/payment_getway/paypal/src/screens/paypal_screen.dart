// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_string_interpolations, avoid_print

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/modules/payment_getway/paypal/flutter_paypal.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:get/get.dart';

paypalPayment({
  required String amt,
  required String clientId,
  required String secretKey,
  var function,
  // required BuildContext context,
}) {
  print('---------- clientId :----- $clientId');
  print('-------- secretKey :---- $secretKey');

  Get.to(() => UsePaypal(
        sandboxMode: true,
        clientId: clientId,
        secretKey: secretKey,
        returnURL: "https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=EC-35S7886705514393E",
        cancelURL: "${Confing.baseurl}paypal/cancle.php",
        transactions: [
          {
            "amount": {
              "total": amt,
              "currency": "USD",
              "details": {
                "subtotal": amt,
                "shipping": '0',
                "shipping_discount": 0
              }
            },
            "description": "The payment transaction description.",
            "item_list": {
              "items": [
                {
                  "name": "A demo product",
                  "quantity": 1,
                  "price": amt,
                  "currency": "USD"
                }
              ]
            }
          }
        ],
        note: "Contact us for any questions on your order.",
        onSuccess: (Map params) {
          function(params);
          showToastMessage("Success Payment");
        },
        onError: (error) {
          print("onError: $error");
          Get.snackbar("Error", error.toString());
        },
        onCancel: (params) {
          print('cancelled: $params');
          Get.snackbar("Cancelled", "Payment cancelled by user");
        },
      ));
}