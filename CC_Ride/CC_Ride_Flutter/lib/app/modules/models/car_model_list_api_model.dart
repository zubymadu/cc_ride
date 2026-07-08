// To parse this JSON data, do
//
//     final carModelListApiModel = carModelListApiModelFromJson(jsonString);

import 'dart:convert';

CarModelListApiModel carModelListApiModelFromJson(String str) => CarModelListApiModel.fromJson(json.decode(str));

String carModelListApiModelToJson(CarModelListApiModel data) => json.encode(data.toJson());

class CarModelListApiModel {
    List<ModelDatum>? modelData;
    String? responseCode;
    String? result;
    String? responseMsg;

    CarModelListApiModel({
        this.modelData,
        this.responseCode,
        this.result,
        this.responseMsg,
    });

    factory CarModelListApiModel.fromJson(Map<String, dynamic> json) => CarModelListApiModel(
        modelData: json["ModelData"] == null ? [] : List<ModelDatum>.from(json["ModelData"]!.map((x) => ModelDatum.fromJson(x))),
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
    );

    Map<String, dynamic> toJson() => {
        "ModelData": modelData == null ? [] : List<dynamic>.from(modelData!.map((x) => x.toJson())),
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
    };
}

class ModelDatum {
    String? id;
    String? title;
    String? status;

    ModelDatum({
        this.id,
        this.title,
        this.status,
    });

    factory ModelDatum.fromJson(Map<String, dynamic> json) => ModelDatum(
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
