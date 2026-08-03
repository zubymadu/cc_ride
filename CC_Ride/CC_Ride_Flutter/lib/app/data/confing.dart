
class Confing {
  static String imageurl = "https://api.ccride.ng/";
  static String baseurl = '${imageurl}api/';

  //======================= mapkey  =======================
  static String mapkey = "AIzaSyCmwZUAtfztYbllQ5U093ukJkyNXQ7nZlQ";

  //======================= oneSignalKey  =======================
  static String oneSignalKey = "************";
  static const String projectID = "**************";
  static String? firebaseKey;


  // ======================= login =======================
  static String emailcheck = 'email_check.php';
  static String mobileCheck = 'mobile_check.php';
  static String login = 'user_login.php';
  static String regUser = 'reg_user.php';
  static String forgetpassword = 'forget_password.php';

  //======================= homeApi =======================
  static String postTrip = 'post_trip.php';
  static String editPostTrip = 'edit_post_trip.php';
  static String cancelTrip = 'cancel_trip.php';
  static String addvehicle = 'add_vehicle.php';

  static String dataGet = 'dataget.php';
  static String colorTypeModellist = 'color_type_modellist.php';
  static String tripList = 'my_trip_list.php';
  static String tripDetails = 'trip_details.php';

  //======================= profile =======================
  static String profileEdit = 'profile_edit.php';
  static String accDelete = 'acc_delete.php';
  static String faq = 'faq.php';
  static String pagelist = 'pagelist.php';
  static String proImage = 'pro_image.php';
  static String editvehicle = 'edit_vehicle.php';
  static String vehicleList = 'vehicle_list.php';
  static String userProfile = 'user_profile.php';
  static String referdata = 'referdata.php';

  //======================= trip =======================
  static String tripRequest = 'trip_request.php';
  static String tripRequestlist = 'trip_request_list.php';
  static String editTripRequest = 'edit_trip_request.php';
  static String deleteTripRequest = 'delete_trip_request.php';

  //======================= otp =======================
  static String smsType = 'sms_type.php';
  static String msgOtp = 'msg_otp.php';
  static String twilioOtp = 'twilio_otp.php';
  // static String emailOtp = 'email_otp.php';

  //======================= find =======================
  static String findTrip = 'find_trip.php';
  static String findTripDetail = 'find_trip_detail.php';
  static String requestList = 'request_list.php';
  static String bookSeat = 'book_seat.php';
  static String cancleSeat = 'cancle_seat.php';

  //======================= payment =======================
  static String paymentgateway = 'paymentgateway.php';
  static String walletUp = 'wallet_up.php';
  static String walletreport = 'wallet_report.php';
  static String checkcoupon = 'u_check_coupon.php';
  static String couponlist = 'u_couponlist.php';

  //======================= book =======================
  static String mybookTriplist = 'my_book_trip_list.php';
  static String bookTripDetails = 'book_trip_details.php';
  static String makeDecision = 'make_decision.php';
  static String processingTrip = 'processing_trip.php';
  static String completeTrip = 'complete_trip.php';
  static String rateUpdate = 'rate_update.php';



  //======================= varification =======================
  static const String emailOtp = "email_otp.php";
  static const String verifyEmail = "verify_email.php";
  static const String mobileVerify = "mobile_verify.php";

  //======================= corporate =======================
  // Corporate booking flow
  static const String userCompanyWallets = "user/companies/wallets";
  static const String corporateEmployeeProfile = "corporate/employee/profile";
  static const String corporateBookingCheckPolicy = "corporate/bookings/check-policy";
  static const String corporateBookingBook = "corporate/bookings/book";
  static const String corporateBookingCancel = "corporate/bookings/cancel-approval";

  static const String corporateDashboard = "corporate/dashboard";
  static const String corporateEmployees = "corporate/employees";
  static const String corporateInviteEmployee = "corporate/employees/invite";
  static const String corporateDeactivateEmployee = "corporate/employees/deactivate";
  static const String corporateReactivateEmployee = "corporate/employees/reactivate";
  static const String corporateDepartments = "corporate/departments";
  static const String corporateCompanyLogo = "corporate/company/logo";
  static const String corporateDepartmentsImport = "corporate/departments/import";
  static const String corporateEmployeesImport = "corporate/employees/import";
  static const String corporateBudgets = "corporate/budgets";
  static const String corporateCreateBudget = "corporate/budgets/create";
  static const String corporateApprovals = "corporate/approvals";
  static const String corporateApprovalDecide = "corporate/approvals/decide";
  static const String corporatePolicies = "corporate/policies";
  static const String corporateCreatePolicy = "corporate/policies/create";
  static const String corporateTogglePolicy = "corporate/policies/toggle";

  //======================= varification =======================
  static const String earning = "earning.php";
  static const String requestWithdraw = "request_withdraw.php";
  static const String payoutList = "payout_list.php";

  //======================= payment getway =======================
  static String flutterwave = "flutterwave/index.php?";
  static String stripe = "stripe/index.php?";
  static String paytm = "paytm/index.php?";
  static String payStack = "paystack/index.php";
  static String merpago = "merpago/index.php?";
  static String payFast = "Payfast/index.php?";
  static String midtans = "Midtrans/index.php?";
  static String checkout2 = "2checkout/index.php?";
  static String khalti = "Khalti/index.php?";
}
