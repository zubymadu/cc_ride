// To parse this JSON data, do
//
//     final payoutHistoryApiModel = payoutHistoryApiModelFromJson(jsonString);

import 'dart:convert';

PayoutHistoryApiModel payoutHistoryApiModelFromJson(String str) => PayoutHistoryApiModel.fromJson(json.decode(str));

String payoutHistoryApiModelToJson(PayoutHistoryApiModel data) => json.encode(data.toJson());

class PayoutHistoryApiModel {
    String? responseCode;
    String? result;
    String? responseMsg;
    List<Payoutlist>? payoutlist;

    PayoutHistoryApiModel({
        this.responseCode,
        this.result,
        this.responseMsg,
        this.payoutlist,
    });

    factory PayoutHistoryApiModel.fromJson(Map<String, dynamic> json) => PayoutHistoryApiModel(
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
        payoutlist: json["Payoutlist"] == null ? [] : List<Payoutlist>.from(json["Payoutlist"]!.map((x) => Payoutlist.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
        "Payoutlist": payoutlist == null ? [] : List<dynamic>.from(payoutlist!.map((x) => x.toJson())),
    };
}

class Payoutlist {
    String? payoutId;
    String? amt;
    String? status;
    dynamic proof;
    String? rDate;
    String? rType;
    String? accNumber;
    String? bankName;
    String? accName;
    String? ifscCode;
    String? upiId;
    String? paypalId;

    Payoutlist({
        this.payoutId,
        this.amt,
        this.status,
        this.proof,
        this.rDate,
        this.rType,
        this.accNumber,
        this.bankName,
        this.accName,
        this.ifscCode,
        this.upiId,
        this.paypalId,
    });

    factory Payoutlist.fromJson(Map<String, dynamic> json) => Payoutlist(
        payoutId: json["payout_id"],
        amt: json["amt"],
        status: json["status"],
        proof: json["proof"],
        rDate: json["r_date"],
        rType: json["r_type"],
        accNumber: json["acc_number"],
        bankName: json["bank_name"],
        accName: json["acc_name"],
        ifscCode: json["ifsc_code"],
        upiId: json["upi_id"],
        paypalId: json["paypal_id"],
    );

    Map<String, dynamic> toJson() => {
        "payout_id": payoutId,
        "amt": amt,
        "status": status,
        "proof": proof,
        "r_date": rDate,
        "r_type": rType,
        "acc_number": accNumber,
        "bank_name": bankName,
        "acc_name": accName,
        "ifsc_code": ifscCode,
        "upi_id": upiId,
        "paypal_id": paypalId,
    };
}
