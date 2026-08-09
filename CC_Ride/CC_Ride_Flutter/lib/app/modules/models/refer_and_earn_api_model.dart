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
        // Backend (legacyReferData) sends `referral_code`/`referral_bonus` —
        // this was reading `code`/`signupcredit`/`refercredit`, keys that
        // never existed in the response, so every one of these rendered as
        // the literal string "null" on screen. Backend only tracks a single
        // bonus amount (not separate signup/refer amounts), so both map to
        // the same value.
        code: json["referral_code"],
        signupcredit: "${json["referral_bonus"] ?? ''}",
        refercredit: "${json["referral_bonus"] ?? ''}",
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
