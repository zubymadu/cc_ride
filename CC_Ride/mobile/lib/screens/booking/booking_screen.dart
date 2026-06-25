import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../../widgets/loading_overlay.dart';

class BookingScreen extends StatefulWidget {
  final String rideId;
  const BookingScreen({super.key, required this.rideId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _seats = 1;
  String? _policyStatus;
  String? _policyReason;
  bool _checkingPolicy = false;
  bool _booking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPolicy());
  }

  Future<void> _checkPolicy() async {
    final auth = context.read<AuthProvider>();
    final ride = context.read<RideProvider>().selectedRide;
    if (ride == null || auth.user?.companyId == null) {
      setState(() => _policyStatus = 'allowed');
      return;
    }
    setState(() => _checkingPolicy = true);
    final res = await context.read<RideProvider>().checkPolicy(
          companyId: auth.user!.companyId!,
          userId: auth.user!.id,
          fare: ride.baseFare * _seats,
          departmentId: auth.user?.departmentId,
        );
    setState(() {
      _checkingPolicy = false;
      _policyStatus = res?['data']?['status'] as String? ?? 'allowed';
      _policyReason = res?['data']?['reason'] as String?;
    });
  }

  Future<void> _book() async {
    final auth = context.read<AuthProvider>();
    final ride = context.read<RideProvider>().selectedRide;
    if (ride == null) return;

    setState(() => _booking = true);
    final result = await context.read<RideProvider>().bookRide(
          companyId: auth.user?.companyId ?? '',
          userId: auth.user!.id,
          rideId: ride.id,
          seats: _seats,
          subtotal: ride.baseFare * _seats,
          totalAmount: ride.baseFare * _seats,
          departmentId: auth.user?.departmentId,
          costCentreId: auth.user?.costCentreId,
          requiresApproval: _policyStatus == 'requires_approval',
        );
    setState(() => _booking = false);

    if (!mounted) return;
    if (result != null && result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>?;
      final requiresApproval = data?['status'] == 'pending';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(requiresApproval ? Icons.pending_outlined : Icons.check_circle,
                  color: requiresApproval ? AppTheme.warning : AppTheme.secondary),
              const SizedBox(width: 8),
              Text(requiresApproval ? 'Awaiting Approval' : 'Booked!'),
            ],
          ),
          content: Text(requiresApproval
              ? 'Your ride request has been submitted for manager approval.'
              : 'Your ride has been confirmed. Check My Bookings for details.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                context.pop();
                context.go('/home');
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking failed. Please try again.'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>().selectedRide;
    if (ride == null) {
      return const Scaffold(body: Center(child: Text('Ride not found')));
    }
    final totalFare = ride.baseFare * _seats;
    final isBlocked = _policyStatus == 'blocked';
    final requiresApproval = _policyStatus == 'requires_approval';

    return LoadingOverlay(
      isLoading: _booking,
      child: Scaffold(
        appBar: AppBar(title: const Text('Confirm Booking')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _RouteRow(
                        icon: Icons.radio_button_checked,
                        color: AppTheme.secondary,
                        label: 'Pickup',
                        address: ride.originAddress,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: SizedBox(height: 20, child: VerticalDivider()),
                      ),
                      _RouteRow(
                        icon: Icons.location_on,
                        color: AppTheme.error,
                        label: 'Dropoff',
                        address: ride.destinationAddress,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Ride details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.schedule,
                        label: 'Departure',
                        value: DateFormat('EEE, dd MMM yyyy • HH:mm').format(ride.scheduledAt),
                      ),
                      if (ride.driverName != null) ...[
                        const Divider(height: 20),
                        _DetailRow(icon: Icons.person, label: 'Driver', value: ride.driverName!),
                      ],
                      if (ride.vehiclePlate != null) ...[
                        const Divider(height: 20),
                        _DetailRow(icon: Icons.directions_car, label: 'Vehicle', value: ride.vehiclePlate!),
                      ],
                      if (ride.estimatedDurationMin != null) ...[
                        const Divider(height: 20),
                        _DetailRow(
                          icon: Icons.timelapse,
                          label: 'Est. Duration',
                          value: '${ride.estimatedDurationMin} min',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Seats selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.event_seat, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      const Text('Seats', style: TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _seats > 1 ? () => setState(() { _seats--; _checkPolicy(); }) : null,
                      ),
                      Text('$_seats', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _seats < ride.availableSeats
                            ? () => setState(() { _seats++; _checkPolicy(); })
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Policy status
              if (_checkingPolicy)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('Checking company policy…'),
                    ]),
                  ),
                )
              else if (_policyStatus != null && _policyStatus != 'allowed')
                Card(
                  color: isBlocked
                      ? AppTheme.error.withOpacity(0.08)
                      : AppTheme.warning.withOpacity(0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isBlocked ? Icons.block : Icons.info_outline,
                          color: isBlocked ? AppTheme.error : AppTheme.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _policyReason ?? (requiresApproval ? 'This ride requires manager approval.' : ''),
                            style: TextStyle(
                              color: isBlocked ? AppTheme.error : AppTheme.warning,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              // Fare summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(
                      '₦${NumberFormat('#,##0.00').format(totalFare)}',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!isBlocked)
                CCRideButton(
                  label: requiresApproval ? 'Request Approval' : 'Confirm Booking',
                  loading: _booking,
                  onPressed: _book,
                  icon: requiresApproval ? Icons.send : Icons.check,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  const _RouteRow({required this.icon, required this.color, required this.label, required this.address});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(address, style: const TextStyle(fontWeight: FontWeight.w500), maxLines: 2),
              ],
            ),
          ),
        ],
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      );
}
