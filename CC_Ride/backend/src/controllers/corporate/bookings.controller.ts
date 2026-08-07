import { Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'
import { dec } from '../../lib/naira'
import { computeFareSplit } from '../../lib/pricingService'
import { checkPoolRideEligibility, checkWalletPaymentEligibility } from '../../lib/poolAccessService'
import crypto from 'crypto'

// RideReceipt.receiptNumber is a required, UNIQUE column — this was
// previously hardcoded to '' with a comment claiming "trigger fills this",
// but no such DB trigger or default expression exists anywhere in the
// migrations. The first booking ever made would succeed (nothing to
// conflict with yet); every booking after that would violate the unique
// constraint and throw exactly the "invalid tx.rideReceipt.create()" error
// this was built to diagnose. Same short-code convention as genRouteCode()
// in legacy.controller.ts.
function genReceiptNumber(): string {
  return `RCPT-${Date.now().toString(36).toUpperCase()}-${crypto.randomBytes(3).toString('hex').toUpperCase()}`
}

// ─── POST /corporate/bookings/check-policy ────────────────────────────────────
//
// Validates a pending ride against the company's active ride policies.
// Returns one of: allowed | requires_approval | blocked

const CheckPolicySchema = z.object({
  company_id:     z.string().uuid(),
  user_id:        z.string().uuid(),
  department_id:  z.string().optional(),
  estimated_fare: z.string().or(z.number()).transform(Number),
  scheduled_at:   z.string().optional(),
  vehicle_type_id: z.string().optional(),
  origin_lat:     z.string().optional(),
  origin_lng:     z.string().optional(),
})

export async function checkPolicy(req: Request, res: Response) {
  try {
    const data       = CheckPolicySchema.parse(req.body)
    // requireCompanyMember always sets req.companyId from a verified, active
    // CompanyEmployee row before this handler runs — asserting it (rather
    // than falling back to data.company_id) means a future refactor that
    // removes the middleware from this route fails loudly instead of
    // silently starting to trust a client-supplied company id.
    const companyId  = req.companyId!
    const now        = new Date()

    // Load all active policies for this company / department
    const policies = await prisma.ridePolicy.findMany({
      where: {
        companyId,
        isActive: true,
        OR: [
          { departmentId: null }, // company-wide
          ...(data.department_id
            ? [{ departmentId: BigInt(data.department_id) }]
            : []),
        ],
      },
      orderBy: { departmentId: 'desc' }, // dept-specific trumps company-wide
    })

    if (policies.length === 0) {
      ok(res, { status: 'allowed', reason: null, policy_name: null })
      return
    }

    // Use most-specific (department-scoped) policy if available
    const policy = policies[0]

    // ── Day restriction ──────────────────────────────────────────────────
    let scheduledDay = now.getDay() === 0 ? 7 : now.getDay() // ISO: 1=Mon 7=Sun
    if (data.scheduled_at) {
      try {
        const d = new Date(data.scheduled_at)
        scheduledDay = d.getDay() === 0 ? 7 : d.getDay()
      } catch { /* use now */ }
    }

    if (
      policy.allowedDays.length > 0 &&
      !policy.allowedDays.includes(scheduledDay)
    ) {
      ok(res, {
        status:      'blocked',
        reason:      `Rides are not allowed on ${_dayName(scheduledDay)}s under your company policy.`,
        policy_name: policy.name,
      })
      return
    }

    // ── Time restriction ─────────────────────────────────────────────────
    if (policy.allowedTimeFrom && policy.allowedTimeTo && data.scheduled_at) {
      try {
        const dt      = new Date(data.scheduled_at)
        const hhmm    = `${String(dt.getHours()).padLeft(2, '0')}:${String(dt.getMinutes()).padLeft(2, '0')}`
        const inRange = hhmm >= policy.allowedTimeFrom && hhmm <= policy.allowedTimeTo
        if (!inRange) {
          ok(res, {
            status:      'blocked',
            reason:      `Rides must be booked between ${policy.allowedTimeFrom} and ${policy.allowedTimeTo}.`,
            policy_name: policy.name,
          })
          return
        }
      } catch { /* ignore malformed date */ }
    }

    // ── Fare cap ─────────────────────────────────────────────────────────
    if (policy.maxFarePerTrip && data.estimated_fare > dec(policy.maxFarePerTrip)) {
      ok(res, {
        status:      'blocked',
        reason:      `Estimated fare ₦${data.estimated_fare.toLocaleString()} exceeds the ₦${dec(policy.maxFarePerTrip).toLocaleString()} per-trip limit.`,
        policy_name: policy.name,
      })
      return
    }

    // ── Monthly spend cap ────────────────────────────────────────────────
    if (policy.maxMonthlySpend) {
      const monthStart = new Date(now.getFullYear(), now.getMonth(), 1)
      const spentAgg   = await prisma.budgetTransaction.aggregate({
        where: { employeeId: data.user_id, transactedAt: { gte: monthStart } },
        _sum:  { amount: true },
      })
      const spentSoFar = dec(spentAgg._sum.amount)
      if (spentSoFar + data.estimated_fare > dec(policy.maxMonthlySpend)) {
        ok(res, {
          status:      'blocked',
          reason:      `This ride would exceed your monthly spend limit of ₦${dec(policy.maxMonthlySpend).toLocaleString()}.`,
          policy_name: policy.name,
        })
        return
      }
    }

    // ── Check approval workflow ───────────────────────────────────────────
    const workflow = await prisma.approvalWorkflow.findFirst({
      where: {
        companyId,
        isActive: true,
        OR: [
          { departmentId: null },
          ...(data.department_id
            ? [{ departmentId: BigInt(data.department_id) }]
            : []),
        ],
      },
      include: {
        specificApprover:   { select: { name: true } },
        escalationApprover: { select: { name: true } },
      },
      orderBy: { departmentId: 'desc' },
    })

    if (workflow?.requiresApproval) {
      const autoBelow = workflow.autoApproveBelow
        ? dec(workflow.autoApproveBelow)
        : null

      if (autoBelow === null || data.estimated_fare > autoBelow) {
        ok(res, {
          status:        'requires_approval',
          reason:        `Rides above ₦${(autoBelow ?? 0).toLocaleString()} require manager approval.`,
          policy_name:   policy.name,
          approver_name: workflow.specificApprover?.name ?? `your ${workflow.approverRole}`,
          approver_role: workflow.approverRole,
          expiry_hours:  workflow.escalationHours,
        })
        return
      }
    }

    ok(res, { status: 'allowed', reason: null, policy_name: policy.name })
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /corporate/bookings/book ────────────────────────────────────────────

const BookSchema = z.object({
  company_id:       z.string().uuid(),
  uid:              z.string().uuid(),
  trip_id:          z.string(),
  total_seat:       z.string().or(z.number()).transform(Number).pipe(z.number().int().min(1)),
  book_method:      z.string().default('Instant'),
  subtotal:         z.string().or(z.number()).transform(Number),
  total_amount:     z.string().or(z.number()).transform(Number),
  cou_amt:          z.string().or(z.number()).transform(Number).pipe(z.number().nonnegative()).default(0),
  // Fed straight into a `decrement` on Company.walletBalance — a negative
  // value here would flip that into an increment, letting any employee
  // credit their own company's wallet through a booking request. Crediting
  // is reserved for super-admin via creditCompany/creditBranch only.
  wall_amt:         z.string().or(z.number()).transform(Number).pipe(z.number().nonnegative()).default(0),
  driver_alert_info: z.string().default(''),
  booking_fees:     z.string().or(z.number()).transform(Number).default(0),
  department_id:    z.string().optional(),
  cost_centre_id:   z.string().optional(),
  requires_approval: z.string().or(z.boolean()).transform((v) => v === '1' || v === true).default(false),
})

export async function createCorporateBooking(req: Request, res: Response) {
  try {
    const data      = BookSchema.parse(req.body)
    // Same reasoning as checkPolicy above — requireCompanyMember guarantees
    // this before the handler runs, so assert it rather than falling back
    // to a client-supplied value.
    const companyId = req.companyId!
    const userId    = req.user.id

    // Verify ride exists
    const ride = await prisma.ride.findUnique({ where: { id: data.trip_id } })
    if (!ride) { fail(res, 'Ride not found'); return }
    if (ride.availableSeats < data.total_seat) {
      fail(res, `Only ${ride.availableSeats} seat(s) available`)
      return
    }

    // Resolved via the pricing engine (super-admin PricingRateCard layers +
    // Company.commissionRate, company scope = the sponsoring company so a
    // negotiated corporate rate applies) rather than reading
    // PlatformSettings.platformCommission directly. Pool-vehicle detection
    // (driver earns organisation points, not cash) is resolved internally
    // from ride.vehicleId — a corporate booking on a pool vehicle now
    // correctly zeroes driver cash earnings the same way the personal-app
    // booking path already does, instead of always treating it as a cash ride.
    const { driverEarning, platformCommission: commissionAmt, isPoolRide, poolCompanyId, poolBranchId } = await computeFareSplit({
      subtotal: data.subtotal,
      bookingFeeAmount: data.booking_fees,
      vehicleId: ride.vehicleId,
      companyId,
    })

    // The pool vehicle's owning company (poolCompanyId) isn't necessarily
    // the same as the sponsoring company paying for this booking (companyId
    // above) — an employee booking a ride that happens to run on a
    // different organisation's pool vehicle is exactly the cross-company
    // sharing case that needs gating.
    if (isPoolRide && poolCompanyId) {
      const eligibility = await checkPoolRideEligibility({ passengerUserId: userId, poolCompanyId, poolBranchId })
      if (!eligibility.allowed) { fail(res, eligibility.reason ?? 'You are not eligible to book this pool vehicle'); return }
    }

    // wall_amt here always means the SPONSORING company's own funds (this
    // booking's companyId), never the passenger's personal wallet — that's
    // what "corporate booking" means. Gated the same way pool access is:
    // off by default, admin-granted, optionally time-windowed.
    if (data.wall_amt > 0) {
      const walletEligibility = await checkWalletPaymentEligibility({ userId, companyId })
      if (!walletEligibility.allowed) { fail(res, walletEligibility.reason ?? 'You are not eligible to pay with your company wallet'); return }
    }

    const deptId = data.department_id ? BigInt(data.department_id) : null
    const ccId   = data.cost_centre_id ? BigInt(data.cost_centre_id) : null

    // Generate OTPs
    const pickupOtp  = String(Math.floor(100000 + Math.random() * 900000))
    const dropoffOtp = String(Math.floor(100000 + Math.random() * 900000))

    let approvalRequestId: string | undefined

    const booking = await prisma.$transaction(async (tx) => {
      const b = await tx.booking.create({
        data: {
          rideId:             data.trip_id,
          passengerId:        userId,
          companyId,
          departmentId:       deptId,
          costCentreId:       ccId,
          seatsBooked:        data.total_seat,
          subtotal:           data.subtotal,
          couponDiscount:     data.cou_amt,
          walletAmountUsed:   data.wall_amt,
          totalAmount:        data.total_amount,
          driverEarning,
          platformCommission: commissionAmt,
          bookingFee:         data.booking_fees,
          bookingMethod:      'instant',
          paymentStatus:      'successful', // company account = no gateway charge
          status:             data.requires_approval ? 'pending' : 'confirmed',
          confirmedAt:        data.requires_approval ? null : new Date(),
        },
      })

      // Decrement available seats
      await tx.ride.update({
        where: { id: data.trip_id },
        data:  { availableSeats: { decrement: data.total_seat } },
      })

      // Record budget spend immediately if auto-approved
      if (!data.requires_approval && deptId) {
        const budget = await tx.budget.findFirst({
          where: {
            companyId,
            departmentId: deptId,
            isActive:     true,
            periodStart:  { lte: new Date() },
            periodEnd:    { gte: new Date() },
          },
        })
        if (budget) {
          await tx.budgetTransaction.create({
            data: {
              budgetId:    budget.id,
              bookingId:   b.id,
              employeeId:  userId,
              amount:      data.total_amount,
              description: `Ride booking — ${ride.originAddress} → ${ride.destinationAddress}`,
            },
          })
        }
      }

      // Debit the company wallet immediately, same condition as the budget
      // spend above — only if this booking doesn't need approval first. A
      // requires_approval booking defers the actual debit to decideApproval,
      // since debiting now and having the request later rejected would mean
      // refunding rather than simply never having spent it.
      if (!data.requires_approval && data.wall_amt > 0) {
        // Conditional update, not a separate read-then-write — guards
        // against two concurrent bookings both passing a balance check
        // before either commits and overdrawing the account.
        const debited = await tx.company.updateMany({
          where: { id: companyId, walletBalance: { gte: data.wall_amt } },
          data:  { walletBalance: { decrement: data.wall_amt } },
        })
        if (debited.count === 0) throw new Error('INSUFFICIENT_WALLET_BALANCE')

        const after = await tx.company.findUniqueOrThrow({ where: { id: companyId }, select: { walletBalance: true } })
        await tx.companyCredit.create({
          data: {
            companyId,
            amount:        -data.wall_amt,
            balanceAfter:  after.walletBalance,
            paymentMethod: 'ride_payment',
            bookingId:     b.id,
            creditedById:  null,
            note:          `Ride payment — ${ride.originAddress} → ${ride.destinationAddress}`,
          },
        })
      }

      // Create approval request if needed
      if (data.requires_approval) {
        const workflow = await tx.approvalWorkflow.findFirst({
          where: { companyId, isActive: true },
          include: { specificApprover: true },
        })

        if (workflow) {
          const expires = new Date()
          expires.setHours(expires.getHours() + workflow.escalationHours)

          // Find an approver: specific person or first manager in company
          let approverId: string | null = workflow.specificApproverId ?? null
          if (!approverId) {
            const mgr = await tx.companyEmployee.findFirst({
              where: { companyId, role: workflow.approverRole as any, isActive: true },
              select: { userId: true },
            })
            approverId = mgr?.userId ?? null
          }

          const ar = await tx.approvalRequest.create({
            data: {
              workflowId:         workflow.id,
              bookingId:          b.id,
              requesterId:        userId,
              approverId:         approverId ?? undefined,
              originAddress:      ride.originAddress,
              destinationAddress: ride.destinationAddress,
              estimatedFare:      data.total_amount,
              scheduledAt:        ride.scheduledAt,
              expiresAt:          expires,
              status:             'pending',
            },
          })

          // Link back to booking
          await tx.booking.update({
            where: { id: b.id },
            data:  { approvalRequestId: ar.id },
          })

          approvalRequestId = ar.id.toString()
        }
      }

      // Create ride receipt
      await tx.rideReceipt.create({
        data: {
          bookingId:         b.id,
          companyId,
          employeeId:        userId,
          departmentId:      deptId,
          costCentreId:      ccId,
          baseFare:          data.subtotal,
          platformFee:       commissionAmt,
          discount:          data.cou_amt,
          totalCharged:      data.total_amount,
          originAddress:     ride.originAddress,
          destinationAddress: ride.destinationAddress,
          receiptNumber:     genReceiptNumber(),
        },
      })

      return b
    })

    const responseData: Record<string, unknown> = {
      booking_id: booking.id,
      status:     booking.status,
    }
    if (approvalRequestId) {
      responseData.approval_request_id = approvalRequestId
      const ar = await prisma.approvalRequest.findUnique({
        where: { id: BigInt(approvalRequestId) },
        select: { expiresAt: true },
      })
      responseData.expires_at = ar?.expiresAt.toISOString() ?? ''
    }

    ok(res, responseData,
      data.requires_approval
        ? 'Booking submitted for approval'
        : 'Ride booked successfully')
  } catch (err) {
    if (err instanceof Error && err.message === 'INSUFFICIENT_WALLET_BALANCE') {
      fail(res, 'Insufficient company wallet balance for this ride'); return
    }
    serverError(res, err)
  }
}

// ─── POST /corporate/bookings/cancel-approval ─────────────────────────────────

export async function cancelApproval(req: Request, res: Response) {
  try {
    const { approval_request_id, user_id } = req.body as {
      approval_request_id: string
      user_id: string
    }

    const ar = await prisma.approvalRequest.findFirst({
      where: { id: BigInt(approval_request_id), requesterId: user_id, status: 'pending' },
    })
    if (!ar) { fail(res, 'Approval request not found or already decided'); return }

    await prisma.$transaction([
      prisma.approvalRequest.update({
        where: { id: ar.id },
        data:  { status: 'rejected', decisionNote: 'Cancelled by requester', decidedAt: new Date() },
      }),
      prisma.booking.update({
        where: { id: ar.bookingId },
        data:  { status: 'cancelled', cancelledAt: new Date(), cancellationReason: 'Cancelled by requester' },
      }),
      // Restore seat
      prisma.ride.update({
        where: { id: (await prisma.booking.findUnique({ where: { id: ar.bookingId }, select: { rideId: true } }))!.rideId },
        data:  { availableSeats: { increment: 1 } },
      }),
    ])

    ok(res, { approval_request_id }, 'Request cancelled')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function _dayName(iso: number) {
  return ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][iso]
}

// Polyfill String.prototype.padLeft used in checkPolicy
declare global {
  interface String { padLeft(len: number, char: string): string }
}
String.prototype.padLeft = function (len: number, char: string) {
  return this.toString().padStart(len, char)
}
