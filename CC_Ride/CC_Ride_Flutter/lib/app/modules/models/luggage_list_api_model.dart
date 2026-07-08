// To parse this JSON data, do
//
//     final luggageListApiModel = luggageListApiModelFromJson(jsonString);

import 'dart:convert';

LuggageListApiModel luggageListApiModelFromJson(String str) => LuggageListApiModel.fromJson(json.decode(str));

String luggageListApiModelToJson(LuggageListApiModel data) => json.encode(data.toJson());

class LuggageListApiModel {
    List<CarluggageDatum>? carluggageData;
    String? responseCode;
    String? result;
    String? responseMsg;

    LuggageListApiModel({
        this.carluggageData,
        this.responseCode,
        this.result,
        this.responseMsg,
    });

    factory LuggageListApiModel.fromJson(Map<String, dynamic> json) => LuggageListApiModel(
        carluggageData: json["CarluggageData"] == null ? [] : List<CarluggageDatum>.from(json["CarluggageData"]!.map((x) => CarluggageDatum.fromJson(x))),
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
    );

    Map<String, dynamic> toJson() => {
        "CarluggageData": carluggageData == null ? [] : List<dynamic>.from(carluggageData!.map((x) => x.toJson())),
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
    };
}

class CarluggageDatum {
    String? id;
    String? title;

    CarluggageDatum({
        this.id,
        this.title,
    });

    factory CarluggageDatum.fromJson(Map<String, dynamic> json) => CarluggageDatum(
        id: json["id"],
        title: json["title"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
    };
}
