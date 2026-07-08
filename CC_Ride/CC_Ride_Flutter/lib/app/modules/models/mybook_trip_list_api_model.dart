// To parse this JSON data, do
//
//     final myBookTripListApiModel = myBookTripListApiModelFromJson(jsonString);

import 'dart:convert';

MyBookTripListApiModel myBookTripListApiModelFromJson(String str) => MyBookTripListApiModel.fromJson(json.decode(str));

String myBookTripListApiModelToJson(MyBookTripListApiModel data) => json.encode(data.toJson());

class MyBookTripListApiModel {
    String? responseCode;
    String? result;
    String? responseMsg;
    List<TripDatum>? tripData;

    MyBookTripListApiModel({
        this.responseCode,
        this.result,
        this.responseMsg,
        this.tripData,
    });

    factory MyBookTripListApiModel.fromJson(Map<String, dynamic> json) => MyBookTripListApiModel(
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
        tripData: json["TripData"] == null ? [] : List<TripDatum>.from(json["TripData"]!.map((x) => TripDatum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
        "TripData": tripData == null ? [] : List<dynamic>.from(tripData!.map((x) => x.toJson())),
    };
}

class TripDatum {
    String? tripId;
    String? ownerId;
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
    double? totalDriven;
    String? userProfile;
    String? userTitle;
    String? status;
    Vehicle? vehicle;

    TripDatum({
        this.tripId,
        this.ownerId,
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
        this.userProfile,
        this.userTitle,
        this.status,
        this.vehicle,
    });

    factory TripDatum.fromJson(Map<String, dynamic> json) => TripDatum(
        tripId: json["trip_id"],
        ownerId: json["owner_id"],
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
        userProfile: json["user_profile"],
        userTitle: json["user_title"],
        status: json["status"],
        vehicle: json["vehicle"] == null ? null : Vehicle.fromJson(json["vehicle"]),
    );

    Map<String, dynamic> toJson() => {
        "trip_id": tripId,
        "owner_id": ownerId,
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
        "user_profile": userProfile,
        "user_title": userTitle,
        "status": status,
        "vehicle": vehicle?.toJson(),
    };
}

class Vehicle {
    String? vehicleTitle;
    String? vehicleImage;
    String? vehicleType;

    Vehicle({
        this.vehicleTitle,
        this.vehicleImage,
        this.vehicleType,
    });

    factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        vehicleTitle: json["vehicle_title"],
        vehicleImage: json["vehicle_image"],
        vehicleType: json["vehicle_type"],
    );

    Map<String, dynamic> toJson() => {
        "vehicle_title": vehicleTitle,
        "vehicle_image": vehicleImage,
        "vehicle_type": vehicleType,
    };
}
