import { Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'
import { dec } from '../../lib/naira'
import crypto from 'crypto'
import { sendMail } from '../../lib/mail'
import { resolveRequiredIdentity } from '../../lib/identity'

// ─── GET /corporate/employee/profile ─────────────────────────────────────────

export async function getEmployeeProfile(req: Request, res: Response) {
  try {
    const userId    = req.user.id
    const companyId = (req.query.company_id as string) || ''

    const membership = await prisma.companyEmployee.findFirst({
      where: { userId, companyId, isActive: true },
      include: {
        company:    { select: { name: true } },
        department: { select: { id: true, name: true } },
        costCentre: { select: { id: true, name: true, code: true } },
      },
    })

    if (!membership) {
      fail(res, 'Not a member of this company')
      return
    }

    // Monthly spend for this employee
    const now        = new Date()
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1)

    const spentThisMonth = await prisma.budgetTransaction.aggregate({
      where: { employeeId: userId, transactedAt: { gte: monthStart } },
      _sum: { amount: true },
    })

    // All cost centres for employee's dept (for selector in app)
    const costCentres = await prisma.costCentre.findMany({
      where: {
        companyId,
        ...(membership.departmentId ? { departmentId: membership.departmentId } : {}),
        isActive: true,
      },
      select: { id: true, name: true, code: true },
      orderBy: { name: 'asc' },
    })

    ok(res, {
      company_id:          companyId,
      company_name:        membership.company.name,
      department_id:       membership.departmentId?.toString() ?? '',
      department:          membership.department?.name ?? '',
      cost_centre_id:      membership.costCentreId?.toString() ?? '',
      cost_centre:         membership.costCentre?.name ?? '',
      role:                membership.role,
      job_title:           membership.jobTitle ?? '',
      monthly_spend_limit: dec(membership.monthlySpendLimit),
      monthly_spent:       dec(spentThisMonth._sum.amount),
      // Gates the "own-car driver" operating mode in the app — set by this
      // company's own admin via /corporate/employees/:id/approve-personal-vehicle.
      personal_vehicle_approved: membership.personalVehicleApproved,
      is_driver:           req.user.isDriver ?? false,
      cost_centres:        costCentres.map((c) => ({
        id:   c.id.toString(),
        name: c.name,
        code: c.code,
      })),
    })
  } catch (err) {
    serverError(res, err)
  }
}

// ─── GET /corporate/employees ─────────────────────────────────────────────────

export async function listEmployees(req: Request, res: Response) {
  try {
    const companyId = req.companyId!

    const members = await prisma.companyEmployee.findMany({
      where:   { companyId },
      orderBy: { invitedAt: 'desc' },
      include: {
        user:       { select: { name: true, email: true, mobile: true, profilePicUrl: true } },
        department: { select: { name: true } },
        costCentre: { select: { name: true } },
      },
    })

    ok(res, members.map((m) => ({
      id:                   m.id.toString(),
      user_id:              m.userId,
      name:                 m.user.name,
      email:                m.user.email ?? '',
      mobile:               m.user.mobile,
      profile_pic:          m.user.profilePicUrl ?? '',
      department:           m.department?.name ?? '',
      department_id:        m.departmentId?.toString() ?? '',
      cost_centre:          m.costCentre?.name ?? '',
      role:                 m.role,
      job_title:            m.jobTitle ?? '',
      monthly_spend_limit:  dec(m.monthlySpendLimit),
      is_active:            m.isActive,
      joined_at:            m.joinedAt?.toISOString() ?? '',
    })))
  } catch (err) {
    serverError(res, err)
  }
}

// ─── GET /corporate/departments ───────────────────────────────────────────────

export async function listDepartments(req: Request, res: Response) {
  try {
    // requireCompanyMember guarantees req.companyId before this handler
    // runs — assert rather than falling back to a client-supplied value.
    const companyId = req.companyId!

    const depts = await prisma.department.findMany({
      where:   { companyId, isActive: true },
      orderBy: { name: 'asc' },
    })

    ok(res, depts.map((d) => ({
      id:   d.id.toString(),
      name: d.name,
      code: d.code ?? '',
    })))
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /corporate/employees/invite ────────────────────────────────────────

const InviteSchema = z.object({
  company_id:      z.string().uuid(),
  name:            z.string().min(2),
  // The employer's correspondence address — used to send the invite, never
  // used to look up or create a User. See registerCompanyEmployee (the web
  // console's equivalent) for why: a person's work email having no
  // relationship to their personal signup email is the normal case.
  email:           z.string().email(),
  mobile:          z.string().min(7),
  nin:             z.string().optional(),
  passport_number: z.string().optional(),
  department_id:   z.string().optional(),
  role:            z.enum(['employee', 'manager', 'company_admin', 'company_finance', 'company_hr']).default('employee'),
})

export async function inviteEmployee(req: Request, res: Response) {
  try {
    const data       = InviteSchema.parse(req.body)
    const companyId  = req.companyId!

    const identity = resolveRequiredIdentity(data.nin, data.passport_number)
    if (!identity.ok) { fail(res, identity.error); return }

    // NIN/passport is the reliable match — email/mobile can each
    // legitimately differ between someone's personal account and what
    // their employer has on file.
    let user = await prisma.user.findFirst({
      where: identity.nin ? { nin: identity.nin } : { passportNumber: identity.passportNumber! },
    })
    if (!user) user = await prisma.user.findFirst({ where: { mobile: data.mobile } })

    // Create stub user if genuinely new
    if (!user) {
      const tempPassword = crypto.randomBytes(16).toString('hex')
      const bcrypt = await import('bcryptjs')
      user = await prisma.user.create({
        data: {
          name:           data.name,
          mobile:         data.mobile,
          countryCode:    '+234',
          nin:            identity.nin,
          passportNumber: identity.passportNumber,
          passwordHash:   await bcrypt.hash(tempPassword, 12),
          status:         'pending_verification',
          referralCode:   crypto.randomBytes(4).toString('hex').toUpperCase(),
        },
      })
    } else if (!user.nin && !user.passportNumber) {
      // Found by mobile, but the identity document wasn't on file yet —
      // backfill it now that we've actually been given one.
      user = await prisma.user.update({
        where: { id: user.id },
        data: { nin: identity.nin, passportNumber: identity.passportNumber },
      })
    }

    // Check not already a member
    const existing = await prisma.companyEmployee.findFirst({
      where: { companyId, userId: user.id },
    })
    if (existing) {
      fail(res, existing.isActive ? 'Employee already in company' : 'Employee was deactivated — reactivate instead')
      return
    }

    // Validate department if provided
    let deptId: bigint | null = null
    if (data.department_id) {
      const dept = await prisma.department.findFirst({
        where: { id: BigInt(data.department_id), companyId },
      })
      if (!dept) { fail(res, 'Department not found'); return }
      deptId = dept.id
    }

    await prisma.companyEmployee.create({
      data: {
        companyId,
        userId:       user.id,
        departmentId: deptId,
        role:         data.role as any,
        isActive:     true,
      },
    })

    // Send invitation email (fire-and-forget)
    _sendInviteEmail(data.email, data.name, companyId).catch(console.error)

    ok(res, { user_id: user.id }, 'Invitation sent successfully')
  } catch (err: any) {
    if (err?.code === 'P2002') {
      const field = err?.meta?.target?.[0]
      if (field === 'nin') { fail(res, 'A different account already exists with this NIN'); return }
      if (field === 'passport_number') { fail(res, 'A different account already exists with this passport number'); return }
      fail(res, 'A user with this mobile number already exists'); return
    }
    serverError(res, err)
  }
}

// ─── POST /corporate/employees/deactivate ────────────────────────────────────

export async function deactivateEmployee(req: Request, res: Response) {
  try {
    const { company_id: _cid, employee_id } = req.body as { company_id: string; employee_id: string }
    const companyId = req.companyId!

    const membership = await prisma.companyEmployee.findFirst({
      where: { id: BigInt(employee_id), companyId },
    })
    if (!membership) { fail(res, 'Employee not found'); return }

    await prisma.companyEmployee.update({
      where:  { id: membership.id },
      data:   { isActive: false, deactivatedAt: new Date() },
    })

    ok(res, { employee_id }, 'Employee deactivated')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

async function _sendInviteEmail(email: string, name: string, companyId: string) {
  const company = await prisma.company.findUnique({ where: { id: companyId }, select: { name: true } })

  await sendMail(
    email,
    `You've been invited to ${company?.name ?? 'a company'} on CC Ride`,
    `<p>Hi ${name},</p><p>You have been added to ${company?.name} on CC Ride. Download the app to get started.</p>`,
  )
}
