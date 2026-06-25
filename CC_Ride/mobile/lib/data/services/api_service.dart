import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) {
        handler.next(err);
      },
    ));
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String name,
    required String mobile,
    required String password,
    String? email,
    bool isDriver = false,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'name': name,
      'mobile': mobile,
      'password': password,
      if (email != null) 'email': email,
      'is_driver': isDriver,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String mobile,
    required String password,
  }) async {
    final res = await _dio.post('/auth/login', data: {
      'mobile': mobile,
      'password': password,
    });
    return res.data as Map<String, dynamic>;
  }

  // ── Rides ─────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getAvailableRides({
    String? originLat,
    String? originLng,
    String? date,
  }) async {
    final res = await _dio.get('/rides/available', queryParameters: {
      if (originLat != null) 'lat': originLat,
      if (originLng != null) 'lng': originLng,
      if (date != null) 'date': date,
    });
    final data = res.data as Map<String, dynamic>;
    return data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getRideDetail(String rideId) async {
    final res = await _dio.get('/rides/$rideId');
    return res.data as Map<String, dynamic>;
  }

  // ── Policy check + booking ────────────────────────────────────────────────

  Future<Map<String, dynamic>> checkPolicy({
    required String companyId,
    required String userId,
    required double estimatedFare,
    String? departmentId,
    String? vehicleTypeId,
    String? scheduledAt,
  }) async {
    final res = await _dio.post('/corporate/bookings/check-policy', data: {
      'company_id': companyId,
      'user_id': userId,
      'estimated_fare': estimatedFare,
      if (departmentId != null) 'department_id': departmentId,
      if (vehicleTypeId != null) 'vehicle_type_id': vehicleTypeId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createBooking({
    required String companyId,
    required String userId,
    required String rideId,
    required int seats,
    required double subtotal,
    required double totalAmount,
    String? departmentId,
    String? costCentreId,
    bool requiresApproval = false,
  }) async {
    final res = await _dio.post('/corporate/bookings/book', data: {
      'company_id': companyId,
      'uid': userId,
      'trip_id': rideId,
      'total_seat': seats,
      'subtotal': subtotal,
      'total_amount': totalAmount,
      if (departmentId != null) 'department_id': departmentId,
      if (costCentreId != null) 'cost_centre_id': costCentreId,
      'requires_approval': requiresApproval,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelApproval({
    required String approvalRequestId,
    required String userId,
  }) async {
    final res = await _dio.post('/corporate/bookings/cancel-approval', data: {
      'approval_request_id': approvalRequestId,
      'user_id': userId,
    });
    return res.data as Map<String, dynamic>;
  }

  // ── User bookings ─────────────────────────────────────────────────────────

  Future<List<dynamic>> getMyBookings({String? status}) async {
    final res = await _dio.get('/user/bookings', queryParameters: {
      if (status != null) 'status': status,
    });
    final data = res.data as Map<String, dynamic>;
    return data['data'] as List<dynamic>;
  }

  // ── Company & profile ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMyCompanyProfile() async {
    final res = await _dio.get('/user/company-profile');
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getDepartments() async {
    final res = await _dio.get('/corporate/departments');
    final data = res.data as Map<String, dynamic>;
    return data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getEmployeeProfile() async {
    final res = await _dio.get('/corporate/employee/profile');
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> searchCompanies(String query) async {
    final res = await _dio.get('/user/companies/search', queryParameters: {'q': query});
    final data = res.data as Map<String, dynamic>;
    return data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> joinCompany({
    required String companyId,
    String? departmentId,
    String? employeeNumber,
  }) async {
    final res = await _dio.post('/user/companies/join', data: {
      'company_id': companyId,
      if (departmentId != null) 'department_id': departmentId,
      if (employeeNumber != null) 'employee_number': employeeNumber,
    });
    return res.data as Map<String, dynamic>;
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<List<dynamic>> getNotifications() async {
    final res = await _dio.get('/user/notifications');
    final data = res.data as Map<String, dynamic>;
    return data['data'] as List<dynamic>;
  }

  Future<void> markNotificationRead(String id) async {
    await _dio.post('/user/notifications/$id/read');
  }

  // ── Wallet ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getWallet() async {
    final res = await _dio.get('/user/wallet');
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getWalletTransactions() async {
    final res = await _dio.get('/user/wallet/transactions');
    final data = res.data as Map<String, dynamic>;
    return data['data'] as List<dynamic>;
  }

  // ── Driver ────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getDriverRides({String? status}) async {
    final res = await _dio.get('/driver/rides', queryParameters: {
      if (status != null) 'status': status,
    });
    final data = res.data as Map<String, dynamic>;
    return data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> updateDriverStatus(String status) async {
    final res = await _dio.post('/driver/status', data: {'status': status});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String rideId,
    required String otp,
    required String type, // 'pickup' | 'dropoff'
  }) async {
    final res = await _dio.post('/driver/verify-otp', data: {
      'ride_id': rideId,
      'otp': otp,
      'type': type,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDriverEarnings() async {
    final res = await _dio.get('/driver/earnings');
    return res.data as Map<String, dynamic>;
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    final res = await _dio.get('/user/profile');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? bio,
  }) async {
    final res = await _dio.put('/user/profile', data: {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (bio != null) 'bio': bio,
    });
    return res.data as Map<String, dynamic>;
  }
}
