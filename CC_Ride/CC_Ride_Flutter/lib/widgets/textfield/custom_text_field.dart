import 'dart:async';

import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

Widget customTextFormField({
  required String hintText,
  String? labelText,
  TextEditingController? controller,
  String? Function(String?)? validator,
  void Function(String)? onChanged,
  bool obscureText = false,
  TextInputType keyboardType = TextInputType.text,
  TextInputAction? textInputAction,
  Widget? prefixIcon,
  Widget? suffixIcon,
  BorderRadius? borderRadius,
  String? title,
  int? maxLines,
  Color? fillColor,
  EdgeInsetsGeometry? contentPadding,
  BorderSide? borderSide,
  void Function(String?)? onSaved,
  List<TextInputFormatter>? inputFormatters,
  TextStyle? errorStyle,
  TextCapitalization? textCapitalization,
  bool readOnly = false,
}) {
  final radius = borderRadius ?? BorderRadius.circular(CCRadius.input);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (title != null) ...[
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ccNavyText,
          ),
        ),
        const SizedBox(height: 6),
      ],
      TextFormField(
        inputFormatters: inputFormatters,
        onSaved: onSaved,
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization ?? TextCapitalization.sentences,
        textInputAction: textInputAction ?? TextInputAction.done,
        cursorColor: ccPrimary,
        style: const TextStyle(fontFamily: 'Inter', color: ccNavyText),
        onChanged: onChanged,
        maxLines: obscureText ? 1 : (maxLines ?? 1),
        readOnly: readOnly,
        decoration: InputDecoration(
          prefixIcon: prefixIcon,
          labelText: labelText,
          floatingLabelStyle: const TextStyle(
            color: ccPrimary,
            fontFamily: 'Inter',
          ),
          labelStyle: const TextStyle(
            color: ccSecondaryText,
            fontSize: 15,
            fontFamily: 'Inter',
          ),
          hintText: hintText,
          hintStyle: const TextStyle(
            color: ccSecondaryText,
            fontSize: 15,
            fontFamily: 'Inter',
          ),
          fillColor: fillColor ?? ccSurface,
          filled: true,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: radius,
            borderSide: borderSide ?? const BorderSide(color: ccInputBorder),
          ),
          errorStyle: errorStyle,
          enabledBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: borderSide ?? const BorderSide(color: ccInputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: ccPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: ccError),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: ccError, width: 1.5),
          ),
          contentPadding: contentPadding ??
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    ],
  );
}

Widget customPhoneField({
  required String hintText,
  TextEditingController? controller,
  void Function(PhoneNumber)? onChanged,
  TextInputAction? textInputAction,
  bool obscureText = false,
  Widget? prefixIcon,
  Widget? suffixIcon,
  BorderRadius? borderRadius,
  String? title,
  bool showCountryFlag = true,
  FutureOr<String?> Function(PhoneNumber?)? validator,
  TextStyle? errorStyle,
  void Function(Country)? onCountryChanged,
  Color? fillBordercolor,
  Color? fillfocusBordercolor,
  Color? fillColor,
  bool readOnly = false,
  void Function()? onTap,
}) {
  final radius = borderRadius ?? BorderRadius.circular(CCRadius.input);
  final borderColor = fillBordercolor ?? ccInputBorder;
  final focusColor = fillfocusBordercolor ?? ccPrimary;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (title != null) ...[
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ccNavyText,
          ),
        ),
        const SizedBox(height: 6),
      ],
      IntlPhoneField(
        controller: controller,
        obscureText: obscureText,
        onCountryChanged: onCountryChanged,
        textInputAction: textInputAction,
        keyboardType: TextInputType.number,
        cursorColor: ccPrimary,
        readOnly: readOnly,
        style: const TextStyle(fontFamily: 'Inter', color: ccNavyText),
        validator: validator,
        disableLengthCheck: true,
        onChanged: onChanged,
        initialCountryCode: 'NG',
        showCountryFlag: showCountryFlag,
        dropdownIconPosition: IconPosition.trailing,
        flagsButtonPadding: const EdgeInsets.only(left: 5),
        dropdownTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          color: ccNavyText,
          letterSpacing: 0.3,
        ),
        onTap: onTap,
        dropdownDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
        ),
        flagsButtonMargin: const EdgeInsets.all(5),
        dropdownIcon: const Icon(
          Icons.keyboard_arrow_down_outlined,
          color: ccSecondaryText,
        ),
        decoration: InputDecoration(
          counterText: "",
          prefixIcon: prefixIcon,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: ccSecondaryText,
            fontSize: 15,
            fontFamily: 'Inter',
          ),
          errorStyle: errorStyle,
          fillColor: fillColor ?? ccSurface,
          filled: true,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: focusColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: ccError),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: ccError, width: 1.5),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ],
  );
}

Widget blueTextFilled({
  required String hintText,
  void Function(String)? onChanged,
  String? Function(String?)? validator,
  FocusNode? focusNode,
  TextEditingController? controller,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool? readOnly,
  void Function()? onTap,
  BorderRadius? borderRadius,
  EdgeInsetsGeometry? contentPadding,
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  int? maxLines = 1,
  String? title,
  bool obscureText = false,
  TextCapitalization textCapitalization = TextCapitalization.none,
  Color? fillColor,
}) {
  final radius = borderRadius ?? BorderRadius.circular(CCRadius.input);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (title != null) ...[
        Text(
          title,
          style: const TextStyle(
            color: ccNavyText,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
      ],
      TextFormField(
        readOnly: readOnly ?? false,
        onChanged: onChanged,
        validator: validator,
        focusNode: focusNode,
        controller: controller,
        cursorColor: ccPrimary,
        obscureText: obscureText,
        onTap: onTap,
        maxLines: obscureText ? 1 : maxLines,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        style: const TextStyle(fontFamily: 'Inter', color: ccNavyText),
        decoration: InputDecoration(
          contentPadding: contentPadding ??
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: fillColor ?? ccSurface,
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            color: ccSecondaryText,
          ),
          errorStyle: const TextStyle(fontFamily: 'Inter'),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: ccPrimary, width: 1.5),
            borderRadius: radius,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: ccInputBorder),
          ),
          border: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: ccInputBorder),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: ccError, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(color: ccError),
          ),
        ),
      ),
    ],
  );
}
