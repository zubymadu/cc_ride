class AppConstants {
  static const String appName = 'CC Ride';
  static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator → localhost
  static const String socketUrl = 'http://10.0.2.2:3000';

  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
