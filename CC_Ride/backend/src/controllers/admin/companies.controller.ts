import { Request, Response } from 'express'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'
import { dec } from '../../lib/naira'
import { assertCompanyScope } from '../../lib/adminScope'
import { provisionCompanyAdminInvite } from '../../lib/adminInvite'
import { sendMail } from '../../lib/mail'
import crypto from 'crypto'
import { z } from 'zod'

export async function listCompanies(req: Request, res: Response) {
  try {
    const { status, search } = req.query as Record<string, string>
    const now        = new Date()
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1)

    const companies = await prisma.company.findMany({
      where: {
        // A scoped admin only ever sees their own company here — this is
        // the list endpoint the company-detail views are driven from.
        // (Company's own primary key is the scope, not a companyId column,
        // so this can't reuse companyScopeWhere() directly.)
        ...(req.admin?.isSuperAdmin ? {} : { id: req.admin?.scopeCompanyId ?? '__no_scope__' }),
        ...(status ? { status: status as any } : {}),
        ...(search ? {
          OR: [
            { name:         { contains: search, mode: 'insensitive' } },
            { contactEmail: { contains: search, mode: 'insensitive' } },
          ],
        } : {}),
      },
      orderBy: [{ status: 'asc' }, { createdAt: 'desc' }],
      include: {
        _count: { select: { employees: { where: { isActive: true } } } },
        bookings: {
          where: {
            createdAt: { gte: monthStart },
            status:    { in: ['completed', 'confirmed'] as any },
          },
          select: { totalAmount: true },
        },
      },
    })

    ok(res, companies.map((c) => ({
      id:                  c.id,
      name:                c.name,
      logo_url:            c.logoUrl ?? null,
      registration_number: c.registrationNumber ?? '',
      contact_name:        c.contactName,
      contact_email:       c.contactEmail,
      contact_phone:       c.contactPhone ?? '',
      status:              c.status,
      total_employees:     c._count.employees,
      rides_this_month:    c.bookings.length,
      gmv_this_month:      c.bookings.reduce((s, b) => s + dec(b.totalAmount), 0),
      commission_rate:     dec(c.commissionRate ?? 15),
      created_at:          c.createdAt.toISOString(),
    })))
  } catch (err) {
    serverError(res, err)
  }
}

export async function companyAction(req: Request, res: Response) {
  try {
    const { company_id, action } = req.body as { company_id: string; action: string }
    const statusMap: Record<string, string> = {
      approve:  'active',
      reject:   'rejected',
      suspend:  'suspended',
      activate: 'active',
    }
    const newStatus = statusMap[action]
    if (!newStatus) { fail(res, 'Invalid action'); return }

    await prisma.company.update({
      where: { id: company_id },
      data:  { status: newStatus as any },
    })

    // Newly approved — auto-provision their first scoped admin and email a
    // claim link, rather than making a super-admin manually create one for
    // every organisation that signs on. Fire-and-forget: the approval
    // itself must succeed regardless of whether the invite email goes out.
    if (action === 'approve') {
      provisionCompanyAdminInvite(company_id).catch((err) => console.error('companyAction: invite provisioning failed:', err))
    }

    ok(res, { company_id, status: newStatus })
  } catch (err) {
    serverError(res, err)
  }
}

export async function updateCommission(req: Request, res: Response) {
  try {
    const { company_id, commission_rate } = req.body as { company_id: string; commission_rate: number }
    if (commission_rate < 0 || commission_rate > 50) { fail(res, 'Commission must be 0–50%'); return }

    await prisma.company.update({
      where: { id: company_id },
      data:  { commissionRate: commission_rate },
    })
    ok(res, { company_id, commission_rate })
  } catch (err) {
    serverError(res, err)
  }
}

// ─── GET /admin/companies/:id/employees ───────────────────────────────────────

export async function listCompanyEmployees(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const employees = await prisma.companyEmployee.findMany({
      where:   { companyId },
      orderBy: [{ role: 'asc' }],
      include: { user: { select: { name: true, email: true, mobile: true, status: true } } },
    })

    ok(res, employees.map((e) => {
      const u = e as typeof e & { user: { name: string; email: string | null; mobile: string; status: string } }
      return {
        id:         e.id.toString(),
        user_id:    e.userId,
        name:       u.user.name,
        email:      u.user.email ?? '',
        mobile:     u.user.mobile,
        role:       e.role,
        department: e.departmentId?.toString() ?? null,
        is_active:  e.isActive,
        joined_at:  (e.joinedAt ?? new Date()).toISOString(),
        status:     u.user.status,
      }
    }))
  } catch (err) {
    serverError(res, err)
  }
}

// ─── GET /admin/companies/:id/rides ──────────────────────────────────────────

export async function listCompanyRides(req: Request, res: Response) {
  try {
    const companyId  = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const { status } = req.query as Record<string, string>

    const bookings = await prisma.booking.findMany({
      where: {
        companyId,
        ...(status && status !== 'all' ? { status: status as any } : {}),
      },
      orderBy: { createdAt: 'desc' },
      take: 100,
      include: {
        passenger: { select: { name: true } },
        driver:    { select: { name: true } },
        ride:      { select: { originAddress: true, destinationAddress: true } },
      },
    })

    ok(res, bookings.map((b) => {
      const bk = b as typeof b & {
        passenger: { name: string }
        driver: { name: string } | null
        ride: { originAddress: string; destinationAddress: string }
      }
      return {
        id:             bk.id,
        passenger:      bk.passenger.name,
        driver:         bk.driver?.name ?? '—',
        origin:         bk.ride.originAddress,
        destination:    bk.ride.destinationAddress,
        status:         bk.status,
        total_amount:   dec(bk.totalAmount),
        payment_status: bk.paymentStatus,
        created_at:     bk.createdAt.toISOString(),
      }
    }))
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /admin/rides/cancel ─────────────────────────────────────────────────

export async function cancelRide(req: Request, res: Response) {
  try {
    const { booking_id, reason } = req.body as { booking_id: string; reason?: string }
    if (!booking_id) { fail(res, 'booking_id required'); return }

    const booking = await prisma.booking.findUnique({ where: { id: booking_id } })
    if (!booking) { fail(res, 'Booking not found'); return }
    // A scoped admin may only cancel their own company's bookings — a
    // personal (non-corporate) ride has no companyId, so it's platform-only.
    if (!req.admin?.isSuperAdmin && !assertCompanyScope(req, res, booking.companyId)) return

    const cancellable = ['confirmed', 'pending', 'in_progress', 'processing']
    if (!cancellable.includes(booking.status)) {
      fail(res, `Cannot cancel a booking with status "${booking.status}"`); return
    }

    await prisma.$transaction([
      prisma.booking.update({
        where: { id: booking_id },
        data: {
          status:             'cancelled',
          cancelledAt:        new Date(),
          cancellationReason: reason ?? 'Cancelled by admin',
        },
      }),
      // Restore seat on the parent ride
      prisma.ride.update({
        where: { id: booking.rideId },
        data:  { availableSeats: { increment: booking.seatsBooked } },
      }),
    ])

    ok(res, { booking_id, status: 'cancelled' }, 'Ride cancelled')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── GET /admin/bookings/approvals ───────────────────────────────────────────
// Pending corporate booking approval requests for the queue page

export async function listPendingApprovals(req: Request, res: Response) {
  try {
    const requests = await prisma.approvalRequest.findMany({
      where: {
        status: 'pending',
        ...(req.admin?.isSuperAdmin ? {} : { booking: { companyId: req.admin?.scopeCompanyId ?? '__no_scope__' } }),
      },
      orderBy: { createdAt: 'desc' },
      take:    100,
      include: {
        requester: { select: { name: true, email: true, mobile: true } },
        booking: {
          select: {
            id: true, totalAmount: true, seatsBooked: true, status: true, createdAt: true,
            company:    { select: { name: true, monthlySubscription: true } },
            department: { select: { name: true } },
            costCentre: { select: { name: true, code: true } },
            ride: {
              select: {
                originAddress: true, destinationAddress: true,
                scheduledAt: true, baseFare: true,
              },
            },
          },
        },
      },
    })

    ok(res, requests.map((r) => ({
      id:              r.id.toString(),
      booking_id:      r.bookingId,
      requester_name:  r.requester.name,
      requester_email: r.requester.email ?? '',
      requester_mobile:r.requester.mobile,
      origin:          r.originAddress,
      destination:     r.destinationAddress,
      estimated_fare:  dec(r.estimatedFare),
      scheduled_at:    r.scheduledAt.toISOString(),
      created_at:      r.createdAt.toISOString(),
      expires_at:      r.expiresAt.toISOString(),
      company:         r.booking.company?.name ?? '—',
      department:      r.booking.department?.name ?? null,
      cost_centre:     r.booking.costCentre?.code ?? null,
      seats:           r.booking.seatsBooked,
      total_amount:    dec(r.booking.totalAmount),
    })))
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /admin/bookings/approve ─────────────────────────────────────────────

export async function decideApproval(req: Request, res: Response) {
  try {
    const { request_id, action, note } = req.body as {
      request_id: string; action: 'approved' | 'rejected'; note?: string
    }
    const adminId = req.admin?.id ? BigInt(req.admin.id) : null

    // Find the admin user's corresponding User record (if linked)
    const request = await prisma.approvalRequest.findUnique({
      where:   { id: BigInt(request_id) },
      include: {
        booking: {
          select: {
            id: true, status: true, companyId: true, walletAmountUsed: true,
            ride: { select: { originAddress: true, destinationAddress: true } },
          },
        },
      },
    })
    if (!request) { fail(res, 'Approval request not found'); return }
    if (!assertCompanyScope(req, res, request.booking.companyId)) return
    if (request.status !== 'pending') { fail(res, 'Request already decided'); return }

    const walletAmount = dec(request.booking.walletAmountUsed)

    await prisma.$transaction(async (tx) => {
      await tx.approvalRequest.update({
        where: { id: BigInt(request_id) },
        data: {
          status:      action,
          decisionNote:note ?? null,
          decidedAt:   new Date(),
        },
      })
      await tx.booking.update({
        where: { id: request.bookingId },
        data: {
          status: action === 'approved' ? 'confirmed' : 'cancelled',
          ...(action === 'rejected' ? { cancellationReason: note ?? 'Rejected by admin', cancelledAt: new Date() } : {}),
        },
      })

      // The wallet debit was deferred at booking time specifically because
      // approval was still pending — settle it now, only on approval, so a
      // rejected request never touches the balance at all.
      if (action === 'approved' && walletAmount > 0 && request.booking.companyId) {
        const companyId = request.booking.companyId
        const debited = await tx.company.updateMany({
          where: { id: companyId, walletBalance: { gte: walletAmount } },
          data:  { walletBalance: { decrement: walletAmount } },
        })
        if (debited.count === 0) throw new Error('INSUFFICIENT_WALLET_BALANCE')

        const after = await tx.company.findUniqueOrThrow({ where: { id: companyId }, select: { walletBalance: true } })
        await tx.companyCredit.create({
          data: {
            companyId,
            amount:        -walletAmount,
            balanceAfter:  after.walletBalance,
            paymentMethod: 'ride_payment',
            bookingId:     request.bookingId,
            creditedById:  null,
            note:          `Ride payment (approved) — ${request.booking.ride.originAddress} → ${request.booking.ride.destinationAddress}`,
          },
        })
      }
    })

    ok(res, { request_id, action }, `Booking ${action}`)
  } catch (err) {
    if (err instanceof Error && err.message === 'INSUFFICIENT_WALLET_BALANCE') {
      fail(res, 'Cannot approve — the company wallet no longer has sufficient balance for this ride'); return
    }
    serverError(res, err)
  }
}

// ─── Super-admin: edit a company's contact details ──────────────────────────
// Platform-level correction (wrong contact on file, staff change at the
// client) — not exposed to the company's own scoped admin, who shouldn't be
// able to unilaterally change who the platform considers their contact.

const UpdateContactSchema = z.object({
  contact_name:  z.string().min(2).optional(),
  contact_email: z.string().email().optional(),
  contact_phone: z.string().optional(),
})

// PATCH /admin/companies/:id/contact
export async function updateCompanyContact(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    const data = UpdateContactSchema.parse(req.body)

    const company = await prisma.company.findUnique({ where: { id: companyId } })
    if (!company) { fail(res, 'Company not found'); return }

    const updated = await prisma.company.update({
      where: { id: companyId },
      data: {
        ...(data.contact_name  !== undefined ? { contactName:  data.contact_name }  : {}),
        ...(data.contact_email !== undefined ? { contactEmail: data.contact_email } : {}),
        ...(data.contact_phone !== undefined ? { contactPhone: data.contact_phone } : {}),
      },
    })

    // Keep the linked admin login in sync — it was originally seeded from
    // contactEmail, and a stale login email would silently drift from
    // reality otherwise.
    if (data.contact_email !== undefined) {
      await prisma.adminUser.updateMany({
        where: { scopeCompanyId: companyId },
        data: { email: data.contact_email },
      })
    }

    ok(res, {
      id: updated.id,
      contact_name: updated.contactName,
      contact_email: updated.contactEmail,
      contact_phone: updated.contactPhone ?? '',
    }, 'Contact details updated')
  } catch (err: any) {
    if (err?.code === 'P2002') { fail(res, 'Another account already uses that email'); return }
    serverError(res, err)
  }
}

// ─── Super-admin: delete a company ──────────────────────────────────────────
// Housekeeping only — permanent, cascades through every company-scoped
// table (employees, bookings, budgets, invoices, credit ledger, admin
// users, ...). walletBalance is never editable through any path; deleting
// the row removes the balance along with everything else, which is a
// different concern from letting someone adjust it in place.

export async function deleteCompany(req: Request, res: Response) {
  try {
    const id = String(req.params.id)
    const force = req.query.force === 'true'

    const company = await prisma.company.findUnique({ where: { id } })
    if (!company) { fail(res, 'Company not found'); return }

    if (!force) {
      const [bookingCount, walletBalance] = await Promise.all([
        prisma.booking.count({ where: { companyId: id, status: { in: ['completed', 'confirmed', 'in_progress'] } } }),
        Promise.resolve(dec(company.walletBalance)),
      ])
      if (bookingCount > 0 || walletBalance > 0 || company.status === 'active') {
        fail(res, `This company has real activity (${bookingCount} booking(s), ₦${walletBalance} wallet balance, status "${company.status}") — pass force=true to delete anyway (this permanently removes all of it)`)
        return
      }
    }

    await prisma.company.delete({ where: { id } })
    ok(res, {}, 'Company deleted')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Super-admin: reset a company's admin user ──────────────────────────────
// Regenerates credentials the same way initial provisioning does — clears
// the password, issues a fresh invite token, and returns the claim link
// directly in the response (not just email) since email delivery can't be
// assumed to work.

// POST /admin/companies/:id/reset-admin-user
export async function resetCompanyAdminUser(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    const company = await prisma.company.findUnique({ where: { id: companyId } })
    if (!company) { fail(res, 'Company not found'); return }

    const admin = await prisma.adminUser.findFirst({ where: { scopeCompanyId: companyId } })
    if (!admin) { fail(res, 'No admin user exists for this company yet'); return }

    const inviteToken = crypto.randomBytes(32).toString('hex')
    const inviteExpiresAt = new Date(Date.now() + 168 * 3600 * 1000) // 7 days, matches initial provisioning

    await prisma.adminUser.update({
      where: { id: admin.id },
      data: { passwordHash: null, inviteToken, inviteExpiresAt, isActive: true },
    })

    const claimUrl = `${process.env.ADMIN_URL ?? 'http://localhost:5174'}/claim-invite/${inviteToken}`
    const emailed = await sendMail(
      admin.email,
      `Your CC Ride admin account for ${company.name} has been reset`,
      `<p>Hi,</p><p>Your admin access for ${company.name} was reset by CC Ride support. Set a new password here:</p><p><a href="${claimUrl}">${claimUrl}</a></p><p>This link expires in 7 days.</p>`,
    )

    ok(res, { username: admin.username, claim_url: claimUrl, emailed }, emailed ? 'Reset email sent' : 'Reset link generated (email not sent — share this link directly)')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Company logo upload ────────────────────────────────────────────────────
// Self-service for the company's own scoped admin — the logo shows up in
// the console sidebar/welcome banner and on their savings reports.

export async function uploadCompanyLogo(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return

    const file = (req as any).file as { filename?: string } | undefined
    if (!file?.filename) { fail(res, 'logo file required'); return }

    const logoUrl = `/api/uploads/profiles/${file.filename}`
    await prisma.company.update({ where: { id: companyId }, data: { logoUrl } })

    ok(res, { logo_url: logoUrl }, 'Logo updated')
  } catch (err) {
    serverError(res, err)
  }
}
