import 'package:carride/Utils/font_family.dart';
import 'package:carride/theme/theme_colores.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

Widget customButton({
  Color? backgroundColor,
  Color? buttonBorderColor,
  Color? buttontextColor,
  double? height,
  double? width,
  double? fontSize,
  BorderRadius? borderRadius,
  EdgeInsetsGeometry? padding,
  required VoidCallback onPressed,
  required String text,
}) {
  ThemeColores themeColores = Get.put(ThemeColores());
  return InkWell(
    onTap: onPressed,
    child: Container(
      height: height ?? 45,
      width: width ?? Get.width,
      padding: padding ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: backgroundColor ?? themeColores.themebuttoncolor,
        borderRadius: borderRadius ?? BorderRadius.circular(15),
        border: Border.all(color: buttonBorderColor ?? Colors.transparent),
      ),
      child: Center(
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          textAlign: TextAlign.center,
          style:  TextStyle(
            fontFamily: FontFamily.bold,
            fontSize: fontSize ?? 17,
            color: buttontextColor ?? Colors.white,
          ),
        ),
      ),
    ),
  );
}

Widget loaderButton({
  BorderRadius? borderRadius,
  double? height,
  double? width,
  Color? colors,
}){
  ThemeColores themeColores = Get.put(ThemeColores());
  return SizedBox(
    height: height ?? 45,
    width: width ?? Get.width,
    child: ElevatedButton(
      style: ButtonStyle(
        elevation: const WidgetStatePropertyAll(0),
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
        backgroundColor: WidgetStateProperty.all(colors?.withOpacity(0.15) ?? themeColores.themeText.withOpacity(0.15)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(15),
          ),
        ),
      ),
      onPressed: (){},
      child: LoadingAnimationWidget.staggeredDotsWave(
        color: colors ?? themeColores.themeText,
        size: 25,
      ),
    ),
  );
}

Widget customBackButton({VoidCallback ? onTap}) {
  ThemeColores themeColores = Get.put(ThemeColores());
  return InkWell(
    onTap: onTap ?? () {
      Get.back();
    },
    child: Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: themeColores.themebgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.arrow_back,
        color: themeColores.themeText,
      ),
    ),
  );
}

PreferredSizeWidget customAppBar({VoidCallback ? onTap, required String title}) {
  ThemeColores themeColores = Get.put(ThemeColores());
  return AppBar(
    leading: InkWell(
      onTap: onTap ?? () {
        Get.back();
      },
      child: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeColores.themebgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back,
          color: themeColores.themeText,
        ),
      ),
    ),
    backgroundColor: themeColores.themelightbgColor,

    elevation: 0,
    centerTitle: true,
    title: Text(title),
  );
}

Future<void> makingPhoneCall({required String number}) async {
  await Permission.phone.request();
  var status = await Permission.phone.status;
  if (!status.isGranted) {
    status = await Permission.phone.request();
  }
  if (status.isGranted) {
    var url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  } else if (status.isPermanentlyDenied) {
    showToastMessage("Please allow calls Permission".tr);
    await openAppSettings();
  } else {
    showToastMessage("Please allow calls Permission".tr);
    await openAppSettings();
  }
}

