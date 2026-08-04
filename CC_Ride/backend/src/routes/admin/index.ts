import { Router } from 'express'
import multer from 'multer'
import { requireAdmin, requireSuperAdmin } from '../../middleware/adminAuth'
import { adminLogin, getInviteInfo, claimInvite }   from '../../controllers/admin/auth.controller'
import { getOverview }                              from '../../controllers/admin/overview.controller'
import { listUsers, userAction, editUser, deleteUser } from '../../controllers/admin/users.controller'
import { listDrivers, approveDriver, updateDriverStatus, listRides, listLiveRides,
         createDriver, createRide, livePositions,
         editDriver, deleteDriver, editRide, deleteRide } from '../../controllers/admin/drivers.controller'
import { listCompanies, companyAction, updateCommission, listCompanyEmployees, listCompanyRides, cancelRide,
         updateCompanyContact, resetCompanyAdminUser, uploadCompanyLogo, deleteCompany }
                                                    from '../../controllers/admin/companies.controller'
import { getPaymentSummary, listTransactions, listPayouts }
                                                    from '../../controllers/admin/payments.controller'
import { processPayout }                            from '../../controllers/payment/payment.controller'
import {
  createCompany, createDepartment, listDepartments,
  createCostCentre, listCostCentres, createCompanyRide,
  listAvailableDrivers,
} from '../../controllers/admin/company-manage.controller'
import { listPendingApprovals, decideApproval }      from '../../controllers/admin/companies.controller'
import { getAnalytics, getCompanyAnalytics }         from '../../controllers/admin/analytics.controller'
import { listInvoices, getInvoiceDetail }            from '../../controllers/admin/billing.controller'
import { listTickets, replyToTicket, resolveTicket } from '../../controllers/admin/support.controller'
import { getSettings, updateSettings, geocodeAddress, searchPlaces } from '../../controllers/admin/settings.controller'
import { creditCompany, getCompanyCreditLedger }    from '../../controllers/admin/company-credit.controller'
import {
  listRegions, createRegion,
  listBranches, createBranch, updateBranch,
  creditBranch, getBranchCreditLedger,
  listBranchAdmins, createBranchAdmin,
} from '../../controllers/admin/branches.controller'
import {
  listVehicleTypes,
  listPricingRateCards, createPricingRateCard, supersedePricingRateCard,
  deactivatePricingRateCard, getPricingRateCardHistory,
  listMarketBenchmarkRates, createMarketBenchmarkRate,
  listCorporateSavingsReports, generateCorporateSavingsReport, updateSavingsReportStatus,
  getSavingsBreakdown,
} from '../../controllers/admin/pricing.controller'
import {
  getPoolPolicy, updatePoolPolicy,
  listPoolSharingAgreements, addPoolSharingAgreement, revokePoolSharingAgreement,
  listEmployeePoolAccess, updateEmployeePoolAccess, updateEmployeeWalletAccess,
  searchPartnerCompanies, getPoolTracking,
  listAccessRequests, decideAccessRequest,
} from '../../controllers/admin/pool.controller'
import {
  listVehicleModels, listVehicleColors,
  listPoolVehicles, createPoolVehicle, updatePoolVehicleStatus,
  listPoolDrivers, createPoolDriver, grantPoolVehicleAccess, revokePoolVehicleAccess,
} from '../../controllers/admin/fleet.controller'
import {
  registerCompanyEmployee, terminateCompanyEmployee, reinstateCompanyEmployee, deleteEmployeeRecord,
  getEmployeeInviteInfo, claimEmployeeInvite,
  getEmployeeImportTemplate, importEmployeesCsv,
} from '../../controllers/admin/employees.controller'
import { deleteWalletTransaction, deletePayoutRequest } from '../../controllers/admin/financeHousekeeping.controller'
import { reseedFaqs } from '../../controllers/user/legacy.controller'

const logoUpload = multer({
  dest: '/app/uploads/profiles/',
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const ok = /\.(jpe?g|png|webp|svg)$/i.test(file.originalname)
    cb(null, ok)
  },
})

// In-memory, not disk — the CSV is parsed once and discarded, never served
// back or referenced by URL the way an uploaded photo is.
const csvUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 2 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const ok = /\.csv$/i.test(file.originalname)
    cb(null, ok)
  },
})

const router = Router()

// ── Public ────────────────────────────────────────────────────────────────────
router.post('/auth/login', adminLogin)
router.get('/auth/invite/:token',   getInviteInfo)
router.post('/auth/claim-invite',   claimInvite)
router.get('/employee-invite/:token', getEmployeeInviteInfo)
router.post('/employee-invite/claim', claimEmployeeInvite)

// ── All routes below require super-admin JWT ──────────────────────────────────
router.use(requireAdmin)

// Dashboard — platform-wide, not meaningful per-company
router.get('/overview', requireSuperAdmin, getOverview)

// Users — platform-wide user directory, not company-scoped
router.get('/users',        requireSuperAdmin, listUsers)
router.post('/users/action', requireSuperAdmin, userAction)
router.patch('/users/:id',  requireSuperAdmin, editUser)    // NEW — housekeeping edit
router.delete('/users/:id', requireSuperAdmin, deleteUser)  // NEW — housekeeping delete

// Drivers & Rides — driver onboarding/approval and the full live fleet are
// platform operations; a company doesn't own drivers, so there's no scope
// to filter these by.
router.get('/drivers',          requireSuperAdmin, listDrivers)
router.post('/drivers/create',  requireSuperAdmin, createDriver)          // NEW — register driver
router.post('/drivers/approve', requireSuperAdmin, approveDriver)
router.post('/drivers/status',  requireSuperAdmin, updateDriverStatus)
router.get('/rides',                requireSuperAdmin, listRides)
router.get('/rides/live',           requireSuperAdmin, listLiveRides)
router.get('/rides/live-positions', requireSuperAdmin, livePositions)     // NEW — real-time map snapshot
router.post('/rides/create',        requireSuperAdmin, createRide)        // NEW — create standalone ride
router.patch('/drivers/:id',        requireSuperAdmin, editDriver)        // NEW — housekeeping edit
router.delete('/drivers/:id',       requireSuperAdmin, deleteDriver)      // NEW — housekeeping delete
router.patch('/rides/:id',          requireSuperAdmin, editRide)          // NEW — housekeeping edit
router.delete('/rides/:id',         requireSuperAdmin, deleteRide)        // NEW — housekeeping delete

// Companies
router.get('/companies',                        listCompanies)           // scoped internally — a scoped admin only ever sees their own row
router.post('/companies',                       requireSuperAdmin, createCompany)    // NEW — create company
router.post('/companies/action',                requireSuperAdmin, companyAction)    // approve/reject/suspend — platform-only
router.post('/companies/commission',            requireSuperAdmin, updateCommission) // negotiated rate — platform-only
router.delete('/companies/:id',                 requireSuperAdmin, deleteCompany)     // NEW — housekeeping delete
router.get('/companies/:id/employees',          listCompanyEmployees)
router.post('/companies/:id/employees/register',  registerCompanyEmployee)  // scoped inline — self-service
router.post('/companies/:id/employees/terminate', terminateCompanyEmployee) // scoped inline — self-service
router.post('/companies/:id/employees/reinstate',  reinstateCompanyEmployee) // scoped inline — self-service
router.get('/companies/:id/employees/import-template', getEmployeeImportTemplate)
router.post('/companies/:id/employees/import-csv', csvUpload.single('file'), importEmployeesCsv)
router.delete('/companies/:id/employees/:employeeId', requireSuperAdmin, deleteEmployeeRecord) // NEW — housekeeping delete
router.get('/companies/:id/rides',              listCompanyRides)
router.post('/companies/:id/rides',             createCompanyRide)      // NEW — add ride
router.get('/companies/:id/departments',        listDepartments)        // NEW
router.post('/companies/:id/departments',       createDepartment)       // NEW
router.get('/companies/:id/cost-centres',       listCostCentres)        // NEW
router.post('/companies/:id/cost-centres',      createCostCentre)       // NEW
router.post('/companies/:id/credit',            requireSuperAdmin, creditCompany)     // wallet top-up = real money received — never self-serve
router.get('/companies/:id/credits',            getCompanyCreditLedger)
// Regions
router.get('/companies/:companyId/regions',     listRegions)
router.post('/companies/:companyId/regions',    createRegion)
// Branches
router.get('/companies/:companyId/branches',          listBranches)
router.post('/companies/:companyId/branches',         createBranch)
router.patch('/companies/:companyId/branches/:branchId', updateBranch)
router.post('/branches/:branchId/credit',             requireSuperAdmin, creditBranch) // same reasoning as company credit
router.get('/branches/:branchId/credits',             getBranchCreditLedger)
// Branch / company admin users
router.get('/companies/:companyId/admins',            listBranchAdmins)
router.post('/companies/:companyId/admins',           createBranchAdmin)

// Rides (cancel) — scoped inline against the booking's own companyId
router.post('/rides/cancel',                    cancelRide)

// Available drivers (for ride creation dropdown)
router.get('/drivers/available',                listAvailableDrivers)

// Payments — platform-wide settlement/payout operations, not company-scoped
router.get('/payments/summary',        requireSuperAdmin, getPaymentSummary)
router.get('/payments/transactions',   requireSuperAdmin, listTransactions)
router.get('/payments/payouts',        requireSuperAdmin, listPayouts)
router.post('/payments/process-payout', requireSuperAdmin, processPayout)
router.delete('/wallet-transactions/:id', requireSuperAdmin, deleteWalletTransaction) // NEW — housekeeping delete
router.delete('/payout-requests/:id',     requireSuperAdmin, deletePayoutRequest)     // NEW — housekeeping delete

// Approval queue — scoped inline (booking.companyId)
router.get('/bookings/approvals',   listPendingApprovals)
router.post('/bookings/approve',    decideApproval)

// Analytics
router.get('/analytics',                    requireSuperAdmin, getAnalytics) // platform-wide
router.get('/analytics/company/:id',        getCompanyAnalytics)             // scoped

// Billing / Invoices
router.get('/billing/invoices',             requireSuperAdmin, listInvoices) // platform-wide index
router.get('/billing/invoices/:companyId/:month', getInvoiceDetail)          // scoped

// Support — internal support queue, platform-wide
router.get('/support/tickets',    requireSuperAdmin, listTickets)
router.post('/support/reply',     requireSuperAdmin, replyToTicket)
router.post('/support/resolve',   requireSuperAdmin, resolveTicket)

// Settings — platform-wide defaults
router.get('/settings',  requireSuperAdmin, getSettings)
router.post('/settings', requireSuperAdmin, updateSettings)
router.get('/geocode',   geocodeAddress) // any authenticated admin — used by address entry forms, not settings management
router.get('/places-search', searchPlaces) // live search-as-you-type suggestions for address fields

// FAQ content — no full CRUD UI yet, this is the only way to push updated
// FAQ_SEED_DATA content live (the read endpoint only seeds an empty table).
router.post('/faqs/reseed', requireSuperAdmin, reseedFaqs)

// Pricing engine — mutations require super-admin; reads allowed for any scoped admin
router.get('/vehicle-types', listVehicleTypes)

router.get('/pricing-rate-cards',                     listPricingRateCards)
router.post('/pricing-rate-cards',                    requireSuperAdmin, createPricingRateCard)
router.patch('/pricing-rate-cards/:id/supersede',     requireSuperAdmin, supersedePricingRateCard)
router.patch('/pricing-rate-cards/:id/deactivate',    requireSuperAdmin, deactivatePricingRateCard)
router.get('/pricing-rate-cards/:id/history',         getPricingRateCardHistory)

router.get('/market-benchmark-rates',   listMarketBenchmarkRates)
router.post('/market-benchmark-rates',  requireSuperAdmin, createMarketBenchmarkRate)

router.get('/savings-reports',            listCorporateSavingsReports)      // scoped inline
router.post('/savings-reports/generate',  generateCorporateSavingsReport)   // scoped inline — self-service for own company
router.patch('/savings-reports/:id/status', requireSuperAdmin, updateSavingsReportStatus)
router.get('/savings-reports/breakdown',    getSavingsBreakdown)            // scoped inline — employee/department drill-down

// Pool-car access policy — self-service for the company's own scoped admin,
// each handler asserts the company matches the caller's own scope internally.
router.get('/companies/:id/pool-policy',    getPoolPolicy)
router.patch('/companies/:id/pool-policy',  updatePoolPolicy)
router.get('/companies/:id/pool-sharing',   listPoolSharingAgreements)
router.post('/companies/:id/pool-sharing',  addPoolSharingAgreement)
router.patch('/companies/:id/pool-sharing/:agreementId/revoke', revokePoolSharingAgreement)
router.get('/companies/:id/employees/pool-access',                listEmployeePoolAccess)
router.patch('/companies/:id/employees/:employeeId/pool-access',  updateEmployeePoolAccess)
router.patch('/companies/:id/employees/:employeeId/wallet-access', updateEmployeeWalletAccess)
router.get('/companies/:id/access-requests',                      listAccessRequests)
router.patch('/companies/:id/access-requests/:requestId/decide',  decideAccessRequest)

// Partner discovery — cross-tenant by design, for picking a sharing partner.
// Must be registered before /companies/:id/... routes below since it's a
// static path a param route could otherwise swallow — Express matches in
// registration order, so this needs to come first among /companies siblings.
router.get('/companies/partner-search', searchPartnerCompanies)

// Pool car tracking — own + shared-with-us + public only, enforced in the
// controller by construction (never a filter that could be forgotten).
router.get('/companies/:id/pool-tracking', getPoolTracking)

// Pool fleet & drivers — self-service for the company's own scoped admin.
router.get('/vehicle-models', listVehicleModels)
router.get('/vehicle-colors', listVehicleColors)
router.get('/companies/:id/pool-vehicles',                listPoolVehicles)
router.post('/companies/:id/pool-vehicles',               createPoolVehicle)
router.patch('/companies/:id/pool-vehicles/:vehicleId',   updatePoolVehicleStatus)
router.get('/companies/:id/pool-drivers',                 listPoolDrivers)
router.post('/companies/:id/pool-drivers',                createPoolDriver)
router.post('/companies/:id/pool-drivers/grant',          grantPoolVehicleAccess)
router.post('/companies/:id/pool-drivers/revoke',         revokePoolVehicleAccess)

// Company logo — self-service, shows in console branding + savings reports.
router.post('/companies/:id/logo', logoUpload.single('logo'), uploadCompanyLogo)

// Super-admin: company contact correction + admin-account reset.
router.patch('/companies/:id/contact',           requireSuperAdmin, updateCompanyContact)
router.post('/companies/:id/reset-admin-user',   requireSuperAdmin, resetCompanyAdminUser)

export default router
