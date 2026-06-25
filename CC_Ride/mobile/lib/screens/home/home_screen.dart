import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../../providers/notification_provider.dart';
import '../../data/models/ride_model.dart';
import '../../widgets/loading_overlay.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideProvider>().loadAvailableRides();
      context.read<NotificationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final rideProvider = context.watch<RideProvider>();
    final notifProvider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, ${user?.name.split(' ').first ?? ''}!',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            if (user?.companyId != null)
              Text('Corporate Ride', style: Theme.of(context).textTheme.bodySmall),
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
      body: Column(
        children: [
          // Wallet banner
          if (user != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        '₦${NumberFormat('#,##0.00').format(user.walletBalance)}',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push('/wallet'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white24,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Top Up'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _TabChip(label: 'Available Rides', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                const SizedBox(width: 8),
                _TabChip(label: 'My Bookings', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _tab == 0
                ? _AvailableRidesTab(provider: rideProvider)
                : _MyBookingsTab(onLoad: () => context.read<RideProvider>().loadMyBookings()),
          ),
        ],
      ),
    );
  }
}

class _AvailableRidesTab extends StatelessWidget {
  final RideProvider provider;
  const _AvailableRidesTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.availableRides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_car_outlined, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            const Text('No rides available', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => provider.loadAvailableRides(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.loadAvailableRides(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.availableRides.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _RideCard(
          ride: provider.availableRides[i],
          onTap: () {
            provider.selectRide(provider.availableRides[i]);
            context.push('/booking/${provider.availableRides[i].id}');
          },
        ),
      ),
    );
  }
}

class _MyBookingsTab extends StatefulWidget {
  final VoidCallback onLoad;
  const _MyBookingsTab({required this.onLoad});

  @override
  State<_MyBookingsTab> createState() => _MyBookingsTabState();
}

class _MyBookingsTabState extends State<_MyBookingsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLoad());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RideProvider>();
    if (provider.loading) return const Center(child: CircularProgressIndicator());
    if (provider.myBookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text('No bookings yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.loadMyBookings(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.myBookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final b = provider.myBookings[i];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.surface,
                child: Icon(Icons.directions_car, color: AppTheme.primary),
              ),
              title: Text(b.ride?.originAddress ?? 'Booking #${b.id.substring(0, 8)}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                b.ride != null
                    ? '→ ${b.ride!.destinationAddress}'
                    : DateFormat('dd MMM yyyy').format(b.createdAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: StatusChip(
                label: b.status,
                color: StatusChip.colorFor(b.status),
              ),
              onTap: () => context.push('/tracking/${b.rideId}'),
            ),
          );
        },
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final RideModel ride;
  final VoidCallback onTap;

  const _RideCard({required this.ride, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.radio_button_checked, color: AppTheme.secondary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(ride.originAddress, style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 7),
                  child: Container(width: 2, height: 20, color: AppTheme.divider),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(ride.destinationAddress, style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(DateFormat('EEE, dd MMM • HH:mm').format(ride.scheduledAt),
                        style: Theme.of(context).textTheme.bodySmall),
                    const Spacer(),
                    Text('₦${NumberFormat('#,##0').format(ride.baseFare)}',
                        style: const TextStyle(
                          color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_seat, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text('${ride.availableSeats}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppTheme.primary : AppTheme.divider),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
}
