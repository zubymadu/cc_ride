// Shared employee-registration logic — used by both the single-row admin
// endpoint and the CSV bulk-import endpoint, so the NIN/passport dedup rules
// only ever live in one place.
import bcrypt from 'bcryptjs'
import crypto from 'crypto'
import { prisma } from './prisma'
import { sendMail } from './mail'
import { resolveRequiredIdentity } from './identity'

const INVITE_TTL_HOURS = 168 // 7 days — matches the AdminUser invite flow

export interface RegisterEmployeeInput {
  name: string
  work_email: string
  mobile: string
  nin?: string
  passport_number?: string
  personal_email?: string
  role: 'employee' | 'manager' | 'company_admin' | 'company_finance' | 'company_hr'
  department_id?: string | null
}

export type RegisterEmployeeResult =
  | { ok: true; employeeId: string; userId: string; claimUrl: string | null; emailed: boolean; alreadyHadAccount: boolean }
  | { ok: false; error: string }

// Shared by both the initial invite (registerEmployee, below) and
// resendActivationEmail (used when reinstating a terminated employee) — a
// fresh token/expiry is issued every time this is called rather than reusing
// whatever was last on the User row, since a previously-sent link may well
// have already expired (7-day TTL) by the time someone re-sends it.
export async function issueAndEmailActivationLink(
  userId: string,
  workEmail: string,
  name: string,
  companyName: string,
): Promise<{ claimUrl: string; emailed: boolean }> {
  const inviteToken = crypto.randomBytes(32).toString('hex')
  await prisma.user.update({
    where: { id: userId },
    data: { inviteToken, inviteExpiresAt: new Date(Date.now() + INVITE_TTL_HOURS * 3600 * 1000) },
  })
  const claimUrl = `${process.env.ADMIN_URL ?? 'https://admin.ccride.ng'}/activate/${inviteToken}`
  const emailed = await sendMail(
    workEmail,
    `You've been added to ${companyName} on CC Ride`,
    `<p>Hi ${name},</p><p>You've been added to ${companyName} on CC Ride. Set up your account here:</p><p><a href="${claimUrl}">${claimUrl}</a></p><p>This link expires in 7 days.</p>`,
  )
  return { claimUrl, emailed }
}

export async function registerEmployee(
  companyId: string,
  companyName: string,
  data: RegisterEmployeeInput,
): Promise<RegisterEmployeeResult> {
  const identity = resolveRequiredIdentity(data.nin, data.passport_number)
  if (!identity.ok) return { ok: false, error: identity.error }

  try {
    let user = await prisma.user.findFirst({
      where: identity.nin ? { nin: identity.nin } : { passportNumber: identity.passportNumber! },
    })

    if (!user && data.personal_email) {
      user = await prisma.user.findFirst({ where: { email: data.personal_email } })
    }
    if (!user) {
      const byMobile = await prisma.user.findFirst({ where: { mobile: data.mobile } })
      if (byMobile) {
        return { ok: false, error: 'A different account already exists with this mobile number (matched under a different NIN/passport, or none on file) — resolve the conflict before registering' }
      }
    }

    if (user) {
      const existingMembership = await prisma.companyEmployee.findFirst({ where: { companyId, userId: user.id } })
      if (existingMembership) {
        return { ok: false, error: existingMembership.isActive ? 'This person is already an employee here' : 'This person was previously terminated — reactivate instead of re-registering' }
      }
      if (!user.nin && !user.passportNumber) {
        user = await prisma.user.update({
          where: { id: user.id },
          data: { nin: identity.nin, passportNumber: identity.passportNumber },
        })
      }
    } else {
      const randomHash = await bcrypt.hash(crypto.randomBytes(24).toString('hex'), 10)
      const inviteToken = crypto.randomBytes(32).toString('hex')
      user = await prisma.user.create({
        data: {
          name: data.name,
          email: data.personal_email ?? null,
          mobile: data.mobile,
          nin: identity.nin,
          passportNumber: identity.passportNumber,
          passwordHash: randomHash,
          status: 'pending_verification',
          referralCode: crypto.randomBytes(4).toString('hex').toUpperCase(),
          inviteToken,
          inviteExpiresAt: new Date(Date.now() + INVITE_TTL_HOURS * 3600 * 1000),
        },
      })
    }

    const employee = await prisma.companyEmployee.create({
      data: {
        companyId,
        userId: user.id,
        departmentId: data.department_id ? BigInt(data.department_id) : null,
        role: data.role,
        workEmail: data.work_email,
        isActive: true,
        joinedAt: new Date(),
      },
    })

    let claimUrl: string | null = null
    let emailed = false
    if (user.inviteToken) {
      claimUrl = `${process.env.ADMIN_URL ?? 'https://admin.ccride.ng'}/activate/${user.inviteToken}`
      emailed = await sendMail(
        data.work_email,
        `You've been added to ${companyName} on CC Ride`,
        `<p>Hi ${data.name},</p><p>You've been added to ${companyName} on CC Ride. Set up your account here:</p><p><a href="${claimUrl}">${claimUrl}</a></p><p>This link expires in 7 days.</p>`,
      )
    }

    return {
      ok: true,
      employeeId: employee.id.toString(),
      userId: user.id,
      claimUrl,
      emailed,
      alreadyHadAccount: claimUrl === null,
    }
  } catch (err: any) {
    if (err?.code === 'P2002') {
      const field = err?.meta?.target?.[0]
      if (field === 'nin') return { ok: false, error: 'A different account already exists with this NIN' }
      if (field === 'passport_number') return { ok: false, error: 'A different account already exists with this passport number' }
      return { ok: false, error: 'A user with this personal email already exists' }
    }
    return { ok: false, error: err?.message ?? 'Unexpected error' }
  }
}
