// To parse this JSON data, do
//
//     final colorListApiModel = colorListApiModelFromJson(jsonString);

import 'dart:convert';

ColorListApiModel colorListApiModelFromJson(String str) => ColorListApiModel.fromJson(json.decode(str));

String colorListApiModelToJson(ColorListApiModel data) => json.encode(data.toJson());

class ColorListApiModel {
    List<CarColorDatum>? carColorData;
    String? responseCode;
    String? result;
    String? responseMsg;

    ColorListApiModel({
        this.carColorData,
        this.responseCode,
        this.result,
        this.responseMsg,
    });

    factory ColorListApiModel.fromJson(Map<String, dynamic> json) => ColorListApiModel(
        carColorData: json["CarColorData"] == null ? [] : List<CarColorDatum>.from(json["CarColorData"]!.map((x) => CarColorDatum.fromJson(x))),
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
    );

    Map<String, dynamic> toJson() => {
        "CarColorData": carColorData == null ? [] : List<dynamic>.from(carColorData!.map((x) => x.toJson())),
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
    };
}

class CarColorDatum {
    String? id;
    String? title;
    String? status;

    CarColorDatum({
        this.id,
        this.title,
        this.status,
    });

    factory CarColorDatum.fromJson(Map<String, dynamic> json) => CarColorDatum(
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
