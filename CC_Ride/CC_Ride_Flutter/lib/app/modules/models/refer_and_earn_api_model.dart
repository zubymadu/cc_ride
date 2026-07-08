// To parse this JSON data, do
//
//     final referAndEarnApiModel = referAndEarnApiModelFromJson(jsonString);

import 'dart:convert';

ReferAndEarnApiModel referAndEarnApiModelFromJson(String str) => ReferAndEarnApiModel.fromJson(json.decode(str));

String referAndEarnApiModelToJson(ReferAndEarnApiModel data) => json.encode(data.toJson());

class ReferAndEarnApiModel {
    String? responseCode;
    String? result;
    String? responseMsg;
    String? code;
    String? signupcredit;
    String? refercredit;

    ReferAndEarnApiModel({
        this.responseCode,
        this.result,
        this.responseMsg,
        this.code,
        this.signupcredit,
        this.refercredit,
    });

    factory ReferAndEarnApiModel.fromJson(Map<String, dynamic> json) => ReferAndEarnApiModel(
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
        code: json["code"],
        signupcredit: json["signupcredit"],
        refercredit: json["refercredit"],
    );

    Map<String, dynamic> toJson() => {
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
        "code": code,
        "signupcredit": signupcredit,
        "refercredit": refercredit,
    };
}
