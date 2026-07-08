// To parse this JSON data, do
//
//     final walletReportApiModel = walletReportApiModelFromJson(jsonString);

import 'dart:convert';

WalletReportApiModel walletReportApiModelFromJson(String str) => WalletReportApiModel.fromJson(json.decode(str));

String walletReportApiModelToJson(WalletReportApiModel data) => json.encode(data.toJson());

class WalletReportApiModel {
    List<Walletitem>? walletitem;
    String? wallet;
    String? responseCode;
    String? result;
    String? responseMsg;

    WalletReportApiModel({
        this.walletitem,
        this.wallet,
        this.responseCode,
        this.result,
        this.responseMsg,
    });

    factory WalletReportApiModel.fromJson(Map<String, dynamic> json) => WalletReportApiModel(
        walletitem: json["Walletitem"] == null ? [] : List<Walletitem>.from(json["Walletitem"]!.map((x) => Walletitem.fromJson(x))),
        wallet: json["wallet"],
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
    );

    Map<String, dynamic> toJson() => {
        "Walletitem": walletitem == null ? [] : List<dynamic>.from(walletitem!.map((x) => x.toJson())),
        "wallet": wallet,
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
    };
}

class Walletitem {
    String? message;
    String? status;
    String? amt;

    Walletitem({
        this.message,
        this.status,
        this.amt,
    });

    factory Walletitem.fromJson(Map<String, dynamic> json) => Walletitem(
        message: json["message"],
        status: json["status"],
        amt: json["amt"],
    );

    Map<String, dynamic> toJson() => {
        "message": message,
        "status": status,
        "amt": amt,
    };
}
