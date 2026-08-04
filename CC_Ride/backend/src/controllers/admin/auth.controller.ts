import { Request, Response } from 'express'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'

export async function adminLogin(req: Request, res: Response) {
  try {
    const { username, password } = req.body as { username: string; password: string }
    if (!username || !password) { fail(res, 'Username and password required'); return }

    const admin = await (prisma.adminUser as any).findFirst({
      where: { OR: [{ username }, { email: username }] },
      select: {
        id: true, username: true, email: true, passwordHash: true,
        isSuperAdmin: true, isActive: true,
        scopeCompanyId: true, scopeBranchId: true,
      },
    })
    if (!admin) { fail(res, 'Invalid credentials'); return }
    // No password set yet — this account was auto-provisioned by an invite
    // and hasn't been claimed. bcrypt.compare against a null hash is
    // undefined behavior, so check explicitly rather than relying on it to
    // just fail closed.
    if (!admin.passwordHash) { fail(res, 'This account has not been activated yet — check your email for a setup link'); return }

    const valid = await bcrypt.compare(password, admin.passwordHash)
    if (!valid) { fail(res, 'Invalid credentials'); return }

    if (!admin.isActive) { fail(res, 'Account disabled'); return }

    const adminId = admin.id.toString()

    const token = jwt.sign(
      {
        id: adminId, username: admin.username, email: admin.email,
        isSuperAdmin: admin.isSuperAdmin,
        scopeCompanyId: admin.scopeCompanyId ?? null,
        scopeBranchId:  admin.scopeBranchId?.toString() ?? null,
      },
      process.env.JWT_SECRET!,
      { expiresIn: '12h' },
    )

    await prisma.adminUser.update({ where: { id: admin.id }, data: { lastLoginAt: new Date() } })

    // Resolved once at login and handed to the client so the console can
    // personalise the whole session (sidebar branding, welcome banner)
    // without an extra round-trip on every page load.
    const company = admin.scopeCompanyId
      ? await prisma.company.findUnique({ where: { id: admin.scopeCompanyId }, select: { name: true, logoUrl: true } })
      : null

    ok(res, {
      token,
      admin: {
        id: adminId, username: admin.username, email: admin.email,
        isSuperAdmin: admin.isSuperAdmin,
        scopeCompanyId: admin.scopeCompanyId ?? null,
        scopeBranchId:  admin.scopeBranchId?.toString() ?? null,
        companyName:     company?.name ?? null,
        companyLogoUrl:  company?.logoUrl ?? null,
      },
    })
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Invite claim flow ──────────────────────────────────────────────────────
// Public — no requireAdmin, since the whole point is letting a
// not-yet-credentialed company admin get in for the first time.

// GET /admin/auth/invite/:token — lets the claim page show "You're setting
// up an admin account for {company}" before asking for a password.
export async function getInviteInfo(req: Request, res: Response) {
  try {
    const token = String(req.params.token)
    const admin = await prisma.adminUser.findUnique({
      where: { inviteToken: token },
      select: { email: true, inviteExpiresAt: true, scopeCompanyId: true, passwordHash: true },
    })
    if (!admin || admin.passwordHash) { fail(res, 'Invite not found or already used'); return }
    if (!admin.inviteExpiresAt || admin.inviteExpiresAt < new Date()) { fail(res, 'This invite link has expired'); return }

    const company = admin.scopeCompanyId
      ? await prisma.company.findUnique({ where: { id: admin.scopeCompanyId }, select: { name: true } })
      : null

    ok(res, { email: admin.email, company_name: company?.name ?? null })
  } catch (err) {
    serverError(res, err)
  }
}

const ClaimInviteSchema = z.object({
  token:    z.string().min(1),
  username: z.string().min(3).max(30).regex(/^[a-z0-9_.-]+$/i, 'Letters, numbers, and . _ - only').optional(),
  password: z.string().min(8, 'Password must be at least 8 characters'),
})

// POST /admin/auth/claim-invite
export async function claimInvite(req: Request, res: Response) {
  try {
    const data = ClaimInviteSchema.parse(req.body)

    const admin = await prisma.adminUser.findUnique({ where: { inviteToken: data.token } })
    if (!admin || admin.passwordHash) { fail(res, 'Invite not found or already used'); return }
    if (!admin.inviteExpiresAt || admin.inviteExpiresAt < new Date()) { fail(res, 'This invite link has expired'); return }

    if (data.username && data.username !== admin.username) {
      const taken = await prisma.adminUser.findUnique({ where: { username: data.username } })
      if (taken) { fail(res, 'That username is already taken'); return }
    }

    const passwordHash = await bcrypt.hash(data.password, 12)
    await prisma.adminUser.update({
      where: { id: admin.id },
      data: {
        passwordHash,
        username: data.username ?? admin.username,
        inviteToken: null,
        inviteExpiresAt: null,
      },
    })

    ok(res, { username: data.username ?? admin.username }, 'Account activated — you can now sign in')
  } catch (err) {
    serverError(res, err)
  }
}
