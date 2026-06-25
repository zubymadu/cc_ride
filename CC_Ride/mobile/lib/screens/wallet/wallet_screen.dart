import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List<dynamic> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final txns = await context.read<ApiService>().getWalletTransactions();
      setState(() { _transactions = txns; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: Column(
        children: [
          // Balance card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  '₦${NumberFormat('#,##0.00').format(user?.walletBalance ?? 0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _WalletAction(
                      icon: Icons.add,
                      label: 'Top Up',
                      onTap: () => _showTopUpSheet(context),
                    ),
                    const SizedBox(width: 12),
                    _WalletAction(
                      icon: Icons.history,
                      label: 'History',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Transactions
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textSecondary),
                            SizedBox(height: 12),
                            Text('No transactions yet', style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _transactions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final t = _transactions[i] as Map<String, dynamic>;
                          final amount = double.tryParse(t['amount'].toString()) ?? 0;
                          final isCredit = amount > 0;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: (isCredit ? AppTheme.secondary : AppTheme.error).withOpacity(0.1),
                              child: Icon(
                                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isCredit ? AppTheme.secondary : AppTheme.error,
                                size: 18,
                              ),
                            ),
                            title: Text(t['description'] as String? ?? 'Transaction'),
                            subtitle: Text(
                              DateFormat('dd MMM yyyy • HH:mm')
                                  .format(DateTime.parse(t['created_at'] as String)),
                            ),
                            trailing: Text(
                              '${isCredit ? '+' : ''}₦${NumberFormat('#,##0').format(amount.abs())}',
                              style: TextStyle(
                                color: isCredit ? AppTheme.secondary : AppTheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showTopUpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Up Wallet', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Text('Select an amount', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [1000, 2000, 5000, 10000, 20000, 50000].map((amount) => ActionChip(
                label: Text('₦${NumberFormat('#,##0').format(amount)}'),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment gateway integration required')),
                  );
                },
              )).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _WalletAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _WalletAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primary,
            minimumSize: const Size.fromHeight(44),
          ),
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
      );
}
