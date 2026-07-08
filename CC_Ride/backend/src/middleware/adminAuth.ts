import { Request, Response, NextFunction } from 'express'
import jwt from 'jsonwebtoken'
import { fail } from '../lib/response'

export interface AdminPayload {
  id: string
  username: string
  email: string
  isSuperAdmin: boolean
  // Scoped admins (company / branch level)
  scopeCompanyId?: string | null
  scopeBranchId?:  string | null
}

declare global {
  namespace Express {
    interface Request { admin?: AdminPayload }
  }
}

export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization
  if (!header?.startsWith('Bearer ')) { fail(res, 'Admin authentication required', 401); return }
  try {
    const payload = jwt.verify(header.slice(7), process.env.JWT_SECRET!) as AdminPayload
    // Both super-admins and scoped admins are allowed through — controllers
    // enforce scope by checking req.admin.isSuperAdmin / scopeCompanyId / scopeBranchId
    if (!payload.isSuperAdmin && !payload.scopeCompanyId) {
      fail(res, 'Admin access required', 403); return
    }
    req.admin = payload
    next()
  } catch {
    fail(res, 'Invalid or expired token', 401)
  }
}

export function requireSuperAdmin(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization
  if (!header?.startsWith('Bearer ')) { fail(res, 'Admin authentication required', 401); return }
  try {
    const payload = jwt.verify(header.slice(7), process.env.JWT_SECRET!) as AdminPayload
    if (!payload.isSuperAdmin) { fail(res, 'Super-admin access required', 403); return }
    req.admin = payload
    next()
  } catch {
    fail(res, 'Invalid or expired token', 401)
  }
}
