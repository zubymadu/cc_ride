// To parse this JSON data, do
//
//     final carTypeListApiModel = carTypeListApiModelFromJson(jsonString);

import 'dart:convert';

CarTypeListApiModel carTypeListApiModelFromJson(String str) => CarTypeListApiModel.fromJson(json.decode(str));

String carTypeListApiModelToJson(CarTypeListApiModel data) => json.encode(data.toJson());

class CarTypeListApiModel {
    List<CarTypeDatum>? carTypeData;
    String? responseCode;
    String? result;
    String? responseMsg;

    CarTypeListApiModel({
        this.carTypeData,
        this.responseCode,
        this.result,
        this.responseMsg,
    });

    factory CarTypeListApiModel.fromJson(Map<String, dynamic> json) => CarTypeListApiModel(
        carTypeData: json["CarTypeData"] == null ? [] : List<CarTypeDatum>.from(json["CarTypeData"]!.map((x) => CarTypeDatum.fromJson(x))),
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
    );

    Map<String, dynamic> toJson() => {
        "CarTypeData": carTypeData == null ? [] : List<dynamic>.from(carTypeData!.map((x) => x.toJson())),
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
    };
}

class CarTypeDatum {
    String? id;
    String? title;
    String? status;

    CarTypeDatum({
        this.id,
        this.title,
        this.status,
    });

    factory CarTypeDatum.fromJson(Map<String, dynamic> json) => CarTypeDatum(
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
