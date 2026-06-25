import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pinput/pinput.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/notification_provider.dart';
import '../../data/models/ride_model.dart';
import '../../widgets/loading_overlay.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().loadRides();
      context.read<NotificationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final driver = context.watch<DriverProvider>();
    final notifProvider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver Dashboard', style: Theme.of(context).textTheme.headlineSmall),
            Text(user?.name ?? '', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        centerTitle: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/notifications'),
              ),
              if (notifProvider.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => driver.loadRides(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Online toggle
            _OnlineToggle(
              isOnline: driver.isOnline,
              onToggle: () => driver.toggleOnlineStatus(),
            ),
            const SizedBox(height: 16),
            // Active ride banner
            if (driver.activeRide != null)
              _ActiveRideBanner(ride: driver.activeRide!),
            const SizedBox(height: 16),
            // Earnings card
            _EarningsCard(driver: driver),
            const SizedBox(height: 20),
            Text('Assigned Rides', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (driver.loading)
              const Center(child: CircularProgressIndicator())
            else if (driver.assignedRides.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.event_available, size: 48, color: AppTheme.textSecondary),
                      SizedBox(height: 12),
                      Text('No rides assigned yet', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              )
            else
              ...driver.assignedRides.map((ride) => _DriverRideCard(
                    ride: ride,
                    isActive: driver.activeRide?.id == ride.id,
                  )),
          ],
        ),
      ),
    );
  }
}

class _OnlineToggle extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onToggle;

  const _OnlineToggle({required this.isOnline, required this.onToggle});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isOnline
                  ? [AppTheme.secondary, const Color(0xFF057A55)]
                  : [AppTheme.textSecondary, const Color(0xFF4B5563)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                isOnline ? Icons.radio_button_on : Icons.radio_button_off,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    isOnline ? 'Online — Accepting Rides' : 'Offline',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const Spacer(),
              Switch(
                value: isOnline,
                onChanged: (_) => onToggle(),
                activeColor: Colors.white,
                activeTrackColor: Colors.white38,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.white24,
              ),
            ],
          ),
        ),
      );
}

class _ActiveRideBanner extends StatelessWidget {
  final RideModel ride;
  const _ActiveRideBanner({required this.ride});

  @override
  Widget build(BuildContext context) => Card(
        color: AppTheme.primary,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_car, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Active Ride', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${ride.originAddress} → ${ride.destinationAddress}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _OtpButton(
                    label: 'Pickup OTP',
                    onTap: () => _showOtpDialog(context, 'pickup'),
                  ),
                  const SizedBox(width: 10),
                  _OtpButton(
                    label: 'Dropoff OTP',
                    onTap: () => _showOtpDialog(context, 'dropoff'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  void _showOtpDialog(BuildContext context, String type) {
    String otp = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Enter ${type == 'pickup' ? 'Pickup' : 'Dropoff'} OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ask the passenger for the $type OTP to verify the ride.'),
            const SizedBox(height: 16),
            Pinput(
              length: 6,
              onCompleted: (val) => otp = val,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final driver = context.read<DriverProvider>();
              final ok = type == 'pickup'
                  ? await driver.verifyPickupOtp(otp)
                  : await driver.verifyDropoffOtp(otp);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'OTP verified!' : 'Invalid OTP'),
                  backgroundColor: ok ? AppTheme.secondary : AppTheme.error,
                ));
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}

class _OtpButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OtpButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primary,
            minimumSize: const Size.fromHeight(40),
            textStyle: const TextStyle(fontSize: 13),
          ),
          onPressed: onTap,
          child: Text(label),
        ),
      );
}

class _EarningsCard extends StatelessWidget {
  final DriverProvider driver;
  const _EarningsCard({required this.driver});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Trips', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    Text(driver.assignedRides.length.toString(),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.divider),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      Text(
                        driver.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: driver.isOnline ? AppTheme.secondary : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _DriverRideCard extends StatelessWidget {
  final RideModel ride;
  final bool isActive;

  const _DriverRideCard({required this.ride, required this.isActive});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isActive ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
            child: Icon(Icons.directions_car, color: isActive ? AppTheme.primary : AppTheme.textSecondary),
          ),
          title: Text(
            '${ride.originAddress} → ${ride.destinationAddress}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(DateFormat('EEE, dd MMM • HH:mm').format(ride.scheduledAt)),
          trailing: StatusChip(label: ride.status, color: StatusChip.colorFor(ride.status)),
        ),
      );
}
