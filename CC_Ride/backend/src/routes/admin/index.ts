import { Router } from 'express'
import { requireAdmin, requireSuperAdmin } from '../../middleware/adminAuth'
import { logoUpload, csvUpload } from '../../lib/uploads'
import { adminLogin }                               from '../../controllers/admin/auth.controller'
import { getOverview }                              from '../../controllers/admin/overview.controller'
import { listUsers, userAction }                    from '../../controllers/admin/users.controller'
import { listDrivers, approveDriver, updateDriverStatus, listRides, listLiveRides,
         createDriver, createRide, livePositions }  from '../../controllers/admin/drivers.controller'
import { listCompanies, companyAction, updateCommission, listCompanyEmployees, listCompanyRides, cancelRide,
         uploadCompanyLogo, getBranding }
                                                    from '../../controllers/admin/companies.controller'
import { getPaymentSummary, listTransactions, listPayouts }
                                                    from '../../controllers/admin/payments.controller'
import { processPayout }                            from '../../controllers/payment/payment.controller'
import {
  createCompany, createDepartment, listDepartments,
  createCostCentre, listCostCentres, createCompanyRide,
  listAvailableDrivers, importDepartments, importEmployees,
} from '../../controllers/admin/company-manage.controller'
import { listPendingApprovals, decideApproval }      from '../../controllers/admin/companies.controller'
import { getAnalytics, getCompanyAnalytics }         from '../../controllers/admin/analytics.controller'
import { listInvoices, getInvoiceDetail }            from '../../controllers/admin/billing.controller'
import { listTickets, replyToTicket, resolveTicket } from '../../controllers/admin/support.controller'
import { getSettings, updateSettings }              from '../../controllers/admin/settings.controller'
import { creditCompany, getCompanyCreditLedger }    from '../../controllers/admin/company-credit.controller'
import {
  listRegions, createRegion,
  listBranches, createBranch, updateBranch,
  creditBranch, getBranchCreditLedger,
  listBranchAdmins, createBranchAdmin,
} from '../../controllers/admin/branches.controller'
import {
  listBranchFleet, assignVehicleToBranch, removeVehicleFromBranch,
  assignDriverToBranch, removeDriverFromBranch,
} from '../../controllers/admin/fleet.controller'
import {
  listBranchPartnerships, createBranchPartnership, revokeBranchPartnership, searchBranches,
} from '../../controllers/admin/partnerships.controller'
import { searchPlaces } from '../../controllers/admin/places.controller'

const router = Router()

// ── Public ────────────────────────────────────────────────────────────────────
router.post('/auth/login', adminLogin)

// ── All routes below require super-admin JWT ──────────────────────────────────
router.use(requireAdmin)

// Dashboard
router.get('/overview', getOverview)

// Address lookup (server-side proxy to Google Places — browsers can't call
// the Places Web Service directly due to CORS)
router.get('/places/search', searchPlaces)

// Users
router.get('/users',        listUsers)
router.post('/users/action', userAction)

// Drivers & Rides
router.get('/drivers',          listDrivers)
router.post('/drivers/create',  createDriver)          // NEW — register driver
router.post('/drivers/approve', approveDriver)
router.post('/drivers/status',  updateDriverStatus)
router.get('/rides',                listRides)
router.get('/rides/live',           listLiveRides)
router.get('/rides/live-positions', livePositions)     // NEW — real-time map snapshot
router.post('/rides/create',        createRide)        // NEW — create standalone ride

// Companies
router.get('/companies',                        listCompanies)
router.post('/companies',                       requireSuperAdmin, createCompany)          // NEW — create company
router.post('/companies/action',                requireSuperAdmin, companyAction)
router.post('/companies/commission',            requireSuperAdmin, updateCommission)
router.post('/companies/logo',                  logoUpload.single('logo'), uploadCompanyLogo)
router.get('/branding',                         getBranding)
router.get('/companies/:id/employees',          listCompanyEmployees)
router.get('/companies/:id/rides',              listCompanyRides)
router.post('/companies/:id/rides',             createCompanyRide)      // NEW — add ride
router.get('/companies/:id/departments',        listDepartments)        // NEW
router.post('/companies/:id/departments',       createDepartment)       // NEW
router.post('/companies/:id/departments/import', csvUpload.single('file'), importDepartments)
router.post('/companies/:id/employees/import',   csvUpload.single('file'), importEmployees)
router.get('/companies/:id/cost-centres',       listCostCentres)        // NEW
router.post('/companies/:id/cost-centres',      createCostCentre)       // NEW
router.post('/companies/:id/credit',            creditCompany)
router.get('/companies/:id/credits',            getCompanyCreditLedger)
// Regions
router.get('/companies/:companyId/regions',     listRegions)
router.post('/companies/:companyId/regions',    createRegion)
// Branches
router.get('/companies/:companyId/branches',          listBranches)
router.post('/companies/:companyId/branches',         createBranch)
router.patch('/companies/:companyId/branches/:branchId', updateBranch)
router.post('/branches/:branchId/credit',             creditBranch)
router.get('/branches/:branchId/credits',             getBranchCreditLedger)
// Branch fleet (pool vehicles & drivers)
router.get('/companies/:companyId/branches/:branchId/fleet',                listBranchFleet)
router.post('/companies/:companyId/branches/:branchId/fleet/vehicles',        assignVehicleToBranch)
router.post('/companies/:companyId/branches/:branchId/fleet/vehicles/remove', removeVehicleFromBranch)
router.post('/companies/:companyId/branches/:branchId/fleet/drivers',         assignDriverToBranch)
router.post('/companies/:companyId/branches/:branchId/fleet/drivers/remove',  removeDriverFromBranch)
// Branch fleet-sharing partnerships
router.get('/branches/search',                                              searchBranches)
router.get('/companies/:companyId/branches/:branchId/partnerships',          listBranchPartnerships)
router.post('/companies/:companyId/branches/:branchId/partnerships',         createBranchPartnership)
router.post('/companies/:companyId/branches/:branchId/partnerships/revoke',  revokeBranchPartnership)
// Branch / company admin users
router.get('/companies/:companyId/admins',            listBranchAdmins)
router.post('/companies/:companyId/admins',           createBranchAdmin)

// Rides (cancel)
router.post('/rides/cancel',                    cancelRide)

// Available drivers (for ride creation dropdown)
router.get('/drivers/available',                listAvailableDrivers)

// Payments
router.get('/payments/summary',        getPaymentSummary)
router.get('/payments/transactions',   listTransactions)
router.get('/payments/payouts',        listPayouts)
router.post('/payments/process-payout', processPayout)

// Approval queue
router.get('/bookings/approvals',   listPendingApprovals)
router.post('/bookings/approve',    decideApproval)

// Analytics
router.get('/analytics',                    getAnalytics)
router.get('/analytics/company/:id',        getCompanyAnalytics)

// Billing / Invoices
router.get('/billing/invoices',             listInvoices)
router.get('/billing/invoices/:companyId/:month', getInvoiceDetail)

// Support
router.get('/support/tickets',    listTickets)
router.post('/support/reply',     replyToTicket)
router.post('/support/resolve',   resolveTicket)

// Settings
router.get('/settings',  getSettings)
router.post('/settings', updateSettings)

export default router
