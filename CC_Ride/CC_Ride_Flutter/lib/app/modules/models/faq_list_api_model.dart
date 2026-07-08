// To parse this JSON data, do
//
//     final faqListApiModel = faqListApiModelFromJson(jsonString);

import 'dart:convert';

FaqListApiModel faqListApiModelFromJson(String str) => FaqListApiModel.fromJson(json.decode(str));

String faqListApiModelToJson(FaqListApiModel data) => json.encode(data.toJson());

class FaqListApiModel {
    List<FaqDatum>? faqData;
    String? currency;
    String? bookingFee;
    String? responseCode;
    String? result;
    String? responseMsg;

    FaqListApiModel({
        this.faqData,
        this.currency,
        this.bookingFee,
        this.responseCode,
        this.result,
        this.responseMsg,
    });

    factory FaqListApiModel.fromJson(Map<String, dynamic> json) => FaqListApiModel(
        faqData: json["FaqData"] == null ? [] : List<FaqDatum>.from(json["FaqData"]!.map((x) => FaqDatum.fromJson(x))),
        currency: json["currency"],
        bookingFee: json["booking_fee"],
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
    );

    Map<String, dynamic> toJson() => {
        "FaqData": faqData == null ? [] : List<dynamic>.from(faqData!.map((x) => x.toJson())),
        "currency": currency,
        "booking_fee": bookingFee,
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
    };
}

class FaqDatum {
    String? id;
    String? question;
    String? answer;
    String? status;

    FaqDatum({
        this.id,
        this.question,
        this.answer,
        this.status,
    });

    factory FaqDatum.fromJson(Map<String, dynamic> json) => FaqDatum(
        id: json["id"],
        question: json["question"],
        answer: json["answer"],
        status: json["status"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "question": question,
        "answer": answer,
        "status": status,
    };
}
