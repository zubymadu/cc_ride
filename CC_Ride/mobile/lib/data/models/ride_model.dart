class RideModel {
  final String id;
  final String driverId;
  final String? driverName;
  final String? driverPhone;
  final double? driverRating;
  final String? vehiclePlate;
  final String? vehicleModel;
  final String? vehicleColor;
  final String originAddress;
  final double originLat;
  final double originLng;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final DateTime scheduledAt;
  final double baseFare;
  final int availableSeats;
  final String status;
  final String? pickupOtp;
  final String? tripNotes;
  final int? estimatedDurationMin;
  final double? estimatedDistanceKm;

  const RideModel({
    required this.id,
    required this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverRating,
    this.vehiclePlate,
    this.vehicleModel,
    this.vehicleColor,
    required this.originAddress,
    required this.originLat,
    required this.originLng,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.scheduledAt,
    required this.baseFare,
    required this.availableSeats,
    required this.status,
    this.pickupOtp,
    this.tripNotes,
    this.estimatedDurationMin,
    this.estimatedDistanceKm,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) => RideModel(
        id: json['id'] as String,
        driverId: json['driver_id'] as String,
        driverName: json['driver_name'] as String?,
        driverPhone: json['driver_phone'] as String?,
        driverRating: double.tryParse(json['driver_rating']?.toString() ?? ''),
        vehiclePlate: json['vehicle_plate'] as String?,
        vehicleModel: json['vehicle_model'] as String?,
        vehicleColor: json['vehicle_color'] as String?,
        originAddress: json['origin_address'] as String,
        originLat: double.parse(json['origin_lat'].toString()),
        originLng: double.parse(json['origin_lng'].toString()),
        destinationAddress: json['destination_address'] as String,
        destinationLat: double.parse(json['destination_lat'].toString()),
        destinationLng: double.parse(json['destination_lng'].toString()),
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        baseFare: double.parse(json['base_fare'].toString()),
        availableSeats: json['available_seats'] as int,
        status: json['status'] as String,
        pickupOtp: json['pickup_otp'] as String?,
        tripNotes: json['trip_notes'] as String?,
        estimatedDurationMin: json['estimated_duration_min'] as int?,
        estimatedDistanceKm: double.tryParse(json['estimated_distance_km']?.toString() ?? ''),
      );
}
