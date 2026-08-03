/**
 * Admin — Branch fleet management (company-owned "pool" vehicles & drivers)
 */
import { Request, Response } from 'express'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'
import { assertCompanyScope, assertBranchScope } from '../../lib/adminScope'

async function loadBranch(companyId: string, branchId: string) {
  return prisma.companyBranch.findFirst({ where: { id: BigInt(branchId), companyId } })
}

// ─── GET /admin/companies/:companyId/branches/:branchId/fleet ─────────────────

export async function listBranchFleet(req: Request, res: Response) {
  try {
    const companyId = String(req.params.companyId)
    const branchId   = String(req.params.branchId)
    if (!assertCompanyScope(req, res, companyId)) return
    if (!assertBranchScope(req, res, BigInt(branchId))) return

    const branch = await loadBranch(companyId, branchId)
    if (!branch) { fail(res, 'Branch not found'); return }

    const [vehicles, drivers] = await Promise.all([
      prisma.vehicle.findMany({
        where:   { ownerBranchId: branch.id },
        include: {
          driver: { select: { name: true, mobile: true } },
          model:  { select: { title: true } },
          type:   { select: { title: true } },
        },
        orderBy: { createdAt: 'desc' },
      }),
      prisma.driverProfile.findMany({
        where:   { poolBranchId: branch.id },
        include: { user: { select: { name: true, mobile: true, email: true } } },
        orderBy: { createdAt: 'desc' },
      }),
    ])

    ok(res, {
      vehicles: vehicles.map((v) => ({
        id:            v.id.toString(),
        driver_id:     v.driverId,
        driver_name:   v.driver.name,
        driver_mobile: v.driver.mobile,
        model:         v.model.title,
        type:          v.type.title,
        license_plate: v.licensePlate,
        status:        v.status,
      })),
      drivers: drivers.map((d) => ({
        id:     d.userId,
        name:   d.user.name,
        mobile: d.user.mobile,
        email:  d.user.email ?? '',
        status: d.status,
      })),
    })
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /admin/companies/:companyId/branches/:branchId/fleet/vehicles ───────
// body: { vehicle_id } — marks an existing vehicle as this branch's pool vehicle

export async function assignVehicleToBranch(req: Request, res: Response) {
  try {
    const companyId = String(req.params.companyId)
    const branchId   = String(req.params.branchId)
    if (!assertCompanyScope(req, res, companyId)) return
    if (!assertBranchScope(req, res, BigInt(branchId))) return

    const branch = await loadBranch(companyId, branchId)
    if (!branch) { fail(res, 'Branch not found'); return }

    const { vehicle_id } = req.body as { vehicle_id: string }
    if (!vehicle_id) { fail(res, 'vehicle_id is required'); return }

    const vehicle = await prisma.vehicle.findUnique({ where: { id: BigInt(vehicle_id) } })
    if (!vehicle) { fail(res, 'Vehicle not found'); return }

    await prisma.vehicle.update({
      where: { id: vehicle.id },
      data:  { ownerCompanyId: companyId, ownerBranchId: branch.id },
    })

    ok(res, { vehicle_id }, 'Vehicle added to branch fleet')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /admin/companies/:companyId/branches/:branchId/fleet/vehicles/remove ─
// body: { vehicle_id } — releases a vehicle back to being a personal (non-pool) vehicle

export async function removeVehicleFromBranch(req: Request, res: Response) {
  try {
    const companyId = String(req.params.companyId)
    const branchId   = String(req.params.branchId)
    if (!assertCompanyScope(req, res, companyId)) return
    if (!assertBranchScope(req, res, BigInt(branchId))) return

    const { vehicle_id } = req.body as { vehicle_id: string }
    if (!vehicle_id) { fail(res, 'vehicle_id is required'); return }

    const vehicle = await prisma.vehicle.findUnique({ where: { id: BigInt(vehicle_id) } })
    if (!vehicle || vehicle.ownerBranchId?.toString() !== branchId) { fail(res, 'Vehicle is not part of this branch fleet'); return }

    await prisma.vehicle.update({
      where: { id: vehicle.id },
      data:  { ownerCompanyId: null, ownerBranchId: null },
    })

    ok(res, { vehicle_id }, 'Vehicle removed from branch fleet')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /admin/companies/:companyId/branches/:branchId/fleet/drivers ────────
// body: { driver_id } — marks an existing driver as this branch's pool driver

export async function assignDriverToBranch(req: Request, res: Response) {
  try {
    const companyId = String(req.params.companyId)
    const branchId   = String(req.params.branchId)
    if (!assertCompanyScope(req, res, companyId)) return
    if (!assertBranchScope(req, res, BigInt(branchId))) return

    const branch = await loadBranch(companyId, branchId)
    if (!branch) { fail(res, 'Branch not found'); return }

    const { driver_id } = req.body as { driver_id: string }
    if (!driver_id) { fail(res, 'driver_id is required'); return }

    const driver = await prisma.driverProfile.findUnique({ where: { userId: driver_id } })
    if (!driver) { fail(res, 'Driver not found'); return }

    await prisma.driverProfile.update({
      where: { userId: driver_id },
      data:  { poolCompanyId: companyId, poolBranchId: branch.id },
    })

    ok(res, { driver_id }, 'Driver added to branch fleet')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /admin/companies/:companyId/branches/:branchId/fleet/drivers/remove ─
// body: { driver_id } — releases a driver back to being an independent driver

export async function removeDriverFromBranch(req: Request, res: Response) {
  try {
    const companyId = String(req.params.companyId)
    const branchId   = String(req.params.branchId)
    if (!assertCompanyScope(req, res, companyId)) return
    if (!assertBranchScope(req, res, BigInt(branchId))) return

    const { driver_id } = req.body as { driver_id: string }
    if (!driver_id) { fail(res, 'driver_id is required'); return }

    const driver = await prisma.driverProfile.findUnique({ where: { userId: driver_id } })
    if (!driver || driver.poolBranchId?.toString() !== branchId) { fail(res, 'Driver is not part of this branch fleet'); return }

    await prisma.driverProfile.update({
      where: { userId: driver_id },
      data:  { poolCompanyId: null, poolBranchId: null },
    })

    ok(res, { driver_id }, 'Driver removed from branch fleet')
  } catch (err) {
    serverError(res, err)
  }
}
