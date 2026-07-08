// To parse this JSON data, do
//
//     final earningApiModel = earningApiModelFromJson(jsonString);

import 'dart:convert';

EarningApiModel earningApiModelFromJson(String str) => EarningApiModel.fromJson(json.decode(str));

String earningApiModelToJson(EarningApiModel data) => json.encode(data.toJson());

class EarningApiModel {
    num? driverUid;
    String? totalCompleted;
    String? totalCancelled;
    String? totalPending;
    String? wLimit;
    double? totalKmDriven;
    num? totalEarning;
    String? totalPayout;
    String? currency;
    List<PastTrip>? pastTrips;
    String? responseCode;
    String? result;
    String? responseMsg;

    EarningApiModel({
        this.driverUid,
        this.totalCompleted,
        this.totalCancelled,
        this.totalPending,
        this.wLimit,
        this.totalKmDriven,
        this.totalEarning,
        this.totalPayout,
        this.currency,
        this.pastTrips,
        this.responseCode,
        this.result,
        this.responseMsg,
    });

    factory EarningApiModel.fromJson(Map<String, dynamic> json) => EarningApiModel(
        driverUid: json["driver_uid"],
        totalCompleted: json["total_completed"],
        totalCancelled: json["total_cancelled"],
        totalPending: json["total_pending"],
        wLimit: json["w_limit"],
        totalKmDriven: json["total_km_driven"]?.toDouble(),
        totalEarning: json["total_earning"],
        totalPayout: json["total_payout"],
        currency: json["currency"],
        pastTrips: json["pastTrips"] == null ? [] : List<PastTrip>.from(json["pastTrips"]!.map((x) => PastTrip.fromJson(x))),
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
    );

    Map<String, dynamic> toJson() => {
        "driver_uid": driverUid,
        "total_completed": totalCompleted,
        "total_cancelled": totalCancelled,
        "total_pending": totalPending,
        "w_limit": wLimit,
        "total_km_driven": totalKmDriven,
        "total_earning": totalEarning,
        "total_payout": totalPayout,
        "currency": currency,
        "pastTrips": pastTrips == null ? [] : List<dynamic>.from(pastTrips!.map((x) => x.toJson())),
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
    };
}

class PastTrip {
    num? tripId;
    String? originAddress;
    double? originLat;
    double? originLong;
    String? destiAddress;
    double? destiLat;
    double? destiLong;
    String? profilePic;
    String? startTime;
    num? totalSeat;
    num? seatPrice;
    num? driverEarning;

    PastTrip({
        this.tripId,
        this.originAddress,
        this.originLat,
        this.originLong,
        this.destiAddress,
        this.destiLat,
        this.destiLong,
        this.profilePic,
        this.startTime,
        this.totalSeat,
        this.seatPrice,
        this.driverEarning,
    });

    factory PastTrip.fromJson(Map<String, dynamic> json) => PastTrip(
        tripId: json["trip_id"],
        originAddress: json["origin_address"],
        originLat: json["origin_lat"]?.toDouble(),
        originLong: json["origin_long"]?.toDouble(),
        destiAddress: json["desti_address"],
        destiLat: json["desti_lat"]?.toDouble(),
        destiLong: json["desti_long"]?.toDouble(),
        profilePic: json["profile_pic"],
        startTime: json["start_time"],
        totalSeat: json["total_seat"],
        seatPrice: json["seat_price"],
        driverEarning: json["driver_earning"],
    );

    Map<String, dynamic> toJson() => {
        "trip_id": tripId,
        "origin_address": originAddress,
        "origin_lat": originLat,
        "origin_long": originLong,
        "desti_address": destiAddress,
        "desti_lat": destiLat,
        "desti_long": destiLong,
        "profile_pic": profilePic,
        "start_time": startTime,
        "total_seat": totalSeat,
        "seat_price": seatPrice,
        "driver_earning": driverEarning,
    };
}
