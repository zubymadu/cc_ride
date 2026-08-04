// Pool-car access control: a company's pool fleet serves its own employees
// by default. Crossing into another company's roster requires sharing to
// be opted into on two levels — the owning company's own
// CompanyPoolPolicy.allowExternalSharing toggle, AND an explicit
// PoolSharingAgreement naming the requesting employee's company — plus
// whatever daily/weekly/monthly ration applies to that specific employee.
import { prisma } from './prisma'
import { isWithinTimeWindow } from './timeWindow'

export interface PoolAccessResult {
  allowed: boolean
  reason?: string
}

/** Resolves the CompanyEmployee row (if any, active) that would grant this
 *  user access to ride the given pool vehicle's company fleet — either
 *  their own membership in that company, or membership in a company that
 *  has been granted a sharing agreement. Returns null if neither applies.
 *
 *  poolBranchId (the requested vehicle's branch, if any) is checked first
 *  against branch-scoped agreements, then falls back to a company-wide
 *  (branchId: null) agreement — so a branch with no agreement of its own
 *  shares with nobody even if the company has other branches that do,
 *  regardless of the company-level allowExternalSharing switch being on. */
async function resolveGrantingMembership(userId: string, poolCompanyId: string, poolBranchId?: string | null) {
  const ownMembership = await prisma.companyEmployee.findFirst({
    where: { userId, companyId: poolCompanyId, isActive: true },
  })
  if (ownMembership) return ownMembership

  const [policy, memberships] = await Promise.all([
    prisma.companyPoolPolicy.findUnique({ where: { companyId: poolCompanyId } }),
    prisma.companyEmployee.findMany({ where: { userId, isActive: true } }),
  ])
  if (!policy?.allowExternalSharing || memberships.length === 0) return null

  const partnerCompanyIds = memberships.map((m) => m.companyId)
  const agreement = await prisma.poolSharingAgreement.findFirst({
    where: {
      companyId: poolCompanyId,
      partnerCompanyId: { in: partnerCompanyIds },
      isActive: true,
      branchId: poolBranchId ? BigInt(poolBranchId) : null,
    },
  }) ?? (poolBranchId
    ? await prisma.poolSharingAgreement.findFirst({
        where: { companyId: poolCompanyId, partnerCompanyId: { in: partnerCompanyIds }, isActive: true, branchId: null },
      })
    : null)
  if (!agreement) return null

  return memberships.find((m) => m.companyId === agreement.partnerCompanyId) ?? null
}

function startOfDay(d: Date) { const x = new Date(d); x.setHours(0, 0, 0, 0); return x }
function startOfWeek(d: Date) { const x = startOfDay(d); const day = x.getDay() === 0 ? 7 : x.getDay(); x.setDate(x.getDate() - (day - 1)); return x }
function startOfMonth(d: Date) { return new Date(d.getFullYear(), d.getMonth(), 1) }

/** Checks both eligibility and remaining ration. Call before creating a
 *  booking on a pool vehicle — never after, since the ration count depends
 *  on bookings already committed. */
export async function checkPoolRideEligibility(params: {
  passengerUserId: string
  poolCompanyId: string
  poolBranchId?: string | null
  at?: Date
}): Promise<PoolAccessResult> {
  const at = params.at ?? new Date()

  const membership = await resolveGrantingMembership(params.passengerUserId, params.poolCompanyId, params.poolBranchId)
  if (!membership) {
    return { allowed: false, reason: 'You are not eligible to book this organisation\'s pool vehicles.' }
  }
  if (!membership.poolAccessEnabled) {
    return { allowed: false, reason: 'Your organisation has not enabled pool-car access for your account.' }
  }
  if (!isWithinTimeWindow({
    daysOfWeek: membership.poolAccessDaysOfWeek,
    timeFrom: membership.poolAccessTimeFrom,
    timeTo: membership.poolAccessTimeTo,
  }, at)) {
    return { allowed: false, reason: 'Pool-car access is outside the hours your organisation has made it available to you.' }
  }

  const policy = await prisma.companyPoolPolicy.findUnique({ where: { companyId: params.poolCompanyId } })

  const dailyLimit   = membership.poolDailyLimit   ?? policy?.dailyLimit   ?? null
  const weeklyLimit  = membership.poolWeeklyLimit  ?? policy?.weeklyLimit  ?? null
  const monthlyLimit = membership.poolMonthlyLimit ?? policy?.monthlyLimit ?? null

  if (dailyLimit == null && weeklyLimit == null && monthlyLimit == null) {
    return { allowed: true }
  }

  // Ration is counted against rides on THIS company's pool fleet
  // specifically — a limit rations that company's own fleet capacity, not
  // a global cap across every organisation the employee might ride with.
  const countSince = async (since: Date) => prisma.booking.count({
    where: {
      passengerId: params.passengerUserId,
      status: { in: ['pending', 'confirmed', 'processing', 'in_progress', 'completed'] },
      ride: { vehicle: { companyId: params.poolCompanyId } },
      createdAt: { gte: since },
    },
  })

  if (dailyLimit != null && (await countSince(startOfDay(at))) >= dailyLimit) {
    return { allowed: false, reason: `You've reached your daily pool-ride limit (${dailyLimit}).` }
  }
  if (weeklyLimit != null && (await countSince(startOfWeek(at))) >= weeklyLimit) {
    return { allowed: false, reason: `You've reached your weekly pool-ride limit (${weeklyLimit}).` }
  }
  if (monthlyLimit != null && (await countSince(startOfMonth(at))) >= monthlyLimit) {
    return { allowed: false, reason: `You've reached your monthly pool-ride limit (${monthlyLimit}).` }
  }

  return { allowed: true }
}

/** Whether this employee may pay for a ride out of their own company's
 *  funds right now — off by default, an admin grants it explicitly and can
 *  restrict it to a time window, mirroring pool-car access above. Unlike
 *  pool access there's no cross-company sharing case: an employee only
 *  ever spends their own employer's money. */
export async function checkWalletPaymentEligibility(params: {
  userId: string
  companyId: string
  at?: Date
}): Promise<PoolAccessResult> {
  const at = params.at ?? new Date()

  const membership = await prisma.companyEmployee.findFirst({
    where: { userId: params.userId, companyId: params.companyId, isActive: true },
  })
  if (!membership) {
    return { allowed: false, reason: 'You are not an active member of this organisation.' }
  }
  if (!membership.walletAccessEnabled) {
    return { allowed: false, reason: 'Your organisation has not enabled company-wallet payment for your account.' }
  }
  if (!isWithinTimeWindow({
    daysOfWeek: membership.walletAccessDaysOfWeek,
    timeFrom: membership.walletAccessTimeFrom,
    timeTo: membership.walletAccessTimeTo,
  }, at)) {
    return { allowed: false, reason: 'Company-wallet payment is outside the hours your organisation has made it available to you.' }
  }

  return { allowed: true }
}
