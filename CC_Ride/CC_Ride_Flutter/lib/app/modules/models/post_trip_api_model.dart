// To parse this JSON data, do
//
//     final postTripApiModel = postTripApiModelFromJson(jsonString);

import 'dart:convert';

PostTripApiModel postTripApiModelFromJson(String str) => PostTripApiModel.fromJson(json.decode(str));

String postTripApiModelToJson(PostTripApiModel data) => json.encode(data.toJson());

class PostTripApiModel {
    String? responseCode;
    String? result;
    String? responseMsg;
    List<int>? parentTripIds;

    PostTripApiModel({
        this.responseCode,
        this.result,
        this.responseMsg,
        this.parentTripIds,
    });

    factory PostTripApiModel.fromJson(Map<String, dynamic> json) => PostTripApiModel(
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
        parentTripIds: json["parent_trip_ids"] == null ? [] : List<int>.from(json["parent_trip_ids"]!.map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
        "parent_trip_ids": parentTripIds == null ? [] : List<dynamic>.from(parentTripIds!.map((x) => x)),
    };
}
