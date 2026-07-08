// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:carride/app/modules/models/map_api_model.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';

Widget suggestionsTextField({
  FocusNode? focusNode,
  TextEditingController? controller,
  Widget Function(BuildContext, TextEditingController, FocusNode)? builder,
  required FutureOr<List<Result>?> Function(String) suggestionsCallback,
  required void Function(Result)? onSelected,
  String? title,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if(title != null)...[
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: ccNavyText,
          ),
        ),
        const SizedBox(height: 5),
      ],
      TypeAheadField<Result>(
        controller: controller,
        focusNode: focusNode,
        builder: builder,
        loadingBuilder: (context) => const SizedBox(),
        suggestionsCallback: suggestionsCallback,
        itemBuilder: (context, Result suggestion) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ccBackground,
                    border: Border.all(color: ccInputBorder),
                  ),
                  child: SvgPicture.asset(
                    "assets/image/svg/locationpin.svg",
                    color: ccNavyText,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${suggestion.name}",
                        style: const TextStyle(
                          color: ccNavyText,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "${suggestion.formattedAddress}",
                        style: const TextStyle(
                          color: ccSecondaryText,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        onSelected: onSelected,
        emptyBuilder: (context) => const SizedBox(),
      ),
    ],
  );
}

Widget dropdownFile({
  String? value,
  String? hintText,
  required List<DropdownMenuItem<String>> items,
  required void Function(String?) onChanged,
  Color? fillColor,
}) {
  return DropdownButtonFormField<String>(
    initialValue: value!.isEmpty ? null : value,
    borderRadius: BorderRadius.circular(CCRadius.card),
    icon: const Icon(Icons.arrow_forward_ios, color: ccSecondaryText, size: 15),
    elevation: 1,
    style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: ccNavyText),
    decoration: InputDecoration(
      filled: true,
      fillColor: fillColor ?? ccSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      hintText: hintText,
      hintStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, color: ccSecondaryText),
      hoverColor: Colors.transparent,
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: ccPrimary, width: 1.5),
        borderRadius: BorderRadius.circular(CCRadius.input),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CCRadius.input),
        borderSide: const BorderSide(color: ccInputBorder, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CCRadius.input),
        borderSide: const BorderSide(color: ccError, width: 1.4),
      ),
    ),
    dropdownColor: ccBackground,
    isExpanded: false,
    items: items,
    onChanged: onChanged,
  );
}