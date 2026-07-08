/// CC Ride Design System — shared components matching the Corporate Transit
/// Excellence design spec (cc_ride_designs/designs/corporate_transit_excellence).
library cc_ds;

import 'package:flutter/material.dart';
import 'color.dart';
export 'color.dart';

// ─── Typography ───────────────────────────────────────────────────────────────

const String _inter = 'Inter';

class CCText {
  static const TextStyle headlineLgMobile = TextStyle(
    fontFamily: _inter, fontSize: 26, fontWeight: FontWeight.w700,
    height: 1.23, letterSpacing: -0.52, color: ccNavyText,
  );
  static const TextStyle headlineMd = TextStyle(
    fontFamily: _inter, fontSize: 20, fontWeight: FontWeight.w600,
    height: 1.4, color: ccNavyText,
  );
  static const TextStyle titleMd = TextStyle(
    fontFamily: _inter, fontSize: 16, fontWeight: FontWeight.w600,
    height: 1.5, color: ccNavyText,
  );
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _inter, fontSize: 16, fontWeight: FontWeight.w400,
    height: 1.5, color: ccNavyText,
  );
  static const TextStyle bodyMd = TextStyle(
    fontFamily: _inter, fontSize: 14, fontWeight: FontWeight.w400,
    height: 1.43, color: ccNavyText,
  );
  static const TextStyle labelSm = TextStyle(
    fontFamily: _inter, fontSize: 12, fontWeight: FontWeight.w500,
    height: 1.33, letterSpacing: 0.6, color: ccSecondaryText,
  );
  static const TextStyle btn = TextStyle(
    fontFamily: _inter, fontSize: 15, fontWeight: FontWeight.w600,
    height: 1.33,
  );
}

// ─── Border Radius ────────────────────────────────────────────────────────────

class CCRadius {
  static const double btn   = 12;
  static const double input = 14;
  static const double card  = 16;
  static const double sheet = 24;
  static const double chip  = 8;
}

// ─── Elevation / Shadows ──────────────────────────────────────────────────────

class CCShadow {
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x141565C0), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x1F1565C0), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

// ─── Primary Button ───────────────────────────────────────────────────────────

class CCButton extends StatelessWidget {
  const CCButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.outlined = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool outlined;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final bg    = outlined ? Colors.transparent : ccPrimary;
    final fg    = outlined ? ccPrimary          : ccSurface;
    final border = outlined
        ? Border.all(color: ccPrimary, width: 1.5)
        : null;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 52,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(CCRadius.btn),
        child: InkWell(
          borderRadius: BorderRadius.circular(CCRadius.btn),
          onTap: loading ? null : onPressed,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CCRadius.btn),
              border: border,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: loading
                ? SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: fg,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: fg, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(label, style: CCText.btn.copyWith(color: fg)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Text Input ───────────────────────────────────────────────────────────────

class CCInput extends StatelessWidget {
  const CCInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CCText.labelSm.copyWith(
          color: ccNavyText, letterSpacing: 0,
          fontSize: 13, fontWeight: FontWeight.w500,
        )),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          style: CCText.bodyLg.copyWith(color: ccNavyText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: CCText.bodyLg.copyWith(color: ccSecondaryText),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: ccPrimary, size: 20)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: ccSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CCRadius.input),
              borderSide: const BorderSide(color: ccInputBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CCRadius.input),
              borderSide: const BorderSide(color: ccInputBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CCRadius.input),
              borderSide: const BorderSide(color: ccPrimary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CCRadius.input),
              borderSide: const BorderSide(color: ccError, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CCRadius.input),
              borderSide: const BorderSide(color: ccError, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class CCCard extends StatelessWidget {
  const CCCard({
    super.key,
    required this.child,
    this.padding,
    this.iceBlue = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets? padding;
  final bool iceBlue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: iceBlue ? ccIceBlue : ccSurface,
      borderRadius: BorderRadius.circular(CCRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(CCRadius.card),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CCRadius.card),
            boxShadow: iceBlue ? null : CCShadow.card,
          ),
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class CCBadge extends StatelessWidget {
  const CCBadge({super.key, required this.label, required this.color, required this.bg});

  final String label;
  final Color color;
  final Color bg;

  factory CCBadge.status(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return CCBadge(label: status, color: ccSuccess, bg: ccSuccessLight);
      case 'pending':   return CCBadge(label: status, color: ccWarning, bg: ccWarningLight);
      case 'cancelled': return CCBadge(label: status, color: ccError,   bg: ccErrorLight);
      case 'active':
      case 'ongoing':   return CCBadge(label: status, color: ccPrimary, bg: ccIceBlue);
      default:          return CCBadge(label: status, color: ccSecondaryText, bg: ccSurfaceLow);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: CCText.labelSm.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Screen scaffold with standard padding ────────────────────────────────────

class CCScreen extends StatelessWidget {
  const CCScreen({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.showBack = true,
    this.backgroundColor,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool showBack;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? ccBackground,
      appBar: title != null
          ? AppBar(
              title: Text(title!, style: CCText.titleMd),
              backgroundColor: ccSurface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: showBack,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: ccInputBorder),
              ),
              actions: actions,
            )
          : null,
      body: child,
    );
  }
}

// ─── Section header row ───────────────────────────────────────────────────────

class CCSectionHeader extends StatelessWidget {
  const CCSectionHeader({super.key, required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: CCText.titleMd),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: CCText.labelSm.copyWith(
              color: ccPrimary, fontWeight: FontWeight.w600,
            )),
          ),
      ],
    );
  }
}
