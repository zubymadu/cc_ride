import { Request, Response } from 'express'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'
import { assertCompanyScope } from '../../lib/adminScope'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const db = prisma as any
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const adminDb = prisma.adminUser as any

// ─── Regions ─────────────────────────────────────────────────────────────────

export async function listRegions(req: Request, res: Response) {
  try {
    const companyId = String(req.params.companyId)
    if (!assertCompanyScope(req, res, companyId)) return
    const regions = await db.companyRegion.findMany({
      where: { companyId },
      orderBy: { name: 'asc' },
      include: { _count: { select: { branches: true } } },
    })
    ok(res, regions.map((r: any) => ({
      id: r.id.toString(), company_id: r.companyId, name: r.name,
      code: r.code, is_active: r.isActive, branch_count: r._count.branches,
      created_at: r.createdAt,
    })))
  } catch (err) { serverError(res, err) }
}

export async function createRegion(req: Request, res: Response) {
  try {
    const companyId = String(req.params.companyId)
    if (!assertCompanyScope(req, res, companyId)) return
    const { name, code } = req.body as { name: string; code?: string }
    if (!name) { fail(res, 'Region name is required'); return }

    const region = await db.companyRegion.create({
      data: { companyId, name, code: code ?? null },
    })
    ok(res, { id: region.id.toString(), name: region.name, code: region.code })
  } catch (err: any) {
    if (err.code === 'P2002') { fail(res, 'A region with that name already exists'); return }
    serverError(res, err)
  }
}

// ─── Branches ────────────────────────────────────────────────────────────────

export async function listBranches(req: Request, res: Response) {
  try {
    const companyId = String(req.params.companyId)
    if (!assertCompanyScope(req, res, companyId)) return
    const branches = await db.companyBranch.findMany({
      where: { companyId },
      orderBy: [{ regionId: 'asc' }, { name: 'asc' }],
      include: {
        region: { select: { id: true, name: true } },
        _count: { select: { employees: { where: { isActive: true } }, bookings: true } },
      },
    })
    ok(res, branches.map((b: any) => ({
      id:               b.id.toString(),
      company_id:       b.companyId,
      region_id:        b.regionId?.toString() ?? null,
      region_name:      b.region?.name ?? null,
      name:             b.name,
      code:             b.code,
      address:          b.address,
      city:             b.city,
      state:            b.state,
      contact_name:     b.contactName,
      contact_phone:    b.contactPhone,
      contact_email:    b.contactEmail,
      is_headquarters:  b.isHeadquarters,
      is_active:        b.isActive,
      billed_separately: b.billedSeparately,
      wallet_balance:   Number(b.walletBalance),
      employee_count:   b._count.employees,
      booking_count:    b._count.bookings,
      created_at:       b.createdAt,
    })))
  } catch (err) { serverError(res, err) }
}

export async function createBranch(req: Request, res: Response) {
  try {
    const companyId = String(req.params.companyId)
    if (!assertCompanyScope(req, res, companyId)) return
    const {
      name, code, region_id, address, city, state,
      contact_name, contact_phone, contact_email,
      is_headquarters, billed_separately,
    } = req.body as {
      name: string; code?: string; region_id?: string
      address?: string; city?: string; state?: string
      contact_name?: string; contact_phone?: string; contact_email?: string
      is_headquarters?: boolean; billed_separately?: boolean
    }
    if (!name) { fail(res, 'Branch name is required'); return }

    const branch = await db.companyBranch.create({
      data: {
        companyId,
        regionId:        region_id ? BigInt(region_id) : null,
        name,
        code:            code ?? null,
        address:         address ?? null,
        city:            city ?? null,
        state:           state ?? 'Lagos',
        contactName:     contact_name ?? null,
        contactPhone:    contact_phone ?? null,
        contactEmail:    contact_email ?? null,
        isHeadquarters:  is_headquarters ?? false,
        billedSeparately: billed_separately ?? false,
      },
    })
    ok(res, { id: branch.id.toString(), name: branch.name, code: branch.code })
  } catch (err: any) {
    if (err.code === 'P2002') { fail(res, 'Branch code already exists for this company'); return }
    serverError(res, err)
  }
}

export async function updateBranch(req: Request, res: Response) {
  try {
    const branchId = req.params.branchId as string
    const {
      name, code, region_id, address, city, state,
      contact_name, contact_phone, contact_email,
      is_headquarters, is_active, billed_separately,
    } = req.body as any

    const existing = await db.companyBranch.findUnique({ where: { id: BigInt(branchId) }, select: { companyId: true } })
    if (!existing) { fail(res, 'Branch not found'); return }
    if (!assertCompanyScope(req, res, existing.companyId)) return

    const branch = await db.companyBranch.update({
      where: { id: BigInt(branchId) },
      data: {
        ...(name             !== undefined && { name }),
        ...(code             !== undefined && { code }),
        ...(region_id        !== undefined && { regionId: region_id ? BigInt(region_id) : null }),
        ...(address          !== undefined && { address }),
        ...(city             !== undefined && { city }),
        ...(state            !== undefined && { state }),
        ...(contact_name     !== undefined && { contactName: contact_name }),
        ...(contact_phone    !== undefined && { contactPhone: contact_phone }),
        ...(contact_email    !== undefined && { contactEmail: contact_email }),
        ...(is_headquarters  !== undefined && { isHeadquarters: is_headquarters }),
        ...(is_active        !== undefined && { isActive: is_active }),
        ...(billed_separately !== undefined && { billedSeparately: billed_separately }),
      },
    })
    ok(res, { id: branch.id.toString(), name: branch.name })
  } catch (err) { serverError(res, err) }
}

// ─── Branch wallet credit ─────────────────────────────────────────────────────

export async function creditBranch(req: Request, res: Response) {
  try {
    const branchId = req.params.branchId as string
    const { amount, payment_method, reference, note } = req.body as {
      amount: number; payment_method: string; reference?: string; note?: string
    }
    const adminId = BigInt((req as any).admin.id)

    if (!amount || amount <= 0) { fail(res, 'Amount must be greater than zero'); return }
    if (!payment_method) { fail(res, 'Payment method is required'); return }

    const branch = await db.companyBranch.findUnique({
      where: { id: BigInt(branchId) },
      select: { walletBalance: true, name: true },
    })
    if (!branch) { fail(res, 'Branch not found'); return }

    const newBalance = Number(branch.walletBalance) + Number(amount)

    await prisma.$transaction([
      db.companyBranch.update({
        where: { id: BigInt(branchId) },
        data:  { walletBalance: newBalance },
      }),
      db.branchCredit.create({
        data: {
          branchId:      BigInt(branchId),
          amount:        Number(amount),
          balanceAfter:  newBalance,
          paymentMethod: payment_method,
          reference:     reference ?? null,
          note:          note ?? null,
          creditedById:  adminId,
        },
      }),
    ])

    ok(res, { balance: newBalance }, `₦${Number(amount).toLocaleString()} credited to ${branch.name}`)
  } catch (err) { serverError(res, err) }
}

export async function getBranchCreditLedger(req: Request, res: Response) {
  try {
    const branchId = req.params.branchId as string
    const page  = Math.max(1, parseInt(req.query.page as string) || 1)
    const limit = 20

    const branchScope = await db.companyBranch.findUnique({ where: { id: BigInt(branchId) }, select: { companyId: true } })
    if (!branchScope) { fail(res, 'Branch not found'); return }
    if (!assertCompanyScope(req, res, branchScope.companyId)) return

    const [branch, credits, total] = await Promise.all([
      db.companyBranch.findUnique({ where: { id: BigInt(branchId) }, select: { walletBalance: true } }),
      db.branchCredit.findMany({
        where:   { branchId: BigInt(branchId) },
        orderBy: { createdAt: 'desc' },
        skip:    (page - 1) * limit,
        take:    limit,
        include: { creditedBy: { select: { username: true } } },
      }),
      db.branchCredit.count({ where: { branchId: BigInt(branchId) } }),
    ])

    if (!branch) { fail(res, 'Branch not found'); return }

    ok(res, {
      wallet_balance: Number(branch.walletBalance),
      credits: credits.map((c: any) => ({
        id:             c.id.toString(),
        amount:         Number(c.amount),
        balance_after:  Number(c.balanceAfter),
        payment_method: c.paymentMethod,
        reference:      c.reference,
        note:           c.note,
        credited_by:    c.creditedBy.username,
        created_at:     c.createdAt,
      })),
      total, page, pages: Math.ceil(total / limit),
    })
  } catch (err) { serverError(res, err) }
}

// ─── Branch admin users ───────────────────────────────────────────────────────

export async function listBranchAdmins(req: Request, res: Response) {
  try {
    const companyId = req.params.companyId as string
    if (!assertCompanyScope(req, res, companyId)) return
    const branchId  = req.query.branch_id as string | undefined
    const admins = await adminDb.findMany({
      where: { scopeCompanyId: companyId, scopeBranchId: branchId ? BigInt(branchId) : undefined },
      select: { id: true, username: true, email: true, isActive: true, lastLoginAt: true, scopeBranchId: true, createdAt: true },
      orderBy: { createdAt: 'asc' },
    })
    ok(res, admins.map((a: any) => ({
      id: a.id.toString(), username: a.username, email: a.email,
      is_active: a.isActive, last_login_at: a.lastLoginAt,
      branch_id: a.scopeBranchId?.toString() ?? null, created_at: a.createdAt,
    })))
  } catch (err) { serverError(res, err) }
}

export async function createBranchAdmin(req: Request, res: Response) {
  try {
    const companyId = String(req.params.companyId)
    if (!assertCompanyScope(req, res, companyId)) return
    const { username, email, password, branch_id } = req.body as {
      username: string; email: string; password: string; branch_id?: string
    }
    if (!username || !email || !password) { fail(res, 'username, email and password are required'); return }

    // companyId above is already verified as this admin's own scope (or a
    // super-admin's free choice) — but branch_id is a separate id from the
    // request body, so it must be checked independently to belong to that
    // same company. Otherwise a scoped admin could scope the new admin to
    // a branch under a different company while keeping scopeCompanyId
    // pinned to their own — a mismatched, confusing privilege that other
    // branch-scoped checks elsewhere assume can't happen.
    if (branch_id) {
      const branch = await db.companyBranch.findUnique({ where: { id: BigInt(branch_id) }, select: { companyId: true } })
      if (!branch || branch.companyId !== companyId) { fail(res, 'Branch does not belong to this company'); return }
    }

    const bcrypt = await import('bcryptjs')
    const hash   = await bcrypt.default.hash(password, 12)

    const admin = await adminDb.create({
      data: {
        username, email,
        passwordHash:   hash,
        isSuperAdmin:   false,
        scopeCompanyId: companyId,
        scopeBranchId:  branch_id ? BigInt(branch_id) : null,
      },
      select: { id: true, username: true, email: true },
    })
    ok(res, { id: admin.id.toString(), username: admin.username, email: admin.email })
  } catch (err: any) {
    if (err.code === 'P2002') { fail(res, 'Username or email already in use'); return }
    serverError(res, err)
  }
}
