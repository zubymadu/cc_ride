// Corporate data models for CC Ride

// ─── Dashboard ────────────────────────────────────────────────────────────────

class CorporateDashboardModel {
  final String companyName;
  final String companyId;
  final double monthlyBudget;
  final double monthlySpent;
  final int totalEmployees;
  final int activeEmployees;
  final int pendingApprovals;
  final int ridesThisMonth;
  final double spendPercent;
  final List<DeptSpendItem> deptSpend;
  final List<RecentRideItem> recentRides;

  CorporateDashboardModel({
    required this.companyName,
    required this.companyId,
    required this.monthlyBudget,
    required this.monthlySpent,
    required this.totalEmployees,
    required this.activeEmployees,
    required this.pendingApprovals,
    required this.ridesThisMonth,
    required this.spendPercent,
    required this.deptSpend,
    required this.recentRides,
  });

  factory CorporateDashboardModel.fromJson(Map<String, dynamic> json) {
    return CorporateDashboardModel(
      companyName: json['company_name'] ?? '',
      companyId: json['company_id'] ?? '',
      monthlyBudget: double.tryParse('${json['monthly_budget']}') ?? 0,
      monthlySpent: double.tryParse('${json['monthly_spent']}') ?? 0,
      totalEmployees: int.tryParse('${json['total_employees']}') ?? 0,
      activeEmployees: int.tryParse('${json['active_employees']}') ?? 0,
      pendingApprovals: int.tryParse('${json['pending_approvals']}') ?? 0,
      ridesThisMonth: int.tryParse('${json['rides_this_month']}') ?? 0,
      spendPercent: double.tryParse('${json['spend_percent']}') ?? 0,
      deptSpend: (json['dept_spend'] as List? ?? [])
          .map((e) => DeptSpendItem.fromJson(e))
          .toList(),
      recentRides: (json['recent_rides'] as List? ?? [])
          .map((e) => RecentRideItem.fromJson(e))
          .toList(),
    );
  }
}

class DeptSpendItem {
  final String department;
  final double spent;
  final double budget;
  final double percent;

  DeptSpendItem({
    required this.department,
    required this.spent,
    required this.budget,
    required this.percent,
  });

  factory DeptSpendItem.fromJson(Map<String, dynamic> json) => DeptSpendItem(
        department: json['department'] ?? '',
        spent: double.tryParse('${json['spent']}') ?? 0,
        budget: double.tryParse('${json['budget']}') ?? 0,
        percent: double.tryParse('${json['percent']}') ?? 0,
      );
}

class RecentRideItem {
  final String employeeName;
  final String profilePic;
  final String origin;
  final String destination;
  final double amount;
  final String status;
  final String rideDate;

  RecentRideItem({
    required this.employeeName,
    required this.profilePic,
    required this.origin,
    required this.destination,
    required this.amount,
    required this.status,
    required this.rideDate,
  });

  factory RecentRideItem.fromJson(Map<String, dynamic> json) => RecentRideItem(
        employeeName: json['employee_name'] ?? '',
        profilePic: json['profile_pic'] ?? '',
        origin: json['origin'] ?? '',
        destination: json['destination'] ?? '',
        amount: double.tryParse('${json['amount']}') ?? 0,
        status: json['status'] ?? '',
        rideDate: json['ride_date'] ?? '',
      );
}

// ─── Employees ────────────────────────────────────────────────────────────────

class EmployeeModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String mobile;
  final String profilePic;
  final String department;
  final String departmentId;
  final String costCentre;
  final String role;
  final String jobTitle;
  final double? monthlySpendLimit;
  final bool isActive;
  final String joinedAt;

  EmployeeModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.mobile,
    required this.profilePic,
    required this.department,
    required this.departmentId,
    required this.costCentre,
    required this.role,
    required this.jobTitle,
    this.monthlySpendLimit,
    required this.isActive,
    required this.joinedAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) => EmployeeModel(
        id: '${json['id']}',
        userId: '${json['user_id']}',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        mobile: json['mobile'] ?? '',
        profilePic: json['profile_pic'] ?? '',
        department: json['department'] ?? '',
        departmentId: '${json['department_id'] ?? ''}',
        costCentre: json['cost_centre'] ?? '',
        role: json['role'] ?? 'employee',
        jobTitle: json['job_title'] ?? '',
        monthlySpendLimit: json['monthly_spend_limit'] != null
            ? double.tryParse('${json['monthly_spend_limit']}')
            : null,
        isActive: json['is_active'] == true || json['is_active'] == 1,
        joinedAt: json['joined_at'] ?? '',
      );
}

class DepartmentModel {
  final String id;
  final String name;
  final String code;

  DepartmentModel({required this.id, required this.name, required this.code});

  factory DepartmentModel.fromJson(Map<String, dynamic> json) =>
      DepartmentModel(
        id: '${json['id']}',
        name: json['name'] ?? '',
        code: json['code'] ?? '',
      );
}

// ─── Budgets ──────────────────────────────────────────────────────────────────

class BudgetModel {
  final String id;
  final String department;
  final String departmentId;
  final String periodType;
  final String periodStart;
  final String periodEnd;
  final double allocatedAmount;
  final double spentAmount;
  final double remainingAmount;
  final double spendPercent;
  final double alertThreshold;
  final bool isActive;

  BudgetModel({
    required this.id,
    required this.department,
    required this.departmentId,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.spendPercent,
    required this.alertThreshold,
    required this.isActive,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: '${json['id']}',
        department: json['department'] ?? 'Company-wide',
        departmentId: '${json['department_id'] ?? ''}',
        periodType: json['period_type'] ?? 'monthly',
        periodStart: json['period_start'] ?? '',
        periodEnd: json['period_end'] ?? '',
        allocatedAmount: double.tryParse('${json['allocated_amount']}') ?? 0,
        spentAmount: double.tryParse('${json['spent_amount']}') ?? 0,
        remainingAmount: double.tryParse('${json['remaining_amount']}') ?? 0,
        spendPercent: double.tryParse('${json['spend_percent']}') ?? 0,
        alertThreshold: double.tryParse('${json['alert_threshold']}') ?? 80,
        isActive: json['is_active'] == true || json['is_active'] == 1,
      );
}

// ─── Approvals ────────────────────────────────────────────────────────────────

class ApprovalRequestModel {
  final String id;
  final String bookingId;
  final String requesterName;
  final String requesterPic;
  final String requesterDept;
  final String origin;
  final String destination;
  final double estimatedFare;
  final String scheduledAt;
  final String status;
  final String? decisionNote;
  final String expiresAt;
  final String createdAt;

  ApprovalRequestModel({
    required this.id,
    required this.bookingId,
    required this.requesterName,
    required this.requesterPic,
    required this.requesterDept,
    required this.origin,
    required this.destination,
    required this.estimatedFare,
    required this.scheduledAt,
    required this.status,
    this.decisionNote,
    required this.expiresAt,
    required this.createdAt,
  });

  factory ApprovalRequestModel.fromJson(Map<String, dynamic> json) =>
      ApprovalRequestModel(
        id: '${json['id']}',
        bookingId: '${json['booking_id']}',
        requesterName: json['requester_name'] ?? '',
        requesterPic: json['requester_pic'] ?? '',
        requesterDept: json['requester_dept'] ?? '',
        origin: json['origin_address'] ?? '',
        destination: json['destination_address'] ?? '',
        estimatedFare: double.tryParse('${json['estimated_fare']}') ?? 0,
        scheduledAt: json['scheduled_at'] ?? '',
        status: json['status'] ?? 'pending',
        decisionNote: json['decision_note'],
        expiresAt: json['expires_at'] ?? '',
        createdAt: json['created_at'] ?? '',
      );
}

// ─── Ride Policies ────────────────────────────────────────────────────────────

class RidePolicyModel {
  final String id;
  final String name;
  final String department;
  final String departmentId;
  final List<int> allowedDays;
  final String? allowedTimeFrom;
  final String? allowedTimeTo;
  final double? maxFarePerTrip;
  final double? maxMonthlySpend;
  final String? maxVehicleType;
  final bool isActive;

  RidePolicyModel({
    required this.id,
    required this.name,
    required this.department,
    required this.departmentId,
    required this.allowedDays,
    this.allowedTimeFrom,
    this.allowedTimeTo,
    this.maxFarePerTrip,
    this.maxMonthlySpend,
    this.maxVehicleType,
    required this.isActive,
  });

  factory RidePolicyModel.fromJson(Map<String, dynamic> json) => RidePolicyModel(
        id: '${json['id']}',
        name: json['name'] ?? '',
        department: json['department'] ?? 'Company-wide',
        departmentId: '${json['department_id'] ?? ''}',
        allowedDays: (json['allowed_days'] as List? ?? [])
            .map((e) => int.tryParse('$e') ?? 0)
            .toList(),
        allowedTimeFrom: json['allowed_time_from'],
        allowedTimeTo: json['allowed_time_to'],
        maxFarePerTrip: json['max_fare_per_trip'] != null
            ? double.tryParse('${json['max_fare_per_trip']}')
            : null,
        maxMonthlySpend: json['max_monthly_spend'] != null
            ? double.tryParse('${json['max_monthly_spend']}')
            : null,
        maxVehicleType: json['max_vehicle_type'],
        isActive: json['is_active'] == true || json['is_active'] == 1,
      );

  String get daysLabel {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (allowedDays.isEmpty) return 'All days';
    if (allowedDays.length == 7) return 'All days';
    if (allowedDays.toSet().containsAll({1, 2, 3, 4, 5}) && allowedDays.length == 5) {
      return 'Weekdays';
    }
    return allowedDays.map((d) => names[d]).join(', ');
  }
}

// ─── Fixed Routes ("Find Shared Route") ────────────────────────────────────────

class RouteModel {
  final String id;
  final String code;
  final String name;
  final String originName;
  final String destinationName;
  final bool isActive;
  final int stopCount;
  final int scheduleCount;

  RouteModel({
    required this.id,
    required this.code,
    required this.name,
    required this.originName,
    required this.destinationName,
    required this.isActive,
    required this.stopCount,
    required this.scheduleCount,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) => RouteModel(
        id: json['id'] ?? '',
        code: json['code'] ?? '',
        name: json['name'] ?? '',
        originName: json['origin_name'] ?? '',
        destinationName: json['destination_name'] ?? '',
        isActive: json['is_active'] == true || json['is_active'] == 1,
        stopCount: int.tryParse('${json['stop_count']}') ?? 0,
        scheduleCount: int.tryParse('${json['schedule_count']}') ?? 0,
      );
}

class RouteScheduleModel {
  final String id;
  final String departureTime;
  final List<int> daysOfWeek;
  final String driverId;
  final String driverName;
  final String vehicleId;
  final String vehicleTitle;
  final int seatCapacity;
  final double fare;
  final bool isActive;

  RouteScheduleModel({
    required this.id,
    required this.departureTime,
    required this.daysOfWeek,
    required this.driverId,
    required this.driverName,
    required this.vehicleId,
    required this.vehicleTitle,
    required this.seatCapacity,
    required this.fare,
    required this.isActive,
  });

  factory RouteScheduleModel.fromJson(Map<String, dynamic> json) =>
      RouteScheduleModel(
        id: '${json['id'] ?? ''}',
        departureTime: json['departure_time'] ?? '',
        daysOfWeek: (json['days_of_week'] as List? ?? [])
            .map((e) => int.tryParse('$e') ?? 0)
            .toList(),
        driverId: json['driver_id'] ?? '',
        driverName: json['driver_name'] ?? '',
        vehicleId: '${json['vehicle_id'] ?? ''}',
        vehicleTitle: json['vehicle_title'] ?? '',
        seatCapacity: int.tryParse('${json['seat_capacity']}') ?? 0,
        fare: double.tryParse('${json['fare']}') ?? 0,
        isActive: json['is_active'] == true || json['is_active'] == 1,
      );

  String get daysLabel {
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (daysOfWeek.length == 7) return 'Every day';
    final sorted = [...daysOfWeek]..sort();
    return sorted.map((d) => names[d]).join(', ');
  }
}
