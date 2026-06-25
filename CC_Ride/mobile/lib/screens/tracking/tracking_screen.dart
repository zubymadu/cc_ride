import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ride_provider.dart';
import '../../data/services/socket_service.dart';

class TrackingScreen extends StatefulWidget {
  final String rideId;
  const TrackingScreen({super.key, required this.rideId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();
  LatLng? _driverLocation;
  String _rideStatus = 'confirmed';

  @override
  void initState() {
    super.initState();
    _subscribeToRide();
  }

  void _subscribeToRide() {
    final socket = context.read<SocketService>();
    socket.subscribeToRide(
      widget.rideId,
      onDriverLocation: (lat, lng) {
        if (mounted) {
          setState(() => _driverLocation = LatLng(lat, lng));
          _mapController.move(LatLng(lat, lng), 15);
        }
      },
      onStatusChange: (status) {
        if (mounted) setState(() => _rideStatus = status);
      },
    );
  }

  @override
  void dispose() {
    context.read<SocketService>().unsubscribeFromRide(widget.rideId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>().selectedRide;
    final pickupLatLng = ride != null ? LatLng(ride.originLat, ride.originLng) : const LatLng(6.5244, 3.3792);
    final destLatLng = ride != null ? LatLng(ride.destinationLat, ride.destinationLng) : const LatLng(6.5244, 3.3792);

    return Scaffold(
      appBar: AppBar(title: const Text('Track Ride')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: pickupLatLng,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ccride.mobile',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: pickupLatLng,
                    child: const Icon(Icons.radio_button_checked, color: AppTheme.secondary, size: 28),
                  ),
                  Marker(
                    point: destLatLng,
                    child: const Icon(Icons.location_on, color: AppTheme.error, size: 32),
                  ),
                  if (_driverLocation != null)
                    Marker(
                      point: _driverLocation!,
                      child: Container(
                        decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.directions_car, color: Colors.white, size: 18),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Bottom sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatusBanner(status: _rideStatus),
                  if (ride != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.radio_button_checked, color: AppTheme.secondary, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(ride.originAddress, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppTheme.error, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(ride.destinationAddress, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                    if (ride.driverName != null) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.surface,
                            child: Icon(Icons.person, color: AppTheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ride.driverName!, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (ride.vehiclePlate != null)
                                Text(ride.vehiclePlate!, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                          const Spacer(),
                          if (ride.driverRating != null)
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 2),
                                Text(ride.driverRating!.toStringAsFixed(1)),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'confirmed' => ('Ride Confirmed', AppTheme.primary, Icons.check_circle_outline),
      'driver_assigned' => ('Driver Assigned', AppTheme.primary, Icons.directions_car),
      'driver_en_route' => ('Driver On The Way', AppTheme.warning, Icons.navigation),
      'in_progress' => ('Ride In Progress', AppTheme.secondary, Icons.radio_button_on),
      'completed' => ('Ride Completed', AppTheme.secondary, Icons.done_all),
      'cancelled' => ('Ride Cancelled', AppTheme.error, Icons.cancel_outlined),
      _ => ('Pending', AppTheme.textSecondary, Icons.hourglass_empty),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
