import { Router } from 'express'
import { requireAuth } from '../../middleware/auth'
import {
  searchCompanies, getCompanyDepartments,
  joinCompany, updateCompanyProfile,
  getMyCompanyProfile, leaveCompany,
} from '../../controllers/user/company-enrol.controller'
import {
  getMyBookings, getMyNotifications, markNotificationRead,
  getWallet, getWalletTransactions,
  getProfile, updateProfile,
} from '../../controllers/mobile/user.controller'

const router = Router()

router.use(requireAuth)

// ── Profile ────────────────────────────────────────────────────────────────────
router.get('/profile',  getProfile)
router.put('/profile',  updateProfile)

// ── Bookings ───────────────────────────────────────────────────────────────────
router.get('/bookings', getMyBookings)

// ── Notifications ──────────────────────────────────────────────────────────────
router.get('/notifications',          getMyNotifications)
router.post('/notifications/:id/read', markNotificationRead)

// ── Wallet ─────────────────────────────────────────────────────────────────────
router.get('/wallet',              getWallet)
router.get('/wallet/transactions', getWalletTransactions)

// ── Company discovery & enrolment ─────────────────────────────────────────────
router.get('/companies/search',           searchCompanies)
router.get('/companies/:id/departments',  getCompanyDepartments)
router.post('/companies/join',            joinCompany)
router.post('/companies/leave',           leaveCompany)
router.get('/company-profile',            getMyCompanyProfile)
router.put('/company-profile',            updateCompanyProfile)

export default router
