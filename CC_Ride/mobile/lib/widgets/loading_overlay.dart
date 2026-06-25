import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const LoadingOverlay({super.key, required this.child, required this.isLoading});

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          if (isLoading)
            const ColoredBox(
              color: Color(0x80000000),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),
        ],
      );
}

class CCRideButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;

  const CCRideButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Text(label),
            ],
          );

    if (outlined) {
      return OutlinedButton(onPressed: loading ? null : onPressed, child: child);
    }
    return ElevatedButton(onPressed: loading ? null : onPressed, child: child);
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  static Color colorFor(String status) => switch (status) {
        'confirmed' || 'active' || 'completed' || 'approved' => AppTheme.secondary,
        'pending' => AppTheme.warning,
        'cancelled' || 'rejected' || 'blocked' => AppTheme.error,
        'in_progress' || 'driver_assigned' => AppTheme.primary,
        _ => AppTheme.textSecondary,
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label.replaceAll('_', ' ').toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      );
}
