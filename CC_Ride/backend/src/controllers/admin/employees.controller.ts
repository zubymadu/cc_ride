/**
 * Admin — company self-service employee registration & termination for the
 * web console. Mirrors src/controllers/corporate/employees.controller.ts
 * (the Flutter-app-facing, User-JWT equivalent) but AdminUser-scoped, and
 * uses a claim-link/token first-access flow instead of emailing a temp
 * password in plaintext.
 */
import { Request, Response } from 'express'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import { parse as parseCsv } from 'csv-parse/sync'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'
import { assertCompanyScope } from '../../lib/adminScope'
import { registerEmployee, RegisterEmployeeInput, issueAndEmailActivationLink } from '../../lib/employeeRegistration'

const RegisterEmployeeSchema = z.object({
  name:           z.string().min(2),
  // The employer's official correspondence address — always stored on
  // CompanyEmployee.workEmail and always where the invite is sent. Never
  // used to look up or create a User; a person's work email having no
  // relationship to their personal signup email is the normal case, not
  // the exception.
  work_email:     z.string().email(),
  mobile:         z.string().min(7),
  // The actual identity anchor — see resolveRequiredIdentity. Neither
  // mobile nor email is reliable enough to dedupe on alone (a person can
  // hold two mobile numbers, one personal and one employer-issued, which
  // is exactly the ambiguity a NIN/passport doesn't have).
  nin:             z.string().optional(),
  passport_number: z.string().optional(),
  personal_email: z.string().email().optional(),
  role:           z.enum(['employee', 'manager', 'company_admin', 'company_finance', 'company_hr']).default('employee'),
  department_id:  z.string().optional(),
})

// POST /admin/companies/:id/employees/register
export async function registerCompanyEmployee(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const data = RegisterEmployeeSchema.parse(req.body)

    const company = await prisma.company.findUnique({ where: { id: companyId }, select: { name: true } })
    if (!company) { fail(res, 'Company not found'); return }

    const result = await registerEmployee(companyId, company.name, data)
    if (!result.ok) { fail(res, result.error); return }

    ok(res, {
      employee_id: result.employeeId,
      user_id: result.userId,
      claim_url: result.claimUrl,
      emailed: result.emailed,
      already_had_account: result.alreadyHadAccount,
    }, result.claimUrl ? (result.emailed ? 'Employee registered — invite emailed' : 'Employee registered — email not sent, share the claim link directly') : 'Existing user added as employee')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Bulk registration via CSV ───────────────────────────────────────────────
// Expected columns (header row required): name, work_email, mobile,
// nin OR passport_number, personal_email (optional), role (optional,
// defaults to employee), department (optional — matched by name, not id,
// since a CSV author won't know internal department ids).

const CSV_ROLE_VALUES = ['employee', 'manager', 'company_admin', 'company_finance', 'company_hr'] as const
const MAX_CSV_ROWS = 500

interface CsvRowResult {
  row: number
  name: string
  status: 'created' | 'linked' | 'error'
  message: string
}

// GET /admin/companies/:id/employees/import-template
export async function getEmployeeImportTemplate(req: Request, res: Response) {
  const companyId = String(req.params.id)
  if (!assertCompanyScope(req, res, companyId)) return
  const header = 'name,work_email,mobile,nin,passport_number,personal_email,role,department\n'
  const example = 'Jane Doe,jane.doe@example-corp.com,+2348012345678,12345678901,,jane.personal@gmail.com,employee,Operations\n'
  res.setHeader('Content-Type', 'text/csv')
  res.setHeader('Content-Disposition', 'attachment; filename="employee_import_template.csv"')
  res.send(header + example)
}

// POST /admin/companies/:id/employees/import-csv (multipart, field name "file")
export async function importEmployeesCsv(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return

    const file = (req as any).file as { buffer: Buffer; originalname: string } | undefined
    if (!file) { fail(res, 'CSV file required'); return }

    const company = await prisma.company.findUnique({ where: { id: companyId }, select: { name: true } })
    if (!company) { fail(res, 'Company not found'); return }

    let rows: Record<string, string>[]
    try {
      rows = parseCsv(file.buffer, { columns: true, skip_empty_lines: true, trim: true })
    } catch (err: any) {
      fail(res, `Could not parse CSV: ${err.message}`); return
    }
    if (rows.length === 0) { fail(res, 'CSV has no data rows'); return }
    if (rows.length > MAX_CSV_ROWS) { fail(res, `CSV has ${rows.length} rows — max ${MAX_CSV_ROWS} per import, split into batches`); return }

    // Department names resolved once, up front, rather than per row.
    const departments = await prisma.department.findMany({ where: { companyId }, select: { id: true, name: true } })
    const deptByName = new Map(departments.map((d) => [d.name.toLowerCase(), d.id.toString()]))

    const results: CsvRowResult[] = []
    for (let i = 0; i < rows.length; i++) {
      const row = rows[i]
      const rowNum = i + 2 // +1 for 0-index, +1 for the header row
      const name = row.name?.trim() ?? ''

      if (!name || !row.work_email || !row.mobile) {
        results.push({ row: rowNum, name, status: 'error', message: 'name, work_email and mobile are required' })
        continue
      }
      const roleRaw = (row.role ?? 'employee').trim().toLowerCase()
      if (!CSV_ROLE_VALUES.includes(roleRaw as any)) {
        results.push({ row: rowNum, name, status: 'error', message: `Invalid role "${row.role}" — must be one of ${CSV_ROLE_VALUES.join(', ')}` })
        continue
      }
      let departmentId: string | undefined
      const deptName = row.department?.trim()
      if (deptName) {
        const key = deptName.toLowerCase()
        let match = deptByName.get(key)
        if (!match) {
          // Create it on the fly rather than rejecting the row — a CSV of
          // new hires commonly references departments that don't exist yet
          // in the system, and requiring a separate manual step to create
          // each one first defeats the point of a bulk import. Cached in
          // deptByName so later rows referencing the same new department
          // reuse it instead of creating duplicates.
          const created = await prisma.department.create({
            data: { companyId, name: deptName },
            select: { id: true },
          })
          match = created.id.toString()
          deptByName.set(key, match)
        }
        departmentId = match
      }

      const input: RegisterEmployeeInput = {
        name,
        work_email: row.work_email.trim(),
        mobile: row.mobile.trim(),
        nin: row.nin?.trim() || undefined,
        passport_number: row.passport_number?.trim() || undefined,
        personal_email: row.personal_email?.trim() || undefined,
        role: roleRaw as RegisterEmployeeInput['role'],
        department_id: departmentId,
      }

      const outcome = await registerEmployee(companyId, company.name, input)
      results.push(outcome.ok
        ? { row: rowNum, name, status: outcome.alreadyHadAccount ? 'linked' : 'created', message: outcome.alreadyHadAccount ? 'Linked to existing account' : (outcome.emailed ? 'Invite emailed' : 'Created — email not sent, share claim link manually') }
        : { row: rowNum, name, status: 'error', message: outcome.error })
    }

    const created = results.filter((r) => r.status === 'created').length
    const linked = results.filter((r) => r.status === 'linked').length
    const errored = results.filter((r) => r.status === 'error').length

    ok(res, { total: results.length, created, linked, errored, results }, `${created + linked} of ${results.length} rows registered`)
  } catch (err) {
    serverError(res, err)
  }
}

const TerminateSchema = z.object({ employee_id: z.string() })

// POST /admin/companies/:id/employees/terminate
export async function terminateCompanyEmployee(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const { employee_id } = TerminateSchema.parse(req.body)

    const employee = await prisma.companyEmployee.findFirst({ where: { id: BigInt(employee_id), companyId } })
    if (!employee) { fail(res, 'Employee not found'); return }
    if (!employee.isActive) { fail(res, 'Employee is already terminated'); return }

    // isActive is the single gate every corporate privilege check already
    // reads (requireCompanyMember's membership lookup, pool-access
    // eligibility, budget/approval flows) — flipping it here is sufficient
    // to immediately revoke everything without touching each check
    // individually.
    await prisma.$transaction([
      prisma.companyEmployee.update({
        where: { id: employee.id },
        data: { isActive: false, deactivatedAt: new Date() },
      }),
      // A terminated employee shouldn't retain standing driver access to
      // this company's pool vehicles either.
      prisma.driverVehicleAccess.updateMany({
        where: { driverId: employee.userId, isActive: true, vehicle: { companyId } },
        data: { isActive: false, revokedAt: new Date() },
      }),
    ])

    ok(res, {}, 'Employee terminated')
  } catch (err) {
    serverError(res, err)
  }
}

// POST /admin/companies/:id/employees/reinstate — undoes a termination and
// re-sends a fresh activation link, since a terminated employee's original
// invite (if they never claimed it) or password reset has likely long since
// expired by the time someone decides to bring them back.
const ReinstateSchema = z.object({ employee_id: z.string() })

export async function reinstateCompanyEmployee(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const { employee_id } = ReinstateSchema.parse(req.body)

    const employee = await prisma.companyEmployee.findFirst({
      where: { id: BigInt(employee_id), companyId },
      include: { user: true },
    })
    if (!employee) { fail(res, 'Employee not found'); return }
    if (employee.isActive) { fail(res, 'Employee is already active'); return }

    const company = await prisma.company.findUnique({ where: { id: companyId }, select: { name: true } })
    if (!company) { fail(res, 'Company not found'); return }

    await prisma.companyEmployee.update({
      where: { id: employee.id },
      data: { isActive: true, deactivatedAt: null },
    })

    const recipientEmail = employee.workEmail ?? employee.user.email
    if (!recipientEmail) { fail(res, 'This employee has no email on file to send an activation link to'); return }

    const { claimUrl, emailed } = await issueAndEmailActivationLink(
      employee.userId, recipientEmail, employee.user.name, company.name,
    )

    ok(res, { claim_url: claimUrl, emailed }, emailed ? 'Employee reinstated — activation email sent' : 'Employee reinstated — email not sent, share this link directly')
  } catch (err) {
    serverError(res, err)
  }
}

// DELETE /admin/companies/:id/employees/:employeeId — housekeeping only, not
// the normal offboarding path (that's terminate, above, which is reversible
// and keeps historical booking/savings data intact). This permanently
// removes the CompanyEmployee record itself — for cleaning up a duplicate
// registration or seeded/test data, not for real staff turnover. The
// underlying User account and their personal ride history are never
// touched, only this company's link to them.
export async function deleteEmployeeRecord(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const employeeId = BigInt(String(req.params.employeeId))
    const force = req.query.force === 'true'

    const employee = await prisma.companyEmployee.findFirst({ where: { id: employeeId, companyId } })
    if (!employee) { fail(res, 'Employee not found'); return }

    if (!force) {
      const sponsoredBookings = await prisma.booking.count({
        where: { passengerId: employee.userId, companyId, status: { in: ['completed', 'confirmed', 'in_progress'] } },
      })
      if (employee.isActive || sponsoredBookings > 0) {
        fail(res, `${employee.isActive ? 'Still active — terminate first, or pass' : 'Has'} ${sponsoredBookings} real sponsored booking(s) on record — pass force=true to delete anyway`)
        return
      }
    }

    await prisma.companyEmployee.delete({ where: { id: employeeId } })
    ok(res, {}, 'Employee record deleted')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Public: first-access claim (employees, not admins) ────────────────────

// GET /admin/employee-invite/:token
export async function getEmployeeInviteInfo(req: Request, res: Response) {
  try {
    const token = String(req.params.token)
    const user = await prisma.user.findUnique({
      where: { inviteToken: token },
      select: { name: true, email: true, inviteExpiresAt: true },
    })
    if (!user) { fail(res, 'Invite not found or already used'); return }
    if (!user.inviteExpiresAt || user.inviteExpiresAt < new Date()) { fail(res, 'This invite link has expired'); return }

    ok(res, { name: user.name, email: user.email })
  } catch (err) {
    serverError(res, err)
  }
}

const ClaimEmployeeInviteSchema = z.object({
  token: z.string().min(1),
  password: z.string().min(8, 'Password must be at least 8 characters'),
})

// POST /admin/employee-invite/claim
export async function claimEmployeeInvite(req: Request, res: Response) {
  try {
    const data = ClaimEmployeeInviteSchema.parse(req.body)

    const user = await prisma.user.findUnique({ where: { inviteToken: data.token } })
    if (!user) { fail(res, 'Invite not found or already used'); return }
    if (!user.inviteExpiresAt || user.inviteExpiresAt < new Date()) { fail(res, 'This invite link has expired'); return }

    const passwordHash = await bcrypt.hash(data.password, 12)
    await prisma.user.update({
      where: { id: user.id },
      data: {
        passwordHash,
        inviteToken: null,
        inviteExpiresAt: null,
        isMobileVerified: user.mobile ? true : undefined,
        status: 'active',
      },
    })

    ok(res, { mobile: user.mobile }, 'Account activated — open the CC Ride app and sign in')
  } catch (err) {
    serverError(res, err)
  }
}
