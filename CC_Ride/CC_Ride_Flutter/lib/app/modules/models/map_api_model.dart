import 'dart:convert';

MapApiModel mapApiModelFromJson(String str) => MapApiModel.fromJson(json.decode(str));

String mapApiModelToJson(MapApiModel data) => json.encode(data.toJson());

class MapApiModel {
  List<dynamic>? htmlAttributions;
  List<Result>? results;
  String? status;

  MapApiModel({
    this.htmlAttributions,
    this.results,
    this.status,
  });

  factory MapApiModel.fromJson(Map<String, dynamic> json) => MapApiModel(
    htmlAttributions: json["html_attributions"] == null ? [] : List<dynamic>.from(json["html_attributions"]!.map((x) => x)),
    results: json["results"] == null ? [] : List<Result>.from(json["results"]!.map((x) => Result.fromJson(x))),
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "html_attributions": htmlAttributions == null ? [] : List<dynamic>.from(htmlAttributions!.map((x) => x)),
    "results": results == null ? [] : List<dynamic>.from(results!.map((x) => x.toJson())),
    "status": status,
  };
}

class Result {
  String? businessStatus;
  String? formattedAddress;
  Geometry? geometry;
  String? icon;
  String? iconBackgroundColor;
  String? iconMaskBaseUri;
  String? name;
  OpeningHours? openingHours;
  String? placeId;
  PlusCode? plusCode;
  double? rating;
  String? reference;
  List<String>? types;
  int? userRatingsTotal;
  List<Photo>? photos;
  int? priceLevel;

  Result({
    this.businessStatus,
    this.formattedAddress,
    this.geometry,
    this.icon,
    this.iconBackgroundColor,
    this.iconMaskBaseUri,
    this.name,
    this.openingHours,
    this.placeId,
    this.plusCode,
    this.rating,
    this.reference,
    this.types,
    this.userRatingsTotal,
    this.photos,
    this.priceLevel,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    businessStatus: json["business_status"],
    formattedAddress: json["formatted_address"],
    geometry: json["geometry"] == null ? null : Geometry.fromJson(json["geometry"]),
    icon: json["icon"],
    iconBackgroundColor: json["icon_background_color"],
    iconMaskBaseUri: json["icon_mask_base_uri"],
    name: json["name"],
    openingHours: json["opening_hours"] == null ? null : OpeningHours.fromJson(json["opening_hours"]),
    placeId: json["place_id"],
    plusCode: json["plus_code"] == null ? null : PlusCode.fromJson(json["plus_code"]),
    rating: json["rating"]?.toDouble(),
    reference: json["reference"],
    types: json["types"] == null ? [] : List<String>.from(json["types"]!.map((x) => x)),
    userRatingsTotal: json["user_ratings_total"],
    photos: json["photos"] == null ? [] : List<Photo>.from(json["photos"]!.map((x) => Photo.fromJson(x))),
    priceLevel: json["price_level"],
  );

  Map<String, dynamic> toJson() => {
    "business_status": businessStatus,
    "formatted_address": formattedAddress,
    "geometry": geometry?.toJson(),
    "icon": icon,
    "icon_background_color": iconBackgroundColor,
    "icon_mask_base_uri": iconMaskBaseUri,
    "name": name,
    "opening_hours": openingHours?.toJson(),
    "place_id": placeId,
    "plus_code": plusCode?.toJson(),
    "rating": rating,
    "reference": reference,
    "types": types == null ? [] : List<dynamic>.from(types!.map((x) => x)),
    "user_ratings_total": userRatingsTotal,
    "photos": photos == null ? [] : List<dynamic>.from(photos!.map((x) => x.toJson())),
    "price_level": priceLevel,
  };
}

class Geometry {
  Location? location;
  Viewport? viewport;

  Geometry({
    this.location,
    this.viewport,
  });

  factory Geometry.fromJson(Map<String, dynamic> json) => Geometry(
    location: json["location"] == null ? null : Location.fromJson(json["location"]),
    viewport: json["viewport"] == null ? null : Viewport.fromJson(json["viewport"]),
  );

  Map<String, dynamic> toJson() => {
    "location": location?.toJson(),
    "viewport": viewport?.toJson(),
  };
}

class Location {
  double? lat;
  double? lng;

  Location({
    this.lat,
    this.lng,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "lat": lat,
    "lng": lng,
  };
}

class Viewport {
  Location? northeast;
  Location? southwest;

  Viewport({
    this.northeast,
    this.southwest,
  });

  factory Viewport.fromJson(Map<String, dynamic> json) => Viewport(
    northeast: json["northeast"] == null ? null : Location.fromJson(json["northeast"]),
    southwest: json["southwest"] == null ? null : Location.fromJson(json["southwest"]),
  );

  Map<String, dynamic> toJson() => {
    "northeast": northeast?.toJson(),
    "southwest": southwest?.toJson(),
  };
}

class OpeningHours {
  bool? openNow;

  OpeningHours({
    this.openNow,
  });

  factory OpeningHours.fromJson(Map<String, dynamic> json) => OpeningHours(
    openNow: json["open_now"],
  );

  Map<String, dynamic> toJson() => {
    "open_now": openNow,
  };
}

class Photo {
  int? height;
  List<String>? htmlAttributions;
  String? photoReference;
  int? width;

  Photo({
    this.height,
    this.htmlAttributions,
    this.photoReference,
    this.width,
  });

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
    height: json["height"],
    htmlAttributions: json["html_attributions"] == null ? [] : List<String>.from(json["html_attributions"]!.map((x) => x)),
    photoReference: json["photo_reference"],
    width: json["width"],
  );

  Map<String, dynamic> toJson() => {
    "height": height,
    "html_attributions": htmlAttributions == null ? [] : List<dynamic>.from(htmlAttributions!.map((x) => x)),
    "photo_reference": photoReference,
    "width": width,
  };
}

class PlusCode {
  String? compoundCode;
  String? globalCode;

  PlusCode({
    this.compoundCode,
    this.globalCode,
  });

  factory PlusCode.fromJson(Map<String, dynamic> json) => PlusCode(
    compoundCode: json["compound_code"],
    globalCode: json["global_code"],
  );

  Map<String, dynamic> toJson() => {
    "compound_code": compoundCode,
    "global_code": globalCode,
  };
}
