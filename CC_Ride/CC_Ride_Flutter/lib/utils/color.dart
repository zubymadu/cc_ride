import 'package:carride/app/data/data_store.dart';
import 'package:flutter/material.dart';

// ─── CC Ride Design System — Corporate Transit Excellence ─────────────────────
// Exact tokens from cc_ride_designs/designs/corporate_transit_excellence/DESIGN.md

// Primary blues
const Color ccPrimary        = Color(0xFF1565C0); // CTA buttons, interactive
const Color ccPrimaryDark    = Color(0xFF004D99); // pressed / deep blue
const Color ccNavyText       = Color(0xFF0D2137); // headlines, body text
const Color ccIceBlue        = Color(0xFFE8F1FF); // card fills, chips bg
const Color ccInputBorder    = Color(0xFFDCE8F5); // input borders
const Color ccSecondaryText  = Color(0xFF5C7080); // secondary / placeholder text

// Backgrounds
const Color ccBackground     = Color(0xFFF6F9FE); // global bg
const Color ccSurface        = Color(0xFFFFFFFF); // cards, sheets
const Color ccSurfaceLow     = Color(0xFFF1F4F9); // slightly dimmed surface
const Color ccOutlineVariant = Color(0xFFC2C6D4); // dividers

// Semantic
const Color ccError          = Color(0xFFBA1A1A);
const Color ccErrorLight     = Color(0xFFFFDAD6);
const Color ccSuccess        = Color(0xFF2A9C64);
const Color ccSuccessLight   = Color(0xFFEFFAF3);
const Color ccWarning        = Color(0xFFEAB308);
const Color ccWarningLight   = Color(0xFFFEF5D5);
const Color ccOrange         = Color(0xFFFF6347);

// ─── Legacy aliases (keep all existing code compiling) ────────────────────────
Color introcolor      = const Color(0xFF0D2137);
Color textcolor       = ccSecondaryText;
Color primaryColor    = ccPrimary;

Color white           = ccSurface;
Color bgColor         = ccBackground;
Color greyColor       = const Color(0xFFBEBEBE);
Color darkblueColor   = ccNavyText;
Color bluegreyColor   = ccSecondaryText;
Color blueColor       = ccPrimary;
Color lightBlueColor  = ccIceBlue;
Color blueborderColor = ccInputBorder;

// kept for dark theme
const Color ccBlue        = ccPrimary;
const Color ccBlueDark    = ccPrimaryDark;
const Color ccBlueDarker  = ccNavyText;
const Color ccBlueLight   = ccPrimary;
const Color ccBlueLighter = Color(0xFFAEC3FF);
const Color ccBlueGhost   = ccIceBlue;
const Color ccBlueBorder  = ccInputBorder;
const Color ccNavy        = ccNavyText;
const Color ccSlate       = ccSecondaryText;
const Color ccMist        = Color(0xFF8BA4C8);
const Color ccWhite       = ccSurface;
const Color ccOffWhite    = ccBackground;
const Color ccBg          = ccBackground;

Color redColor         = ccError;
Color greenColor       = ccSuccess;
Color orangeColor      = ccOrange;
Color darkOrangeColor  = const Color(0xFFC75E00);
Color purpleColor      = const Color(0xFF8A38F5);
Color redlightColor    = ccErrorLight;
Color greenlightColor  = ccSuccessLight;
Color yellowlightColor = ccWarningLight;
Color yellowColor      = ccWarning;
Color yellowborderColor = const Color(0xFFF6E1BB);
Color lightyellowColor  = ccWarningLight;

Color bordercolor = ccInputBorder;
Color black       = ccNavyText;

String currency = (getData.read("currency") == null || "${getData.read("currency")}" == "null")
    ? "₦"
    : "${getData.read("currency")}";
