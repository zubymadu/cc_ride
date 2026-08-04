/**
 * Admin — Pricing engine (rate cards, market benchmarks) & corporate
 * savings reports. Mirrors the layered scope model implemented by
 * src/lib/pricingService.ts.
 */
import { Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'
import { dec } from '../../lib/naira'
import { assertCompanyScope } from '../../lib/adminScope'

function adminId(req: Request): bigint {
  if (!req.admin?.id) throw new Error('Admin session missing id')
  return BigInt(req.admin.id)
}

// ─── GET /admin/vehicle-types ──────────────────────────────────────────────
// Lightweight lookup list for the rate-card / benchmark scope dropdowns.

export async function listVehicleTypes(req: Request, res: Response) {
  try {
    const types = await prisma.vehicleType.findMany({ where: { status: true }, orderBy: { title: 'asc' } })
    ok(res, types.map((t) => ({ id: t.id.toString(), title: t.title })))
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Pricing rate cards ─────────────────────────────────────────────────────

const RateCardFactorsSchema = z.object({
  base_fare:              z.number().nonnegative().optional(),
  fare_per_km:            z.number().nonnegative().optional(),
  fare_per_min:           z.number().nonnegative().optional(),
  min_fare_floor:         z.number().nonnegative().optional(),
  driver_earnings_floor:  z.number().nonnegative().optional(),
  commission_rate:        z.number().min(0).max(100).optional(),
  surge_multiplier:       z.number().min(1).optional(),
})

const CreateRateCardSchema = RateCardFactorsSchema.extend({
  scope:           z.enum(['global', 'vehicle_type', 'company', 'time_window']),
  vehicle_type_id: z.string().optional(),
  company_id:      z.string().uuid().optional(),
  days_of_week:    z.array(z.number().int().min(1).max(7)).default([]),
  time_from:       z.string().regex(/^\d{2}:\d{2}$/).optional(),
  time_to:         z.string().regex(/^\d{2}:\d{2}$/).optional(),
})

function rateCardScopeGuard(data: z.infer<typeof CreateRateCardSchema>): string | null {
  if (data.scope === 'vehicle_type' && !data.vehicle_type_id) return 'vehicle_type_id is required for vehicle_type scope'
  if (data.scope === 'company' && !data.company_id) return 'company_id is required for company scope'
  if (data.scope === 'time_window' && (!data.time_from || !data.time_to)) return 'time_from and time_to are required for time_window scope'
  return null
}

function serializeRateCard(c: Awaited<ReturnType<typeof prisma.pricingRateCard.findFirstOrThrow>>) {
  return {
    id:                     c.id.toString(),
    scope:                  c.scope,
    vehicle_type_id:        c.vehicleTypeId?.toString() ?? null,
    company_id:             c.companyId ?? null,
    days_of_week:           c.daysOfWeek,
    time_from:              c.timeFrom,
    time_to:                c.timeTo,
    base_fare:              c.baseFare != null ? dec(c.baseFare) : null,
    fare_per_km:            c.farePerKm != null ? dec(c.farePerKm) : null,
    fare_per_min:           c.farePerMin != null ? dec(c.farePerMin) : null,
    min_fare_floor:         c.minFareFloor != null ? dec(c.minFareFloor) : null,
    driver_earnings_floor:  c.driverEarningsFloor != null ? dec(c.driverEarningsFloor) : null,
    commission_rate:        c.commissionRate != null ? dec(c.commissionRate) : null,
    surge_multiplier:       c.surgeMultiplier != null ? dec(c.surgeMultiplier) : null,
    effective_from:         c.effectiveFrom.toISOString(),
    effective_to:           c.effectiveTo?.toISOString() ?? null,
    is_active:              c.isActive,
    created_at:             c.createdAt.toISOString(),
  }
}

// GET /admin/pricing-rate-cards?scope=&is_active=
export async function listPricingRateCards(req: Request, res: Response) {
  try {
    const scope = req.query.scope ? String(req.query.scope) : undefined
    const isActiveParam = req.query.is_active
    const cards = await prisma.pricingRateCard.findMany({
      where: {
        ...(scope ? { scope: scope as any } : {}),
        ...(isActiveParam != null ? { isActive: isActiveParam === 'true' } : {}),
        // A scoped admin can see global/vehicle_type/time_window cards (they
        // affect their own rides) but never another company's negotiated
        // commission rate — only company-scoped cards for their own company.
        ...(req.admin?.isSuperAdmin ? {} : {
          OR: [
            { scope: { not: 'company' } },
            { scope: 'company', companyId: req.admin?.scopeCompanyId ?? '__no_scope__' },
          ],
        }),
      },
      orderBy: [{ scope: 'asc' }, { effectiveFrom: 'desc' }],
      include: { vehicleType: { select: { title: true } }, company: { select: { name: true } } },
    })
    ok(res, cards.map((c) => ({
      ...serializeRateCard(c),
      vehicle_type_title: c.vehicleType?.title ?? null,
      company_name:       c.company?.name ?? null,
    })))
  } catch (err) {
    serverError(res, err)
  }
}

// POST /admin/pricing-rate-cards
export async function createPricingRateCard(req: Request, res: Response) {
  try {
    const data = CreateRateCardSchema.parse(req.body)
    const guardMsg = rateCardScopeGuard(data)
    if (guardMsg) { fail(res, guardMsg); return }

    const card = await prisma.pricingRateCard.create({
      data: {
        scope:               data.scope,
        vehicleTypeId:       data.vehicle_type_id ? BigInt(data.vehicle_type_id) : null,
        companyId:           data.company_id ?? null,
        daysOfWeek:          data.days_of_week,
        timeFrom:            data.time_from ?? null,
        timeTo:              data.time_to ?? null,
        baseFare:            data.base_fare ?? null,
        farePerKm:           data.fare_per_km ?? null,
        farePerMin:          data.fare_per_min ?? null,
        minFareFloor:        data.min_fare_floor ?? null,
        driverEarningsFloor: data.driver_earnings_floor ?? null,
        commissionRate:      data.commission_rate ?? null,
        surgeMultiplier:     data.surge_multiplier ?? null,
        createdById:         adminId(req),
      },
    })
    ok(res, serializeRateCard(card), 'Rate card created')
  } catch (err) {
    serverError(res, err)
  }
}

// PATCH /admin/pricing-rate-cards/:id/supersede
// Rows are never edited in place — this closes the existing row
// (effectiveTo = now) and opens a new one with the merged factors, logging
// a field-level diff for every changed value so a disputed fare can be
// traced back to who changed what, when, and why.
const SupersedeSchema = RateCardFactorsSchema.extend({
  reason: z.string().min(3, 'A reason is required when changing pricing factors'),
})

export async function supersedePricingRateCard(req: Request, res: Response) {
  try {
    const id = BigInt(String(req.params.id))
    const data = SupersedeSchema.parse(req.body)

    const existing = await prisma.pricingRateCard.findUnique({ where: { id } })
    if (!existing) { fail(res, 'Rate card not found'); return }
    if (!existing.isActive || existing.effectiveTo != null) { fail(res, 'This rate card has already been superseded or deactivated'); return }

    const who = adminId(req)
    const now = new Date()

    const merged = {
      baseFare:            data.base_fare              ?? existing.baseFare,
      farePerKm:           data.fare_per_km             ?? existing.farePerKm,
      farePerMin:          data.fare_per_min            ?? existing.farePerMin,
      minFareFloor:        data.min_fare_floor          ?? existing.minFareFloor,
      driverEarningsFloor: data.driver_earnings_floor   ?? existing.driverEarningsFloor,
      commissionRate:      data.commission_rate         ?? existing.commissionRate,
      surgeMultiplier:     data.surge_multiplier        ?? existing.surgeMultiplier,
    }

    const changedFields = (Object.keys(merged) as Array<keyof typeof merged>).filter(
      (k) => dec(merged[k] ?? 0) !== dec(existing[k] ?? 0),
    )

    const result = await prisma.$transaction(async (tx) => {
      await tx.pricingRateCard.update({ where: { id }, data: { effectiveTo: now } })

      const next = await tx.pricingRateCard.create({
        data: {
          scope:               existing.scope,
          vehicleTypeId:       existing.vehicleTypeId,
          companyId:           existing.companyId,
          daysOfWeek:          existing.daysOfWeek,
          timeFrom:            existing.timeFrom,
          timeTo:              existing.timeTo,
          effectiveFrom:       now,
          createdById:         who,
          ...merged,
        },
      })

      if (changedFields.length > 0) {
        await tx.pricingFactorChangeLog.createMany({
          data: changedFields.map((field) => ({
            rateCardId:  next.id,
            fieldChanged: field,
            oldValue:    existing[field] != null ? String(dec(existing[field])) : null,
            newValue:    merged[field] != null ? String(dec(merged[field])) : null,
            reason:      data.reason,
            changedById: who,
          })),
        })
      }

      return next
    })

    ok(res, serializeRateCard(result), 'Rate card superseded')
  } catch (err) {
    serverError(res, err)
  }
}

// PATCH /admin/pricing-rate-cards/:id/deactivate
export async function deactivatePricingRateCard(req: Request, res: Response) {
  try {
    const id = BigInt(String(req.params.id))
    const reason = z.object({ reason: z.string().min(3) }).parse(req.body).reason

    const existing = await prisma.pricingRateCard.findUnique({ where: { id } })
    if (!existing) { fail(res, 'Rate card not found'); return }

    await prisma.$transaction([
      prisma.pricingRateCard.update({ where: { id }, data: { isActive: false, effectiveTo: existing.effectiveTo ?? new Date() } }),
      prisma.pricingFactorChangeLog.create({
        data: { rateCardId: id, fieldChanged: 'isActive', oldValue: 'true', newValue: 'false', reason, changedById: adminId(req) },
      }),
    ])

    ok(res, {}, 'Rate card deactivated')
  } catch (err) {
    serverError(res, err)
  }
}

// GET /admin/pricing-rate-cards/:id/history
export async function getPricingRateCardHistory(req: Request, res: Response) {
  try {
    const id = BigInt(String(req.params.id))
    const card = await prisma.pricingRateCard.findUnique({ where: { id }, select: { scope: true, companyId: true } })
    if (!card) { fail(res, 'Rate card not found'); return }
    if (card.scope === 'company' && !assertCompanyScope(req, res, card.companyId)) return
    const log = await prisma.pricingFactorChangeLog.findMany({
      where: { rateCardId: id },
      orderBy: { changedAt: 'desc' },
      include: { changedBy: { select: { username: true } } },
    })
    ok(res, log.map((l) => ({
      id:             l.id.toString(),
      field_changed:  l.fieldChanged,
      old_value:      l.oldValue,
      new_value:      l.newValue,
      reason:         l.reason,
      changed_by:     l.changedBy.username,
      changed_at:     l.changedAt.toISOString(),
    })))
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Market benchmark rates ─────────────────────────────────────────────────

const CreateBenchmarkSchema = z.object({
  vehicle_type_id:  z.string().optional(),
  distance_band_km: z.enum(['0-5', '5-10', '10-20', '20-40', '40+']),
  competitor:       z.enum(['uber', 'bolt', 'indrive']).optional(),
  sampled_fare:     z.number().positive(),
  sampled_at:       z.string().optional(),
  source:           z.string().default('manual'),
})

// GET /admin/market-benchmark-rates
export async function listMarketBenchmarkRates(req: Request, res: Response) {
  try {
    const rates = await prisma.marketBenchmarkRate.findMany({
      orderBy: [{ distanceBandKm: 'asc' }, { sampledAt: 'desc' }],
      include: { vehicleType: { select: { title: true } } },
    })
    ok(res, rates.map((r) => ({
      id:                r.id.toString(),
      vehicle_type_id:   r.vehicleTypeId?.toString() ?? null,
      vehicle_type_title: r.vehicleType?.title ?? null,
      distance_band_km:  r.distanceBandKm,
      competitor:        r.competitor,
      sampled_fare:      dec(r.sampledFare),
      sampled_at:        r.sampledAt.toISOString(),
      source:            r.source,
      is_active:         r.isActive,
    })))
  } catch (err) {
    serverError(res, err)
  }
}

// POST /admin/market-benchmark-rates
export async function createMarketBenchmarkRate(req: Request, res: Response) {
  try {
    const data = CreateBenchmarkSchema.parse(req.body)
    const vehicleTypeId = data.vehicle_type_id ? BigInt(data.vehicle_type_id) : null

    const result = await prisma.$transaction(async (tx) => {
      // Superseded by the new sample below — keeps "latest active wins" for
      // this exact (band, vehicle type, competitor) combination unambiguous
      // rather than relying purely on sampledAt ordering.
      await tx.marketBenchmarkRate.updateMany({
        where: { distanceBandKm: data.distance_band_km, vehicleTypeId, competitor: data.competitor ?? null, isActive: true },
        data:  { isActive: false },
      })
      return tx.marketBenchmarkRate.create({
        data: {
          vehicleTypeId,
          distanceBandKm: data.distance_band_km,
          competitor:     data.competitor ?? null,
          sampledFare:    data.sampled_fare,
          sampledAt:      data.sampled_at ? new Date(data.sampled_at) : new Date(),
          source:         data.source,
          enteredById:    adminId(req),
        },
      })
    })

    ok(res, { id: result.id.toString() }, 'Benchmark sample recorded')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Corporate savings reports ──────────────────────────────────────────────

// GET /admin/savings-reports?company_id=
export async function listCorporateSavingsReports(req: Request, res: Response) {
  try {
    const requestedCompanyId = req.query.company_id ? String(req.query.company_id) : undefined
    // A scoped admin only ever sees their own company's reports, regardless
    // of what company_id is passed — never trust a query param for scoping.
    if (requestedCompanyId && !assertCompanyScope(req, res, requestedCompanyId)) return
    const companyId = req.admin?.isSuperAdmin ? requestedCompanyId : (req.admin?.scopeCompanyId ?? '__no_scope__')

    const reports = await prisma.corporateSavingsReport.findMany({
      where: companyId ? { companyId } : {},
      orderBy: { periodStart: 'desc' },
      include: { company: { select: { name: true } } },
    })
    ok(res, reports.map((r) => ({
      id:                            r.id.toString(),
      company_id:                    r.companyId,
      company_name:                  r.company.name,
      period_start:                  r.periodStart.toISOString().slice(0, 10),
      period_end:                    r.periodEnd.toISOString().slice(0, 10),
      total_rides:                   r.totalRides,
      total_market_benchmark_cost:   dec(r.totalMarketBenchmarkCost),
      total_org_spend:               dec(r.totalOrgSpend),
      total_savings:                 dec(r.totalSavings),
      savings_percentage:            dec(r.savingsPercentage),
      status:                        r.status,
      pdf_url:                       r.pdfUrl,
      generated_at:                  r.generatedAt.toISOString(),
    })))
  } catch (err) {
    serverError(res, err)
  }
}

// POST /admin/savings-reports/generate
const GenerateReportSchema = z.object({
  company_id:   z.string().uuid(),
  period_start: z.string(),
  period_end:   z.string(),
})

export async function generateCorporateSavingsReport(req: Request, res: Response) {
  try {
    const data = GenerateReportSchema.parse(req.body)
    // Self-service for the company's own admin — it only ever aggregates
    // data already scoped to that company, so this doesn't need to be
    // super-admin-only the way rate cards/benchmarks are.
    if (!assertCompanyScope(req, res, data.company_id)) return
    const periodStart = new Date(data.period_start)
    const periodEnd = new Date(data.period_end)

    const company = await prisma.company.findUnique({ where: { id: data.company_id } })
    if (!company) { fail(res, 'Company not found'); return }

    const records = await prisma.rideSavingsRecord.findMany({
      where: { companyId: data.company_id, rideDate: { gte: periodStart, lte: periodEnd } },
    })

    // total_savings is always benchmark - actual org spend, never derived
    // from CC Ride's own fare formula (computedFairFare), so the figure
    // holds up independently in a renewal conversation with the client.
    const totalRides = records.length
    const totalMarketBenchmarkCost = records.reduce((sum, r) => sum + dec(r.computedMarketBenchmark ?? r.computedFairFare), 0)
    const totalOrgSpend = records.reduce((sum, r) => sum + dec(r.actualOrgCost), 0)
    const totalSavings = totalMarketBenchmarkCost - totalOrgSpend
    const savingsPercentage = totalMarketBenchmarkCost > 0 ? (totalSavings / totalMarketBenchmarkCost) * 100 : 0

    const report = await prisma.corporateSavingsReport.create({
      data: {
        companyId: data.company_id,
        periodStart, periodEnd,
        totalRides,
        totalMarketBenchmarkCost,
        totalOrgSpend,
        totalSavings,
        savingsPercentage,
        generatedById: adminId(req),
      },
    })

    ok(res, { id: report.id.toString() }, 'Savings report generated')
  } catch (err) {
    serverError(res, err)
  }
}

// PATCH /admin/savings-reports/:id/status
const UpdateReportStatusSchema = z.object({ status: z.enum(['draft', 'sent', 'archived']) })

export async function updateSavingsReportStatus(req: Request, res: Response) {
  try {
    const id = BigInt(String(req.params.id))
    const { status } = UpdateReportStatusSchema.parse(req.body)
    await prisma.corporateSavingsReport.update({ where: { id }, data: { status } })
    ok(res, {}, 'Status updated')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Employee / department savings drill-down ───────────────────────────────
// Grouped on the fly from RideSavingsRecord rather than a materialized
// rollup table — simpler and always current; revisit only if a company's
// ride volume ever makes this slow in practice.

const BreakdownSchema = z.object({
  company_id:   z.string().uuid(),
  period_start: z.string(),
  period_end:   z.string(),
  group_by:     z.enum(['employee', 'department']),
})

// GET /admin/savings-reports/breakdown?company_id=&period_start=&period_end=&group_by=
export async function getSavingsBreakdown(req: Request, res: Response) {
  try {
    const data = BreakdownSchema.parse(req.query)
    if (!assertCompanyScope(req, res, data.company_id)) return

    const periodStart = new Date(data.period_start)
    const periodEnd = new Date(data.period_end)

    const records = await prisma.rideSavingsRecord.findMany({
      where: { companyId: data.company_id, rideDate: { gte: periodStart, lte: periodEnd } },
      include: {
        employee: { select: { id: true, jobTitle: true, user: { select: { name: true } } } },
        booking:  { select: { departmentId: true, department: { select: { name: true } } } },
      },
    })

    const groups = new Map<string, { key: string; label: string; rides: number; marketBenchmark: number; orgSpend: number }>()
    for (const r of records) {
      const key = data.group_by === 'employee'
        ? (r.employeeId?.toString() ?? 'unassigned')
        : (r.booking.departmentId?.toString() ?? 'unassigned')
      const label = data.group_by === 'employee'
        ? (r.employee?.user?.name ?? 'Unassigned')
        : (r.booking.department?.name ?? 'No department')

      const g = groups.get(key) ?? { key, label, rides: 0, marketBenchmark: 0, orgSpend: 0 }
      g.rides += 1
      g.marketBenchmark += dec(r.computedMarketBenchmark ?? r.computedFairFare)
      g.orgSpend += dec(r.actualOrgCost)
      groups.set(key, g)
    }

    const rows = Array.from(groups.values())
      .map((g) => ({
        key: g.key,
        label: g.label,
        total_rides: g.rides,
        total_market_benchmark_cost: g.marketBenchmark,
        total_org_spend: g.orgSpend,
        total_savings: g.marketBenchmark - g.orgSpend,
        savings_percentage: g.marketBenchmark > 0 ? ((g.marketBenchmark - g.orgSpend) / g.marketBenchmark) * 100 : 0,
      }))
      .sort((a, b) => b.total_savings - a.total_savings)

    ok(res, rows)
  } catch (err) {
    serverError(res, err)
  }
}
