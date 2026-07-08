// To parse this JSON data, do
//
//     final pageListApiModel = pageListApiModelFromJson(jsonString);

import 'dart:convert';

PageListApiModel pageListApiModelFromJson(String str) => PageListApiModel.fromJson(json.decode(str));

String pageListApiModelToJson(PageListApiModel data) => json.encode(data.toJson());

class PageListApiModel {
    List<Pagelist>? pagelist;
    String? responseCode;
    String? result;
    String? responseMsg;

    PageListApiModel({
        this.pagelist,
        this.responseCode,
        this.result,
        this.responseMsg,
    });

    factory PageListApiModel.fromJson(Map<String, dynamic> json) => PageListApiModel(
        pagelist: json["pagelist"] == null ? [] : List<Pagelist>.from(json["pagelist"]!.map((x) => Pagelist.fromJson(x))),
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
    );

    Map<String, dynamic> toJson() => {
        "pagelist": pagelist == null ? [] : List<dynamic>.from(pagelist!.map((x) => x.toJson())),
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
    };
}

class Pagelist {
    String? title;
    String? description;

    Pagelist({
        this.title,
        this.description,
    });

    factory Pagelist.fromJson(Map<String, dynamic> json) => Pagelist(
        title: json["title"],
        description: json["description"],
    );

    Map<String, dynamic> toJson() => {
        "title": title,
        "description": description,
    };
}
