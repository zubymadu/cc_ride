import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router.dart';
import 'data/services/api_service.dart';
import 'data/services/socket_service.dart';
import 'providers/auth_provider.dart';
import 'providers/ride_provider.dart';
import 'providers/driver_provider.dart';
import 'providers/notification_provider.dart';

void main() {
  runApp(const CCRideApp());
}

class CCRideApp extends StatefulWidget {
  const CCRideApp({super.key});

  @override
  State<CCRideApp> createState() => _CCRideAppState();
}

class _CCRideAppState extends State<CCRideApp> {
  late final ApiService _api;
  late final SocketService _socket;
  late final AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    _api = ApiService();
    _socket = SocketService();
    _auth = AuthProvider(_api, _socket);
    _auth.tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: _api),
        Provider<SocketService>.value(value: _socket),
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider(create: (_) => RideProvider(_api)),
        ChangeNotifierProvider(create: (_) => DriverProvider(_api, _socket)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(_api)),
      ],
      child: Builder(
        builder: (context) {
          final auth = context.watch<AuthProvider>();
          final router = buildRouter(auth);
          return MaterialApp.router(
            title: 'CC Ride',
            theme: AppTheme.light,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
