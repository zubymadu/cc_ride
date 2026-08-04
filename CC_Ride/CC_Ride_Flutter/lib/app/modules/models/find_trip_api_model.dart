// To parse this JSON data, do
//
//     final findtripmodel = findtripmodelFromJson(jsonString);

import 'dart:convert';

Findtripmodel findtripmodelFromJson(String str) => Findtripmodel.fromJson(json.decode(str));

String findtripmodelToJson(Findtripmodel data) => json.encode(data.toJson());

class Findtripmodel {
    String? responseCode;
    String? result;
    String? responseMsg;
    Data? data;

    Findtripmodel({
        this.responseCode,
        this.result,
        this.responseMsg,
        this.data,
    });

    factory Findtripmodel.fromJson(Map<String, dynamic> json) => Findtripmodel(
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
        data: json["Data"] == null ? null : Data.fromJson(json["Data"]),
    );

    Map<String, dynamic> toJson() => {
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
        "Data": data?.toJson(),
    };
}

class Data {
    List<TripDatum>? tripData;
    List<RequestDatum>? requestData;

    Data({
        this.tripData,
        this.requestData,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        tripData: json["TripData"] == null ? [] : List<TripDatum>.from(json["TripData"]!.map((x) => TripDatum.fromJson(x))),
        requestData: json["RequestData"] == null ? [] : List<RequestDatum>.from(json["RequestData"]!.map((x) => RequestDatum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "TripData": tripData == null ? [] : List<dynamic>.from(tripData!.map((x) => x.toJson())),
        "RequestData": requestData == null ? [] : List<dynamic>.from(requestData!.map((x) => x.toJson())),
    };
}

class RequestDatum {
    String? requestId;
    String? fromAddress;
    String? fromLat;
    String? fromLong;
    String? toAddress;
    String? toLat;
    String? toLong;
    num? peopleDriven;
    num? ridesTaken;
    double? kmShared;
    num? totalReviews;
    double? avgRating;
    String? departureDate;
    String? seatRequire;
    String? requestDescription;
    String? userProfile;
    String? userTitle;
    num? isInvited;
    String? userId;

    RequestDatum({
        this.requestId,
        this.fromAddress,
        this.fromLat,
        this.fromLong,
        this.toAddress,
        this.toLat,
        this.toLong,
        this.peopleDriven,
        this.ridesTaken,
        this.kmShared,
        this.totalReviews,
        this.avgRating,
        this.departureDate,
        this.seatRequire,
        this.requestDescription,
        this.userProfile,
        this.userTitle,
        this.isInvited,
        this.userId,
    });

    factory RequestDatum.fromJson(Map<String, dynamic> json) => RequestDatum(
        requestId: json["request_id"],
        fromAddress: json["from_address"],
        fromLat: json["from_lat"],
        fromLong: json["from_long"],
        toAddress: json["to_address"],
        toLat: json["to_lat"],
        toLong: json["to_long"],
        peopleDriven: json["people_driven"],
        ridesTaken: json["rides_taken"],
        kmShared: json["km_shared"]?.toDouble(),
        totalReviews: json["total_reviews"],
        avgRating: json["avg_rating"]?.toDouble(),
        departureDate: json["departure_date"],
        seatRequire: json["seat_require"],
        requestDescription: json["request_description"],
        userProfile: json["user_profile"],
        userTitle: json["user_title"],
        isInvited: json["is_invited"],
        userId: json["user_id"],
    );

    Map<String, dynamic> toJson() => {
        "request_id": requestId,
        "from_address": fromAddress,
        "from_lat": fromLat,
        "from_long": fromLong,
        "to_address": toAddress,
        "to_lat": toLat,
        "to_long": toLong,
        "people_driven": peopleDriven,
        "rides_taken": ridesTaken,
        "km_shared": kmShared,
        "total_reviews": totalReviews,
        "avg_rating": avgRating,
        "departure_date": departureDate,
        "seat_require": seatRequire,
        "request_description": requestDescription,
        "user_profile": userProfile,
        "user_title": userTitle,
        "is_invited": isInvited,
        "user_id": userId,
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
    num? tripIsReturn;
    num? instantApprove;
    num? peopleDriven;
    num? ridesTaken;
    double? kmShared;
    num? totalReviews;
    double? avgRating;
    num? totalCompletedTrip;
    double? totalDriven;
    String? userProfile;
    String? userTitle;
    String? vehicleTitle;
    String? routeId;
    String? routeCode;
    num? remainSeat;

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
        this.peopleDriven,
        this.ridesTaken,
        this.kmShared,
        this.totalReviews,
        this.avgRating,
        this.totalCompletedTrip,
        this.totalDriven,
        this.userProfile,
        this.userTitle,
        this.vehicleTitle,
        this.routeId,
        this.routeCode,
        this.remainSeat,
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
        peopleDriven: json["people_driven"],
        ridesTaken: json["rides_taken"],
        kmShared: json["km_shared"]?.toDouble(),
        totalReviews: json["total_reviews"],
        avgRating: json["avg_rating"]?.toDouble(),
        totalCompletedTrip: json["total_completed_trip"],
        totalDriven: json["total_driven"]?.toDouble(),
        userProfile: json["user_profile"],
        userTitle: json["user_title"],
        vehicleTitle: json["vehicle_title"],
        routeId: json["route_id"],
        routeCode: json["route_code"],
        remainSeat: json["remain_seat"],
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
        "people_driven": peopleDriven,
        "rides_taken": ridesTaken,
        "km_shared": kmShared,
        "total_reviews": totalReviews,
        "avg_rating": avgRating,
        "total_completed_trip": totalCompletedTrip,
        "total_driven": totalDriven,
        "user_profile": userProfile,
        "user_title": userTitle,
        "vehicle_title": vehicleTitle,
        "route_id": routeId,
        "route_code": routeCode,
        "remain_seat": remainSeat,
    };
}
