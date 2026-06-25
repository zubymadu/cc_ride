import { Router } from 'express'
import { rateLimit } from 'express-rate-limit'
import { register, login } from '../../controllers/auth.controller'

const router = Router()

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { success: false, message: 'Too many auth attempts. Try again in 15 minutes.' },
})

router.post('/register', authLimiter, register)
router.post('/login',    authLimiter, login)

export default router
