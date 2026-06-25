import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/constants/app_constants.dart';

typedef LocationCallback = void Function(double lat, double lng);
typedef StatusCallback = void Function(String status);

class SocketService {
  io.Socket? _socket;
  bool _connected = false;

  bool get isConnected => _connected;

  void connect(String token) {
    if (_connected) return;
    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) => _connected = true);
    _socket!.onDisconnect((_) => _connected = false);
    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _connected = false;
  }

  void emitLocation({required double lat, required double lng, String? rideId}) {
    if (!_connected) return;
    _socket!.emit('driver:location', {
      'lat': lat,
      'lng': lng,
      if (rideId != null) 'ride_id': rideId,
    });
  }

  void subscribeToRide(String rideId, {
    LocationCallback? onDriverLocation,
    StatusCallback? onStatusChange,
  }) {
    if (!_connected) return;
    _socket!.emit('passenger:track', {'ride_id': rideId});

    if (onDriverLocation != null) {
      _socket!.on('driver:location:$rideId', (data) {
        if (data is Map) {
          final lat = double.tryParse(data['lat'].toString());
          final lng = double.tryParse(data['lng'].toString());
          if (lat != null && lng != null) onDriverLocation(lat, lng);
        }
      });
    }

    if (onStatusChange != null) {
      _socket!.on('ride:status:$rideId', (data) {
        if (data is Map) {
          final status = data['status'] as String?;
          if (status != null) onStatusChange(status);
        }
      });
    }
  }

  void unsubscribeFromRide(String rideId) {
    _socket?.off('driver:location:$rideId');
    _socket?.off('ride:status:$rideId');
  }
}
