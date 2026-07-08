import 'package:carride/Utils/color.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

DateTime? lastBackPressed;
Future popScopeBack() async {
  DateTime now = DateTime.now();
  if (lastBackPressed == null ||
      now.difference(lastBackPressed!) > Duration(seconds: 2)) {
    lastBackPressed = now;
    showToastMessage("Press back again to exit");
    return false;
  } else {
    return true;
  }
}

void showToastMessage(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    // backgroundColor: Colors.black87,
    // textColor: Colors.white,
    fontSize: 16.0,
  );
}

CircularProgressIndicator circularProgressDark = CircularProgressIndicator(color: darkblueColor);
CircularProgressIndicator circularProgressLight = CircularProgressIndicator(color: white);