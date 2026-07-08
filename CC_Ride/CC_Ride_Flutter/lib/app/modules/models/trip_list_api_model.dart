// To parse this JSON data, do
//
//     final tripListApiModel = tripListApiModelFromJson(jsonString);

import 'dart:convert';

TripListApiModel tripListApiModelFromJson(String str) => TripListApiModel.fromJson(json.decode(str));

String tripListApiModelToJson(TripListApiModel data) => json.encode(data.toJson());

class TripListApiModel {
    String? responseCode;
    String? result;
    String? responseMsg;
    String? tripType;
    List<TripDatum>? tripData;

    TripListApiModel({
        this.responseCode,
        this.result,
        this.responseMsg,
        this.tripType,
        this.tripData,
    });

    factory TripListApiModel.fromJson(Map<String, dynamic> json) => TripListApiModel(
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
        tripType: json["TripType"],
        tripData: json["TripData"] == null ? [] : List<TripDatum>.from(json["TripData"]!.map((x) => TripDatum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
        "TripType": tripType,
        "TripData": tripData == null ? [] : List<dynamic>.from(tripData!.map((x) => x.toJson())),
    };
}

class TripDatum {
    String? tripId;
    String? totalSeat;
    String? seatPrice;
    String? originAddress;
    double? originLat;
    double? originLong;
    String? destiAddress;
    double? destiLat;
    double? destiLong;
    String? tripStartDate;
    String? tripStartTime;
    String? tripIsReturn;
    num? instantApprove;
    num? totalRate;
    num? totalDriven;
    String? tripStatus;
    String? userProfile;
    String? userTitle;
    String? vehicleTitle;
    String? vehicleImage;
    String? vehicleType;

    TripDatum({
        this.tripId,
        this.totalSeat,
        this.seatPrice,
        this.originAddress,
        this.originLat,
        this.originLong,
        this.destiAddress,
        this.destiLat,
        this.destiLong,
        this.tripStartDate,
        this.tripStartTime,
        this.tripIsReturn,
        this.instantApprove,
        this.totalRate,
        this.totalDriven,
        this.tripStatus,
        this.userProfile,
        this.userTitle,
        this.vehicleTitle,
        this.vehicleImage,
        this.vehicleType,
    });

    factory TripDatum.fromJson(Map<String, dynamic> json) => TripDatum(
        tripId: json["trip_id"],
        totalSeat: json["total_seat"],
        seatPrice: json["seat_price"],
        originAddress: json["origin_address"],
        originLat: json["origin_lat"]?.toDouble(),
        originLong: json["origin_long"]?.toDouble(),
        destiAddress: json["desti_address"],
        destiLat: json["desti_lat"]?.toDouble(),
        destiLong: json["desti_long"]?.toDouble(),
        tripStartDate: json["trip_start_date"],
        tripStartTime: json["trip_start_time"],
        tripIsReturn: json["trip_is_return"],
        instantApprove: json["instant_approve"],
        totalRate: json["total_rate"],
        totalDriven: json["total_driven"]?.toDouble(),
        tripStatus: json["trip_status"],
        userProfile: json["user_profile"],
        userTitle: json["user_title"],
        vehicleTitle: json["vehicle_title"],
        vehicleImage: json["vehicle_image"],
        vehicleType: json["vehicle_type"],
    );

    Map<String, dynamic> toJson() => {
        "trip_id": tripId,
        "total_seat": totalSeat,
        "seat_price": seatPrice,
        "origin_address": originAddress,
        "origin_lat": originLat,
        "origin_long": originLong,
        "desti_address": destiAddress,
        "desti_lat": destiLat,
        "desti_long": destiLong,
        "trip_start_date": tripStartDate,
        "trip_start_time": tripStartTime,
        "trip_is_return": tripIsReturn,
        "instant_approve": instantApprove,
        "total_rate": totalRate,
        "total_driven": totalDriven,
        "trip_status": tripStatus,
        "user_profile": userProfile,
        "user_title": userTitle,
        "vehicle_title": vehicleTitle,
        "vehicle_image": vehicleImage,
        "vehicle_type": vehicleType,
    };
}
