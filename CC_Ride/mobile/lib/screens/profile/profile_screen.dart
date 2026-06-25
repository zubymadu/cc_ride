import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        children: [
          // Avatar section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: user?.profilePicUrl != null
                      ? null
                      : Text(
                          (user?.name.isNotEmpty == true ? user!.name[0] : '?').toUpperCase(),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppTheme.primary),
                        ),
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? '', style: Theme.of(context).textTheme.headlineSmall),
                if (user?.email != null)
                  Text(user!.email!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                Text(user?.mobile ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: (user?.isDriver == true ? AppTheme.secondary : AppTheme.primary).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.isDriver == true ? 'Driver' : (user?.employeeRole?.replaceAll('_', ' ').toUpperCase() ?? 'Employee'),
                    style: TextStyle(
                      color: user?.isDriver == true ? AppTheme.secondary : AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Menu items
          _MenuItem(
            icon: Icons.business,
            label: 'My Company',
            subtitle: user?.companyId != null ? 'View company profile' : 'Join a company',
            onTap: () {},
          ),
          if (!( user?.isDriver ?? false))
            _MenuItem(
              icon: Icons.receipt_long,
              label: 'My Bookings',
              onTap: () => context.go('/home'),
            ),
          if (user?.isDriver == true)
            _MenuItem(
              icon: Icons.attach_money,
              label: 'Earnings',
              onTap: () {},
            ),
          _MenuItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Wallet',
            onTap: () => context.push('/wallet'),
          ),
          _MenuItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => context.push('/notifications'),
          ),
          _MenuItem(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await context.read<AuthProvider>().logout();
                }
              },
              icon: const Icon(Icons.logout, color: AppTheme.error),
              label: const Text('Sign Out', style: TextStyle(color: AppTheme.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.error),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ListTile(
            tileColor: Colors.white,
            leading: CircleAvatar(
              backgroundColor: AppTheme.surface,
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: subtitle != null ? Text(subtitle!) : null,
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            onTap: onTap,
          ),
          const Divider(height: 1, indent: 72),
        ],
      );
}
