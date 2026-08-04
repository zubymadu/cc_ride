
class Confing {
  static String imageurl = "https://api.ccride.ng/";
  static String baseurl = '${imageurl}api/';

  //======================= mapkey  =======================
  static String mapkey = "AIzaSyCmwZUAtfztYbllQ5U093ukJkyNXQ7nZlQ";

  //======================= oneSignalKey  =======================
  // Was a literal placeholder ("************") that never got filled in —
  // initPlatformState() (called from login/register) re-initializes OneSignal
  // with this value *after* OneSignalService.initializeOneSignal() already
  // initialized it correctly at app boot with the real app ID below, silently
  // breaking the SDK's app id binding and the "userid" tag it sets right
  // after. That tag is what the backend now targets pushes at.
  static String oneSignalKey = "c90e9b2c-8f33-443d-8f28-2bc1993cd367";
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
  static String estimateFare = 'estimate_fare.php';

  //======================= corporate wallets =======================
  static String companyWallets = 'user/company-wallets';

  //======================= support tickets =======================
  static String supportTickets = 'user/support/tickets';

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
  static String confirmMatchedRequest = 'confirm_matched_request.php';
  static String declineMatchedRequest = 'decline_matched_request.php';
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
  static String nearbyRoutes = 'nearby_routes.php';
  static String driverRouteCreate = 'driver_route_create.php';
  static String driverRouteEdit = 'driver_route_edit.php';
  static String driverRouteList = 'driver_route_list.php';
  static String driverRouteDeactivate = 'driver_route_deactivate.php';
  static String nearbyRequestsRoute = 'nearby_requests_route.php';
  static String confirmBookingRequest = 'confirm_booking_request.php';
  static String declineBookingRequest = 'decline_booking_request.php';
  static String routeBookingRequests = 'route_booking_requests.php';
  static String requestList = 'request_list.php';
  static String bookSeat = 'book_seat.php';
  static String cancleSeat = 'cancle_seat.php';

  //======================= notifications =======================
  static String notificationList = 'notification_list.php';
  static String notificationRead = 'notification_read.php';
  static String notificationDelete = 'notification_delete.php';

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
  static const String corporateEmployeeProfile = "corporate/employee/profile";
  static const String corporateBookingCheckPolicy = "corporate/bookings/check-policy";
  static const String corporateBookingBook = "corporate/bookings/book";
  static const String corporateBookingCancel = "corporate/bookings/cancel-approval";

  static const String corporateDashboard = "corporate/dashboard";
  static const String corporateEmployees = "corporate/employees";
  static const String corporateInviteEmployee = "corporate/employees/invite";
  static const String corporateDeactivateEmployee = "corporate/employees/deactivate";
  static const String corporateDepartments = "corporate/departments";
  static const String corporateBudgets = "corporate/budgets";
  static const String corporateCreateBudget = "corporate/budgets/create";
  static const String corporateApprovals = "corporate/approvals";
  static const String corporateApprovalDecide = "corporate/approvals/decide";
  static const String corporatePolicies = "corporate/policies";
  static const String corporateCreatePolicy = "corporate/policies/create";
  static const String corporateTogglePolicy = "corporate/policies/toggle";

  // Pool vehicles / driver operating modes
  static const String corporatePoolVehicles = "corporate/pool-vehicles";
  static const String corporateDriverAccess = "corporate/driver-access";
  static const String corporateDriverAccessGrant = "corporate/driver-access/grant";
  static const String corporateDriverAccessRevoke = "corporate/driver-access/revoke";
  static const String corporateApprovePersonalVehicle = "corporate/employees"; // + /:id/approve-personal-vehicle

  // Fixed routes (Find Shared Route)
  static const String corporateRoutes = "corporate/routes";
  static const String corporateRouteSchedules = "corporate/routes"; // + /:id/schedules
  static const String corporateAccessRequests = "corporate/access-requests";
  static const String corporateAccessRequestsMine = "corporate/access-requests/mine";

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
