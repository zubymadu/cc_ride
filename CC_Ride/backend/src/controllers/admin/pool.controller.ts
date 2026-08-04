/**
 * Admin — pool-car access policy: company-wide sharing toggle + partner
 * agreements, and per-employee pool access + usage rations. Self-service
 * for a company's own scoped admin (assertCompanyScope), not super-admin-only.
 */
import { Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'
import { assertCompanyScope } from '../../lib/adminScope'

function adminId(req: Request): bigint {
  if (!req.admin?.id) throw new Error('Admin session missing id')
  return BigInt(req.admin.id)
}

// ─── Company-wide policy ─────────────────────────────────────────────────────

// GET /admin/companies/:id/pool-policy
export async function getPoolPolicy(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return

    const policy = await prisma.companyPoolPolicy.findUnique({ where: { companyId } })
    ok(res, {
      allow_external_sharing: policy?.allowExternalSharing ?? false,
      daily_limit:   policy?.dailyLimit   ?? null,
      weekly_limit:  policy?.weeklyLimit  ?? null,
      monthly_limit: policy?.monthlyLimit ?? null,
    })
  } catch (err) {
    serverError(res, err)
  }
}

const UpdatePolicySchema = z.object({
  allow_external_sharing: z.boolean().optional(),
  daily_limit:   z.number().int().positive().nullable().optional(),
  weekly_limit:  z.number().int().positive().nullable().optional(),
  monthly_limit: z.number().int().positive().nullable().optional(),
})

// PATCH /admin/companies/:id/pool-policy
export async function updatePoolPolicy(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const data = UpdatePolicySchema.parse(req.body)

    const policy = await prisma.companyPoolPolicy.upsert({
      where: { companyId },
      create: {
        companyId,
        allowExternalSharing: data.allow_external_sharing ?? false,
        dailyLimit:   data.daily_limit ?? null,
        weeklyLimit:  data.weekly_limit ?? null,
        monthlyLimit: data.monthly_limit ?? null,
      },
      update: {
        ...(data.allow_external_sharing !== undefined ? { allowExternalSharing: data.allow_external_sharing } : {}),
        ...(data.daily_limit   !== undefined ? { dailyLimit:   data.daily_limit }   : {}),
        ...(data.weekly_limit  !== undefined ? { weeklyLimit:  data.weekly_limit }  : {}),
        ...(data.monthly_limit !== undefined ? { monthlyLimit: data.monthly_limit } : {}),
      },
    })

    ok(res, {
      allow_external_sharing: policy.allowExternalSharing,
      daily_limit:   policy.dailyLimit,
      weekly_limit:  policy.weeklyLimit,
      monthly_limit: policy.monthlyLimit,
    }, 'Pool policy updated')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Partner discovery ───────────────────────────────────────────────────────
// A deliberate, controlled cross-tenant read: a scoped admin picking a
// sharing partner needs to find OTHER companies, which the regular
// /admin/companies endpoint intentionally can't return (it's scoped to the
// caller's own company). Only non-sensitive fields are exposed here — no
// contact info, wallet balance, or commission rate.

const PartnerSearchSchema = z.object({ q: z.string().optional() })

// GET /admin/companies/partner-search?q=
export async function searchPartnerCompanies(req: Request, res: Response) {
  try {
    const { q } = PartnerSearchSchema.parse(req.query)
    const excludeId = req.admin?.isSuperAdmin
      ? (req.query.exclude ? String(req.query.exclude) : undefined)
      : (req.admin?.scopeCompanyId ?? undefined)

    const companies = await prisma.company.findMany({
      where: {
        status: 'active',
        ...(excludeId ? { id: { not: excludeId } } : {}),
        ...(q ? {
          OR: [
            { name:     { contains: q, mode: 'insensitive' } },
            { city:     { contains: q, mode: 'insensitive' } },
            { industry: { contains: q, mode: 'insensitive' } },
          ],
        } : {}),
      },
      select: { id: true, name: true, logoUrl: true, city: true, industry: true },
      orderBy: { name: 'asc' },
      take: 20,
    })

    ok(res, companies.map((c) => ({
      id: c.id, name: c.name, logo_url: c.logoUrl, city: c.city, industry: c.industry,
    })))
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Sharing agreements (which OTHER companies may use this company's pool) ─

// GET /admin/companies/:id/pool-sharing
export async function listPoolSharingAgreements(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return

    const agreements = await prisma.poolSharingAgreement.findMany({
      where: { companyId },
      orderBy: { createdAt: 'desc' },
      include: { partnerCompany: { select: { name: true, logoUrl: true } }, branch: { select: { name: true } } },
    })
    ok(res, agreements.map((a) => ({
      id: a.id.toString(),
      partner_company_id: a.partnerCompanyId,
      partner_company_name: a.partnerCompany.name,
      partner_company_logo_url: a.partnerCompany.logoUrl,
      // null ⇒ applies to every branch (the original, company-wide
      // behaviour); set ⇒ this agreement only covers that one branch's pool
      // fleet.
      branch_id:   a.branchId?.toString() ?? null,
      branch_name: a.branch?.name ?? null,
      is_active:   a.isActive,
      created_at:  a.createdAt.toISOString(),
    })))
  } catch (err) {
    serverError(res, err)
  }
}

const AddSharingSchema = z.object({
  partner_company_id: z.string().uuid(),
  branch_id: z.string().optional(),
})

// POST /admin/companies/:id/pool-sharing
export async function addPoolSharingAgreement(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const { partner_company_id, branch_id } = AddSharingSchema.parse(req.body)

    if (partner_company_id === companyId) { fail(res, 'A company cannot share pool access with itself'); return }

    const partner = await prisma.company.findUnique({ where: { id: partner_company_id }, select: { id: true, status: true } })
    if (!partner) { fail(res, 'Partner company not found'); return }
    if (partner.status !== 'active') { fail(res, 'Partner company is not an active participating organisation'); return }

    let branchId: bigint | null = null
    if (branch_id) {
      const branch = await prisma.companyBranch.findFirst({ where: { id: BigInt(branch_id), companyId } })
      if (!branch) { fail(res, 'Branch not found'); return }
      branchId = branch.id
    }

    // Postgres treats NULL branch_id as distinct from any other NULL, so the
    // DB's unique index alone won't stop two identical company-wide
    // (branch_id: null) agreements for the same partner from being created —
    // check for that case explicitly.
    const existing = await prisma.poolSharingAgreement.findFirst({
      where: { companyId, partnerCompanyId: partner_company_id, branchId },
    })
    const agreement = existing
      ? await prisma.poolSharingAgreement.update({ where: { id: existing.id }, data: { isActive: true } })
      : await prisma.poolSharingAgreement.create({
          data: { companyId, branchId, partnerCompanyId: partner_company_id, isActive: true, createdById: adminId(req) },
        })

    ok(res, { id: agreement.id.toString() }, 'Sharing agreement added')
  } catch (err: any) {
    if (err?.code === 'P2002') { fail(res, 'This company is already on the sharing list'); return }
    serverError(res, err)
  }
}

// PATCH /admin/companies/:id/pool-sharing/:agreementId/revoke
export async function revokePoolSharingAgreement(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const agreementId = BigInt(String(req.params.agreementId))

    const agreement = await prisma.poolSharingAgreement.findUnique({ where: { id: agreementId } })
    if (!agreement || agreement.companyId !== companyId) { fail(res, 'Sharing agreement not found'); return }

    await prisma.poolSharingAgreement.update({ where: { id: agreementId }, data: { isActive: false } })
    ok(res, {}, 'Sharing agreement revoked')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Per-employee pool access ────────────────────────────────────────────────

// GET /admin/companies/:id/employees/pool-access
export async function listEmployeePoolAccess(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return

    const employees = await prisma.companyEmployee.findMany({
      where: { companyId, isActive: true },
      orderBy: { invitedAt: 'asc' },
      include: { user: { select: { name: true, email: true } } },
    })
    ok(res, employees.map((e) => ({
      id: e.id.toString(),
      name: e.user.name,
      email: e.user.email ?? '',
      job_title: e.jobTitle ?? '',
      pool_access_enabled: e.poolAccessEnabled,
      pool_daily_limit:   e.poolDailyLimit,
      pool_weekly_limit:  e.poolWeeklyLimit,
      pool_monthly_limit: e.poolMonthlyLimit,
      pool_access_days_of_week: e.poolAccessDaysOfWeek,
      pool_access_time_from:    e.poolAccessTimeFrom,
      pool_access_time_to:      e.poolAccessTimeTo,
      wallet_access_enabled:      e.walletAccessEnabled,
      wallet_access_days_of_week: e.walletAccessDaysOfWeek,
      wallet_access_time_from:    e.walletAccessTimeFrom,
      wallet_access_time_to:      e.walletAccessTimeTo,
    })))
  } catch (err) {
    serverError(res, err)
  }
}

const DaysOfWeekSchema = z.array(z.number().int().min(1).max(7))

const UpdateEmployeePoolAccessSchema = z.object({
  pool_access_enabled: z.boolean().optional(),
  pool_daily_limit:    z.number().int().positive().nullable().optional(),
  pool_weekly_limit:   z.number().int().positive().nullable().optional(),
  pool_monthly_limit:  z.number().int().positive().nullable().optional(),
  pool_access_days_of_week: DaysOfWeekSchema.optional(),
  pool_access_time_from:    z.string().regex(/^\d{2}:\d{2}$/).nullable().optional(),
  pool_access_time_to:      z.string().regex(/^\d{2}:\d{2}$/).nullable().optional(),
})

// PATCH /admin/companies/:id/employees/:employeeId/pool-access
export async function updateEmployeePoolAccess(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const employeeId = BigInt(String(req.params.employeeId))
    const data = UpdateEmployeePoolAccessSchema.parse(req.body)

    const employee = await prisma.companyEmployee.findUnique({ where: { id: employeeId } })
    if (!employee || employee.companyId !== companyId) { fail(res, 'Employee not found'); return }

    const updated = await prisma.companyEmployee.update({
      where: { id: employeeId },
      data: {
        ...(data.pool_access_enabled !== undefined ? { poolAccessEnabled: data.pool_access_enabled } : {}),
        ...(data.pool_daily_limit    !== undefined ? { poolDailyLimit:    data.pool_daily_limit }    : {}),
        ...(data.pool_weekly_limit   !== undefined ? { poolWeeklyLimit:   data.pool_weekly_limit }   : {}),
        ...(data.pool_monthly_limit  !== undefined ? { poolMonthlyLimit:  data.pool_monthly_limit }  : {}),
        ...(data.pool_access_days_of_week !== undefined ? { poolAccessDaysOfWeek: data.pool_access_days_of_week } : {}),
        ...(data.pool_access_time_from    !== undefined ? { poolAccessTimeFrom:   data.pool_access_time_from }    : {}),
        ...(data.pool_access_time_to      !== undefined ? { poolAccessTimeTo:     data.pool_access_time_to }      : {}),
      },
    })

    ok(res, {
      pool_access_enabled: updated.poolAccessEnabled,
      pool_daily_limit:    updated.poolDailyLimit,
      pool_weekly_limit:   updated.poolWeeklyLimit,
      pool_monthly_limit:  updated.poolMonthlyLimit,
      pool_access_days_of_week: updated.poolAccessDaysOfWeek,
      pool_access_time_from:    updated.poolAccessTimeFrom,
      pool_access_time_to:      updated.poolAccessTimeTo,
    }, 'Employee pool access updated')
  } catch (err) {
    serverError(res, err)
  }
}

const UpdateEmployeeWalletAccessSchema = z.object({
  wallet_access_enabled: z.boolean().optional(),
  wallet_access_days_of_week: DaysOfWeekSchema.optional(),
  wallet_access_time_from:    z.string().regex(/^\d{2}:\d{2}$/).nullable().optional(),
  wallet_access_time_to:      z.string().regex(/^\d{2}:\d{2}$/).nullable().optional(),
})

// PATCH /admin/companies/:id/employees/:employeeId/wallet-access
export async function updateEmployeeWalletAccess(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const employeeId = BigInt(String(req.params.employeeId))
    const data = UpdateEmployeeWalletAccessSchema.parse(req.body)

    const employee = await prisma.companyEmployee.findUnique({ where: { id: employeeId } })
    if (!employee || employee.companyId !== companyId) { fail(res, 'Employee not found'); return }

    const updated = await prisma.companyEmployee.update({
      where: { id: employeeId },
      data: {
        ...(data.wallet_access_enabled !== undefined ? { walletAccessEnabled: data.wallet_access_enabled } : {}),
        ...(data.wallet_access_days_of_week !== undefined ? { walletAccessDaysOfWeek: data.wallet_access_days_of_week } : {}),
        ...(data.wallet_access_time_from    !== undefined ? { walletAccessTimeFrom:   data.wallet_access_time_from }    : {}),
        ...(data.wallet_access_time_to      !== undefined ? { walletAccessTimeTo:     data.wallet_access_time_to }      : {}),
      },
    })

    ok(res, {
      wallet_access_enabled: updated.walletAccessEnabled,
      wallet_access_days_of_week: updated.walletAccessDaysOfWeek,
      wallet_access_time_from:    updated.walletAccessTimeFrom,
      wallet_access_time_to:      updated.walletAccessTimeTo,
    }, 'Employee wallet access updated')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Employee-initiated access requests ─────────────────────────────────────

// GET /admin/companies/:id/access-requests?status=pending
export async function listAccessRequests(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const status = req.query.status ? String(req.query.status) : undefined

    const requests = await prisma.employeeAccessRequest.findMany({
      where: { companyId, ...(status ? { status: status as any } : {}) },
      orderBy: { requestedAt: 'desc' },
      include: { employee: { select: { jobTitle: true, user: { select: { name: true, email: true } } } } },
    })

    ok(res, requests.map((r) => ({
      id: r.id.toString(),
      employee_id: r.employeeId.toString(),
      employee_name: r.employee.user.name,
      employee_email: r.employee.user.email ?? '',
      request_type: r.requestType,
      status: r.status,
      note: r.note,
      requested_at: r.requestedAt.toISOString(),
      decided_at: r.decidedAt?.toISOString() ?? null,
      decision_note: r.decisionNote,
    })))
  } catch (err) {
    serverError(res, err)
  }
}

const DecideAccessRequestSchema = z.object({
  approve: z.boolean(),
  note: z.string().optional(),
})

// PATCH /admin/companies/:id/access-requests/:requestId/decide
export async function decideAccessRequest(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const requestId = BigInt(String(req.params.requestId))
    const { approve, note } = DecideAccessRequestSchema.parse(req.body)

    const request = await prisma.employeeAccessRequest.findUnique({ where: { id: requestId } })
    if (!request || request.companyId !== companyId) { fail(res, 'Access request not found'); return }
    if (request.status !== 'pending') { fail(res, 'This request has already been decided'); return }

    await prisma.$transaction([
      prisma.employeeAccessRequest.update({
        where: { id: requestId },
        data: {
          status: approve ? 'approved' : 'denied',
          decidedAt: new Date(),
          decidedById: adminId(req),
          decisionNote: note ?? null,
        },
      }),
      // Approving grants access outright — the admin can still fine-tune
      // limits/windows afterwards via the pool-access/wallet-access
      // endpoints above; this just flips the same switch those do.
      ...(approve
        ? [prisma.companyEmployee.update({
            where: { id: request.employeeId },
            data: request.requestType === 'pool_car'
              ? { poolAccessEnabled: true }
              : { walletAccessEnabled: true },
          })]
        : []),
    ])

    ok(res, {}, approve ? 'Request approved' : 'Request denied')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Pool car tracking ───────────────────────────────────────────────────────
// A company can only ever see three kinds of car: its own pool vehicles,
// vehicles from a company that has actively shared with it (a
// PoolSharingAgreement where THIS company is the partner), and publicly
// available cars (companyId null — independent drivers, not any org's
// private fleet). Every other company's pool vehicles are invisible here by
// construction, not by a filter that could be forgotten.

// GET /admin/companies/:id/pool-tracking
export async function getPoolTracking(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return

    const sharedFrom = await prisma.poolSharingAgreement.findMany({
      where: { partnerCompanyId: companyId, isActive: true },
      select: { companyId: true },
    })
    const sharedCompanyIds = sharedFrom.map((s) => s.companyId)

    const rides = await prisma.ride.findMany({
      where: {
        status: 'in_progress',
        vehicleId: { not: null },
        vehicle: {
          OR: [
            { companyId },                            // own
            { companyId: { in: sharedCompanyIds } },   // shared with this company
            { companyId: null },                       // publicly available
          ],
        },
      },
      select: {
        id: true, driverId: true,
        originAddress: true, destinationAddress: true,
        vehicle: {
          select: {
            companyId: true, licensePlate: true,
            model: { select: { title: true } },
            company: { select: { name: true } },
          },
        },
        tracking: { orderBy: { recordedAt: 'desc' }, take: 1, select: { lat: true, lng: true, speedKmh: true, recordedAt: true } },
      },
    })

    const driverIds = [...new Set(rides.map((r) => r.driverId))]
    const drivers = await prisma.user.findMany({ where: { id: { in: driverIds } }, select: { id: true, name: true } })
    const driverMap = Object.fromEntries(drivers.map((d) => [d.id, d]))

    ok(res, rides.map((r) => {
      const pos = r.tracking[0]
      const vehicleCompanyId = r.vehicle?.companyId ?? null
      const ownership = vehicleCompanyId === companyId ? 'own' : vehicleCompanyId === null ? 'public' : 'shared'
      return {
        ride_id:           r.id,
        driver_name:       driverMap[r.driverId]?.name ?? '',
        vehicle_plate:     r.vehicle?.licensePlate ?? '',
        vehicle_model:     r.vehicle?.model.title ?? '',
        ownership,
        shared_by_company: ownership === 'shared' ? (r.vehicle?.company?.name ?? null) : null,
        origin:            r.originAddress,
        destination:       r.destinationAddress,
        lat:               pos?.lat ?? null,
        lng:               pos?.lng ?? null,
        speed_kmh:         pos?.speedKmh ?? null,
        recorded_at:       pos?.recordedAt.toISOString() ?? null,
      }
    }))
  } catch (err) {
    serverError(res, err)
  }
}
