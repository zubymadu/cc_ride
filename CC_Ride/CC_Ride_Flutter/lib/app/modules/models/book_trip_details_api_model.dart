// To parse this JSON data, do
//
//     final bookTripDetailsApiModel = bookTripDetailsApiModelFromJson(jsonString);

import 'dart:convert';

BookTripDetailsApiModel bookTripDetailsApiModelFromJson(String str) => BookTripDetailsApiModel.fromJson(json.decode(str));

String bookTripDetailsApiModelToJson(BookTripDetailsApiModel data) => json.encode(data.toJson());

class BookTripDetailsApiModel {
    String? responseCode;
    String? result;
    String? responseMsg;
    TripData? tripData;

    BookTripDetailsApiModel({
        this.responseCode,
        this.result,
        this.responseMsg,
        this.tripData,
    });

    factory BookTripDetailsApiModel.fromJson(Map<String, dynamic> json) => BookTripDetailsApiModel(
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
    String? destiAddress;
    double? destiLat;
    double? destiLong;
    DateTime? tripStartDate;
    String? tripStartTime;
    String? tripStatus;
    num? peopleDriven;
    num? ridesTaken;
    double? kmShared;
    num? totalReviews;
    double? avgRating;
    String? tripIsReturn;
    num? instantApprove;
    String? userProfile;
    String? userTitle;
    String? userId;
    String? userMobile;
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
        this.destiAddress,
        this.destiLat,
        this.destiLong,
        this.tripStartDate,
        this.tripStartTime,
        this.tripStatus,
        this.peopleDriven,
        this.ridesTaken,
        this.kmShared,
        this.totalReviews,
        this.avgRating,
        this.tripIsReturn,
        this.instantApprove,
        this.userProfile,
        this.userTitle,
        this.userId,
        this.userMobile,
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
        destiAddress: json["desti_address"],
        destiLat: json["desti_lat"]?.toDouble(),
        destiLong: json["desti_long"]?.toDouble(),
        tripStartDate: json["trip_start_date"] == null ? null : DateTime.parse(json["trip_start_date"]),
        tripStartTime: json["trip_start_time"],
        tripStatus: json["trip_status"],
        peopleDriven: json["people_driven"],
        ridesTaken: json["rides_taken"],
        kmShared: json["km_shared"]?.toDouble(),
        totalReviews: json["total_reviews"],
        avgRating: json["avg_rating"]?.toDouble(),
        tripIsReturn: json["trip_is_return"],
        instantApprove: json["instant_approve"],
        userProfile: json["user_profile"],
        userTitle: json["user_title"],
        userId: json["user_id"],
        userMobile: json["user_mobile"],
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
        "desti_address": destiAddress,
        "desti_lat": destiLat,
        "desti_long": destiLong,
        "trip_start_date": "${tripStartDate!.year.toString().padLeft(4, '0')}-${tripStartDate!.month.toString().padLeft(2, '0')}-${tripStartDate!.day.toString().padLeft(2, '0')}",
        "trip_start_time": tripStartTime,
        "trip_status": tripStatus,
        "people_driven": peopleDriven,
        "rides_taken": ridesTaken,
        "km_shared": kmShared,
        "total_reviews": totalReviews,
        "avg_rating": avgRating,
        "trip_is_return": tripIsReturn,
        "instant_approve": instantApprove,
        "user_profile": userProfile,
        "user_title": userTitle,
        "user_id": userId,
        "user_mobile": userMobile,
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
    num? userId;
    String? userName;
    String? userMobile;
    String? profilePic;
    num? totalSeat;
    num? isApprove;
    String? bookStatus;
    num? subtotal;
    num? couAmt;
    num? wallAmt;
    num? totalAmount;
    String? transactionId;
    num? isRate;
    String? driverAlertInfo;
    num? totalRate;
    String? rateDesc;
    String? paymentTitle;
    String? bookingFees;
    String? pickupOtp;
    String? dropOtp;
    String? approvalMessage;

    BookedUser({
        this.bookId,
        this.userId,
        this.userName,
        this.userMobile,
        this.profilePic,
        this.totalSeat,
        this.isApprove,
        this.bookStatus,
        this.subtotal,
        this.couAmt,
        this.wallAmt,
        this.totalAmount,
        this.transactionId,
        this.isRate,
        this.driverAlertInfo,
        this.totalRate,
        this.rateDesc,
        this.paymentTitle,
        this.bookingFees,
        this.pickupOtp,
        this.dropOtp,
        this.approvalMessage,
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
        subtotal: json["subtotal"],
        couAmt: json["cou_amt"],
        wallAmt: json["wall_amt"],
        totalAmount: json["total_amount"],
        transactionId: json["transaction_id"],
        isRate: json["is_rate"],
        driverAlertInfo: json["driver_alert_info"],
        totalRate: json["total_rate"],
        rateDesc: json["rate_desc"],
        paymentTitle: json["payment_title"],
        bookingFees: json["booking_fees"],
        pickupOtp: json["pickup_otp"],
        dropOtp: json["drop_otp"],
        approvalMessage: json["approval_message"],
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
        "subtotal": subtotal,
        "cou_amt": couAmt,
        "wall_amt": wallAmt,
        "total_amount": totalAmount,
        "transaction_id": transactionId,
        "is_rate": isRate,
        "driver_alert_info": driverAlertInfo,
        "total_rate": totalRate,
        "rate_desc": rateDesc,
        "payment_title": paymentTitle,
        "booking_fees": bookingFees,
        "pickup_otp": pickupOtp,
        "drop_otp": dropOtp,
        "approval_message": approvalMessage,
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

class StopsDetail {
    String? location;
    double? lat;
    double? long;

    StopsDetail({
        this.location,
        this.lat,
        this.long,
    });

    factory StopsDetail.fromJson(Map<String, dynamic> json) => StopsDetail(
        location: json["location"],
        lat: json["lat"]?.toDouble(),
        long: json["long"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "location": location,
        "lat": lat,
        "long": long,
    };
}


// // To parse this JSON data, do
// //
// //     final bookTripDetailsApiModel = bookTripDetailsApiModelFromJson(jsonString);

// import 'dart:convert';

// BookTripDetailsApiModel bookTripDetailsApiModelFromJson(String str) => BookTripDetailsApiModel.fromJson(json.decode(str));

// String bookTripDetailsApiModelToJson(BookTripDetailsApiModel data) => json.encode(data.toJson());

// class BookTripDetailsApiModel {
//     String? responseCode;
//     String? result;
//     String? responseMsg;
//     TripData? tripData;

//     BookTripDetailsApiModel({
//         this.responseCode,
//         this.result,
//         this.responseMsg,
//         this.tripData,
//     });

//     factory BookTripDetailsApiModel.fromJson(Map<String, dynamic> json) => BookTripDetailsApiModel(
//         responseCode: json["ResponseCode"],
//         result: json["Result"],
//         responseMsg: json["ResponseMsg"],
//         tripData: json["TripData"] == null ? null : TripData.fromJson(json["TripData"]),
//     );

//     Map<String, dynamic> toJson() => {
//         "ResponseCode": responseCode,
//         "Result": result,
//         "ResponseMsg": responseMsg,
//         "TripData": tripData?.toJson(),
//     };
// }

// class TripData {
//     String? tripId;
//     String? totalSeat;
//     String? seatPrice;
//     String? originAddress;
//     double? originLat;
//     double? originLong;
//     String? destiAddress;
//     double? destiLat;
//     double? destiLong;
//     DateTime? tripStartDate;
//     String? tripStartTime;
//     String? tripStatus;
//     num? peopleDriven;
//     num? ridesTaken;
//     double? kmShared;
//     num? totalReviews;
//     num? avgRating;
//     String? tripIsReturn;
//     num? instantApprove;
//     String? userProfile;
//     String? userTitle;
//     String? userId;
//     String? vehicleTitle;
//     String? vehicleImage;
//     String? licensePlate;
//     String? year;
//     String? vehicleColor;
//     String? vehicleType;
//     List<StopsDetail>? stopsDetails;
//     List<RestriDetail>? restriDetails;
//     String? luggageDetails;
//     String? backrowDetails;
//     num? bookedSeat;
//     num? remainSeat;
//     List<BookedUser>? bookedUsers;

//     TripData({
//         this.tripId,
//         this.totalSeat,
//         this.seatPrice,
//         this.originAddress,
//         this.originLat,
//         this.originLong,
//         this.destiAddress,
//         this.destiLat,
//         this.destiLong,
//         this.tripStartDate,
//         this.tripStartTime,
//         this.tripStatus,
//         this.peopleDriven,
//         this.ridesTaken,
//         this.kmShared,
//         this.totalReviews,
//         this.avgRating,
//         this.tripIsReturn,
//         this.instantApprove,
//         this.userProfile,
//         this.userTitle,
//         this.userId,
//         this.vehicleTitle,
//         this.vehicleImage,
//         this.licensePlate,
//         this.year,
//         this.vehicleColor,
//         this.vehicleType,
//         this.stopsDetails,
//         this.restriDetails,
//         this.luggageDetails,
//         this.backrowDetails,
//         this.bookedSeat,
//         this.remainSeat,
//         this.bookedUsers,
//     });

//     factory TripData.fromJson(Map<String, dynamic> json) => TripData(
//         tripId: json["trip_id"],
//         totalSeat: json["total_seat"],
//         seatPrice: json["seat_price"],
//         originAddress: json["origin_address"],
//         originLat: json["origin_lat"]?.toDouble(),
//         originLong: json["origin_long"]?.toDouble(),
//         destiAddress: json["desti_address"],
//         destiLat: json["desti_lat"]?.toDouble(),
//         destiLong: json["desti_long"]?.toDouble(),
//         tripStartDate: json["trip_start_date"] == null ? null : DateTime.parse(json["trip_start_date"]),
//         tripStartTime: json["trip_start_time"],
//         tripStatus: json["trip_status"],
//         peopleDriven: json["people_driven"],
//         ridesTaken: json["rides_taken"],
//         kmShared: json["km_shared"]?.toDouble(),
//         totalReviews: json["total_reviews"],
//         avgRating: json["avg_rating"],
//         tripIsReturn: json["trip_is_return"],
//         instantApprove: json["instant_approve"],
//         userProfile: json["user_profile"],
//         userTitle: json["user_title"],
//         userId: json["user_id"],
//         vehicleTitle: json["vehicle_title"],
//         vehicleImage: json["vehicle_image"],
//         licensePlate: json["license_plate"],
//         year: json["year"],
//         vehicleColor: json["vehicle_color"],
//         vehicleType: json["vehicle_type"],
//         stopsDetails: json["stops_details"] == null ? [] : List<StopsDetail>.from(json["stops_details"]!.map((x) => StopsDetail.fromJson(x))),
//         restriDetails: json["restri_details"] == null ? [] : List<RestriDetail>.from(json["restri_details"]!.map((x) => RestriDetail.fromJson(x))),
//         luggageDetails: json["luggage_details"],
//         backrowDetails: json["backrow_details"],
//         bookedSeat: json["booked_seat"],
//         remainSeat: json["remain_seat"],
//         bookedUsers: json["booked_users"] == null ? [] : List<BookedUser>.from(json["booked_users"]!.map((x) => BookedUser.fromJson(x))),
//     );

//     Map<String, dynamic> toJson() => {
//         "trip_id": tripId,
//         "total_seat": totalSeat,
//         "seat_price": seatPrice,
//         "origin_address": originAddress,
//         "origin_lat": originLat,
//         "origin_long": originLong,
//         "desti_address": destiAddress,
//         "desti_lat": destiLat,
//         "desti_long": destiLong,
//         "trip_start_date": "${tripStartDate!.year.toString().padLeft(4, '0')}-${tripStartDate!.month.toString().padLeft(2, '0')}-${tripStartDate!.day.toString().padLeft(2, '0')}",
//         "trip_start_time": tripStartTime,
//         "trip_status": tripStatus,
//         "people_driven": peopleDriven,
//         "rides_taken": ridesTaken,
//         "km_shared": kmShared,
//         "total_reviews": totalReviews,
//         "avg_rating": avgRating,
//         "trip_is_return": tripIsReturn,
//         "instant_approve": instantApprove,
//         "user_profile": userProfile,
//         "user_title": userTitle,
//         "user_id": userId,
//         "vehicle_title": vehicleTitle,
//         "vehicle_image": vehicleImage,
//         "license_plate": licensePlate,
//         "year": year,
//         "vehicle_color": vehicleColor,
//         "vehicle_type": vehicleType,
//         "stops_details": stopsDetails == null ? [] : List<dynamic>.from(stopsDetails!.map((x) => x.toJson())),
//         "restri_details": restriDetails == null ? [] : List<dynamic>.from(restriDetails!.map((x) => x.toJson())),
//         "luggage_details": luggageDetails,
//         "backrow_details": backrowDetails,
//         "booked_seat": bookedSeat,
//         "remain_seat": remainSeat,
//         "booked_users": bookedUsers == null ? [] : List<dynamic>.from(bookedUsers!.map((x) => x.toJson())),
//     };
// }

// class BookedUser {
//     String? bookId;
//     num? userId;
//     String? userName;
//     String? profilePic;
//     num? totalSeat;
//     num? isApprove;
//     String? bookStatus;
//     num? subtotal;
//     num? couAmt;
//     num? wallAmt;
//     num? totalAmount;
//     String? transactionId;
//     num? isRate;
//     String? driverAlertInfo;
//     num? totalRate;
//     String? rateDesc;
//     String? paymentTitle;
//     String? bookingFees;
//     String? pickupOtp;
//     String? dropOtp;
//     String? approvalMessage;

//     BookedUser({
//         this.bookId,
//         this.userId,
//         this.userName,
//         this.profilePic,
//         this.totalSeat,
//         this.isApprove,
//         this.bookStatus,
//         this.subtotal,
//         this.couAmt,
//         this.wallAmt,
//         this.totalAmount,
//         this.transactionId,
//         this.isRate,
//         this.driverAlertInfo,
//         this.totalRate,
//         this.rateDesc,
//         this.paymentTitle,
//         this.bookingFees,
//         this.pickupOtp,
//         this.dropOtp,
//         this.approvalMessage,
//     });

//     factory BookedUser.fromJson(Map<String, dynamic> json) => BookedUser(
//         bookId: json["book_id"],
//         userId: json["user_id"],
//         userName: json["user_name"],
//         profilePic: json["profile_pic"],
//         totalSeat: json["total_seat"],
//         isApprove: json["is_approve"],
//         bookStatus: json["book_status"],
//         subtotal: json["subtotal"],
//         couAmt: json["cou_amt"],
//         wallAmt: json["wall_amt"],
//         totalAmount: json["total_amount"],
//         transactionId: json["transaction_id"],
//         isRate: json["is_rate"],
//         driverAlertInfo: json["driver_alert_info"],
//         totalRate: json["total_rate"],
//         rateDesc: json["rate_desc"],
//         paymentTitle: json["payment_title"],
//         bookingFees: json["booking_fees"],
//         pickupOtp: json["pickup_otp"],
//         dropOtp: json["drop_otp"],
//         approvalMessage: json["approval_message"],
//     );

//     Map<String, dynamic> toJson() => {
//         "book_id": bookId,
//         "user_id": userId,
//         "user_name": userName,
//         "profile_pic": profilePic,
//         "total_seat": totalSeat,
//         "is_approve": isApprove,
//         "book_status": bookStatus,
//         "subtotal": subtotal,
//         "cou_amt": couAmt,
//         "wall_amt": wallAmt,
//         "total_amount": totalAmount,
//         "transaction_id": transactionId,
//         "is_rate": isRate,
//         "driver_alert_info": driverAlertInfo,
//         "total_rate": totalRate,
//         "rate_desc": rateDesc,
//         "payment_title": paymentTitle,
//         "booking_fees": bookingFees,
//         "pickup_otp": pickupOtp,
//         "drop_otp": dropOtp,
//         "approval_message": approvalMessage,
//     };
// }

// class RestriDetail {
//     String? title;

//     RestriDetail({
//         this.title,
//     });

//     factory RestriDetail.fromJson(Map<String, dynamic> json) => RestriDetail(
//         title: json["title"],
//     );

//     Map<String, dynamic> toJson() => {
//         "title": title,
//     };
// }

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
