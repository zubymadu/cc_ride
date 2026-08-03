/**
 * Admin — Branch fleet-sharing partnerships
 *
 * A one-directional grant: the owner branch shares its pool driver/vehicle
 * fleet with a partner branch's employees. E.g. a Lagos branch can share with
 * one partner org's branch while an Abuja branch of the same company shares
 * with none.
 */
import { Request, Response } from 'express'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'
import { assertCompanyScope, assertBranchScope } from '../../lib/adminScope'

// ─── GET /admin/companies/:companyId/branches/:branchId/partnerships ──────────
// Returns both directions: branches this branch shares its fleet WITH, and
// branches that share their fleet WITH this branch.

export async function listBranchPartnerships(req: Request, res: Response) {
  try {
    const companyId = String(req.params.companyId)
    const branchId   = String(req.params.branchId)
    if (!assertCompanyScope(req, res, companyId)) return
    if (!assertBranchScope(req, res, BigInt(branchId))) return

    const branch = await prisma.companyBranch.findFirst({ where: { id: BigInt(branchId), companyId } })
    if (!branch) { fail(res, 'Branch not found'); return }

    const branchSelect = {
      id: true, name: true, code: true,
      company: { select: { id: true, name: true } },
    }

    const [sharesFleetWith, receivesFleetFrom] = await Promise.all([
      prisma.branchPartnership.findMany({
        where:   { ownerBranchId: branch.id, isActive: true },
        include: { partnerBranch: { select: branchSelect } },
        orderBy: { createdAt: 'desc' },
      }),
      prisma.branchPartnership.findMany({
        where:   { partnerBranchId: branch.id, isActive: true },
        include: { ownerBranch: { select: branchSelect } },
        orderBy: { createdAt: 'desc' },
      }),
    ])

    ok(res, {
      shares_fleet_with: sharesFleetWith.map((p) => ({
        partnership_id: p.id.toString(),
        branch_id:      p.partnerBranch.id.toString(),
        branch_name:    p.partnerBranch.name,
        company_name:   p.partnerBranch.company.name,
        created_at:     p.createdAt.toISOString(),
      })),
      receives_fleet_from: receivesFleetFrom.map((p) => ({
        partnership_id: p.id.toString(),
        branch_id:      p.ownerBranch.id.toString(),
        branch_name:    p.ownerBranch.name,
        company_name:   p.ownerBranch.company.name,
        created_at:     p.createdAt.toISOString(),
      })),
    })
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /admin/companies/:companyId/branches/:branchId/partnerships ─────────
// body: { partner_branch_id } — this branch grants fleet access to another
// branch, which may belong to a different participating organisation.

export async function createBranchPartnership(req: Request, res: Response) {
  try {
    const companyId = String(req.params.companyId)
    const branchId   = String(req.params.branchId)
    if (!assertCompanyScope(req, res, companyId)) return
    if (!assertBranchScope(req, res, BigInt(branchId))) return

    const branch = await prisma.companyBranch.findFirst({ where: { id: BigInt(branchId), companyId } })
    if (!branch) { fail(res, 'Branch not found'); return }

    const { partner_branch_id } = req.body as { partner_branch_id: string }
    if (!partner_branch_id) { fail(res, 'partner_branch_id is required'); return }
    if (partner_branch_id === branchId) { fail(res, 'A branch cannot partner with itself'); return }

    const partnerBranch = await prisma.companyBranch.findUnique({ where: { id: BigInt(partner_branch_id) } })
    if (!partnerBranch) { fail(res, 'Partner branch not found'); return }

    const adminId = req.admin?.id ? BigInt(req.admin.id) : null

    const partnership = await prisma.branchPartnership.upsert({
      where: {
        ownerBranchId_partnerBranchId: { ownerBranchId: branch.id, partnerBranchId: partnerBranch.id },
      },
      create: {
        ownerBranchId:   branch.id,
        partnerBranchId: partnerBranch.id,
        createdById:     adminId,
      },
      update: { isActive: true },
    })

    ok(res, { partnership_id: partnership.id.toString() }, `Fleet sharing enabled with ${partnerBranch.name}`)
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /admin/companies/:companyId/branches/:branchId/partnerships/revoke ──
// body: { partnership_id }

export async function revokeBranchPartnership(req: Request, res: Response) {
  try {
    const companyId = String(req.params.companyId)
    const branchId   = String(req.params.branchId)
    if (!assertCompanyScope(req, res, companyId)) return
    if (!assertBranchScope(req, res, BigInt(branchId))) return

    const { partnership_id } = req.body as { partnership_id: string }
    if (!partnership_id) { fail(res, 'partnership_id is required'); return }

    const partnership = await prisma.branchPartnership.findUnique({ where: { id: BigInt(partnership_id) } })
    if (!partnership || partnership.ownerBranchId.toString() !== branchId) {
      fail(res, 'Partnership not found for this branch'); return
    }

    await prisma.branchPartnership.update({ where: { id: partnership.id }, data: { isActive: false } })

    ok(res, { partnership_id }, 'Fleet sharing revoked')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── GET /admin/branches/search?q= ─────────────────────────────────────────────
// Cross-company branch lookup, used when picking a partner branch to share
// fleet access with.

export async function searchBranches(req: Request, res: Response) {
  try {
    const q = String(req.query.q ?? '').trim()
    if (q.length < 2) { ok(res, []); return }

    const branches = await prisma.companyBranch.findMany({
      where: {
        isActive: true,
        OR: [
          { name: { contains: q, mode: 'insensitive' } },
          { company: { name: { contains: q, mode: 'insensitive' } } },
        ],
      },
      take:    10,
      select:  { id: true, name: true, code: true, company: { select: { id: true, name: true } } },
    })

    ok(res, branches.map((b) => ({
      branch_id:    b.id.toString(),
      branch_name:  b.name,
      branch_code:  b.code,
      company_id:   b.company.id,
      company_name: b.company.name,
    })))
  } catch (err) {
    serverError(res, err)
  }
}
