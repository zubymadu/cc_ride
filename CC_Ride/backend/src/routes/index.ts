import { Router } from 'express'
import authRouter     from './auth'
import corporateRouter from './corporate'
import adminRouter    from './admin'
import paymentRouter  from './payment'
import userRouter     from './user'
import ridesRouter    from './rides'
import driverRouter   from './driver'

const router = Router()

// Health check
router.get('/health', (_req, res) => {
  res.json({ status: 'ok', ts: new Date().toISOString() })
})

// Mobile auth (register + login)
router.use('/auth', authRouter)

// Mobile passenger rides
router.use('/rides', ridesRouter)

// Mobile driver endpoints
router.use('/driver', driverRouter)

// Admin panel
router.use('/admin', adminRouter)

// Corporate module
router.use('/corporate', corporateRouter)

// Payment (Paystack + Flutterwave)
router.use('/payment', paymentRouter)

// User self-service (company enrolment, bookings, notifications, wallet)
router.use('/user', userRouter)

export default router
