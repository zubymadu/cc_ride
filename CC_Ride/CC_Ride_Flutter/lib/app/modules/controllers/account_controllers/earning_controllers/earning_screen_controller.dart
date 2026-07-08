import 'dart:convert';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/models/earning_api_model.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/utils/color.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:carride/widgets/textfield/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class EarningScreenController extends GetxController {
  @override
  void onInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      earningApi();
    });
    super.onInit();
  }

  final RxList<Color> _earningColors = <Color>[
    greenColor,
    ccError,
    orangeColor,
    purpleColor,
    darkOrangeColor,
    yellowColor,
  ].obs;
  List<Color> get earningColors => _earningColors;
  set earningColors(List<Color> value) => _earningColors.value = value;

  final RxList _earningList = [
    "Trip Completed",
    "Trip Cancelled",
    "Trip Pending",
    "Total KM Driven",
    "Total Earning",
    "Total Payout",
  ].obs;
  List get earningList => _earningList;
  set earningList(List value) => _earningList.value = value;

  EarningApiModel? earningApiModel;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
  };

  Future earningApi() async {
    isLoading = true;
    update();
    Map body = {"uid": "${getData.read("userLogin")["id"]}"};

    try {
      String url = Confing.baseurl + Confing.earning;

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      ).timeout(const Duration(seconds: 15));

      debugPrint("============= Earning Api url ============== $url");
      debugPrint("============= Earning Api body ============= $body");
      debugPrint(
        "=========== Earning Api response =========== ${response.body}",
      );

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          earningApiModel = earningApiModelFromJson(response.body);
          update();
          if (earningApiModel!.result == "true") {
            isLoading = false;
            update();
            return data;
          } else {
            showToastMessage("${earningApiModel!.responseMsg}");
            return data;
          }
        } else {
          showToastMessage("${data["ResponseMsg"]}");
          return data;
        }
      } else {
        showToastMessage("Somthing went wrong!.....");
      }
    } catch (e) {
      debugPrint("============= Earning Api Error =============  $e");
    } finally {
      isLoading = false;
      update();
    }
  }

  final RxBool _resquestLoading = false.obs;
  bool get resquestLoading => _resquestLoading.value;
  set resquestLoading(bool value) => _resquestLoading.value = value;

  Future requestWithdrawApi({
    required String amount,
    required String rType,
    required String accNumber,
    required String bankName,
    required String accName,
    required String ifscCode,
    required String upiId,
    required String paypalId,
  }) async {
    resquestLoading = true;
    update();
    Map body = {
      "uid": "${getData.read("userLogin")["id"]}",
      "amt": amount,
      "r_type": rType,
      "acc_number": accNumber,
      "bank_name": bankName,
      "acc_name": accName,
      "ifsc_code": ifscCode,
      "upi_id": upiId,
      "paypal_id": paypalId,
    };

    try {
      String url = Confing.baseurl + Confing.requestWithdraw;

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      debugPrint("============= Request Withdraw Api url ============== $url");
      debugPrint("============= Request Withdraw Api body ============= $body");
      debugPrint(
        "=========== Request Withdraw Api response =========== ${response.body}",
      );

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          earningApi();
          Get.back();
          requestSuccessBottomSheet();
          resquestLoading = false;
          update();
          return data;
        } else {
          resquestLoading = false;
          update();
        }
        showToastMessage("${data["ResponseMsg"]}");
        return data;
      } else {
        showToastMessage("Somthing went wrong!.....");
      }
    } catch (e) {
      resquestLoading = false;
      update();
      debugPrint("============= Request Withdraw Api Error =============  $e");
    }
  }

  final RxList _withdrawText = ["Pending Withdraw", "Min withdraw Limit"].obs;
  List get withdrawText => _withdrawText;
  set withdrawText(List value) => _withdrawText.value = value;

  final RxList _paymentType = ["UPI", "BANK Transfer", "Paypal"].obs;
  List get paymentType => _paymentType;
  set paymentType(List value) => _paymentType.value = value;

  final RxnString _selectedPaymentType = RxnString();
  String? get selectedPaymentType => _selectedPaymentType.value;
  set selectedPaymentType(String? value) => _selectedPaymentType.value = value;

  final formKey = GlobalKey<FormState>();

  TextEditingController amountController = TextEditingController();
  TextEditingController upiIdController = TextEditingController();
  TextEditingController accountNumberController = TextEditingController();
  TextEditingController ifscCodeController = TextEditingController();
  TextEditingController paypalEmailController = TextEditingController();
  TextEditingController bankNameController = TextEditingController();
  TextEditingController accountNameController = TextEditingController();

  withdrawBottomSheet() {
    return Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: ccBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(15)),
      ),
      GetBuilder<EarningScreenController>(
        init: EarningScreenController(),
        initState: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            selectedPaymentType = null;
            update();
          });
        },
        builder: (earningScreenController) {
          return Container(
            constraints: BoxConstraints(maxHeight: Get.height / 1.2),
            padding: const EdgeInsets.all(10),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Withdraw",
                            style: TextStyle(
                              color: ccNavyText,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Get.back(),
                          child: Icon(
                            Icons.close,
                            color: ccNavyText,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: ccInputBorder),
                    ),
                    Row(
                      children: [
                        for (int i = 0; i < withdrawText.length; i++) ...[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${withdrawText[i]}",
                                  style: TextStyle(
                                    color: ccSecondaryText,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  i == 0
                                      ? "${earningApiModel!.currency}${earningApiModel!.totalEarning}"
                                      : "${earningApiModel!.currency}${earningApiModel!.wLimit}",
                                  style: TextStyle(
                                    color: ccNavyText,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (i == 0)
                            Container(
                              width: 1,
                              height: 50,
                              margin: EdgeInsets.symmetric(horizontal: 15),
                              decoration: BoxDecoration(
                                color: ccInputBorder,
                              ),
                            ),
                        ],
                      ],
                    ),
                    SizedBox(height: 10),
                    customTextFormField(
                      title: "Amount",
                      hintText: "Enter withdraw amount",
                      controller: amountController,
                      prefixIcon: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(),
                        child: Center(
                          child: Text(
                            "${earningApiModel!.currency}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ccNavyText,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (String? value) {
                        formKey.currentState!.validate();
                        update();
                      },
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter amount";
                        } else if (num.parse(value) >
                            num.parse(earningApiModel!.wLimit!)) {
                          return "withdraw amount should not be greater than min withdraw limit";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Select Type",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: ccNavyText,
                      ),
                    ),
                    SizedBox(height: 5),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPaymentType,
                      borderRadius: BorderRadius.circular(16),
                      style: TextStyle(
                        color: ccNavyText,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: ccSecondaryText,
                        size: 15,
                      ),
                      items: paymentType
                          .map(
                            (type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: ccNavyText,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        selectedPaymentType = value;
                        update();
                        debugPrint(
                          "------------ Selected Payment Type ----------- $selectedPaymentType",
                        );
                        debugPrint(
                          "---------------------- value ----------------- $value",
                        );
                      },
                      decoration: InputDecoration(
                        floatingLabelStyle: TextStyle(
                          color: ccPrimary,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                        labelStyle: TextStyle(
                          color: ccSecondaryText,
                          fontSize: 15,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                        hintText: "Select Type",
                        hintStyle: TextStyle(
                          color: ccSecondaryText,
                          fontSize: 15,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                        fillColor: ccBackground,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: ccInputBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: ccInputBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: ccNavyText),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 15),
                      ),
                      dropdownColor: ccBackground,
                      isExpanded: false,
                    ),
                    SizedBox(height: 10),
                    if (selectedPaymentType == "UPI") ...[
                      customTextFormField(
                        title: "UPI ID",
                        controller: upiIdController,
                        hintText: "Enter UPI ID",
                        keyboardType: TextInputType.text,
                        onChanged: (String? value) {
                          formKey.currentState!.validate();
                          update();
                        },
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter UPI ID";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                    ] else if (selectedPaymentType == "BANK Transfer") ...[
                      customTextFormField(
                        hintText: "Bank name",
                        title: "Bank Name",
                        controller: bankNameController,
                        keyboardType: TextInputType.text,
                        onChanged: (String? value) {
                          formKey.currentState!.validate();
                          update();
                        },
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter Bank Name";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      customTextFormField(
                        title: "Account Name",
                        hintText: "Enter Account Name",
                        controller: accountNameController,
                        keyboardType: TextInputType.text,
                        onChanged: (String? value) {
                          formKey.currentState!.validate();
                          update();
                        },
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter Account Name";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      customTextFormField(
                        title: "Account Number",
                        hintText: "Enter Account Number",
                        controller: accountNumberController,
                        keyboardType: TextInputType.number,
                        onChanged: (String? value) {
                          formKey.currentState!.validate();
                          update();
                        },
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter Account Number";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      SizedBox(height: 10),
                      customTextFormField(
                        title: "IFSC Code",
                        hintText: "Enter IFSC Code",
                        controller: ifscCodeController,
                        keyboardType: TextInputType.text,
                        onChanged: (String? value) {
                          formKey.currentState!.validate();
                          update();
                        },
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter IFSC Code";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                    ] else if (selectedPaymentType == "Paypal") ...[
                      customTextFormField(
                        title: "Paypal Email",
                        hintText: "Enter Paypal Email",
                        controller: paypalEmailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (String? value) {
                          formKey.currentState!.validate();
                          update();
                        },
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter Paypal Email";
                          }
                          return null;
                        },
                      ),
                    ],
                    SizedBox(height: 10),
                    resquestLoading
                        ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: ccPrimary)))
                        : CCButton(
                            onPressed: () {
                              if (selectedPaymentType == "UPI") {
                                if (amountController.text.isNotEmpty && selectedPaymentType != null && upiIdController.text.isNotEmpty) {
                                  requestWithdrawApi(
                                    amount: amountController.text,
                                    rType: selectedPaymentType!,
                                    accNumber: "",
                                    bankName: "",
                                    accName: "",
                                    ifscCode: "",
                                    upiId: upiIdController.text,
                                    paypalId: "",
                                  );
                                } else {
                                  showToastMessage("Please enter UPI ID");
                                }
                              } else if (selectedPaymentType ==
                                  "BANK Transfer") {
                                if (amountController.text.isNotEmpty && selectedPaymentType != null && accountNameController.text.isNotEmpty && accountNumberController.text.isNotEmpty && bankNameController.text.isNotEmpty && ifscCodeController.text.isNotEmpty) {
                                  requestWithdrawApi(
                                    amount: amountController.text,
                                    rType: selectedPaymentType!,
                                    accNumber: accountNumberController.text,
                                    bankName: bankNameController.text,
                                    accName: accountNameController.text,
                                    ifscCode: ifscCodeController.text,
                                    upiId: "",
                                    paypalId: "",
                                  );
                                } else {
                                  showToastMessage(
                                    "Please fill all bank details",
                                  );
                                }
                              } else if (selectedPaymentType == "Paypal") {
                                if (amountController.text.isNotEmpty && selectedPaymentType != null && paypalEmailController.text.isNotEmpty) {
                                  requestWithdrawApi(
                                    amount: amountController.text,
                                    rType: selectedPaymentType!,
                                    accNumber: "",
                                    bankName: "",
                                    accName: "",
                                    ifscCode: "",
                                    upiId: "",
                                    paypalId: paypalEmailController.text,
                                  );
                                } else {
                                  showToastMessage("Please enter Paypal Email");
                                }
                              }
                            },
                            label: "Send Request",
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  requestSuccessBottomSheet() {
    return Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: ccSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(15)),
      ),
      Container(
        decoration: BoxDecoration(color: ccSurface),
        child: Column(
          children: [
            SizedBox(height: 45),
            Expanded(
              child: Scaffold(
                backgroundColor: ccSurface,
                body: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: SvgPicture.asset(
                          "assets/image/svg/checkmark-circle.svg",
                          width: 70,
                          height: 70,
                        ),
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: 290,
                        child: Text(
                          "Your Payout Request Successfully Sent",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ccNavyText,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        width: 320,
                        child: Text(
                          "Your money should arrive instantly, but it may take up to 24 hours.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ccSecondaryText,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ccBackground,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Payment Information",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ccNavyText,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Divider(color: ccInputBorder),
                            ),
                            for (int i = 0; i < 2; i++) ...[
                              Text(
                                i == 0
                                    ? (accountNumberController.text.isNotEmpty
                                          ? "Account number:"
                                          : upiIdController.text.isNotEmpty
                                          ? "UPI ID:"
                                          : "Paypal ID:")
                                    : "Requested Amount:",
                                style: TextStyle(
                                  color: ccSecondaryText,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                i == 0
                                    ? (accountNumberController.text.isNotEmpty
                                          ? accountNumberController.text
                                          : upiIdController.text.isNotEmpty
                                          ? upiIdController.text
                                          : paypalEmailController.text)
                                    : "${amountController.text}$currency",
                                style: TextStyle(
                                  color: ccNavyText,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (i != 2) SizedBox(height: 10),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      CCButton(
                        onPressed: () {
                          Get.back();
                          Get.toNamed(Routes.PAYOUT_HISTORY_SCREEN);
                        },
                        label: "Done",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  pastTripHistory() {
    return Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: ccSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(15)),
      ),
      Container(
        decoration: BoxDecoration(color: ccSurface),
        child: Column(
          children: [
            SizedBox(height: 45),
            Expanded(
              child: Scaffold(
                backgroundColor: ccSurface,
                appBar: AppBar(
                  backgroundColor: ccSurface,
                  title: Text("Past Trip History"),
                  centerTitle: true,
                ),
                body: ListView.separated(
                  padding: EdgeInsets.all(10),
                  itemCount: earningApiModel!.pastTrips!.length,
                  shrinkWrap: true,
                  physics: BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: greenlightColor,
                                ),
                                child: SvgPicture.asset(
                                  "assets/image/svg/coin.svg",
                                  color: greenColor,
                                  height: 30,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Trip #${earningApiModel!.pastTrips![index].tripId} ${earningApiModel!.pastTrips![index].originAddress!.split(" ").first} to ${earningApiModel!.pastTrips![index].destiAddress!.split(" ").first}",
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: TextStyle(
                                        color: ccNavyText,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      "Seat ${earningApiModel!.pastTrips![index].totalSeat} X ${earningApiModel!.currency}${earningApiModel!.pastTrips![index].seatPrice}",
                                      style: TextStyle(
                                        color: ccSecondaryText,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      "${earningApiModel!.pastTrips![index].startTime}",
                                      style: TextStyle(
                                        color: ccSecondaryText,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.arrow_upward_outlined,
                                  color: greenColor,
                                  size: 18,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  "${earningApiModel!.pastTrips![index].driverEarning}${earningApiModel!.currency}",
                                  style: TextStyle(
                                    color: greenColor,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "You're Earning",
                              style: TextStyle(
                                color: ccSecondaryText,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Divider(color: ccInputBorder),),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
