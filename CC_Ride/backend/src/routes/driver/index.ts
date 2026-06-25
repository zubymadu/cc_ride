import { Router } from 'express'
import { requireAuth } from '../../middleware/auth'
import {
  getDriverRides, updateDriverStatus, verifyOtp, getDriverEarnings,
} from '../../controllers/mobile/driver.controller'

const router = Router()

router.use(requireAuth)

router.get('/rides',       getDriverRides)
router.post('/status',     updateDriverStatus)
router.post('/verify-otp', verifyOtp)
router.get('/earnings',    getDriverEarnings)

export default router
