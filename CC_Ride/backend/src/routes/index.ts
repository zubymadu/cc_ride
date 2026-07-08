import { Router } from 'express'
import multer from 'multer'
import path from 'path'
import corporateRouter from './corporate'
import adminRouter from './admin'
import paymentRouter from './payment'
import userRouter from './user'
import {
  legacyLogin, legacyMobileCheck, legacyEmailCheck, legacySmsType, legacyRegUser,
  legacyDataGet, legacyColorTypeModelList,
  legacyUserProfile, legacyProfileEdit, legacyProImage,
  legacyVehicleList, legacyAddVehicle, legacyEditVehicle,
  legacyFindTrip, legacyFindTripDetail,
  legacyPostTrip, legacyEditPostTrip, legacyCancelTrip,
  legacyTripList, legacyTripDetails,
  legacyBookSeat, legacyCancelSeat,
  legacyMyBookTripList, legacyBookTripDetails,
  legacyRequestList, legacyMakeDecision,
  legacyTripRequest, legacyTripRequestList, legacyDeleteTripRequest, legacyEditTripRequest,
  legacyWalletReport, legacyWalletUp,
  legacyEarning, legacyRequestWithdraw, legacyPayoutList,
  legacyFaq, legacyPageList,
  legacyPaymentGateway, legacyCheckCoupon, legacyCouponList,
  legacyReferData,
  legacyProcessingTrip, legacyCompleteTrip, legacyRateUpdate,
  legacyAccDelete,
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

// ─── Auth ─────────────────────────────────────────────────────────────────────
router.post('/user_login.php',    legacyLogin)
router.post('/mobile_check.php',  legacyMobileCheck)
router.post('/email_check.php',   legacyEmailCheck)
router.get('/sms_type.php',       legacySmsType)
router.post('/reg_user.php',      fileUpload.single('photo'), legacyRegUser)

// ─── Core data ────────────────────────────────────────────────────────────────
router.post('/dataget.php',                legacyDataGet)
router.post('/color_type_modellist.php',   legacyColorTypeModelList)

// ─── Profile ──────────────────────────────────────────────────────────────────
router.post('/user_profile.php',  legacyUserProfile)
router.post('/profile_edit.php',  fileUpload.single('photo'), legacyProfileEdit)
router.post('/pro_image.php',     fileUpload.single('photo'), legacyProImage)
router.post('/acc_delete.php',    legacyAccDelete)
router.post('/referdata.php',     legacyReferData)

// ─── Vehicles ─────────────────────────────────────────────────────────────────
router.post('/vehicle_list.php',  legacyVehicleList)
router.post('/add_vehicle.php',   fileUpload.single('photo'), legacyAddVehicle)
router.post('/edit_vehicle.php',  fileUpload.single('photo'), legacyEditVehicle)

// ─── Trip posting (driver) ────────────────────────────────────────────────────
router.post('/post_trip.php',       legacyPostTrip)
router.post('/edit_post_trip.php',  legacyEditPostTrip)
router.post('/cancel_trip.php',     legacyCancelTrip)
router.post('/my_trip_list.php',    legacyTripList)
router.post('/trip_details.php',    legacyTripDetails)
router.post('/processing_trip.php', legacyProcessingTrip)
router.post('/complete_trip.php',   legacyCompleteTrip)

// ─── Trip finding (passenger) ─────────────────────────────────────────────────
router.post('/find_trip.php',       legacyFindTrip)
router.post('/find_trip_detail.php',legacyFindTripDetail)
router.post('/book_seat.php',       legacyBookSeat)
router.post('/cancle_seat.php',     legacyCancelSeat)  // typo is intentional — matches app
router.post('/my_book_trip_list.php',  legacyMyBookTripList)
router.post('/book_trip_details.php',  legacyBookTripDetails)
router.post('/rate_update.php',     legacyRateUpdate)

// ─── Trip requests ────────────────────────────────────────────────────────────
router.post('/request_list.php',        legacyRequestList)       // driver sees passenger requests
router.post('/make_decision.php',       legacyMakeDecision)
router.post('/trip_request.php',        legacyTripRequest)       // passenger posts a request
router.post('/trip_request_list.php',   legacyTripRequestList)
router.post('/delete_trip_request.php', legacyDeleteTripRequest)
router.post('/edit_trip_request.php',   legacyEditTripRequest)

// ─── Wallet & earnings ────────────────────────────────────────────────────────
router.post('/wallet_report.php',    legacyWalletReport)
router.post('/wallet_up.php',        legacyWalletUp)
router.post('/earning.php',          legacyEarning)
router.post('/request_withdraw.php', legacyRequestWithdraw)
router.post('/payout_list.php',      legacyPayoutList)

// ─── Content ──────────────────────────────────────────────────────────────────
router.post('/faq.php',              legacyFaq)
router.post('/pagelist.php',         legacyPageList)
router.get('/faq.php',               legacyFaq)
router.get('/pagelist.php',          legacyPageList)

// ─── Payments & coupons ───────────────────────────────────────────────────────
router.post('/paymentgateway.php',   legacyPaymentGateway)
router.get('/paymentgateway.php',    legacyPaymentGateway)
router.post('/u_check_coupon.php',   legacyCheckCoupon)
router.post('/u_couponlist.php',     legacyCouponList)

// ─── Catchall for any remaining *.php ─────────────────────────────────────────
router.all(/^\/[\w-]+\.php$/, legacyFallback)

export default router
