/**
 * Admin — company self-service pool fleet & driver management for the web
 * console. Mirrors src/controllers/corporate/vehicles.controller.ts (the
 * Flutter-app-facing, User-JWT/requireCompanyMember equivalent) but scoped
 * via AdminUser/assertCompanyScope, since the two admin auth systems don't
 * share a session.
 */
import { Request, Response } from 'express'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import crypto from 'crypto'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'
import { assertCompanyScope } from '../../lib/adminScope'

function picUrl(path: string | null): string {
  if (!path) return ''
  return path.startsWith('http') ? path : `https://api.ccride.ng${path}`
}

// ─── Reference data ──────────────────────────────────────────────────────────

export async function listVehicleModels(_req: Request, res: Response) {
  try {
    const models = await prisma.vehicleModel.findMany({ where: { status: true }, orderBy: { title: 'asc' } })
    ok(res, models.map((m) => ({ id: m.id.toString(), title: m.title })))
  } catch (err) {
    serverError(res, err)
  }
}

export async function listVehicleColors(_req: Request, res: Response) {
  try {
    const colors = await prisma.vehicleColor.findMany({ where: { status: true }, orderBy: { title: 'asc' } })
    ok(res, colors.map((c) => ({ id: c.id.toString(), title: c.title })))
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Pool vehicles ───────────────────────────────────────────────────────────

// GET /admin/companies/:id/pool-vehicles
export async function listPoolVehicles(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return

    const vehicles = await prisma.vehicle.findMany({
      where: { companyId },
      include: {
        model: true, type: true, color: true, branch: { select: { name: true } },
        driverAccessGrants: { where: { isActive: true }, include: { driver: { select: { name: true } } } },
      },
      orderBy: { createdAt: 'desc' },
    })

    ok(res, vehicles.map((v) => ({
      id:            v.id.toString(),
      photo:         picUrl(v.photoUrl),
      model_title:   v.model.title,
      type_title:    v.type.title,
      color_title:   v.color.title,
      year:          v.year,
      license_plate: v.licensePlate,
      seat_capacity: v.seatCapacity,
      status:        v.status,
      // null ⇒ this pool vehicle isn't tied to any one branch, so it's only
      // ever reachable via a company-wide (branch_id: null) sharing
      // agreement — never a branch-scoped one.
      branch_id:     v.branchId?.toString() ?? null,
      branch_name:   v.branch?.name ?? null,
      assigned_drivers: v.driverAccessGrants.map((a) => ({ driver_id: a.driverId, name: a.driver.name })),
    })))
  } catch (err) {
    serverError(res, err)
  }
}

const CreatePoolVehicleSchema = z.object({
  model_id:      z.string(),
  type_id:       z.string(),
  color_id:      z.string(),
  year:          z.number().int().min(1990).max(2100),
  license_plate: z.string().min(3),
  seat_capacity: z.number().int().min(1).max(20).optional(),
  branch_id:     z.string().optional(),
})

// POST /admin/companies/:id/pool-vehicles
export async function createPoolVehicle(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const data = CreatePoolVehicleSchema.parse(req.body)

    let branchId: bigint | null = null
    if (data.branch_id) {
      const branch = await prisma.companyBranch.findFirst({ where: { id: BigInt(data.branch_id), companyId } })
      if (!branch) { fail(res, 'Branch not found'); return }
      branchId = branch.id
    }

    const vehicle = await prisma.vehicle.create({
      data: {
        companyId,
        branchId,
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
      id: vehicle.id.toString(),
      model_title: vehicle.model.title,
      type_title: vehicle.type.title,
      color_title: vehicle.color.title,
      license_plate: vehicle.licensePlate,
    }, 'Pool vehicle registered')
  } catch (err: any) {
    if (err?.code === 'P2002') { fail(res, 'License plate already registered'); return }
    serverError(res, err)
  }
}

const UpdatePoolVehicleSchema = z.object({
  status:    z.enum(['pending', 'approved', 'rejected', 'inactive']).optional(),
  // Explicit null clears the assignment (moves the vehicle back to
  // company-wide, no specific branch); omitted leaves it unchanged.
  branch_id: z.string().nullable().optional(),
})

// PATCH /admin/companies/:id/pool-vehicles/:vehicleId
export async function updatePoolVehicleStatus(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const vehicleId = BigInt(String(req.params.vehicleId))
    const { status, branch_id } = UpdatePoolVehicleSchema.parse(req.body)

    const vehicle = await prisma.vehicle.findFirst({ where: { id: vehicleId, companyId } })
    if (!vehicle) { fail(res, 'Pool vehicle not found for this company'); return }

    const data: { status?: typeof status; branchId?: bigint | null } = {}
    if (status !== undefined) data.status = status
    if (branch_id !== undefined) {
      if (branch_id === null) {
        data.branchId = null
      } else {
        const branch = await prisma.companyBranch.findFirst({ where: { id: BigInt(branch_id), companyId } })
        if (!branch) { fail(res, 'Branch not found'); return }
        data.branchId = branch.id
      }
    }

    await prisma.vehicle.update({ where: { id: vehicleId }, data })
    ok(res, {}, 'Vehicle updated')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Pool drivers ────────────────────────────────────────────────────────────
// A pool driver is always admin-created — this operates a company-owned
// vehicle and earns organisation points instead of cash, a corporate-
// sponsored arrangement a driver can't opt into unilaterally the way
// registering a personal vehicle works. Every pool driver requires a
// CompanyEmployee record with an employeeNumber assigned.

// GET /admin/companies/:id/pool-drivers
export async function listPoolDrivers(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return

    const employees = await prisma.companyEmployee.findMany({
      where: { companyId, isActive: true, user: { isDriver: true } },
      include: {
        user: { select: { id: true, name: true, mobile: true, driverProfile: { select: { status: true, averageRating: true } } } },
      },
      orderBy: { invitedAt: 'asc' },
    })

    const driverIds = employees.map((e) => e.userId)
    const grants = await prisma.driverVehicleAccess.findMany({
      where: { isActive: true, driverId: { in: driverIds }, vehicle: { companyId } },
      include: { vehicle: { select: { id: true, licensePlate: true } } },
    })
    const grantsByDriver = new Map<string, { vehicle_id: string; license_plate: string }[]>()
    for (const g of grants) {
      const list = grantsByDriver.get(g.driverId) ?? []
      list.push({ vehicle_id: g.vehicle.id.toString(), license_plate: g.vehicle.licensePlate })
      grantsByDriver.set(g.driverId, list)
    }

    ok(res, employees.map((e) => ({
      employee_id:      e.id.toString(),
      user_id:          e.userId,
      name:             e.user.name,
      mobile:           e.user.mobile,
      employee_number:  e.employeeNumber ?? '',
      driver_status:    e.user.driverProfile?.status ?? 'pending',
      rating:           e.user.driverProfile ? Number(e.user.driverProfile.averageRating) : 0,
      assigned_vehicles: grantsByDriver.get(e.userId) ?? [],
    })))
  } catch (err) {
    serverError(res, err)
  }
}

const CreatePoolDriverSchema = z.object({
  name:            z.string().min(2),
  mobile:          z.string().min(7),
  email:           z.string().email().optional(),
  license_number:  z.string().min(3),
  license_expiry:  z.string(), // ISO date
  employee_number: z.string().min(1),
  department_id:   z.string().optional(),
  vehicle_id:      z.string().optional(), // grant access immediately if given
})

// POST /admin/companies/:id/pool-drivers
export async function createPoolDriver(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const data = CreatePoolDriverSchema.parse(req.body)

    const exists = await prisma.user.findFirst({ where: { mobile: data.mobile } })
    if (exists) { fail(res, 'A user with this phone number already exists'); return }

    const tempPassword = crypto.randomBytes(8).toString('hex')
    const hash = await bcrypt.hash(tempPassword, 10)

    const result = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          name: data.name,
          mobile: data.mobile,
          email: data.email ?? null,
          passwordHash: hash,
          isDriver: true,
          isMobileVerified: true,
          status: 'active',
          driverProfile: {
            create: {
              licenseNumber: data.license_number,
              licenseExpiry: new Date(data.license_expiry),
              status: 'active', // admin-provisioned pool drivers are pre-vetted by the org, not self-onboarded
            },
          },
        },
      })

      const employee = await tx.companyEmployee.create({
        data: {
          companyId,
          userId: user.id,
          departmentId: data.department_id ? BigInt(data.department_id) : null,
          employeeNumber: data.employee_number,
          role: 'employee',
          isActive: true,
          joinedAt: new Date(),
        },
      })

      if (data.vehicle_id) {
        const vehicle = await tx.vehicle.findFirst({ where: { id: BigInt(data.vehicle_id), companyId } })
        if (vehicle) {
          await tx.driverVehicleAccess.create({ data: { vehicleId: vehicle.id, driverId: user.id, isActive: true } })
        }
      }

      return { user, employee }
    })

    ok(res, {
      user_id: result.user.id,
      employee_id: result.employee.id.toString(),
      name: result.user.name,
      mobile: result.user.mobile,
      generated_password: tempPassword,
    }, 'Pool driver created')
  } catch (err: any) {
    if (err?.code === 'P2002') { fail(res, 'Employee number already in use for this company'); return }
    serverError(res, err)
  }
}

const GrantAccessSchema = z.object({ vehicle_id: z.string(), driver_id: z.string().uuid() })

// POST /admin/companies/:id/pool-drivers/grant
export async function grantPoolVehicleAccess(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const data = GrantAccessSchema.parse(req.body)

    const vehicle = await prisma.vehicle.findFirst({ where: { id: BigInt(data.vehicle_id), companyId } })
    if (!vehicle) { fail(res, 'Pool vehicle not found for this company'); return }

    const membership = await prisma.companyEmployee.findFirst({ where: { companyId, userId: data.driver_id, isActive: true } })
    if (!membership) { fail(res, 'Driver is not an active employee of this company'); return }

    await prisma.driverVehicleAccess.upsert({
      where: { vehicleId_driverId: { vehicleId: vehicle.id, driverId: data.driver_id } },
      update: { isActive: true, revokedAt: null },
      create: { vehicleId: vehicle.id, driverId: data.driver_id, isActive: true },
    })

    ok(res, {}, 'Access granted')
  } catch (err) {
    serverError(res, err)
  }
}

// POST /admin/companies/:id/pool-drivers/revoke
export async function revokePoolVehicleAccess(req: Request, res: Response) {
  try {
    const companyId = String(req.params.id)
    if (!assertCompanyScope(req, res, companyId)) return
    const data = GrantAccessSchema.parse(req.body)

    const vehicle = await prisma.vehicle.findFirst({ where: { id: BigInt(data.vehicle_id), companyId } })
    if (!vehicle) { fail(res, 'Pool vehicle not found for this company'); return }

    await prisma.driverVehicleAccess.updateMany({
      where: { vehicleId: vehicle.id, driverId: data.driver_id },
      data: { isActive: false, revokedAt: new Date() },
    })

    ok(res, {}, 'Access revoked')
  } catch (err) {
    serverError(res, err)
  }
}
