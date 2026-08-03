import { Router } from 'express'
import { requireAuth } from '../../middleware/auth'
import { requireCompanyMember, requireAdminRole, requireApproverRole } from '../../middleware/corporate'
import { logoUpload, csvUpload } from '../../lib/uploads'

import { getDashboard }                         from '../../controllers/corporate/dashboard.controller'
import { uploadCompanyLogo }                    from '../../controllers/corporate/company.controller'
import { getEmployeeProfile, listEmployees, listDepartments, inviteEmployee, deactivateEmployee,
         reactivateEmployee, importDepartmentsCsv, importEmployeesCsv }
                                                from '../../controllers/corporate/employees.controller'
import { listBudgets, createBudget }            from '../../controllers/corporate/budgets.controller'
import { listApprovals, decideApproval }        from '../../controllers/corporate/approvals.controller'
import { listPolicies, createPolicy, togglePolicy }
                                                from '../../controllers/corporate/policies.controller'
import { checkPolicy, createCorporateBooking, cancelApproval }
                                                from '../../controllers/corporate/bookings.controller'

const router = Router()

// All corporate routes require a valid JWT
router.use(requireAuth)

// ─── Employee profile (no admin role required — any employee) ─────────────────
router.get('/employee/profile', requireCompanyMember, getEmployeeProfile)

// ─── Dashboard ────────────────────────────────────────────────────────────────
router.get('/dashboard', requireCompanyMember, requireAdminRole, getDashboard)

// ─── Company profile (logo) ────────────────────────────────────────────────────
// multer runs first so multipart fields (company_id) are parsed before the
// company-membership check.
router.post('/company/logo', logoUpload.single('logo'), requireCompanyMember, requireAdminRole, uploadCompanyLogo)

// ─── Employees ────────────────────────────────────────────────────────────────
router.get('/employees',              requireCompanyMember, requireAdminRole, listEmployees)
router.get('/departments',            requireCompanyMember, listDepartments)
router.post('/employees/invite',      requireCompanyMember, requireAdminRole, inviteEmployee)
router.post('/employees/deactivate',  requireCompanyMember, requireAdminRole, deactivateEmployee)
router.post('/employees/reactivate',  requireCompanyMember, requireAdminRole, reactivateEmployee)
// CSV bulk import — multer runs first so multipart fields (company_id) are
// parsed before the company-membership check.
router.post('/departments/import', csvUpload.single('file'), requireCompanyMember, requireAdminRole, importDepartmentsCsv)
router.post('/employees/import',   csvUpload.single('file'), requireCompanyMember, requireAdminRole, importEmployeesCsv)

// ─── Budgets ──────────────────────────────────────────────────────────────────
router.get('/budgets',        requireCompanyMember, requireAdminRole, listBudgets)
router.post('/budgets/create', requireCompanyMember, requireAdminRole, createBudget)

// ─── Approvals ────────────────────────────────────────────────────────────────
router.get('/approvals',          requireCompanyMember, requireApproverRole, listApprovals)
router.post('/approvals/decide',  requireCompanyMember, requireApproverRole, decideApproval)

// ─── Ride Policies ────────────────────────────────────────────────────────────
router.get('/policies',          requireCompanyMember, requireAdminRole, listPolicies)
router.post('/policies/create',  requireCompanyMember, requireAdminRole, createPolicy)
router.post('/policies/toggle',  requireCompanyMember, requireAdminRole, togglePolicy)

// ─── Booking flow (any employee) ──────────────────────────────────────────────
router.post('/bookings/check-policy',    requireCompanyMember, checkPolicy)
router.post('/bookings/book',            requireCompanyMember, createCorporateBooking)
router.post('/bookings/cancel-approval', requireCompanyMember, cancelApproval)

export default router
