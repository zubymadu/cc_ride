// To parse this JSON data, do
//
//     final tripDetailsApiModel = tripDetailsApiModelFromJson(jsonString);

import 'dart:convert';

import 'package:carride/app/modules/models/book_trip_details_api_model.dart';

TripDetailsApiModel tripDetailsApiModelFromJson(String str) => TripDetailsApiModel.fromJson(json.decode(str));

String tripDetailsApiModelToJson(TripDetailsApiModel data) => json.encode(data.toJson());

class TripDetailsApiModel {
    String? responseCode;
    String? result;
    String? responseMsg;
    TripData? tripData;

    TripDetailsApiModel({
        this.responseCode,
        this.result,
        this.responseMsg,
        this.tripData,
    });

    factory TripDetailsApiModel.fromJson(Map<String, dynamic> json) => TripDetailsApiModel(
        responseCode: json["ResponseCode"],
        result: json["Result"],
        responseMsg: json["ResponseMsg"],
        tripData: json["TripData"] == null ? null : TripData.fromJson(json["TripData"]),
    );

    Map<String, dynamic> toJson() => {
        "ResponseCode": responseCode,
        "Result": result,
        "ResponseMsg": responseMsg,
        "TripData": tripData?.toJson(),
    };
}

class TripData {
    String? tripId;
    String? totalSeat;
    String? seatPrice;
    String? originAddress;
    double? originLat;
    double? originLong;
    String? tripStatus;
    String? destiAddress;
    num? peopleDriven;
    num? ridesTaken;
    double? kmShared;
    num? totalReviews;
    double? avgRating;
    double? destiLat;
    double? destiLong;
    DateTime? tripStartDate;
    String? tripStartTime;
    String? tripDescription;
    String? tripIsReturn;
    ReturnTripDetail? returnTripDetail;
    num? instantApprove;
    String? userProfile;
    String? userTitle;
    String? userId;
    String? userBio;
    String? userDob;
    String? userJoined;
    String? routeId;
    String? routeCode;
    String? rideSchedule;
    String? vehicleTitle;
    String? vehicleImage;
    String? licensePlate;
    String? year;
    String? vehicleColor;
    String? vehicleType;
    List<StopsDetail>? stopsDetails;
    List<RestriDetail>? restriDetails;
    String? luggageDetails;
    String? backrowDetails;
    num? bookedSeat;
    num? remainSeat;
    List<BookedUser>? bookedUsers;

    TripData({
        this.tripId,
        this.totalSeat,
        this.seatPrice,
        this.originAddress,
        this.originLat,
        this.originLong,
        this.tripStatus,
        this.destiAddress,
        this.peopleDriven,
        this.ridesTaken,
        this.kmShared,
        this.totalReviews,
        this.avgRating,
        this.destiLat,
        this.destiLong,
        this.tripStartDate,
        this.tripStartTime,
        this.tripDescription,
        this.tripIsReturn,
        this.returnTripDetail,
        this.instantApprove,
        this.userProfile,
        this.userTitle,
        this.userId,
        this.userBio,
        this.userDob,
        this.userJoined,
        this.routeId,
        this.routeCode,
        this.rideSchedule,
        this.vehicleTitle,
        this.vehicleImage,
        this.licensePlate,
        this.year,
        this.vehicleColor,
        this.vehicleType,
        this.stopsDetails,
        this.restriDetails,
        this.luggageDetails,
        this.backrowDetails,
        this.bookedSeat,
        this.remainSeat,
        this.bookedUsers,
    });

    factory TripData.fromJson(Map<String, dynamic> json) => TripData(
        tripId: json["trip_id"],
        totalSeat: json["total_seat"],
        seatPrice: json["seat_price"],
        originAddress: json["origin_address"],
        originLat: json["origin_lat"]?.toDouble(),
        originLong: json["origin_long"]?.toDouble(),
        tripStatus: json["trip_status"],
        destiAddress: json["desti_address"],
        peopleDriven: json["people_driven"],
        ridesTaken: json["rides_taken"],
        kmShared: json["km_shared"]?.toDouble(),
        totalReviews: json["total_reviews"],
        avgRating: json["avg_rating"]?.toDouble(),
        destiLat: json["desti_lat"]?.toDouble(),
        destiLong: json["desti_long"]?.toDouble(),
        tripStartDate: json["trip_start_date"] == null ? null : DateTime.parse(json["trip_start_date"]),
        tripStartTime: json["trip_start_time"],
        tripDescription: json["trip_description"],
        tripIsReturn: json["trip_is_return"],
        returnTripDetail: json["return_trip_detail"] == null ? null : ReturnTripDetail.fromJson(json["return_trip_detail"]),
        instantApprove: json["instant_approve"],
        userProfile: json["user_profile"],
        userTitle: json["user_title"],
        userId: json["user_id"],
        userBio: json["user_bio"],
        userDob: json["user_dob"],
        userJoined: json["user_joined"],
        routeId: json["route_id"],
        routeCode: json["route_code"],
        rideSchedule: json["ride_schedule"],
        vehicleTitle: json["vehicle_title"],
        vehicleImage: json["vehicle_image"],
        licensePlate: json["license_plate"],
        year: json["year"],
        vehicleColor: json["vehicle_color"],
        vehicleType: json["vehicle_type"],
        stopsDetails: json["stops_details"] == null ? [] : List<StopsDetail>.from(json["stops_details"]!.map((x) => StopsDetail.fromJson(x))),
        restriDetails: json["restri_details"] == null ? [] : List<RestriDetail>.from(json["restri_details"]!.map((x) => RestriDetail.fromJson(x))),
        luggageDetails: json["luggage_details"],
        backrowDetails: json["backrow_details"],
        bookedSeat: json["booked_seat"],
        remainSeat: json["remain_seat"],
        bookedUsers: json["booked_users"] == null ? [] : List<BookedUser>.from(json["booked_users"]!.map((x) => BookedUser.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "trip_id": tripId,
        "total_seat": totalSeat,
        "seat_price": seatPrice,
        "origin_address": originAddress,
        "origin_lat": originLat,
        "origin_long": originLong,
        "trip_status": tripStatus,
        "desti_address": destiAddress,
        "people_driven": peopleDriven,
        "rides_taken": ridesTaken,
        "km_shared": kmShared,
        "total_reviews": totalReviews,
        "avg_rating": avgRating,
        "desti_lat": destiLat,
        "desti_long": destiLong,
        "trip_start_date": "${tripStartDate!.year.toString().padLeft(4, '0')}-${tripStartDate!.month.toString().padLeft(2, '0')}-${tripStartDate!.day.toString().padLeft(2, '0')}",
        "trip_start_time": tripStartTime,
        "trip_description": tripDescription,
        "trip_is_return": tripIsReturn,
        "return_trip_detail": returnTripDetail?.toJson(),
        "instant_approve": instantApprove,
        "user_profile": userProfile,
        "user_title": userTitle,
        "user_id": userId,
        "user_bio": userBio,
        "user_dob": userDob,
        "user_joined": userJoined,
        "route_id": routeId,
        "route_code": routeCode,
        "ride_schedule": rideSchedule,
        "vehicle_title": vehicleTitle,
        "vehicle_image": vehicleImage,
        "license_plate": licensePlate,
        "year": year,
        "vehicle_color": vehicleColor,
        "vehicle_type": vehicleType,
        "stops_details": stopsDetails == null ? [] : List<dynamic>.from(stopsDetails!.map((x) => x.toJson())),
        "restri_details": restriDetails == null ? [] : List<dynamic>.from(restriDetails!.map((x) => x.toJson())),
        "luggage_details": luggageDetails,
        "backrow_details": backrowDetails,
        "booked_seat": bookedSeat,
        "remain_seat": remainSeat,
        "booked_users": bookedUsers == null ? [] : List<dynamic>.from(bookedUsers!.map((x) => x.toJson())),
    };
}

class BookedUser {
    String? bookId;
    // Backend sends this as a UUID string (passengerId), not a number — was
    // mistyped as num?, which threw a type-cast exception inside
    // tripDetailsApiModelFromJson() for any trip with at least one booking,
    // silently caught by commonApi's try/catch and surfaced to the user as
    // "Unable to load trip details" on tap.
    String? userId;
    String? userName;
    String? userMobile;
    String? profilePic;
    num? totalSeat;
    num? isApprove;
    String? bookStatus;
    String? pickupOtp;
    String? dropOtp;

    BookedUser({
        this.bookId,
        this.userId,
        this.userName,
        this.userMobile,
        this.profilePic,
        this.totalSeat,
        this.isApprove,
        this.bookStatus,
        this.pickupOtp,
        this.dropOtp,
    });

    factory BookedUser.fromJson(Map<String, dynamic> json) => BookedUser(
        bookId: json["book_id"],
        userId: json["user_id"],
        userName: json["user_name"],
        userMobile: json["user_mobile"],
        profilePic: json["profile_pic"],
        totalSeat: json["total_seat"],
        isApprove: json["is_approve"],
        bookStatus: json["book_status"],
        pickupOtp: json["pickup_otp"],
        dropOtp: json["drop_otp"],
    );

    Map<String, dynamic> toJson() => {
        "book_id": bookId,
        "user_id": userId,
        "user_name": userName,
        "user_mobile": userMobile,
        "profile_pic": profilePic,
        "total_seat": totalSeat,
        "is_approve": isApprove,
        "book_status": bookStatus,
        "pickup_otp": pickupOtp,
        "drop_otp": dropOtp,
    };
}

class RestriDetail {
    String? title;

    RestriDetail({
        this.title,
    });

    factory RestriDetail.fromJson(Map<String, dynamic> json) => RestriDetail(
        title: json["title"],
    );

    Map<String, dynamic> toJson() => {
        "title": title,
    };
}

class ReturnTripDetail {
    String? returnDate;
    String? returnTime;

    ReturnTripDetail({
        this.returnDate,
        this.returnTime,
    });

    factory ReturnTripDetail.fromJson(Map<String, dynamic> json) => ReturnTripDetail(
        returnDate: json["return_date"],
        returnTime: json["return_time"],
    );

    Map<String, dynamic> toJson() => {
        "return_date": returnDate,
        "return_time": returnTime,
    };
}

// class StopsDetail {
//     String? location;
//     double? lat;
//     double? long;

//     StopsDetail({
//         this.location,
//         this.lat,
//         this.long,
//     });

//     factory StopsDetail.fromJson(Map<String, dynamic> json) => StopsDetail(
//         location: json["location"],
//         lat: json["lat"]?.toDouble(),
//         long: json["long"]?.toDouble(),
//     );

//     Map<String, dynamic> toJson() => {
//         "location": location,
//         "lat": lat,
//         "long": long,
//     };
// }
