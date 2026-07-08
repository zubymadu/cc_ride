// To parse this JSON data, do
//
//     final vehicleListApiModel = vehicleListApiModelFromJson(jsonString);

import 'dart:convert';

VehicleListApiModel vehicleListApiModelFromJson(String str) => VehicleListApiModel.fromJson(json.decode(str));

String vehicleListApiModelToJson(VehicleListApiModel data) => json.encode(data.toJson());

class VehicleListApiModel {
    List<VehicleDatum>? vehicleData;
    String? responseCode;
    String? result;
    String? responseMsg;

    VehicleListApiModel({
        this.vehicleData,
        this.responseCode,
        this.result,
        this.responseMsg,
    });

    factory VehicleListApiModel.fromJson(Map<String, dynamic> json) => VehicleListApiModel(
        vehicleData: json["VehicleData"] == null ? [] : List<VehicleDatum>.from(json["VehicleData"]!.map((x) => VehicleDatum.fromJson(x))),
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
    );

    Map<String, dynamic> toJson() => {
        "VehicleData": vehicleData == null ? [] : List<dynamic>.from(vehicleData!.map((x) => x.toJson())),
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
    };
}

class VehicleDatum {
    String? id;
    String? uid;
    String? photo;
    String? modelId;
    String? typeId;
    String? colorId;
    String? year;
    String? licensePlate;
    String? status;
    String? modelTitle;
    String? typeTitle;
    String? colorTitle;

    VehicleDatum({
        this.id,
        this.uid,
        this.photo,
        this.modelId,
        this.typeId,
        this.colorId,
        this.year,
        this.licensePlate,
        this.status,
        this.modelTitle,
        this.typeTitle,
        this.colorTitle,
    });

    factory VehicleDatum.fromJson(Map<String, dynamic> json) => VehicleDatum(
        id: json["id"],
        uid: json["uid"],
        photo: json["photo"],
        modelId: json["model_id"],
        typeId: json["type_id"],
        colorId: json["color_id"],
        year: json["year"],
        licensePlate: json["license_plate"],
        status: json["status"],
        modelTitle: json["model_title"],
        typeTitle: json["type_title"],
        colorTitle: json["color_title"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "uid": uid,
        "photo": photo,
        "model_id": modelId,
        "type_id": typeId,
        "color_id": colorId,
        "year": year,
        "license_plate": licensePlate,
        "status": status,
        "model_title": modelTitle,
        "type_title": typeTitle,
        "color_title": colorTitle,
    };
}
