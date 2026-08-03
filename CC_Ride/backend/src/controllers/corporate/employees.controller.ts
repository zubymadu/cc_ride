import { Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'
import { dec } from '../../lib/naira'
import { sendInviteEmail } from '../../lib/mailer'
import { parseCsv } from '../../lib/csv'
import { importDepartmentsForCompany, importEmployeesForCompany } from '../../lib/companyImport'
import { findOrCreateStubUser } from '../../lib/stubUser'

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
    const companyId = req.companyId ?? (req.query.company_id as string)

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
  company_id:    z.string().uuid(),
  name:          z.string().min(2),
  email:         z.string().email(),
  department_id: z.string().optional(),
  role:          z.enum(['employee', 'manager', 'company_admin', 'company_finance', 'company_hr']).default('employee'),
})

export async function inviteEmployee(req: Request, res: Response) {
  try {
    const data       = InviteSchema.parse(req.body)
    const companyId  = req.companyId!

    // Find the user by email, or create a placeholder account for them
    const user = await findOrCreateStubUser(data.name, data.email)

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
    sendInviteEmail(data.email, data.name, companyId).catch(console.error)

    ok(res, { user_id: user.id }, 'Invitation sent successfully')
  } catch (err) {
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

// ─── POST /corporate/employees/reactivate ─────────────────────────────────────
// Reinstates a previously deactivated (terminated) employee and resends the
// invite/download email so they can (re-)set up their account.

export async function reactivateEmployee(req: Request, res: Response) {
  try {
    const { employee_id } = req.body as { employee_id: string }
    const companyId = req.companyId!

    const membership = await prisma.companyEmployee.findFirst({
      where:   { id: BigInt(employee_id), companyId },
      include: { user: { select: { name: true, email: true } } },
    })
    if (!membership) { fail(res, 'Employee not found'); return }
    if (membership.isActive) { fail(res, 'Employee is already active'); return }

    const m = membership as typeof membership & { user: { name: string; email: string | null } }

    await prisma.companyEmployee.update({
      where: { id: membership.id },
      data:  { isActive: true, deactivatedAt: null, joinedAt: new Date() },
    })

    if (m.user.email) {
      sendInviteEmail(m.user.email, m.user.name, companyId).catch(console.error)
    }

    ok(res, { employee_id }, 'Employee reinstated and invite email resent')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /corporate/departments/import ───────────────────────────────────────
// multipart CSV — columns: name (required), code (optional)

export async function importDepartmentsCsv(req: Request, res: Response) {
  try {
    const file = (req as any).file as Express.Multer.File | undefined
    if (!file) { fail(res, 'CSV file required'); return }

    const rows = parseCsv(file.buffer.toString('utf-8'))
    const result = await importDepartmentsForCompany(req.companyId!, rows)
    ok(res, result, `Imported ${result.created} department(s)`)
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /corporate/employees/import ─────────────────────────────────────────
// multipart CSV — columns: name, email (required), department, role, job_title,
// monthly_spend_limit (all optional besides name/email). Missing departments
// named in the sheet are created automatically.

export async function importEmployeesCsv(req: Request, res: Response) {
  try {
    const file = (req as any).file as Express.Multer.File | undefined
    if (!file) { fail(res, 'CSV file required'); return }

    const rows = parseCsv(file.buffer.toString('utf-8'))
    const result = await importEmployeesForCompany(req.companyId!, rows)
    ok(res, result, `Imported ${result.created} employee(s)`)
  } catch (err) {
    serverError(res, err)
  }
}
