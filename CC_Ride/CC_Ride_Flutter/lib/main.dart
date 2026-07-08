import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/data/one_signal_notification.dart';
import 'package:carride/firebase_options.dart';
import 'package:carride/language/localstring.dart';
import 'package:carride/theme/theme_colores.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/utils/color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'app/routes/app_pages.dart';
import 'package:flutter/services.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  // Native Android auto-initializes Firebase from google-services.json;
  // initializing again throws [core/duplicate-app]. Guard + bound the wait —
  // nothing here may delay the first frame indefinitely.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
          .timeout(const Duration(seconds: 5));
    }
  } catch (_) { /* Firebase optional in demo builds */ }
  await GetStorage.init();
  // Fire-and-forget: OneSignal registration needs network + a valid key and
  // can hang forever — it must never block runApp.
  Future(() => OneSignalService.initializeOneSignal())
      .catchError((_) { /* push notifications optional in demo builds */ });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeColores themeColores = Get.put(ThemeColores());
    return GetMaterialApp(
      title: "CC Ride",
      builder: (context, child) {
        return SafeArea(
          top: false,
          child: child!,
        );
      },
      theme: ThemeData(
        brightness: Brightness.light,
        appBarTheme: AppBarTheme(
          backgroundColor: ccSurface,
          actionsIconTheme: IconThemeData(color: ccNavyText),
          elevation: 0,
          titleSpacing: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: TextStyle(
            color: ccNavyText,
            fontFamily: 'Inter', fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          iconTheme: IconThemeData(color: ccNavyText),
        ),
        textTheme: TextTheme(),
        primaryColor: ccPrimary,
        scaffoldBackgroundColor: ccSurface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ccPrimary,
          primary: ccPrimary,
          onPrimary: ccSurface,
          surface: ccSurface,
          onSurface: ccNavyText,
        ),
        splashColor: ccIceBlue,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        dividerColor: ccInputBorder,
        useMaterial3: false,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        appBarTheme: AppBarTheme(
          actionsIconTheme: IconThemeData(color: ccSurface),
          backgroundColor: ccNavyText,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: TextStyle(
            color: ccSurface,
            fontFamily: 'Inter', fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          iconTheme: IconThemeData(color: ccSurface),
        ),
        scaffoldBackgroundColor: ccNavyText,
        primaryColor: ccPrimary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ccPrimary,
          brightness: Brightness.dark,
          primary: ccPrimary,
          onPrimary: ccSurface,
          surface: ccNavyText,
          onSurface: ccSurface,
        ),
        splashColor: const Color(0xFF102050),
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        dividerColor: const Color(0xFF1E3A7A),
        useMaterial3: false,
        fontFamily: 'Inter',
      ),
      themeMode: themeColores.theme,
      debugShowCheckedModeBanner: false,
      translations: LocaleString(),
      locale: getData.read("lan2") != null
          ? Locale(getData.read("lan2"), getData.read("lan1"))
          : Locale('en_US', 'en_US'),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    );
  }
}

Future<void> initPlatformState({required String key, required String loginId}) async {
  try {
    debugPrint("=========== OneSignalKey ============ $key");
    await OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(key);
    await OneSignal.Notifications.requestPermission(true).then((value) {debugPrint("Signal value:- $value");});
    OneSignal.User.addTags({"userid": loginId});
  } catch (e) {
    debugPrint("=========== OneSignal init error (non-fatal) ============ $e");
  }
}
