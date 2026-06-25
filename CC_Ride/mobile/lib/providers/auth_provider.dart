import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../data/models/user_model.dart';
import '../data/services/api_service.dart';
import '../data/services/socket_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final SocketService _socket;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _token;
  String? _error;
  bool _loading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get token => _token;
  String? get error => _error;
  bool get loading => _loading;
  bool get isDriver => _user?.isDriver ?? false;

  AuthProvider(this._api, this._socket);

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final userJson = prefs.getString(AppConstants.userKey);
    if (token != null && userJson != null) {
      _token = token;
      _user = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      _socket.connect(token);
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({required String mobile, required String password}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.login(mobile: mobile, password: password);
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        _token = data['token'] as String;
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await _persist();
        _socket.connect(_token!);
        _status = AuthStatus.authenticated;
        _loading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] as String? ?? 'Login failed';
      }
    } catch (e) {
      _error = _parseError(e);
    }
    _loading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String name,
    required String mobile,
    required String password,
    String? email,
    bool isDriver = false,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.register(
        name: name,
        mobile: mobile,
        password: password,
        email: email,
        isDriver: isDriver,
      );
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        _token = data['token'] as String;
        _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await _persist();
        _socket.connect(_token!);
        _status = AuthStatus.authenticated;
        _loading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] as String? ?? 'Registration failed';
      }
    } catch (e) {
      _error = _parseError(e);
    }
    _loading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _socket.disconnect();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    _token = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void updateUser(UserModel updated) {
    _user = updated;
    _persistUser();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, _token!);
    await _persistUser();
  }

  Future<void> _persistUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
  }

  String _parseError(dynamic e) {
    if (e is Exception) {
      final str = e.toString();
      if (str.contains('DioException')) {
        final msg = str.split('message:').lastOrNull?.trim();
        return msg ?? 'Network error. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
