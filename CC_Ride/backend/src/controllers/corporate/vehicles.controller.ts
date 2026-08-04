import { Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'

function picUrl(path: string | null): string {
  if (!path) return ''
  return path.startsWith('http') ? path : `https://api.ccride.ng${path}`
}

// ─── GET /corporate/pool-vehicles ─────────────────────────────────────────────
// Org admin: list this company's pool vehicles.

export async function listPoolVehicles(req: Request, res: Response) {
  try {
    const companyId = req.companyId!

    const vehicles = await prisma.vehicle.findMany({
      where: { companyId },
      include: { model: true, type: true, color: true },
      orderBy: { createdAt: 'desc' },
    })

    ok(res, vehicles.map((v) => ({
      id:            v.id.toString(),
      photo:         picUrl(v.photoUrl),
      model_id:      v.modelId.toString(),
      model_title:   v.model.title,
      type_id:       v.typeId.toString(),
      type_title:    v.type.title,
      color_id:      v.colorId.toString(),
      color_title:   v.color.title,
      year:          v.year,
      license_plate: v.licensePlate,
      seat_capacity: v.seatCapacity,
      status:        v.status,
    })))
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /corporate/pool-vehicles ────────────────────────────────────────────
// Org admin: register a new pool vehicle for this company.

const RegisterPoolVehicleSchema = z.object({
  company_id:    z.string().uuid(),
  model_id:      z.string(),
  type_id:       z.string(),
  color_id:      z.string(),
  year:          z.number().int().min(1990).max(2100),
  license_plate: z.string().min(3),
  seat_capacity: z.number().int().min(1).max(20).optional(),
})

export async function registerPoolVehicle(req: Request, res: Response) {
  try {
    const data      = RegisterPoolVehicleSchema.parse(req.body)
    const companyId = req.companyId!

    const vehicle = await prisma.vehicle.create({
      data: {
        companyId,
        driverId:     null,
        modelId:      BigInt(data.model_id),
        typeId:       BigInt(data.type_id),
        colorId:      BigInt(data.color_id),
        year:         data.year,
        licensePlate: data.license_plate.toUpperCase(),
        seatCapacity: data.seat_capacity ?? 4,
        status:       'approved',
      },
      include: { model: true, type: true, color: true },
    })

    ok(res, {
      id:            vehicle.id.toString(),
      model_title:   vehicle.model.title,
      type_title:    vehicle.type.title,
      color_title:   vehicle.color.title,
      license_plate: vehicle.licensePlate,
    }, 'Pool vehicle registered')
  } catch (err: any) {
    if (err.code === 'P2002') { fail(res, 'License plate already registered'); return }
    serverError(res, err)
  }
}

// ─── GET /corporate/driver-access ─────────────────────────────────────────────
// A driver's own currently-active pool vehicle access grants. Callable by any
// employee (used by the mobile app's mode-selection flow), not just admins.

export async function listDriverVehicleAccess(req: Request, res: Response) {
  try {
    const companyId = req.companyId!
    const driverId  = (req.query.driver_id as string) || req.user.id

    const grants = await prisma.driverVehicleAccess.findMany({
      where: {
        isActive: true,
        driverId,
        vehicle: { companyId },
      },
      include: { vehicle: { include: { model: true, type: true, color: true } } },
    })

    ok(res, grants.map((g) => ({
      access_id:     g.id.toString(),
      vehicle_id:    g.vehicle.id.toString(),
      photo:         picUrl(g.vehicle.photoUrl),
      model_title:   g.vehicle.model.title,
      type_title:    g.vehicle.type.title,
      color_title:   g.vehicle.color.title,
      license_plate: g.vehicle.licensePlate,
      status:        g.vehicle.status,
    })))
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /corporate/driver-access/grant ──────────────────────────────────────
// Org admin: give an employee access to drive a specific pool vehicle.

const GrantAccessSchema = z.object({
  company_id: z.string().uuid(),
  vehicle_id: z.string(),
  driver_id:  z.string().uuid(),
})

export async function grantDriverVehicleAccess(req: Request, res: Response) {
  try {
    const data      = GrantAccessSchema.parse(req.body)
    const companyId = req.companyId!

    const vehicle = await prisma.vehicle.findFirst({
      where: { id: BigInt(data.vehicle_id), companyId },
    })
    if (!vehicle) { fail(res, 'Pool vehicle not found for this company'); return }

    const membership = await prisma.companyEmployee.findFirst({
      where: { companyId, userId: data.driver_id, isActive: true },
    })
    if (!membership) { fail(res, 'Driver is not an active employee of this company'); return }

    await prisma.driverVehicleAccess.upsert({
      where: {
        vehicleId_driverId: { vehicleId: vehicle.id, driverId: data.driver_id },
      },
      update: { isActive: true, revokedAt: null },
      create: { vehicleId: vehicle.id, driverId: data.driver_id, isActive: true },
    })

    ok(res, {}, 'Access granted')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /corporate/driver-access/revoke ─────────────────────────────────────

const RevokeAccessSchema = z.object({
  company_id: z.string().uuid(),
  vehicle_id: z.string(),
  driver_id:  z.string().uuid(),
})

export async function revokeDriverVehicleAccess(req: Request, res: Response) {
  try {
    const data      = RevokeAccessSchema.parse(req.body)
    const companyId = req.companyId!

    const vehicle = await prisma.vehicle.findFirst({
      where: { id: BigInt(data.vehicle_id), companyId },
    })
    if (!vehicle) { fail(res, 'Pool vehicle not found for this company'); return }

    await prisma.driverVehicleAccess.updateMany({
      where: { vehicleId: vehicle.id, driverId: data.driver_id },
      data:  { isActive: false, revokedAt: new Date() },
    })

    ok(res, {}, 'Access revoked')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /corporate/employees/:employee_id/approve-personal-vehicle ─────────
// Org admin: authorize an employee to drive their own registered vehicle for
// cash earnings ("own-car driver" mode). Toggle-able (approve/unapprove).

const ApprovePersonalVehicleSchema = z.object({
  company_id: z.string().uuid(),
  approved:   z.boolean().default(true),
})

export async function approvePersonalVehicle(req: Request, res: Response) {
  try {
    const data       = ApprovePersonalVehicleSchema.parse(req.body)
    const companyId  = req.companyId!
    const employeeId = BigInt(String(req.params.employee_id))

    const membership = await prisma.companyEmployee.findFirst({
      where: { id: employeeId, companyId },
    })
    if (!membership) { fail(res, 'Employee not found'); return }

    await prisma.companyEmployee.update({
      where: { id: membership.id },
      data:  { personalVehicleApproved: data.approved },
    })

    ok(res, {}, data.approved ? 'Personal vehicle approved' : 'Personal vehicle approval revoked')
  } catch (err) {
    serverError(res, err)
  }
}
