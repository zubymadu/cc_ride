import { Router } from 'express'
import { optionalAuth } from '../../middleware/auth'
import { getAvailableRides } from '../../controllers/mobile/rides.controller'

const router = Router()

// Available rides list — optionally authenticated (policy check requires auth, list doesn't)
router.get('/available', optionalAuth, getAvailableRides)

export default router
