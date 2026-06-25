class BookingModel {
  final String id;
  final String rideId;
  final String passengerId;
  final String? companyId;
  final String? departmentId;
  final String? costCentreId;
  final int seatsBooked;
  final double subtotal;
  final double totalAmount;
  final double driverEarning;
  final String status;
  final String paymentStatus;
  final String bookingMethod;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final String? cancellationReason;
  final String? approvalRequestId;
  final String? approvalStatus;
  final RideSnapshot? ride;

  const BookingModel({
    required this.id,
    required this.rideId,
    required this.passengerId,
    this.companyId,
    this.departmentId,
    this.costCentreId,
    required this.seatsBooked,
    required this.subtotal,
    required this.totalAmount,
    required this.driverEarning,
    required this.status,
    required this.paymentStatus,
    required this.bookingMethod,
    required this.createdAt,
    this.confirmedAt,
    this.completedAt,
    this.cancellationReason,
    this.approvalRequestId,
    this.approvalStatus,
    this.ride,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['id'] as String,
        rideId: json['ride_id'] as String,
        passengerId: json['passenger_id'] as String,
        companyId: json['company_id'] as String?,
        departmentId: json['department_id']?.toString(),
        costCentreId: json['cost_centre_id']?.toString(),
        seatsBooked: json['seats_booked'] as int? ?? 1,
        subtotal: double.parse(json['subtotal'].toString()),
        totalAmount: double.parse(json['total_amount'].toString()),
        driverEarning: double.parse(json['driver_earning'].toString()),
        status: json['status'] as String,
        paymentStatus: json['payment_status'] as String? ?? 'pending',
        bookingMethod: json['booking_method'] as String? ?? 'instant',
        createdAt: DateTime.parse(json['created_at'] as String),
        confirmedAt: json['confirmed_at'] != null ? DateTime.parse(json['confirmed_at'] as String) : null,
        completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
        cancellationReason: json['cancellation_reason'] as String?,
        approvalRequestId: json['approval_request_id']?.toString(),
        approvalStatus: json['approval_status'] as String?,
        ride: json['ride'] != null ? RideSnapshot.fromJson(json['ride'] as Map<String, dynamic>) : null,
      );

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get requiresApproval => approvalRequestId != null && approvalStatus == 'pending';
}

class RideSnapshot {
  final String originAddress;
  final String destinationAddress;
  final DateTime scheduledAt;
  final String? driverName;
  final String? vehiclePlate;

  const RideSnapshot({
    required this.originAddress,
    required this.destinationAddress,
    required this.scheduledAt,
    this.driverName,
    this.vehiclePlate,
  });

  factory RideSnapshot.fromJson(Map<String, dynamic> json) => RideSnapshot(
        originAddress: json['origin_address'] as String,
        destinationAddress: json['destination_address'] as String,
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        driverName: json['driver_name'] as String?,
        vehiclePlate: json['vehicle_plate'] as String?,
      );
}
