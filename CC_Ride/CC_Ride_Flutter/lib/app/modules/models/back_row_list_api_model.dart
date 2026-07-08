// To parse this JSON data, do
//
//     final backRowListApiModel = backRowListApiModelFromJson(jsonString);

import 'dart:convert';

BackRowListApiModel backRowListApiModelFromJson(String str) => BackRowListApiModel.fromJson(json.decode(str));

String backRowListApiModelToJson(BackRowListApiModel data) => json.encode(data.toJson());

class BackRowListApiModel {
    List<CarrowDatum>? carrowData;
    String? responseCode;
    String? result;
    String? responseMsg;

    BackRowListApiModel({
        this.carrowData,
        this.responseCode,
        this.result,
        this.responseMsg,
    });

    factory BackRowListApiModel.fromJson(Map<String, dynamic> json) => BackRowListApiModel(
        carrowData: json["CarrowData"] == null ? [] : List<CarrowDatum>.from(json["CarrowData"]!.map((x) => CarrowDatum.fromJson(x))),
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
    );

    Map<String, dynamic> toJson() => {
        "CarrowData": carrowData == null ? [] : List<dynamic>.from(carrowData!.map((x) => x.toJson())),
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
    };
}

class CarrowDatum {
    String? id;
    String? title;

    CarrowDatum({
        this.id,
        this.title,
    });

    factory CarrowDatum.fromJson(Map<String, dynamic> json) => CarrowDatum(
        id: json["id"],
        title: json["title"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
    };
}
