import 'package:get/get.dart';

import '../../language/language_screen_view.dart';
import '../modules/bindings/account_bindings/account_screen_binding.dart';
import '../modules/bindings/account_bindings/earning_bindings/earning_screen_binding.dart';
import '../modules/bindings/account_bindings/language_screen_binding.dart';
import '../modules/bindings/account_bindings/my_booking_bindings/booking_datails_binding.dart';
import '../modules/bindings/account_bindings/my_booking_bindings/my_booking_screen_binding.dart';
import '../modules/bindings/account_bindings/page_list_description_binding.dart';
import '../modules/bindings/account_bindings/profile_bindings/personal_details_binding.dart';
import '../modules/bindings/account_bindings/profile_bindings/profile_screen_binding.dart';
import '../modules/bindings/account_bindings/refer_screen_binding.dart';
import '../modules/bindings/notification_screen_binding.dart';
import '../modules/bindings/account_bindings/vehicle_bindings/add_vehicle_screen_binding.dart';
import '../modules/bindings/account_bindings/vehicle_bindings/vehicles_list_binding.dart';
import '../modules/bindings/account_bindings/wallet_screen_binding.dart';
import '../modules/bindings/auth_bindings/forget_password_screen_binding.dart';
import '../modules/bindings/auth_bindings/login_screen_binding.dart';
import '../modules/bindings/auth_bindings/new_password_screen_binding.dart';
import '../modules/bindings/auth_bindings/otp_screen_binding.dart';
import '../modules/bindings/auth_bindings/reg_user_screen_binding.dart';
import '../modules/bindings/booking_bindings/book_details_binding.dart';
import '../modules/bindings/booking_bindings/one_way_summary_binding.dart';
import '../modules/bindings/booking_bindings/book_drive_binding.dart';
import '../modules/bindings/booking_bindings/book_pricing_binding.dart';
import '../modules/bindings/booking_bindings/booking_service_binding.dart';
import '../modules/bindings/booking_bindings/coupon_list_binding.dart';
import '../modules/bindings/booking_bindings/payment_screen_binding.dart';
import '../modules/bindings/bottom_bar_screen_binding.dart';
import '../modules/bindings/help_bindings/help_screen_binding.dart';
import '../modules/bindings/support_bindings/support_tickets_binding.dart';
import '../modules/bindings/home_binding.dart';
import '../modules/bindings/intro_bindings/onboarding_screen_binding.dart';
import '../modules/bindings/intro_bindings/splash_screen_binding.dart';
import '../modules/bindings/message_bindings/message_list_binding.dart';
import '../modules/bindings/message_bindings/message_screen_binding.dart';
import '../modules/bindings/post_bindings/multipolyline_map_screen_binding.dart';
import '../modules/bindings/post_bindings/post_screen_binding.dart';
import '../modules/bindings/post_bindings/ride_schedule_screen_binding.dart';
import '../modules/bindings/post_bindings/seats_details_screen_binding.dart';
import '../modules/bindings/post_bindings/trip_preview_screen_binding.dart';
import '../modules/bindings/post_bindings/vehicles_screen_binding.dart';
import '../modules/bindings/search_bindings/search_results_screen_binding.dart';
import '../modules/bindings/search_bindings/search_screen_binding.dart';
import '../modules/bindings/trip_request_bindings/post_req_preiview_screen_binding.dart';
import '../modules/bindings/trip_request_bindings/post_request_screen_binding.dart';
import '../modules/bindings/trips_bindings/trip_screen_binding.dart';
import '../modules/bindings/account_bindings/earning_bindings/payout_history_screen_binding.dart';
import '../modules/view/account_screen/earning_screens/payout_history_screen_view.dart';
// Corporate booking flow
import '../modules/bindings/corporate_bindings/corporate_booking_flow_binding.dart';
import '../modules/view/corporate/corporate_booking_confirm_view.dart';
import '../modules/view/corporate/approval_pending_view.dart';
// Corporate admin
import '../modules/bindings/corporate_bindings/corporate_dashboard_binding.dart';
import '../modules/bindings/corporate_bindings/employee_management_binding.dart';
import '../modules/bindings/corporate_bindings/budget_management_binding.dart';
import '../modules/bindings/corporate_bindings/approval_queue_binding.dart';
import '../modules/bindings/corporate_bindings/ride_policy_binding.dart';
import '../modules/bindings/corporate_bindings/route_management_binding.dart';
import '../modules/view/corporate/corporate_dashboard_view.dart';
import '../modules/view/corporate/employee_management_view.dart';
import '../modules/view/corporate/budget_management_view.dart';
import '../modules/view/corporate/approval_queue_view.dart';
import '../modules/view/corporate/ride_policy_view.dart';
import '../modules/view/corporate/route_management_view.dart';
import '../modules/view/account_screen/account_screen_view.dart';
import '../modules/view/account_screen/earning_screens/earning_screen_view.dart';
import '../modules/view/account_screen/my_booking_screens/booking_details/booking_datails_view.dart';
import '../modules/view/account_screen/my_booking_screens/my_booking_list/my_booking_screen_view.dart';
import '../modules/view/account_screen/page_list_description_view.dart';
import '../modules/view/account_screen/profile_screen/personal_details_view.dart';
import '../modules/view/account_screen/profile_screen/profile_screen/profile_screen_view.dart';
import '../modules/view/account_screen/refer_screen_view.dart';
import '../modules/view/notification_screen_view.dart';
import '../modules/view/account_screen/vehicle_screen/add_vehicle_screen_view.dart';
import '../modules/view/account_screen/vehicle_screen/vehicles_list_view.dart';
import '../modules/view/account_screen/wallet/wallet_screen_view.dart';
import '../modules/view/auth/forget_password_screen_view.dart';
import '../modules/view/auth/login_screen_view.dart';
import '../modules/view/auth/new_password_screen_view.dart';
import '../modules/view/auth/otp_screen_view.dart';
import '../modules/view/auth/reg_user_screen_view.dart';
import '../modules/view/booking_screen/book_details_view.dart';
import '../modules/view/booking_screen/one_way_summary_view.dart';
import '../modules/view/booking_screen/book_drive_view.dart';
import '../modules/view/booking_screen/book_pricing_view.dart';
import '../modules/view/booking_screen/booking_service_view.dart';
import '../modules/view/booking_screen/coupon_list_view.dart';
import '../modules/view/booking_screen/payment_screen_view.dart';
import '../modules/view/bottom_bar_screen_view.dart';
import '../modules/view/help_screen/help_screen_view.dart';
import '../modules/view/support_screen/support_tickets_view.dart';
import '../modules/view/support_screen/support_ticket_detail_view.dart';
import '../modules/view/home_view.dart';
import '../modules/view/intro_screens/onboarding_screen_view.dart';
import '../modules/view/intro_screens/splash_screen_view.dart';
import '../modules/view/message_screen/message_list_view.dart';
import '../modules/view/message_screen/message_screen_view.dart';
import '../modules/view/post/multipolyline_map_screen_view.dart';
import '../modules/view/post/post_screen_view.dart';
import '../modules/view/post/routes/my_routes_screen_view.dart';
import '../modules/view/post/routes/create_route_screen_view.dart';
import '../modules/view/post/routes/route_requests_screen_view.dart';
import '../modules/view/post/ride_schedule/ride_schedule_screen_view.dart';
import '../modules/view/post/seats_details_screen_view.dart';
import '../modules/view/post/trip_preview_screens/trip_preview_screen_view.dart';
import '../modules/view/trip_request_screen/matched_request_screen_view.dart';
import '../modules/view/post/vehicle/vehicles_screen_view.dart';
import '../modules/view/search/search_results/search_results_screen_view.dart';
import '../modules/view/search/search_screen_view.dart';
import '../modules/view/search/trip_plan_screen_view.dart';
import '../modules/view/trip_request_screen/post_req_preiview_screen_view.dart';
import '../modules/view/trip_request_screen/post_request_screen_view.dart';
import '../modules/view/trips/trip_list/post_trip/trip_screen_view.dart';

// ignore_for_file: constant_identifier_names

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH_SCREEN;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.SPLASH_SCREEN,
      page: () => const SplashScreenView(),
      binding: SplashScreenBinding(),
    ),
    GetPage(
      name: _Paths.ONBOARDING_SCREEN,
      page: () => const OnboardingScreenView(),
      binding: OnboardingScreenBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN_SCREEN,
      page: () => const LoginScreenView(),
      binding: LoginScreenBinding(),
    ),
    GetPage(
      name: _Paths.REG_USER_SCREEN,
      page: () => const RegUserScreenView(),
      binding: RegUserScreenBinding(),
    ),
    GetPage(
      name: _Paths.OTP_SCREEN,
      page: () => const OtpScreenView(),
      binding: OtpScreenBinding(),
    ),
    GetPage(
      name: _Paths.FORGET_PASSWORD_SCREEN,
      page: () => const ForgetPasswordScreenView(),
      binding: ForgetPasswordScreenBinding(),
    ),
    GetPage(
      name: _Paths.NEW_PASSWORD_SCREEN,
      page: () => const NewPasswordScreenView(),
      binding: NewPasswordScreenBinding(),
    ),
    GetPage(
      name: _Paths.BOTTOM_BAR_SCREEN,
      page: () => const BottomBarScreenView(),
      binding: BottomBarScreenBinding(),
    ),
    GetPage(
      name: _Paths.SEARCH_SCREEN,
      page: () => const SearchScreenView(),
      binding: SearchScreenBinding(),
    ),
    GetPage(
      name: _Paths.SEARCH_RESULTS_SCREEN,
      page: () => const SearchResultsScreenView(),
      binding: SearchResultsScreenBinding(),
    ),
    GetPage(
      name: _Paths.TRIP_PLAN_SCREEN,
      page: () => const TripPlanScreenView(),
    ),
    GetPage(
      name: _Paths.MULTIPOLYLINE_MAP_SCREEN,
      page: () => const MultipolylineMapScreenView(),
      binding: MultipolylineMapScreenBinding(),
    ),
    GetPage(
      name: _Paths.RIDE_SCHEDULE_SCREEN,
      page: () => const RideScheduleScreenView(),
      binding: RideScheduleScreenBinding(),
    ),
    GetPage(
      name: _Paths.VEHICLES_SCREEN,
      page: () => const VehiclesScreenView(),
      binding: VehiclesScreenBinding(),
    ),
    GetPage(
      name: _Paths.ADD_VEHICLE_SCREEN,
      page: () => const AddVehicleScreenView(),
      binding: AddVehicleScreenBinding(),
    ),
    GetPage(
      name: _Paths.SEATS_DETAILS_SCREEN,
      page: () => const SeatsDetailsScreenView(),
      binding: SeatsDetailsScreenBinding(),
    ),
    GetPage(
      name: _Paths.TRIP_PREVIEW_SCREEN,
      page: () => const TripPreviewScreenView(),
      binding: TripPreviewScreenBinding(),
    ),
    GetPage(
      name: _Paths.MATCHED_REQUEST_SCREEN,
      page: () => const MatchedRequestScreenView(),
    ),
    GetPage(
      name: _Paths.POST_SCREEN,
      page: () => const PostScreenView(),
      binding: PostScreenBinding(),
    ),
    GetPage(
      name: _Paths.TRIP_SCREEN,
      page: () => const TripScreenView(),
      binding: TripScreenBinding(),
    ),
    GetPage(
      name: _Paths.MY_ROUTES_SCREEN,
      page: () => const MyRoutesScreenView(),
    ),
    GetPage(
      name: _Paths.CREATE_ROUTE_SCREEN,
      page: () => const CreateRouteScreenView(),
    ),
    GetPage(
      name: _Paths.ROUTE_REQUESTS_SCREEN,
      page: () => const RouteRequestsScreenView(),
    ),
    // GetPage(
    //   name: _Paths.SEATING_PLAN_SCREEN,
    //   page: () => const SeatingPlanScreenView(),
    //   binding: SeatingPlanScreenBinding(),
    // ),
    // GetPage(
    //   name: _Paths.BOOKINGS_SCREEN,
    //   page: () => const BookingsScreenView(),
    //   binding: BookingsScreenBinding(),
    // ),
    // GetPage(
    //   name: _Paths.SETTINGS_SCREEN,
    //   page: () => const SettingsScreenView(),
    //   binding: SettingsScreenBinding(),
    // ),
    GetPage(
      name: _Paths.POST_REQUEST_SCREEN,
      page: () => const PostRequestScreenView(),
      binding: PostRequestScreenBinding(),
    ),
    GetPage(
      name: _Paths.POST_REQ_PREIVIEW_SCREEN,
      page: () => const PostReqPreiviewScreenView(),
      binding: PostReqPreiviewScreenBinding(),
    ),
    GetPage(
      name: _Paths.ACCOUNT_SCREEN,
      page: () => const AccountScreenView(),
      binding: AccountScreenBinding(),
    ),
    // GetPage(
    //   name: _Paths.EDIT_TRIP_REQ_SCREEN,
    //   page: () => const EditTripReqScreenView(),
    //   binding: EditTripReqScreenBinding(),
    // ),
    GetPage(
      name: _Paths.PROFILE_SCREEN,
      page: () => const ProfileScreenView(),
      binding: ProfileScreenBinding(),
    ),
    GetPage(
      name: _Paths.PERSONAL_DETAILS,
      page: () => const PersonalDetailsView(),
      binding: PersonalDetailsBinding(),
    ),
    GetPage(
      name: _Paths.VEHICLES_LIST,
      page: () => const VehiclesListView(),
      binding: VehiclesListBinding(),
    ),
    GetPage(
      name: _Paths.HELP_SCREEN,
      page: () => const HelpScreenView(),
      binding: HelpScreenBinding(),
    ),
    GetPage(
      name: _Paths.SUPPORT_TICKETS,
      page: () => const SupportTicketsView(),
      binding: SupportTicketsBinding(),
    ),
    GetPage(
      name: _Paths.SUPPORT_TICKET_DETAIL,
      page: () => const SupportTicketDetailView(),
      binding: SupportTicketsBinding(),
    ),
    GetPage(
      name: _Paths.BOOKING_SERVICE,
      page: () => const BookingServiceView(),
      binding: BookingServiceBinding(),
    ),
    GetPage(
      name: _Paths.BOOK_DETAILS,
      page: () => const BookDetailsView(),
      binding: BookDetailsBinding(),
    ),
    GetPage(
      name: _Paths.ONE_WAY_SUMMARY,
      page: () => const OneWaySummaryView(),
      binding: OneWaySummaryBinding(),
    ),
    GetPage(
      name: _Paths.BOOK_DRIVE,
      page: () => const BookDriveView(),
      binding: BookDriveBinding(),
    ),
    GetPage(
      name: _Paths.BOOK_PRICING,
      page: () => const BookPricingView(),
      binding: BookPricingBinding(),
    ),
    GetPage(
      name: _Paths.WALLET_SCREEN,
      page: () => const WalletScreenView(),
      binding: WalletScreenBinding(),
    ),
    GetPage(
      name: _Paths.COUPON_LIST,
      page: () => const CouponListView(),
      binding: CouponListBinding(),
    ),
    GetPage(
      name: _Paths.PAYMENT_SCREEN,
      page: () => const PaymentScreenView(),
      binding: PaymentScreenBinding(),
    ),
    GetPage(
      name: _Paths.MY_BOOKING_SCREEN,
      page: () => const MyBookingScreenView(),
      binding: MyBookingScreenBinding(),
    ),
    GetPage(
      name: _Paths.BOOKING_DATAILS,
      page: () => const BookingDatailsView(),
      binding: BookingDatailsBinding(),
    ),
    GetPage(
      name: _Paths.PAGE_LIST_DESCRIPTION,
      page: () => const PageListDescriptionView(),
      binding: PageListDescriptionBinding(),
    ),
    GetPage(
      name: _Paths.MESSAGE_LIST,
      page: () => const MessageListView(),
      binding: MessageListBinding(),
    ),
    GetPage(
      name: _Paths.MESSAGE_SCREEN,
      page: () => const MessageScreenView(),
      binding: MessageScreenBinding(),
    ),
    GetPage(
      name: _Paths.REFER_SCREEN,
      page: () => const ReferAndEarnScreenView(),
      binding: ReferAndEarnScreenBinding(),
    ),
    GetPage(
      name: _Paths.NOTIFICATION_SCREEN,
      page: () => const NotificationScreenView(),
      binding: NotificationScreenBinding(),
    ),
    GetPage(
      name: _Paths.LANGUAGE_SCREEN,
      page: () => const LanguageScreenView(),
      binding: LanguageScreenBinding(),
    ),
    GetPage(
      name: _Paths.EARNING_SCREEN,
      page: () => const EarningScreenView(),
      binding: EarningScreenBinding(),
    ),
    GetPage(
      name: _Paths.PAYOUT_HISTORY_SCREEN,
      page: () => const PayoutHistoryScreenView(),
      binding: PayoutHistoryScreenBinding(),
    ),
    // ── Corporate booking flow ─────────────────────────────────────────────
    GetPage(
      name: _Paths.CORPORATE_BOOKING_CONFIRM,
      page: () => const CorporateBookingConfirmView(),
      binding: CorporateBookingFlowBinding(),
    ),
    GetPage(
      name: _Paths.APPROVAL_PENDING,
      page: () => const ApprovalPendingView(),
    ),
    // ── Corporate admin ────────────────────────────────────────────────────
    GetPage(
      name: _Paths.CORPORATE_DASHBOARD,
      page: () => const CorporateDashboardView(),
      binding: CorporateDashboardBinding(),
    ),
    GetPage(
      name: _Paths.EMPLOYEE_MANAGEMENT,
      page: () => const EmployeeManagementView(),
      binding: EmployeeManagementBinding(),
    ),
    GetPage(
      name: _Paths.BUDGET_MANAGEMENT,
      page: () => const BudgetManagementView(),
      binding: BudgetManagementBinding(),
    ),
    GetPage(
      name: _Paths.APPROVAL_QUEUE,
      page: () => const ApprovalQueueView(),
      binding: ApprovalQueueBinding(),
    ),
    GetPage(
      name: _Paths.RIDE_POLICY,
      page: () => const RidePolicyView(),
      binding: RidePolicyBinding(),
    ),
    GetPage(
      name: _Paths.ROUTE_MANAGEMENT,
      page: () => const RouteManagementView(),
      binding: RouteManagementBinding(),
    ),
  ];
}
