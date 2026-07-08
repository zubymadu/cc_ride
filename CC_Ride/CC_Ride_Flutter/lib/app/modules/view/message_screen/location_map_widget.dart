// ignore_for_file: deprecated_member_use

import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationMapWidget extends StatefulWidget {
  final double lat;
  final double lng;
  final String address;

  const LocationMapWidget({
    super.key,
    required this.lat,
    required this.lng,
    required this.address,
  });

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget> {
  BitmapDescriptor? customIcon;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    loadCustomIcon();
  }

  Future<void> loadCustomIcon() async {
    final BitmapDescriptor icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(120, 120)),
      'assets/image/pickup.png',
    );

    if (mounted) {
      setState(() {
        customIcon = icon;
        markers = {
          Marker(
            markerId: const MarkerId('shared_location'),
            position: LatLng(widget.lat, widget.lng),
            icon: customIcon!,
            anchor: const Offset(0.5, 1.0),
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CCRadius.card),
        border: Border.all(color: ccInputBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CCRadius.card),
        child: Column(
          children: [
            Expanded(
              child: GoogleMap(
                key: ValueKey('map_${widget.lat}_${widget.lng}'),
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.lat, widget.lng),
                  zoom: 16.5,
                ),
                markers: markers,
                zoomControlsEnabled: false,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              color: ccNavyText,
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      color: ccError, size: 24),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.address,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
