import { Router } from 'express'
import { requireAuth } from '../../middleware/auth'
import {
  searchCompanies, getCompanyDepartments,
  joinCompany, updateCompanyProfile,
  getMyCompanyProfile, getMyCompanyWallets, leaveCompany,
} from '../../controllers/user/company-enrol.controller'
import {
  createTicket, listMyTickets, getMyTicket, replyToMyTicket,
} from '../../controllers/user/support.controller'

const router = Router()

router.use(requireAuth)

// Company discovery (search before joining)
router.get('/companies/search',           searchCompanies)
router.get('/companies/:id/departments',  getCompanyDepartments)

// Enrolment
router.post('/companies/join',            joinCompany)
router.post('/companies/leave',           leaveCompany)

// Profile management
router.get('/company-profile',            getMyCompanyProfile)
router.put('/company-profile',            updateCompanyProfile)
router.get('/company-wallets',            getMyCompanyWallets)

// Support tickets
router.post('/support/tickets',           createTicket)
router.get('/support/tickets',            listMyTickets)
router.get('/support/tickets/:id',        getMyTicket)
router.post('/support/tickets/:id/reply', replyToMyTicket)

export default router
