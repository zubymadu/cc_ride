import { Request, Response } from 'express'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'
import { dec } from '../../lib/naira'
import { assertCompanyScope, assertBranchScope, branchWhereFilter } from '../../lib/adminScope'
import { refundCompanyWallet } from '../../lib/companyWallet'

export async function listCompanies(req: Request, res: Response) {
  try {
    const { status, search } = req.query as Record<string, string>
    const now        = new Date()
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1)
    const isSuperAdmin = !!req.admin?.isSuperAdmin

    const companies = await prisma.company.findMany({
      where: {
        // Scoped (company) admins only ever see their own organisation
        ...(isSuperAdmin ? {} : { id: req.admin?.scopeCompanyId ?? '__none__' }),
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
      registration_number: c.registrationNumber ?? '',
      contact_name:        c.contactName,
      contact_email:       c.contactEmail,
      contact_phone:       c.contactPhone ?? '',
      status:              c.status,
      total_employees:     c._count.employees,
      rides_this_month:    c.bookings.length,
      gmv_this_month:      c.bookings.reduce((s, b) => s + dec(b.totalAmount), 0),
      logo_url:            c.logoUrl ?? '',
      ...(isSuperAdmin ? { commission_rate: dec(c.commissionRate ?? 15) } : {}),
      created_at:          c.createdAt.toISOString(),
    })))
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /admin/companies/logo ───────────────────────────────────────────────
// multipart/form-data: { company_id, logo (file) } — scoped admins can only
// upload their own company's logo regardless of what company_id they send.

export async function uploadCompanyLogo(req: Request, res: Response) {
  try {
    const file = (req as any).file as Express.Multer.File | undefined
    if (!file) { fail(res, 'Logo image required'); return }

    const isSuperAdmin = !!req.admin?.isSuperAdmin
    const companyId = isSuperAdmin
      ? String(req.body.company_id ?? '')
      : (req.admin?.scopeCompanyId ?? '')

    if (!companyId) { fail(res, 'company_id is required'); return }
    if (!assertCompanyScope(req, res, companyId)) return

    const logoUrl = `/api/uploads/company-logos/${file.filename}`
    await prisma.company.update({ where: { id: companyId }, data: { logoUrl } })

    ok(res, { company_id: companyId, logo_url: logoUrl }, 'Logo updated')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── GET /admin/branding ──────────────────────────────────────────────────────
// Used by the console sidebar to show the logged-in organisation's own
// branding. Super-admins get nulls back and the console falls back to the
// default CC Ride mark.

export async function getBranding(req: Request, res: Response) {
  try {
    if (req.admin?.isSuperAdmin || !req.admin?.scopeCompanyId) {
      ok(res, { company_id: null, company_name: null, logo_url: null })
      return
    }

    const company = await prisma.company.findUnique({
      where:  { id: req.admin.scopeCompanyId },
      select: { id: true, name: true, logoUrl: true },
    })
    if (!company) { ok(res, { company_id: null, company_name: null, logo_url: null }); return }

    ok(res, { company_id: company.id, company_name: company.name, logo_url: company.logoUrl ?? null })
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
      where:   { companyId, ...branchWhereFilter(req) },
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
    const { status } = req.query as Record<string, string>
    if (!assertCompanyScope(req, res, companyId)) return

    const bookings = await prisma.booking.findMany({
      where: {
        companyId,
        ...branchWhereFilter(req),
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
    if (booking.companyId && !assertCompanyScope(req, res, booking.companyId)) return
    if (!booking.companyId && !req.admin?.isSuperAdmin) { fail(res, 'Not authorised', 403); return }
    if (booking.companyId && !assertBranchScope(req, res, booking.branchId)) return

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
    const isSuperAdmin = !!req.admin?.isSuperAdmin

    const requests = await prisma.approvalRequest.findMany({
      where: {
        status: 'pending',
        // Scoped (company/branch) admins only see their own organisation's queue
        ...(isSuperAdmin ? {} : {
          workflow: { companyId: req.admin?.scopeCompanyId ?? '__none__', ...branchWhereFilter(req) },
        }),
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
        booking:  { select: { id: true, status: true, rideId: true, companyId: true, totalAmount: true, paymentGateway: true, seatsBooked: true } },
        workflow: { select: { companyId: true, branchId: true } },
      },
    })
    if (!request) { fail(res, 'Approval request not found'); return }
    if (!assertCompanyScope(req, res, request.workflow.companyId)) return
    if (!assertBranchScope(req, res, request.workflow.branchId)) return
    if (request.status !== 'pending') { fail(res, 'Request already decided'); return }

    await prisma.$transaction(async (tx) => {
      await tx.approvalRequest.update({
        where: { id: BigInt(request_id) },
        data: {
          status:      action,
          decisionNote:note ?? null,
          decidedAt:   new Date(),
        },
      })
      // Also update the booking status accordingly
      await tx.booking.update({
        where: { id: request.bookingId },
        data: {
          status: action === 'approved' ? 'confirmed' : 'cancelled',
          ...(action === 'rejected' ? { cancellationReason: note ?? 'Rejected by admin', cancelledAt: new Date() } : {}),
        },
      })

      if (action === 'rejected') {
        // Restore the seat and, if this was charged to a company wallet
        // up front, refund it.
        await tx.ride.update({
          where: { id: request.booking.rideId },
          data:  { availableSeats: { increment: request.booking.seatsBooked } },
        })
        if (request.booking.paymentGateway === 'company_account' && request.booking.companyId) {
          await refundCompanyWallet(tx, request.booking.companyId, Number(request.booking.totalAmount))
        }
      }
    })

    ok(res, { request_id, action }, `Booking ${action}`)
  } catch (err) {
    serverError(res, err)
  }
}
