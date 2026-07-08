// To parse this JSON data, do
//
//     final restricationListApiModel = restricationListApiModelFromJson(jsonString);

import 'dart:convert';

RestricationListApiModel restricationListApiModelFromJson(String str) => RestricationListApiModel.fromJson(json.decode(str));

String restricationListApiModelToJson(RestricationListApiModel data) => json.encode(data.toJson());

class RestricationListApiModel {
    List<CarRestricationDatum>? carRestricationData;
    String? responseCode;
    String? result;
    String? responseMsg;

    RestricationListApiModel({
        this.carRestricationData,
        this.responseCode,
        this.result,
        this.responseMsg,
    });

    factory RestricationListApiModel.fromJson(Map<String, dynamic> json) => RestricationListApiModel(
        carRestricationData: json["CarRestricationData"] == null ? [] : List<CarRestricationDatum>.from(json["CarRestricationData"]!.map((x) => CarRestricationDatum.fromJson(x))),
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
    );

    Map<String, dynamic> toJson() => {
        "CarRestricationData": carRestricationData == null ? [] : List<dynamic>.from(carRestricationData!.map((x) => x.toJson())),
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
    };
}

class CarRestricationDatum {
    String? id;
    String? title;
    String? status;

    CarRestricationDatum({
        this.id,
        this.title,
        this.status,
    });

    factory CarRestricationDatum.fromJson(Map<String, dynamic> json) => CarRestricationDatum(
        id: json["id"],
        title: json["title"],
        status: json["status"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "status": status,
    };
}
