// Auto-provisions a scoped company admin when an organisation signs on,
// instead of requiring a super-admin to manually create one every time —
// the recurring "organisations join from time to time" onboarding case.
import crypto from 'crypto'
import { prisma } from './prisma'
import { sendMail } from './mail'

const INVITE_TTL_HOURS = 168 // 7 days

export async function provisionCompanyAdminInvite(companyId: string): Promise<void> {
  // A company may already have a scoped admin (e.g. reactivated after a
  // suspension) — don't silently create a second one and re-invite.
  const existing = await prisma.adminUser.findFirst({ where: { scopeCompanyId: companyId } })
  if (existing) return

  const company = await prisma.company.findUnique({ where: { id: companyId } })
  if (!company) return

  // AdminUser.email is globally unique — the same contact_email being reused
  // across a second company (a common thing to hit while testing, or when a
  // contact person genuinely manages more than one org) previously made the
  // adminUser.create() call below throw P2002 unconditionally, which killed
  // this whole function *before* sendMail was ever reached. The company was
  // still created successfully, so nothing about that failure was visible
  // except a silently-missing email. Reuse the existing unclaimed account
  // (rescoping + re-inviting it) rather than crashing, or bail out cleanly
  // with a clear log if it's already claimed by someone else.
  const emailConflict = await prisma.adminUser.findUnique({ where: { email: company.contactEmail } })
  if (emailConflict) {
    if (emailConflict.passwordHash) {
      console.error(
        `provisionCompanyAdminInvite: ${company.contactEmail} already belongs to a claimed admin account ` +
        `(scoped to company ${emailConflict.scopeCompanyId ?? 'none — super admin'}) — no invite sent for company ${companyId}.`,
      )
      return
    }
    const inviteToken = crypto.randomBytes(32).toString('hex')
    const inviteExpiresAt = new Date(Date.now() + INVITE_TTL_HOURS * 3600 * 1000)
    await prisma.adminUser.update({
      where: { id: emailConflict.id },
      data: { scopeCompanyId: companyId, inviteToken, inviteExpiresAt },
    })
    await sendInviteEmail(company, inviteToken)
    return
  }

  const baseUsername = (company.contactEmail.split('@')[0] ?? 'admin').toLowerCase().replace(/[^a-z0-9_.-]/g, '') || 'admin'
  let username = baseUsername
  let suffix = 1
  while (await prisma.adminUser.findUnique({ where: { username } })) {
    username = `${baseUsername}${suffix++}`
  }

  const inviteToken = crypto.randomBytes(32).toString('hex')
  const inviteExpiresAt = new Date(Date.now() + INVITE_TTL_HOURS * 3600 * 1000)

  await prisma.adminUser.create({
    data: {
      username,
      email: company.contactEmail,
      passwordHash: null,
      isSuperAdmin: false,
      scopeCompanyId: companyId,
      inviteToken,
      inviteExpiresAt,
    },
  })

  await sendInviteEmail(company, inviteToken)
}

async function sendInviteEmail(
  company: { contactEmail: string; contactName: string; name: string },
  inviteToken: string,
): Promise<void> {
  // Production's .env previously had ADMIN_URL literally set to
  // http://localhost:5174 (a leftover local-dev value), and this fallback
  // matched it — so even once that got fixed, any future deploy/environment
  // missing the var entirely would silently regress to a dead local URL in
  // a real invite email. Default to the actual production admin domain
  // instead; only genuinely local dev needs the localhost value, and that
  // should come from its own .env, not this fallback.
  const claimUrl = `${process.env.ADMIN_URL ?? 'https://admin.ccride.ng'}/claim-invite/${inviteToken}`
  await sendMail(
    company.contactEmail,
    `Set up your CC Ride admin account for ${company.name}`,
    `<p>Hi ${company.contactName},</p>
     <p>${company.name} has been approved on CC Ride. Set up your admin account to manage your organisation's rides, employees, and billing:</p>
     <p><a href="${claimUrl}">${claimUrl}</a></p>
     <p>This link expires in 7 days. If you didn't expect this email, you can ignore it.</p>`,
  ).catch((err) => console.error('provisionCompanyAdminInvite: sendMail failed:', err))
}
