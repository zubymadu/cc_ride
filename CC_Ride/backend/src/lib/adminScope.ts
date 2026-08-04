// Shared tenant-isolation helper for the admin API.
//
// requireAdmin (src/middleware/adminAuth.ts) only checks *authentication* —
// does the caller have a valid scope at all. It does not check
// *authorization* — does the caller's scope match the specific
// company/branch they're asking for. Every admin controller that reads or
// writes company-scoped data must call one of these before trusting a
// companyId, whether it comes from a URL param, request body, or a row
// that was just loaded from the DB.

import { Request, Response } from 'express'
import { fail } from './response'

/** True if this admin can act on the given company: either a platform
 *  super-admin, or a scoped admin whose own scopeCompanyId matches. */
export function canAccessCompany(req: Request, companyId: string | null | undefined): boolean {
  if (!companyId) return false
  if (req.admin?.isSuperAdmin) return true
  return req.admin?.scopeCompanyId === companyId
}

/** Asserts access and writes a 403 if it fails. Returns false (and has
 *  already responded) when the caller should stop handling the request —
 *  callers should `if (!assertCompanyScope(...)) return`. */
export function assertCompanyScope(req: Request, res: Response, companyId: string | null | undefined): boolean {
  if (canAccessCompany(req, companyId)) return true
  fail(res, 'You do not have access to this company', 403)
  return false
}

/** The companyId a scoped admin is allowed to write into a new/updated
 *  row — always their own scope, never trusted from the request. Returns
 *  null for a super-admin, meaning "use whatever the request specified". */
export function ownCompanyIdOrNull(req: Request): string | null {
  return req.admin?.isSuperAdmin ? null : (req.admin?.scopeCompanyId ?? null)
}

/** Prisma `where` fragment to append when listing company-scoped rows:
 *  a super-admin gets `{}` (no filter), a scoped admin gets
 *  `{ companyId: <their own scope> }`. Use as
 *  `where: { ...companyScopeWhere(req), ...otherFilters }`. */
export function companyScopeWhere(req: Request): { companyId: string } | Record<string, never> {
  if (req.admin?.isSuperAdmin) return {}
  return { companyId: req.admin?.scopeCompanyId ?? '__no_scope__' }
}
