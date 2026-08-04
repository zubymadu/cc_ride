import { Router } from 'express'
import { requireAuth } from '../../middleware/auth'
import { requireCompanyMember, requireAdminRole, requireApproverRole } from '../../middleware/corporate'

import { getDashboard }                         from '../../controllers/corporate/dashboard.controller'
import { getEmployeeProfile, listEmployees, listDepartments, inviteEmployee, deactivateEmployee }
                                                from '../../controllers/corporate/employees.controller'
import { listBudgets, createBudget }            from '../../controllers/corporate/budgets.controller'
import { listApprovals, decideApproval }        from '../../controllers/corporate/approvals.controller'
import { listPolicies, createPolicy, togglePolicy }
                                                from '../../controllers/corporate/policies.controller'
import { checkPolicy, createCorporateBooking, cancelApproval }
                                                from '../../controllers/corporate/bookings.controller'
import { listPoolVehicles, registerPoolVehicle, listDriverVehicleAccess,
         grantDriverVehicleAccess, revokeDriverVehicleAccess, approvePersonalVehicle }
                                                from '../../controllers/corporate/vehicles.controller'
import { listRoutes, createRoute, listRouteSchedules, createRouteSchedule }
                                                from '../../controllers/corporate/routes.controller'
import { createAccessRequest, listMyAccessRequests }
                                                from '../../controllers/corporate/accessRequests.controller'

const router = Router()

// All corporate routes require a valid JWT
router.use(requireAuth)

// ─── Employee profile (no admin role required — any employee) ─────────────────
router.get('/employee/profile', requireCompanyMember, getEmployeeProfile)

// ─── Dashboard ────────────────────────────────────────────────────────────────
router.get('/dashboard', requireCompanyMember, requireAdminRole, getDashboard)

// ─── Employees ────────────────────────────────────────────────────────────────
router.get('/employees',              requireCompanyMember, requireAdminRole, listEmployees)
router.get('/departments',            requireCompanyMember, listDepartments)
router.post('/employees/invite',      requireCompanyMember, requireAdminRole, inviteEmployee)
router.post('/employees/deactivate',  requireCompanyMember, requireAdminRole, deactivateEmployee)

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

// ─── Pool vehicles & driver access (admin manages, any employee reads own access) ─
router.get('/pool-vehicles',                        requireCompanyMember, requireAdminRole, listPoolVehicles)
router.post('/pool-vehicles',                        requireCompanyMember, requireAdminRole, registerPoolVehicle)
router.get('/driver-access',                         requireCompanyMember, listDriverVehicleAccess)
router.post('/driver-access/grant',                  requireCompanyMember, requireAdminRole, grantDriverVehicleAccess)
router.post('/driver-access/revoke',                 requireCompanyMember, requireAdminRole, revokeDriverVehicleAccess)
router.post('/employees/:employee_id/approve-personal-vehicle',
                                                      requireCompanyMember, requireAdminRole, approvePersonalVehicle)

// ─── Access requests (any employee asks, admin decides via /admin/*) ─────────
router.post('/access-requests',      requireCompanyMember, createAccessRequest)
router.get('/access-requests/mine',  requireCompanyMember, listMyAccessRequests)

// ─── Fixed routes (Find Shared Route) ─────────────────────────────────────────
router.get('/routes',                  requireCompanyMember, requireAdminRole, listRoutes)
router.post('/routes',                 requireCompanyMember, requireAdminRole, createRoute)
router.get('/routes/:id/schedules',    requireCompanyMember, requireAdminRole, listRouteSchedules)
router.post('/routes/:id/schedules',   requireCompanyMember, requireAdminRole, createRouteSchedule)

export default router
