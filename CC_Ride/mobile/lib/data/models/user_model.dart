class UserModel {
  final String id;
  final String name;
  final String? email;
  final String mobile;
  final String countryCode;
  final String? profilePicUrl;
  final double walletBalance;
  final bool isDriver;
  final String status;
  final String? companyId;
  final String? departmentId;
  final String? costCentreId;
  final String? employeeRole;

  const UserModel({
    required this.id,
    required this.name,
    this.email,
    required this.mobile,
    this.countryCode = '+234',
    this.profilePicUrl,
    this.walletBalance = 0.0,
    this.isDriver = false,
    this.status = 'active',
    this.companyId,
    this.departmentId,
    this.costCentreId,
    this.employeeRole,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        mobile: json['mobile'] as String,
        countryCode: json['country_code'] as String? ?? '+234',
        profilePicUrl: json['profile_pic_url'] as String?,
        walletBalance: double.tryParse(json['wallet_balance']?.toString() ?? '0') ?? 0.0,
        isDriver: json['is_driver'] as bool? ?? false,
        status: json['status'] as String? ?? 'active',
        companyId: json['company_id'] as String?,
        departmentId: json['department_id']?.toString(),
        costCentreId: json['cost_centre_id']?.toString(),
        employeeRole: json['employee_role'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'mobile': mobile,
        'country_code': countryCode,
        'profile_pic_url': profilePicUrl,
        'wallet_balance': walletBalance,
        'is_driver': isDriver,
        'status': status,
        'company_id': companyId,
        'department_id': departmentId,
        'cost_centre_id': costCentreId,
        'employee_role': employeeRole,
      };

  UserModel copyWith({
    String? name,
    String? email,
    String? profilePicUrl,
    double? walletBalance,
    String? companyId,
    String? departmentId,
    String? costCentreId,
    String? employeeRole,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        mobile: mobile,
        countryCode: countryCode,
        profilePicUrl: profilePicUrl ?? this.profilePicUrl,
        walletBalance: walletBalance ?? this.walletBalance,
        isDriver: isDriver,
        status: status,
        companyId: companyId ?? this.companyId,
        departmentId: departmentId ?? this.departmentId,
        costCentreId: costCentreId ?? this.costCentreId,
        employeeRole: employeeRole ?? this.employeeRole,
      );
}
