import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/booking/booking_screen.dart';
import '../screens/tracking/tracking_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/driver/driver_home_screen.dart';
import '../screens/notifications/notifications_screen.dart';

GoRouter buildRouter(AuthProvider auth) => GoRouter(
      initialLocation: '/home',
      refreshListenable: auth,
      redirect: (context, state) {
        final isAuth = auth.status == AuthStatus.authenticated;
        final isUnknown = auth.status == AuthStatus.unknown;
        final path = state.matchedLocation;

        if (isUnknown) return null;
        if (!isAuth && path != '/login' && path != '/register') return '/login';
        if (isAuth && (path == '/login' || path == '/register')) {
          return auth.isDriver ? '/driver' : '/home';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/driver', builder: (_, __) => const DriverHomeScreen()),
        GoRoute(
          path: '/booking/:rideId',
          builder: (_, state) => BookingScreen(rideId: state.pathParameters['rideId']!),
        ),
        GoRoute(
          path: '/tracking/:rideId',
          builder: (_, state) => TrackingScreen(rideId: state.pathParameters['rideId']!),
        ),
        GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      ],
      errorBuilder: (_, state) => Scaffold(
        body: Center(child: Text('Page not found: ${state.error}')),
      ),
    );
