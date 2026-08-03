import { prisma } from './prisma'
import { sendInviteEmail } from './mailer'
import { findOrCreateStubUser } from './stubUser'

export interface ImportResult {
  created: number
  skipped: number
  errors: string[]
}

const VALID_ROLES = ['employee', 'manager', 'company_admin', 'company_finance', 'company_hr']
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

/** CSV columns: name (required), code (optional) */
export async function importDepartmentsForCompany(
  companyId: string,
  rows: Record<string, string>[],
): Promise<ImportResult> {
  const result: ImportResult = { created: 0, skipped: 0, errors: [] }

  for (let i = 0; i < rows.length; i++) {
    const line = i + 2 // account for the header row
    const row  = rows[i]
    const name = row.name?.trim()
    const code = row.code?.trim() || null

    if (!name) {
      result.skipped++
      result.errors.push(`Row ${line}: missing department name`)
      continue
    }

    const existing = await prisma.department.findFirst({
      where: { companyId, name: { equals: name, mode: 'insensitive' } },
    })
    if (existing) {
      result.skipped++
      result.errors.push(`Row ${line}: department "${name}" already exists — skipped`)
      continue
    }

    await prisma.department.create({ data: { companyId, name, code } })
    result.created++
  }

  return result
}

/**
 * CSV columns: name, email (required); department, role, job_title,
 * monthly_spend_limit (all optional). A department named in the sheet that
 * doesn't exist yet is created automatically. Existing members are skipped,
 * not overwritten.
 */
export async function importEmployeesForCompany(
  companyId: string,
  rows: Record<string, string>[],
  sendEmail = true,
): Promise<ImportResult> {
  const result: ImportResult = { created: 0, skipped: 0, errors: [] }

  for (let i = 0; i < rows.length; i++) {
    const line = i + 2
    const row  = rows[i]

    const name     = row.name?.trim()
    const email    = row.email?.trim().toLowerCase()
    const roleRaw  = row.role?.trim().toLowerCase()
    const role     = VALID_ROLES.includes(roleRaw) ? roleRaw : 'employee'
    const deptName = row.department?.trim()
    const jobTitle = row.job_title?.trim() || null
    const spendLimitRaw = row.monthly_spend_limit?.trim()
    const spendLimit = spendLimitRaw ? Number(spendLimitRaw) : null

    if (!name || !email) {
      result.skipped++
      result.errors.push(`Row ${line}: name and email are required`)
      continue
    }
    if (!EMAIL_RE.test(email)) {
      result.skipped++
      result.errors.push(`Row ${line}: invalid email "${email}"`)
      continue
    }
    if (spendLimitRaw && Number.isNaN(spendLimit)) {
      result.skipped++
      result.errors.push(`Row ${line}: invalid monthly_spend_limit "${spendLimitRaw}"`)
      continue
    }

    let departmentId: bigint | null = null
    if (deptName) {
      let dept = await prisma.department.findFirst({
        where: { companyId, name: { equals: deptName, mode: 'insensitive' } },
      })
      if (!dept) dept = await prisma.department.create({ data: { companyId, name: deptName } })
      departmentId = dept.id
    }

    const user = await findOrCreateStubUser(name, email)

    const existingMembership = await prisma.companyEmployee.findFirst({ where: { companyId, userId: user.id } })
    if (existingMembership) {
      result.skipped++
      result.errors.push(
        `Row ${line}: ${email} is already ${existingMembership.isActive ? 'a member' : 'a deactivated member'} — skipped`,
      )
      continue
    }

    await prisma.companyEmployee.create({
      data: {
        companyId,
        userId:            user.id,
        departmentId,
        role:              role as any,
        jobTitle,
        monthlySpendLimit: spendLimit,
        isActive:          true,
      },
    })
    result.created++

    if (sendEmail) sendInviteEmail(email, name, companyId).catch(console.error)
  }

  return result
}
