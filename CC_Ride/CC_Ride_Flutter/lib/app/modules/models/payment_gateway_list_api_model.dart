// To parse this JSON data, do
//
//     final paymentGatewayListApiModel = paymentGatewayListApiModelFromJson(jsonString);

import 'dart:convert';

PaymentGatewayListApiModel paymentGatewayListApiModelFromJson(String str) => PaymentGatewayListApiModel.fromJson(json.decode(str));

String paymentGatewayListApiModelToJson(PaymentGatewayListApiModel data) => json.encode(data.toJson());

class PaymentGatewayListApiModel {
    List<Paymentdatum>? paymentdata;
    String? responseCode;
    String? result;
    String? responseMsg;

    PaymentGatewayListApiModel({
        this.paymentdata,
        this.responseCode,
        this.result,
        this.responseMsg,
    });

    factory PaymentGatewayListApiModel.fromJson(Map<String, dynamic> json) => PaymentGatewayListApiModel(
        paymentdata: json["PaymentData"] == null ? [] : List<Paymentdatum>.from(json["PaymentData"]!.map((x) => Paymentdatum.fromJson(x))),
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
    );

    Map<String, dynamic> toJson() => {
        "paymentdata": paymentdata == null ? [] : List<dynamic>.from(paymentdata!.map((x) => x.toJson())),
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
    };
}

class Paymentdatum {
    String? id;
    String? title;
    String? img;
    String? attributes;
    String? status;
    String? subtitle;
    String? pShow;
    String? gatewayType;

    Paymentdatum({
        this.id,
        this.title,
        this.img,
        this.attributes,
        this.status,
        this.subtitle,
        this.pShow,
        this.gatewayType,
    });

    factory Paymentdatum.fromJson(Map<String, dynamic> json) => Paymentdatum(
        id: json["id"],
        title: json["title"],
        img: json["img"],
        attributes: json["attributes"],
        status: json["status"],
        subtitle: json["subtitle"],
        pShow: json["p_show"],
        gatewayType: json["gateway_type"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "img": img,
        "attributes": attributes,
        "status": status,
        "subtitle": subtitle,
        "p_show": pShow,
        "gateway_type": gatewayType,
    };
}
