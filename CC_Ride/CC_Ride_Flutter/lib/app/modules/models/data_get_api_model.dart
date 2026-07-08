// To parse this JSON data, do
//
//     final dataGetApiModel = dataGetApiModelFromJson(jsonString);

import 'dart:convert';

DataGetApiModel dataGetApiModelFromJson(String str) => DataGetApiModel.fromJson(json.decode(str));

String dataGetApiModelToJson(DataGetApiModel data) => json.encode(data.toJson());

class DataGetApiModel {
    List<DataGetDatum>? backSeatingData;
    List<DataGetDatum>? luggageData;
    List<RestrictionDatum>? restrictionData;
    List<VehicleDatum>? vehicleData;
    String? responseCode;
    String? result;
    String? responseMsg;

    DataGetApiModel({
        this.backSeatingData,
        this.luggageData,
        this.restrictionData,
        this.vehicleData,
        this.responseCode,
        this.result,
        this.responseMsg,
    });

    factory DataGetApiModel.fromJson(Map<String, dynamic> json) => DataGetApiModel(
        backSeatingData: json["BackSeatingData"] == null ? [] : List<DataGetDatum>.from(json["BackSeatingData"]!.map((x) => DataGetDatum.fromJson(x))),
        luggageData: json["LuggageData"] == null ? [] : List<DataGetDatum>.from(json["LuggageData"]!.map((x) => DataGetDatum.fromJson(x))),
        restrictionData: json["RestrictionData"] == null ? [] : List<RestrictionDatum>.from(json["RestrictionData"]!.map((x) => RestrictionDatum.fromJson(x))),
        vehicleData: json["VehicleData"] == null ? [] : List<VehicleDatum>.from(json["VehicleData"]!.map((x) => VehicleDatum.fromJson(x))),
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
    );

    Map<String, dynamic> toJson() => {
        "BackSeatingData": backSeatingData == null ? [] : List<dynamic>.from(backSeatingData!.map((x) => x.toJson())),
        "LuggageData": luggageData == null ? [] : List<dynamic>.from(luggageData!.map((x) => x.toJson())),
        "RestrictionData": restrictionData == null ? [] : List<dynamic>.from(restrictionData!.map((x) => x.toJson())),
        "VehicleData": vehicleData == null ? [] : List<dynamic>.from(vehicleData!.map((x) => x.toJson())),
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
    };
}

class DataGetDatum {
    String? id;
    String? title;

    DataGetDatum({
        this.id,
        this.title,
    });

    factory DataGetDatum.fromJson(Map<String, dynamic> json) => DataGetDatum(
        id: json["id"],
        title: json["title"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
    };
}

class RestrictionDatum {
    String? id;
    String? title;
    String? status;

    RestrictionDatum({
        this.id,
        this.title,
        this.status,
    });

    factory RestrictionDatum.fromJson(Map<String, dynamic> json) => RestrictionDatum(
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
