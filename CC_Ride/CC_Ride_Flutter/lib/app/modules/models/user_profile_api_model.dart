// To parse this JSON data, do
//
//     final userProfileApiModel = userProfileApiModelFromJson(jsonString);

import 'dart:convert';

UserProfileApiModel userProfileApiModelFromJson(String str) => UserProfileApiModel.fromJson(json.decode(str));

String userProfileApiModelToJson(UserProfileApiModel data) => json.encode(data.toJson());

class UserProfileApiModel {
    String? responseCode;
    String? result;
    String? responseMsg;
    UserInfo? userInfo;
    Stats? stats;
    List<Review>? reviews;
    List<UpcomingTrip>? upcomingTrips;

    UserProfileApiModel({
        this.responseCode,
        this.result,
        this.responseMsg,
        this.userInfo,
        this.stats,
        this.reviews,
        this.upcomingTrips,
    });

    factory UserProfileApiModel.fromJson(Map<String, dynamic> json) => UserProfileApiModel(
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
        userInfo: json["UserInfo"] == null ? null : UserInfo.fromJson(json["UserInfo"]),
        stats: json["Stats"] == null ? null : Stats.fromJson(json["Stats"]),
        reviews: json["Reviews"] == null ? [] : List<Review>.from(json["Reviews"]!.map((x) => Review.fromJson(x))),
        upcomingTrips: json["UpcomingTrips"] == null ? [] : List<UpcomingTrip>.from(json["UpcomingTrips"]!.map((x) => UpcomingTrip.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
        "UserInfo": userInfo?.toJson(),
        "Stats": stats?.toJson(),
        "Reviews": reviews == null ? [] : List<dynamic>.from(reviews!.map((x) => x.toJson())),
        "UpcomingTrips": upcomingTrips == null ? [] : List<dynamic>.from(upcomingTrips!.map((x) => x.toJson())),
    };
}

class Review {
    String? bookUid;
    String? name;
    String? profilePic;
    String? totalRate;
    String? rateDesc;

    Review({
        this.bookUid,
        this.name,
        this.profilePic,
        this.totalRate,
        this.rateDesc,
    });

    factory Review.fromJson(Map<String, dynamic> json) => Review(
        bookUid: json["book_uid"],
        name: json["name"],
        profilePic: json["profile_pic"],
        totalRate: json["total_rate"],
        rateDesc: json["rate_desc"],
    );

    Map<String, dynamic> toJson() => {
        "book_uid": bookUid,
        "name": name,
        "profile_pic": profilePic,
        "total_rate": totalRate,
        "rate_desc": rateDesc,
    };
}

class Stats {
    num? peopleDriven;
    num? ridesTaken;
    double? kmShared;
    num? totalReviews;
    double? avgRating;

    Stats({
        this.peopleDriven,
        this.ridesTaken,
        this.kmShared,
        this.totalReviews,
        this.avgRating,
    });

    factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        peopleDriven: json["people_driven"],
        ridesTaken: json["rides_taken"],
        kmShared: double.tryParse('${json["km_shared"]}'),
        totalReviews: json["total_reviews"],
        avgRating: double.tryParse('${json["avg_rating"]}'),
    );

    Map<String, dynamic> toJson() => {
        "people_driven": peopleDriven,
        "rides_taken": ridesTaken,
        "km_shared": kmShared,
        "total_reviews": totalReviews,
        "avg_rating": avgRating,
    };
}

class UpcomingTrip {
    String? tripId;
    String? originAddress;
    double? originLat;
    double? originLong;
    String? seatPrice;
    String? destiAddress;
    double? destiLat;
    double? destiLong;
    String? profilePic;
    String? startTime;
    String? totalSeat;

    UpcomingTrip({
        this.tripId,
        this.originAddress,
        this.originLat,
        this.originLong,
        this.seatPrice,
        this.destiAddress,
        this.destiLat,
        this.destiLong,
        this.profilePic,
        this.startTime,
        this.totalSeat,
    });

    factory UpcomingTrip.fromJson(Map<String, dynamic> json) => UpcomingTrip(
        tripId: json["trip_id"],
        originAddress: json["origin_address"],
        originLat: json["origin_lat"]?.toDouble(),
        originLong: json["origin_long"]?.toDouble(),
        seatPrice: json["seat_price"],
        destiAddress: json["desti_address"],
        destiLat: json["desti_lat"]?.toDouble(),
        destiLong: json["desti_long"]?.toDouble(),
        profilePic: json["profile_pic"],
        startTime: json["start_time"],
        totalSeat: json["total_seat"],
    );

    Map<String, dynamic> toJson() => {
        "trip_id": tripId,
        "origin_address": originAddress,
        "origin_lat": originLat,
        "origin_long": originLong,
        "seat_price": seatPrice,
        "desti_address": destiAddress,
        "desti_lat": destiLat,
        "desti_long": destiLong,
        "profile_pic": profilePic,
        "start_time": startTime,
        "total_seat": totalSeat,
    };
}

class UserInfo {
    String? name;
    String? profilePic;
    String? joined;
    String? dob;
    String? bio;
    String? isMobileVerify;
    String? isEmailVerify;

    UserInfo({
        this.name,
        this.profilePic,
        this.joined,
        this.dob,
        this.bio,
        this.isMobileVerify,
        this.isEmailVerify,
    });

    factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        name: json["name"],
        profilePic: json["profile_pic"],
        joined: json["joined"] ?? (json["created_at"] != null
            ? "Joined ${DateTime.tryParse(json["created_at"])?.year ?? ''}"
            : null),
        dob: json["dob"],
        bio: json["bio"],
        isMobileVerify: json["is_mobile_verify"],
        isEmailVerify: json["is_email_verify"],
    );

    Map<String, dynamic> toJson() => {
        "name": name,
        "profile_pic": profilePic,
        "joined": joined,
        "dob": dob,
        "bio": bio,
        "is_mobile_verify": isMobileVerify,
        "is_email_verify": isEmailVerify,
    };
}
