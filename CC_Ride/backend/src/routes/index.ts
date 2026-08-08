import { Router } from 'express'
import multer from 'multer'
import path from 'path'
import corporateRouter from './corporate'
import adminRouter from './admin'
import paymentRouter from './payment'
import userRouter from './user'
import { requireAuth, optionalAuth } from '../middleware/auth'
import {
  legacyLogin, legacyMobileCheck, legacyEmailCheck, legacySmsType, legacyRegUser,
  legacyDataGet, legacyColorTypeModelList,
  legacyUserProfile, legacyProfileEdit, legacyProImage,
  legacyVehicleList, legacyAddVehicle, legacyEditVehicle,
  legacyFindTrip, legacyFindTripDetail, legacyNearbyRoutes,
  legacyNearbyPostedRides, legacySearchRidesByPlace,
  legacyCreateDriverRoute, legacyEditDriverRoute, legacyMyDriverRoutes, legacyDeactivateDriverRoute,
  legacyNearbyRequestsForRoute, legacyEstimateFare,
  legacyPostTrip, legacyEditPostTrip, legacyCancelTrip,
  legacyTripList, legacyTripDetails,
  legacyBookSeat, legacyCancelSeat,
  legacyConfirmBookingRequest, legacyDeclineBookingRequest, legacyRouteBookingRequests,
  legacyMyBookTripList, legacyBookTripDetails,
  legacyRequestList, legacyMakeDecision,
  legacyTripRequest, legacyTripRequestList, legacyDeleteTripRequest, legacyEditTripRequest,
  legacyConfirmMatchedRequest, legacyDeclineMatchedRequest,
  legacyNotificationList, legacyNotificationRead, legacyNotificationDelete,
  legacyWalletReport, legacyWalletUp,
  legacyEarning, legacyRequestWithdraw, legacyPayoutList,
  legacyFaq, legacyPageList, legacyListAdverts,
  legacyPaymentGateway, legacyCheckCoupon, legacyCouponList,
  legacyReferData,
  legacyProcessingTrip, legacyCompleteTrip, legacyRateUpdate,
  legacyAccDelete,
  legacyEmailOtp, legacyVerifyEmail, legacyVerifyMobile,
  legacyFallback,
} from '../controllers/user/legacy.controller'

const fileUpload = multer({
  dest: '/app/uploads/profiles/',
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const ok = /\.(jpe?g|png|webp|gif)$/i.test(path.extname(file.originalname))
    cb(null, ok)
  },
})

const router = Router()

// Health
router.get('/health', (_req, res) => {
  res.json({ status: 'ok', ts: new Date().toISOString() })
})

// Admin panel
router.use('/admin', adminRouter)

// Corporate module
router.use('/corporate', corporateRouter)

// Payment (Paystack + Flutterwave)
router.use('/payment', paymentRouter)

// User self-service
router.use('/user', userRouter)

// ─── Auth (public — no session exists yet) ────────────────────────────────────
router.post('/user_login.php',    legacyLogin)
router.post('/mobile_check.php',  legacyMobileCheck)
router.post('/email_check.php',   legacyEmailCheck)
router.get('/sms_type.php',       legacySmsType)
router.post('/reg_user.php',      fileUpload.single('photo'), legacyRegUser)

// ─── Core data (guest-browsable, personalizes when logged in) ────────────────
router.post('/dataget.php',                optionalAuth, legacyDataGet)
router.post('/color_type_modellist.php',   legacyColorTypeModelList)

// ─── Profile (own account only — identity comes from the verified JWT) ───────
router.post('/user_profile.php',  requireAuth, legacyUserProfile)
router.post('/profile_edit.php',  requireAuth, fileUpload.single('photo'), legacyProfileEdit)
router.post('/pro_image.php',     requireAuth, fileUpload.single('photo'), legacyProImage)
router.post('/acc_delete.php',    requireAuth, legacyAccDelete)
router.post('/referdata.php',     requireAuth, legacyReferData)

// ─── Email verification ───────────────────────────────────────────────────────
router.post('/email_otp.php',     requireAuth, legacyEmailOtp)
router.post('/verify_email.php',  requireAuth, legacyVerifyEmail)

// ─── Mobile verification ──────────────────────────────────────────────────────
router.post('/mobile_verify.php', requireAuth, legacyVerifyMobile)

// ─── Vehicles ─────────────────────────────────────────────────────────────────
router.post('/vehicle_list.php',  requireAuth, legacyVehicleList)
router.post('/add_vehicle.php',   requireAuth, fileUpload.single('photo'), legacyAddVehicle)
router.post('/edit_vehicle.php',  requireAuth, fileUpload.single('photo'), legacyEditVehicle)

// ─── Trip posting (driver) ────────────────────────────────────────────────────
router.post('/estimate_fare.php',   requireAuth, legacyEstimateFare)
router.post('/post_trip.php',       requireAuth, legacyPostTrip)
router.post('/edit_post_trip.php',  requireAuth, legacyEditPostTrip)
router.post('/cancel_trip.php',     requireAuth, legacyCancelTrip)
router.post('/my_trip_list.php',    requireAuth, legacyTripList)
router.post('/trip_details.php',    legacyTripDetails)               // guest-viewable trip preview
router.post('/processing_trip.php', requireAuth, legacyProcessingTrip)
router.post('/complete_trip.php',   requireAuth, legacyCompleteTrip)

// ─── Trip finding (passenger — guest-browsable, personalizes when logged in) ─
router.post('/find_trip.php',       optionalAuth, legacyFindTrip)
router.post('/nearby_routes.php',   legacyNearbyRoutes)  // public — home screen widget
router.post('/nearby_posted_rides.php', legacyNearbyPostedRides)  // public — home screen widget
router.post('/search_rides_by_place.php', legacySearchRidesByPlace)  // public — free-text city/place search

// ─── Driver-created routes ────────────────────────────────────────────────────
router.post('/driver_route_create.php',     requireAuth, legacyCreateDriverRoute)
router.post('/driver_route_edit.php',       requireAuth, legacyEditDriverRoute)
router.post('/driver_route_list.php',       requireAuth, legacyMyDriverRoutes)
router.post('/driver_route_deactivate.php', requireAuth, legacyDeactivateDriverRoute)
router.post('/nearby_requests_route.php',   requireAuth, legacyNearbyRequestsForRoute)
router.post('/confirm_booking_request.php', requireAuth, legacyConfirmBookingRequest)
router.post('/decline_booking_request.php', requireAuth, legacyDeclineBookingRequest)
router.post('/route_booking_requests.php',  requireAuth, legacyRouteBookingRequests)
router.post('/find_trip_detail.php',legacyFindTripDetail)            // guest-viewable trip preview
router.post('/book_seat.php',       requireAuth, legacyBookSeat)
router.post('/cancle_seat.php',     requireAuth, legacyCancelSeat)  // typo is intentional — matches app
router.post('/my_book_trip_list.php',  requireAuth, legacyMyBookTripList)
router.post('/book_trip_details.php',  requireAuth, legacyBookTripDetails)
router.post('/rate_update.php',     requireAuth, legacyRateUpdate)

// ─── Trip requests ────────────────────────────────────────────────────────────
router.post('/request_list.php',        requireAuth, legacyRequestList)       // driver sees passenger requests
router.post('/make_decision.php',       requireAuth, legacyMakeDecision)
router.post('/trip_request.php',        requireAuth, legacyTripRequest)       // passenger posts a request
router.post('/trip_request_list.php',   requireAuth, legacyTripRequestList)
router.post('/confirm_matched_request.php', requireAuth, legacyConfirmMatchedRequest)
router.post('/decline_matched_request.php', requireAuth, legacyDeclineMatchedRequest)
router.post('/delete_trip_request.php', requireAuth, legacyDeleteTripRequest)
router.post('/edit_trip_request.php',   requireAuth, legacyEditTripRequest)

// ─── Notifications ────────────────────────────────────────────────────────────
router.post('/notification_list.php', requireAuth, legacyNotificationList)
router.post('/notification_read.php', requireAuth, legacyNotificationRead)
router.post('/notification_delete.php', requireAuth, legacyNotificationDelete)

// ─── Wallet & earnings ────────────────────────────────────────────────────────
router.post('/wallet_report.php',    requireAuth, legacyWalletReport)
router.post('/wallet_up.php',        requireAuth, legacyWalletUp)
router.post('/earning.php',          requireAuth, legacyEarning)
router.post('/request_withdraw.php', requireAuth, legacyRequestWithdraw)
router.post('/payout_list.php',      requireAuth, legacyPayoutList)

// ─── Content (public) ─────────────────────────────────────────────────────────
router.post('/faq.php',              legacyFaq)
router.post('/pagelist.php',         legacyPageList)
router.get('/faq.php',               legacyFaq)
router.get('/pagelist.php',          legacyPageList)
router.get('/adverts.php',           legacyListAdverts)

// ─── Payments & coupons ───────────────────────────────────────────────────────
router.post('/paymentgateway.php',   legacyPaymentGateway)
router.get('/paymentgateway.php',    legacyPaymentGateway)
router.post('/u_check_coupon.php',   requireAuth, legacyCheckCoupon)
router.post('/u_couponlist.php',     requireAuth, legacyCouponList)

// ─── Catchall for any remaining *.php ─────────────────────────────────────────
router.all(/^\/[\w-]+\.php$/, legacyFallback)

export default router
