import 'package:flutter/foundation.dart';
import '../data/models/ride_model.dart';
import '../data/models/booking_model.dart';
import '../data/services/api_service.dart';

class RideProvider extends ChangeNotifier {
  final ApiService _api;

  List<RideModel> _availableRides = [];
  List<BookingModel> _myBookings = [];
  RideModel? _selectedRide;
  bool _loading = false;
  String? _error;

  List<RideModel> get availableRides => _availableRides;
  List<BookingModel> get myBookings => _myBookings;
  RideModel? get selectedRide => _selectedRide;
  bool get loading => _loading;
  String? get error => _error;

  RideProvider(this._api);

  Future<void> loadAvailableRides({double? lat, double? lng}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _api.getAvailableRides(
        originLat: lat?.toString(),
        originLng: lng?.toString(),
      );
      _availableRides = list.map((e) => RideModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = 'Failed to load rides';
      _availableRides = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadMyBookings({String? status}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _api.getMyBookings(status: status);
      _myBookings = list.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = 'Failed to load bookings';
      _myBookings = [];
    }
    _loading = false;
    notifyListeners();
  }

  void selectRide(RideModel ride) {
    _selectedRide = ride;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> checkPolicy({
    required String companyId,
    required String userId,
    required double fare,
    String? departmentId,
  }) async {
    try {
      return await _api.checkPolicy(
        companyId: companyId,
        userId: userId,
        estimatedFare: fare,
        departmentId: departmentId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> bookRide({
    required String companyId,
    required String userId,
    required String rideId,
    required int seats,
    required double subtotal,
    required double totalAmount,
    String? departmentId,
    String? costCentreId,
    bool requiresApproval = false,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.createBooking(
        companyId: companyId,
        userId: userId,
        rideId: rideId,
        seats: seats,
        subtotal: subtotal,
        totalAmount: totalAmount,
        departmentId: departmentId,
        costCentreId: costCentreId,
        requiresApproval: requiresApproval,
      );
      _loading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = 'Booking failed. Please try again.';
      _loading = false;
      notifyListeners();
      return null;
    }
  }
}
