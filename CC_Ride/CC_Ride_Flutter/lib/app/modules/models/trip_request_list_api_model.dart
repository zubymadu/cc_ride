// To parse this JSON data, do
//
//     final tripRequestListApiModel = tripRequestListApiModelFromJson(jsonString);

import 'dart:convert';

TripRequestListApiModel tripRequestListApiModelFromJson(String str) => TripRequestListApiModel.fromJson(json.decode(str));

String tripRequestListApiModelToJson(TripRequestListApiModel data) => json.encode(data.toJson());

class TripRequestListApiModel {
    String? responseCode;
    String? result;
    String? responseMsg;
    List<Datum>? data;

    TripRequestListApiModel({
        this.responseCode,
        this.result,
        this.responseMsg,
        this.data,
    });

    factory TripRequestListApiModel.fromJson(Map<String, dynamic> json) => TripRequestListApiModel(
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
        data: json["Data"] == null ? [] : List<Datum>.from(json["Data"]!.map((x) => Datum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
        "Data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    };
}

class Datum {
    String? requestId;
    String? fromAddress;
    String? toAddress;
    String? departureDate;
    String? seatRequire;
    String? requestDescription;
    String? userProfile;
    String? userTitle;
    String? userId;
    String? toLat;
    String? toLong;
    String? fromLat;
    String? fromLong;
    num? peopleDriven;
    num? ridesTaken;
    double? kmShared;
    num? totalReviews;
    double? avgRating;
    String? requestDatetime;
    List<TripInfo>? tripInfo;
    String? matchedTripId;
    String? matchedDriverName;
    String? matchedVehicleTitle;
    String? matchedSeatPrice;
    String? matchedStartDate;
    String? matchedStartTime;

    Datum({
        this.requestId,
        this.fromAddress,
        this.toAddress,
        this.departureDate,
        this.seatRequire,
        this.requestDescription,
        this.userProfile,
        this.userTitle,
        this.userId,
        this.toLat,
        this.toLong,
        this.fromLat,
        this.fromLong,
        this.peopleDriven,
        this.ridesTaken,
        this.kmShared,
        this.totalReviews,
        this.avgRating,
        this.requestDatetime,
        this.tripInfo,
        this.matchedTripId,
        this.matchedDriverName,
        this.matchedVehicleTitle,
        this.matchedSeatPrice,
        this.matchedStartDate,
        this.matchedStartTime,
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        requestId: json["request_id"],
        fromAddress: json["from_address"],
        toAddress: json["to_address"],
        departureDate: json["departure_date"],
        seatRequire: json["seat_require"],
        requestDescription: json["request_description"],
        userProfile: json["user_profile"],
        userTitle: json["user_title"],
        userId: json["user_id"],
        toLat: json["to_lat"],
        toLong: json["to_long"],
        fromLat: json["from_lat"],
        fromLong: json["from_long"],
        peopleDriven: json["people_driven"],
        ridesTaken: json["rides_taken"],
        kmShared: json["km_shared"]?.toDouble(),
        totalReviews: json["total_reviews"],
        avgRating: json["avg_rating"]?.toDouble(),
        requestDatetime: json["request_datetime"],
        tripInfo: json["trip_info"] == null ? [] : List<TripInfo>.from(json["trip_info"]!.map((x) => TripInfo.fromJson(x))),
        matchedTripId: json["matched_trip_id"],
        matchedDriverName: json["matched_driver_name"],
        matchedVehicleTitle: json["matched_vehicle_title"],
        matchedSeatPrice: json["matched_seat_price"],
        matchedStartDate: json["matched_start_date"],
        matchedStartTime: json["matched_start_time"],
    );

    Map<String, dynamic> toJson() => {
        "request_id": requestId,
        "from_address": fromAddress,
        "to_address": toAddress,
        "departure_date": departureDate,
        "seat_require": seatRequire,
        "request_description": requestDescription,
        "user_profile": userProfile,
        "user_title": userTitle,
        "user_id": userId,
        "to_lat": toLat,
        "to_long": toLong,
        "from_lat": fromLat,
        "from_long": fromLong,
        "people_driven": peopleDriven,
        "rides_taken": ridesTaken,
        "km_shared": kmShared,
        "total_reviews": totalReviews,
        "avg_rating": avgRating,
        "request_datetime": requestDatetime,
        "trip_info": tripInfo == null ? [] : List<dynamic>.from(tripInfo!.map((x) => x.toJson())),
        "matched_trip_id": matchedTripId,
        "matched_driver_name": matchedDriverName,
        "matched_vehicle_title": matchedVehicleTitle,
        "matched_seat_price": matchedSeatPrice,
        "matched_start_date": matchedStartDate,
        "matched_start_time": matchedStartTime,
    };
}

class TripInfo {
    String? tripId;
    String? totalSeat;
    String? seatPrice;
    String? origin;
    double? originLat;
    double? originLong;
    String? destination;
    double? destiLat;
    double? destiLong;
    num? peopleDriven;
    num? ridesTaken;
    double? kmShared;
    num? totalReviews;
    double? avgRating;
    String? uid;
    String? userName;
    String? profilePic;

    TripInfo({
        this.tripId,
        this.totalSeat,
        this.seatPrice,
        this.origin,
        this.originLat,
        this.originLong,
        this.destination,
        this.destiLat,
        this.destiLong,
        this.peopleDriven,
        this.ridesTaken,
        this.kmShared,
        this.totalReviews,
        this.avgRating,
        this.uid,
        this.userName,
        this.profilePic,
    });

    factory TripInfo.fromJson(Map<String, dynamic> json) => TripInfo(
        tripId: json["trip_id"],
        totalSeat: json["total_seat"],
        seatPrice: json["seat_price"],
        origin: json["origin"],
        originLat: json["origin_lat"]?.toDouble(),
        originLong: json["origin_long"]?.toDouble(),
        destination: json["destination"],
        destiLat: json["desti_lat"]?.toDouble(),
        destiLong: json["desti_long"]?.toDouble(),
        peopleDriven: json["people_driven"],
        ridesTaken: json["rides_taken"],
        kmShared: json["km_shared"]?.toDouble(),
        totalReviews: json["total_reviews"],
        avgRating: json["avg_rating"]?.toDouble(),
        uid: json["uid"],
        userName: json["user_name"],
        profilePic: json["profile_pic"],
    );

    Map<String, dynamic> toJson() => {
        "trip_id": tripId,
        "total_seat": totalSeat,
        "seat_price": seatPrice,
        "origin": origin,
        "origin_lat": originLat,
        "origin_long": originLong,
        "destination": destination,
        "desti_lat": destiLat,
        "desti_long": destiLong,
        "people_driven": peopleDriven,
        "rides_taken": ridesTaken,
        "km_shared": kmShared,
        "total_reviews": totalReviews,
        "avg_rating": avgRating,
        "uid": uid,
        "user_name": userName,
        "profile_pic": profilePic,
    };
}
