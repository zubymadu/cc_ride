// To parse this JSON data, do
//
//     final colorTypeModelListApiModel = colorTypeModelListApiModelFromJson(jsonString);

import 'dart:convert';

ColorTypeModelListApiModel colorTypeModelListApiModelFromJson(String str) => ColorTypeModelListApiModel.fromJson(json.decode(str));

String colorTypeModelListApiModelToJson(ColorTypeModelListApiModel data) => json.encode(data.toJson());

class ColorTypeModelListApiModel {
    List<Datum>? modelData;
    List<Datum>? carTypeData;
    List<Datum>? carColorData;
    String? responseCode;
    String? result;
    String? responseMsg;

    ColorTypeModelListApiModel({
        this.modelData,
        this.carTypeData,
        this.carColorData,
        this.responseCode,
        this.result,
        this.responseMsg,
    });

    factory ColorTypeModelListApiModel.fromJson(Map<String, dynamic> json) => ColorTypeModelListApiModel(
        modelData: json["ModelData"] == null ? [] : List<Datum>.from(json["ModelData"]!.map((x) => Datum.fromJson(x))),
        carTypeData: json["CarTypeData"] == null ? [] : List<Datum>.from(json["CarTypeData"]!.map((x) => Datum.fromJson(x))),
        carColorData: json["CarColorData"] == null ? [] : List<Datum>.from(json["CarColorData"]!.map((x) => Datum.fromJson(x))),
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
    );

    Map<String, dynamic> toJson() => {
        "ModelData": modelData == null ? [] : List<dynamic>.from(modelData!.map((x) => x.toJson())),
        "CarTypeData": carTypeData == null ? [] : List<dynamic>.from(carTypeData!.map((x) => x.toJson())),
        "CarColorData": carColorData == null ? [] : List<dynamic>.from(carColorData!.map((x) => x.toJson())),
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
    };
}

class Datum {
    String? id;
    String? title;
    String? status;

    Datum({
        this.id,
        this.title,
        this.status,
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
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
