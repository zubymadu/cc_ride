import { Request, Response } from 'express'
import { fail } from './response'

/**
 * Non-super-admins are scoped to a single company (scopeCompanyId set at login).
 * Returns false (and writes a 403) when a scoped admin tries to touch a company
 * that isn't theirs — callers should stop processing when this returns false.
 */
export function assertCompanyScope(req: Request, res: Response, companyId: string): boolean {
  if (req.admin?.isSuperAdmin) return true
  if (req.admin?.scopeCompanyId === companyId) return true
  fail(res, 'Not authorised for this company', 403)
  return false
}

/**
 * Branch-scoped admins (scopeBranchId set, in addition to scopeCompanyId) are
 * further restricted to a single branch within their company. Company-wide
 * scoped admins (scopeBranchId null) and super-admins are unaffected.
 *
 * `branchId` is the resource's own branch (null if the resource has no branch
 * association at all) — a branch-scoped admin cannot see branchless / other
 * branches' resources.
 */
export function assertBranchScope(req: Request, res: Response, branchId: bigint | null): boolean {
  if (req.admin?.isSuperAdmin) return true
  if (!req.admin?.scopeBranchId) return true // not branch-restricted
  if (branchId !== null && req.admin.scopeBranchId === branchId.toString()) return true
  fail(res, 'Not authorised for this branch', 403)
  return false
}

/** Prisma where-clause fragment that restricts a branch-having resource to the
 * requester's own branch, for LIST endpoints. Empty object for super-admins
 * and company-wide scoped admins (no extra filtering needed). */
export function branchWhereFilter(req: Request): { branchId?: bigint } {
  if (req.admin?.isSuperAdmin) return {}
  if (!req.admin?.scopeBranchId) return {}
  return { branchId: BigInt(req.admin.scopeBranchId) }
}

/** Same as branchWhereFilter, but for filtering the CompanyBranch table
 * itself (whose own primary key is the branch id, not a `branchId` FK). */
export function ownBranchWhereFilter(req: Request): { id?: bigint } {
  if (req.admin?.isSuperAdmin) return {}
  if (!req.admin?.scopeBranchId) return {}
  return { id: BigInt(req.admin.scopeBranchId) }
}

/**
 * Company-wide administrative actions (creating a new branch/region, or
 * creating other admin accounts) are restricted to super-admins and
 * company-wide scoped admins — a single-branch-scoped admin cannot perform
 * them, even within their own company.
 */
export function assertNotBranchRestricted(req: Request, res: Response): boolean {
  if (req.admin?.isSuperAdmin) return true
  if (!req.admin?.scopeBranchId) return true
  fail(res, 'This action is not available to branch-level admins', 403)
  return false
}
