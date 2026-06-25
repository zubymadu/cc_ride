import 'package:flutter/foundation.dart';
import '../data/models/ride_model.dart';
import '../data/services/api_service.dart';
import '../data/services/socket_service.dart';

class DriverProvider extends ChangeNotifier {
  final ApiService _api;
  final SocketService _socket;

  List<RideModel> _assignedRides = [];
  RideModel? _activeRide;
  String _driverStatus = 'offline';
  bool _loading = false;
  String? _error;

  List<RideModel> get assignedRides => _assignedRides;
  RideModel? get activeRide => _activeRide;
  String get driverStatus => _driverStatus;
  bool get loading => _loading;
  String? get error => _error;
  bool get isOnline => _driverStatus == 'active';

  DriverProvider(this._api, this._socket);

  Future<void> loadRides({String? status}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _api.getDriverRides(status: status);
      _assignedRides = list.map((e) => RideModel.fromJson(e as Map<String, dynamic>)).toList();
      _activeRide = _assignedRides
          .where((r) => r.status == 'driver_assigned' || r.status == 'in_progress')
          .firstOrNull;
    } catch (e) {
      _error = 'Failed to load rides';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> toggleOnlineStatus() async {
    final newStatus = isOnline ? 'offline' : 'active';
    try {
      await _api.updateDriverStatus(newStatus);
      _driverStatus = newStatus;
      notifyListeners();
    } catch (_) {}
  }

  void updateLocation(double lat, double lng) {
    if (_socket.isConnected) {
      _socket.emitLocation(lat: lat, lng: lng, rideId: _activeRide?.id);
    }
  }

  Future<bool> verifyPickupOtp(String otp) async {
    if (_activeRide == null) return false;
    try {
      final res = await _api.verifyOtp(
        rideId: _activeRide!.id,
        otp: otp,
        type: 'pickup',
      );
      if (res['success'] == true) {
        await loadRides();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> verifyDropoffOtp(String otp) async {
    if (_activeRide == null) return false;
    try {
      final res = await _api.verifyOtp(
        rideId: _activeRide!.id,
        otp: otp,
        type: 'dropoff',
      );
      if (res['success'] == true) {
        await loadRides();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>?> getEarnings() async {
    try {
      return await _api.getDriverEarnings();
    } catch (_) {
      return null;
    }
  }
}
