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
    // The ride id is a UUID string, not a numeric id — this used to be
    // typed List<int>, which meant the model could never actually hold the
    // real trip id in the first place.
    List<String>? parentTripIds;

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
        parentTripIds: json["parent_trip_ids"] == null ? [] : List<String>.from(json["parent_trip_ids"]!.map((x) => "$x")),
    );

    Map<String, dynamic> toJson() => {
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
        "parent_trip_ids": parentTripIds == null ? [] : List<dynamic>.from(parentTripIds!.map((x) => x)),
    };
}
