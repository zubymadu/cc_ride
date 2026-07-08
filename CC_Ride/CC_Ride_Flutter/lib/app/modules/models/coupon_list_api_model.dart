// To parse this JSON data, do
//
//     final couponListApiModel = couponListApiModelFromJson(jsonString);

import 'dart:convert';

CouponListApiModel couponListApiModelFromJson(String str) => CouponListApiModel.fromJson(json.decode(str));

String couponListApiModelToJson(CouponListApiModel data) => json.encode(data.toJson());

class CouponListApiModel {
    List<Couponlist>? couponlist;
    String? responseCode;
    String? result;
    String? responseMsg;

    CouponListApiModel({
        this.couponlist,
        this.responseCode,
        this.result,
        this.responseMsg,
    });

    factory CouponListApiModel.fromJson(Map<String, dynamic> json) => CouponListApiModel(
        couponlist: json["couponlist"] == null ? [] : List<Couponlist>.from(json["couponlist"]!.map((x) => Couponlist.fromJson(x))),
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
    );

    Map<String, dynamic> toJson() => {
        "couponlist": couponlist == null ? [] : List<dynamic>.from(couponlist!.map((x) => x.toJson())),
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
    };
}

class Couponlist {
    String? id;
    String? couponImg;
    DateTime? expireDate;
    String? cDesc;
    String? couponVal;
    String? couponCode;
    String? couponTitle;
    String? couponSubtitle;
    String? minAmt;

    Couponlist({
        this.id,
        this.couponImg,
        this.expireDate,
        this.cDesc,
        this.couponVal,
        this.couponCode,
        this.couponTitle,
        this.couponSubtitle,
        this.minAmt,
    });

    factory Couponlist.fromJson(Map<String, dynamic> json) => Couponlist(
        id: json["id"],
        couponImg: json["coupon_img"],
        expireDate: json["expire_date"] == null ? null : DateTime.parse(json["expire_date"]),
        cDesc: json["c_desc"],
        couponVal: json["coupon_val"],
        couponCode: json["coupon_code"],
        couponTitle: json["coupon_title"],
        couponSubtitle: json["coupon_subtitle"],
        minAmt: json["min_amt"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "coupon_img": couponImg,
        "expire_date": "${expireDate!.year.toString().padLeft(4, '0')}-${expireDate!.month.toString().padLeft(2, '0')}-${expireDate!.day.toString().padLeft(2, '0')}",
        "c_desc": cDesc,
        "coupon_val": couponVal,
        "coupon_code": couponCode,
        "coupon_title": couponTitle,
        "coupon_subtitle": couponSubtitle,
        "min_amt": minAmt,
    };
}
