// Fare-resolution engine: walks the super-admin-configurable PricingRateCard
// layers (global < vehicle_type < company < time_window, each override only
// applying the fields it sets) to resolve the factors used to price a ride,
// then applies them consistently across every booking path.
//
// Kept deliberately separate from the corporate savings ledger below —
// resolveFareFactors/computeFareSplit feed what a passenger/company is
// actually charged, while resolveMarketBenchmark/recordRideSavings are
// informational-only and never influence a real charge.

import { prisma } from './prisma'
import { dec } from './naira'
import { isWithinTimeWindow } from './timeWindow'

export interface ResolvedFactors {
  commissionRate: number       // percent, e.g. 15
  driverEarningsFloor: number  // NGN, 0 = no floor
  surgeMultiplier: number
  // Resolved for completeness (rate cards have always let an admin set
  // these), but only actually consumed by estimateFare() below — the
  // commission/earnings split above never depended on them. Not applying
  // surgeMultiplier to a real charge yet either; it's resolved and capped,
  // but nothing multiplies a fare by it today.
  baseFare: number
  farePerKm: number
  farePerMin: number
}

interface ResolveFactorsInput {
  // The ride's vehicle — typeId/companyId are resolved internally from this
  // rather than requiring the caller to fetch the vehicle first, so that
  // fetch runs concurrently with the rest of this function's queries
  // instead of serialized in front of it.
  vehicleId?: bigint | number | null
  // The sponsoring/paying company for rate-card scoping — distinct from the
  // vehicle's owning company (a pool vehicle's operator company isn't
  // necessarily who's being billed for this particular ride).
  companyId?: string | null
  at?: Date
}

function isEffective(card: { effectiveFrom: Date; effectiveTo: Date | null; isActive: boolean }, at: Date) {
  return card.isActive && card.effectiveFrom <= at && (card.effectiveTo == null || card.effectiveTo > at)
}

/** Resolves the pricing factors that apply right now, layering rate cards
 *  global -> vehicle_type -> company -> time_window on top of
 *  PlatformSettings/Company defaults, each layer overriding only what it
 *  sets. Also resolves whether this is a pool ride (company-owned vehicle —
 *  driver earns organisation points, not cash) from the same vehicle fetch. */
export async function resolveFareFactors(input: ResolveFactorsInput): Promise<ResolvedFactors & { isPoolRide: boolean; poolCompanyId: string | null; poolBranchId: string | null }> {
  const at = input.at ?? new Date()

  const [settings, vehicle, company, globalCards, companyCards, timeWindowCards] = await Promise.all([
    prisma.platformSettings.findUnique({ where: { id: 1 } }),
    input.vehicleId != null
      ? prisma.vehicle.findUnique({ where: { id: BigInt(input.vehicleId) }, select: { typeId: true, companyId: true, branchId: true } })
      : Promise.resolve(null),
    // Company.commissionRate is the pre-existing admin lever (see
    // POST /admin/companies/commission) — resolved here so editing it via
    // the existing admin UI actually takes effect, not just PricingRateCard.
    input.companyId
      ? prisma.company.findUnique({ where: { id: input.companyId }, select: { commissionRate: true } })
      : Promise.resolve(null),
    prisma.pricingRateCard.findMany({ where: { scope: 'global', isActive: true } }),
    input.companyId
      ? prisma.pricingRateCard.findMany({ where: { scope: 'company', companyId: input.companyId, isActive: true } })
      : Promise.resolve([]),
    prisma.pricingRateCard.findMany({ where: { scope: 'time_window', isActive: true } }),
  ])

  // vehicle_type-scoped cards depend on the vehicle lookup above, so this is
  // the one query that can't join the Promise.all — everything else already
  // ran concurrently with the vehicle fetch instead of waiting on it first.
  const vehicleTypeCards = vehicle?.typeId != null
    ? await prisma.pricingRateCard.findMany({ where: { scope: 'vehicle_type', vehicleTypeId: vehicle.typeId, isActive: true } })
    : []

  const factors: ResolvedFactors = {
    commissionRate: dec(settings?.platformCommission ?? 15),
    driverEarningsFloor: 0,
    surgeMultiplier: 1,
    baseFare: dec(settings?.defaultBaseFare ?? 500),
    farePerKm: dec(settings?.defaultFarePerKm ?? 150),
    farePerMin: dec(settings?.defaultFarePerMin ?? 10),
  }

  if (company?.commissionRate != null) factors.commissionRate = dec(company.commissionRate)

  const applyLatestEffective = (cards: typeof globalCards) => {
    const effective = cards.filter((c) => isEffective(c, at)).sort((a, b) => b.effectiveFrom.getTime() - a.effectiveFrom.getTime())
    const card = effective[0]
    if (!card) return
    if (card.commissionRate != null) factors.commissionRate = dec(card.commissionRate)
    if (card.driverEarningsFloor != null) factors.driverEarningsFloor = dec(card.driverEarningsFloor)
    if (card.surgeMultiplier != null) factors.surgeMultiplier = dec(card.surgeMultiplier)
    if (card.baseFare != null) factors.baseFare = dec(card.baseFare)
    if (card.farePerKm != null) factors.farePerKm = dec(card.farePerKm)
    if (card.farePerMin != null) factors.farePerMin = dec(card.farePerMin)
  }

  applyLatestEffective(globalCards)
  applyLatestEffective(vehicleTypeCards)
  applyLatestEffective(companyCards)
  applyLatestEffective(timeWindowCards.filter((c) => isWithinTimeWindow(c, at)))

  const surgeCap = dec(settings?.surgeMultiplierMax ?? 2.5)
  if (factors.surgeMultiplier > surgeCap) factors.surgeMultiplier = surgeCap

  return {
    ...factors,
    isPoolRide: !!vehicle?.companyId,
    poolCompanyId: vehicle?.companyId ?? null,
    poolBranchId: vehicle?.branchId != null ? vehicle.branchId.toString() : null,
  }
}

export interface FareSplit {
  driverEarning: number
  platformCommission: number
  isPoolRide: boolean
  poolCompanyId: string | null
  poolBranchId: string | null
  factorsUsed: ResolvedFactors
}

/** Splits an already-computed ride subtotal into driver/platform shares
 *  using the resolved commission rate and floor. `bookingFeeAmount` is
 *  always platform revenue, added on top of the commission share. */
export async function computeFareSplit(params: {
  subtotal: number
  bookingFeeAmount: number
  vehicleId?: bigint | number | null
  companyId?: string | null
  at?: Date
}): Promise<FareSplit> {
  const { isPoolRide, poolCompanyId, poolBranchId, ...factorsUsed } = await resolveFareFactors({
    vehicleId: params.vehicleId,
    companyId: params.companyId,
    at: params.at,
  })

  // Pool drivers earn organisation points instead of cash — a deliberate,
  // fixed business rule (operating a company-owned vehicle is a
  // corporate-sponsored arrangement, not an admin-tunable rate), applied as
  // a commission-rate/floor override so it still flows through the same
  // split math below instead of a separate early-return formula.
  const commissionRate = isPoolRide ? 100 : factorsUsed.commissionRate
  const floor = isPoolRide ? 0 : factorsUsed.driverEarningsFloor

  const commissionAmt = params.subtotal * (commissionRate / 100)
  let driverEarning = params.subtotal - commissionAmt
  if (driverEarning < floor) driverEarning = floor
  // A floor guarantees the driver a minimum payout, but never more than the
  // fare itself — otherwise platformCommission below would go negative.
  driverEarning = Math.min(driverEarning, params.subtotal)

  const platformCommission = params.subtotal - driverEarning + params.bookingFeeAmount
  return { driverEarning, platformCommission, isPoolRide, poolCompanyId, poolBranchId, factorsUsed }
}

export interface FareEstimate {
  estimatedFare: number
  pricingModel: 'driver_set' | 'platform_computed'
  factorsUsed: Pick<ResolvedFactors, 'baseFare' | 'farePerKm' | 'farePerMin'>
}

/** The platform-computed fare estimate for a non-shared/ad-hoc ride —
 *  base + per-km + per-min, using the same layered rate-card resolution as
 *  everything else in this engine. Always returns a number regardless of
 *  which pricing_model is active; it's the CALLER's job to decide whether
 *  to treat it as authoritative (platform_computed) or just an FYI
 *  alongside the driver's own price (driver_set) — this function doesn't
 *  know which ride it's being asked about, only how to price one. */
export async function estimateFare(params: {
  distanceKm: number
  durationMin?: number
  vehicleId?: bigint | number | null
  companyId?: string | null
  at?: Date
}): Promise<FareEstimate> {
  const [settings, factors] = await Promise.all([
    prisma.platformSettings.findUnique({ where: { id: 1 } }),
    resolveFareFactors({ vehicleId: params.vehicleId, companyId: params.companyId, at: params.at }),
  ])

  const estimatedFare = factors.baseFare
    + factors.farePerKm * Math.max(0, params.distanceKm)
    + factors.farePerMin * Math.max(0, params.durationMin ?? 0)

  return {
    estimatedFare: Math.round(estimatedFare),
    pricingModel: (settings?.pricingModel ?? 'driver_set') as 'driver_set' | 'platform_computed',
    factorsUsed: { baseFare: factors.baseFare, farePerKm: factors.farePerKm, farePerMin: factors.farePerMin },
  }
}

// ─── Corporate savings reporting (informational — never feeds a charge) ────

const DISTANCE_BANDS: Array<[number, string]> = [[5, '0-5'], [10, '5-10'], [20, '10-20'], [40, '20-40']]

function distanceBandFor(km: number): string {
  for (const [max, band] of DISTANCE_BANDS) if (km <= max) return band
  return '40+'
}

/** Latest admin-entered competitor sample for this distance band. Deliberately
 *  never derived from CC Ride's own rate cards, so a savings figure holds up
 *  independently of how CC Ride prices itself. */
export async function resolveMarketBenchmark(distanceKm: number, vehicleTypeId?: bigint | number | null): Promise<number | null> {
  const band = distanceBandFor(distanceKm)
  const card = await prisma.marketBenchmarkRate.findFirst({
    where: {
      distanceBandKm: band,
      isActive: true,
      OR: [
        { vehicleTypeId: vehicleTypeId != null ? BigInt(vehicleTypeId) : undefined },
        { vehicleTypeId: null },
      ],
    },
    orderBy: { sampledAt: 'desc' },
  })
  return card ? dec(card.sampledFare) : null
}

/** Writes/updates the one-row-per-booking shadow price used for corporate
 *  savings reports. Safe to call more than once for the same booking
 *  (upsert) since trip-completion handlers can be hit more than once. */
export async function recordRideSavings(params: {
  bookingId: string
  companyId: string
  employeeId?: bigint | null
  computedFairFare: number
  actualOrgCost: number
  driverPointsAwarded?: number
  distanceKm?: number | null
  durationMinutes?: number | null
  vehicleTypeId?: bigint | number | null
  rideDate: Date
}) {
  const computedMarketBenchmark = params.distanceKm != null
    ? await resolveMarketBenchmark(params.distanceKm, params.vehicleTypeId)
    : null

  const data = {
    companyId: params.companyId,
    employeeId: params.employeeId ?? null,
    computedFairFare: params.computedFairFare,
    computedMarketBenchmark,
    actualOrgCost: params.actualOrgCost,
    driverPointsAwarded: params.driverPointsAwarded ?? 0,
    distanceKm: params.distanceKm ?? null,
    durationMinutes: params.durationMinutes ?? null,
    rideDate: params.rideDate,
  }

  await prisma.rideSavingsRecord.upsert({
    where: { bookingId: params.bookingId },
    create: { bookingId: params.bookingId, ...data },
    update: data,
  })
}
