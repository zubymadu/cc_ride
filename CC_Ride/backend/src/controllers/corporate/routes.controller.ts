import { Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'

// ─── GET /corporate/routes ─────────────────────────────────────────────────
// Org admin: list this company's fixed routes with stop/schedule counts.

export async function listRoutes(req: Request, res: Response) {
  try {
    const companyId = req.companyId!

    const routes = await prisma.route.findMany({
      where: { companyId },
      include: { _count: { select: { stops: true, schedules: true } } },
      orderBy: { createdAt: 'desc' },
    })

    ok(res, routes.map((r) => ({
      id:               r.id,
      code:             r.code,
      name:             r.name,
      origin_name:      r.originName,
      destination_name: r.destinationName,
      is_active:        r.isActive,
      stop_count:       r._count.stops,
      schedule_count:   r._count.schedules,
    })))
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /corporate/routes ────────────────────────────────────────────────
// Org admin: create a route + its ordered stops in one call.

const StopSchema = z.object({
  name: z.string().min(1),
  lat:  z.number(),
  lng:  z.number(),
})

const InlineScheduleSchema = z.object({
  departure_time: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/),
  days_of_week:   z.array(z.number().int().min(0).max(6)).min(1),
  driver_id:      z.string().uuid(),
  vehicle_id:     z.string(),
  seat_capacity:  z.number().int().min(1).max(20),
  fare:           z.number().positive(),
})

const CreateRouteSchema = z.object({
  company_id:        z.string().uuid(),
  code:              z.string().min(2),
  name:              z.string().min(2),
  origin_name:       z.string().min(1),
  origin_lat:        z.number(),
  origin_lng:        z.number(),
  destination_name:  z.string().min(1),
  destination_lat:   z.number(),
  destination_lng:   z.number(),
  stops:             z.array(StopSchema).default([]),
  // Optional — lets an admin who already knows the driver/vehicle/seat
  // capacity set everything up in a single call, the same one-step
  // experience the driver-side app already has via legacyCreateDriverRoute.
  // Route-shell-only (no schedule yet) stays valid for setting up driver/
  // vehicle assignment later.
  schedule:          InlineScheduleSchema.optional(),
})

export async function createRoute(req: Request, res: Response) {
  try {
    const data      = CreateRouteSchema.parse(req.body)
    const companyId = req.companyId!

    if (data.schedule) {
      const vehicleId = BigInt(data.schedule.vehicle_id)
      const vehicle = await prisma.vehicle.findFirst({ where: { id: vehicleId, companyId } })
      if (!vehicle) { fail(res, 'Pool vehicle not found for this company'); return }
      const access = await prisma.driverVehicleAccess.findFirst({
        where: { vehicleId, driverId: data.schedule.driver_id, isActive: true },
      })
      if (!access) { fail(res, 'Driver does not have active access to this pool vehicle'); return }
    }

    const route = await prisma.route.create({
      data: {
        code:              data.code.toUpperCase(),
        name:              data.name,
        companyId,
        originName:        data.origin_name,
        originLat:         data.origin_lat,
        originLng:         data.origin_lng,
        destinationName:   data.destination_name,
        destinationLat:    data.destination_lat,
        destinationLng:    data.destination_lng,
        ...(data.schedule ? {
          schedules: {
            create: {
              departureTime: data.schedule.departure_time,
              daysOfWeek:    data.schedule.days_of_week,
              driverId:      data.schedule.driver_id,
              vehicleId:     BigInt(data.schedule.vehicle_id),
              seatCapacity:  data.schedule.seat_capacity,
              fare:          data.schedule.fare,
            },
          },
        } : {}),
      },
    })

    if (data.stops.length > 0) {
      await prisma.routeStop.createMany({
        data: data.stops.map((s, i) => ({
          routeId:   route.id,
          stopOrder: i,
          name:      s.name,
          lat:       s.lat,
          lng:       s.lng,
        })),
      })
    }

    ok(res, { id: route.id, code: route.code }, 'Route created')
  } catch (err: any) {
    if (err.code === 'P2002') { fail(res, 'Route code already in use'); return }
    serverError(res, err)
  }
}

// ─── GET /corporate/routes/:id/schedules ───────────────────────────────────

export async function listRouteSchedules(req: Request, res: Response) {
  try {
    const companyId = req.companyId!
    const routeId   = String(req.params.id)

    const route = await prisma.route.findFirst({ where: { id: routeId, companyId } })
    if (!route) { fail(res, 'Route not found for this company'); return }

    const schedules = await prisma.routeSchedule.findMany({
      where: { routeId },
      include: { driver: { select: { name: true } }, vehicle: { include: { model: true } } },
      orderBy: { departureTime: 'asc' },
    })

    ok(res, schedules.map((s) => ({
      id:             s.id.toString(),
      departure_time: s.departureTime,
      days_of_week:   s.daysOfWeek,
      driver_id:      s.driverId ?? '',
      driver_name:    s.driver?.name ?? '',
      vehicle_id:     s.vehicleId?.toString() ?? '',
      vehicle_title:  s.vehicle?.model.title ?? '',
      seat_capacity:  s.seatCapacity,
      fare:           s.fare,
      is_active:      s.isActive,
    })))
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /corporate/routes/:id/schedules ──────────────────────────────────
// Org admin: add a recurring departure to a route, assigning a pool driver
// (who must hold an active DriverVehicleAccess grant for the pool vehicle).

const CreateScheduleSchema = z.object({
  company_id:     z.string().uuid(),
  departure_time: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/),
  days_of_week:   z.array(z.number().int().min(0).max(6)).min(1),
  driver_id:      z.string().uuid(),
  vehicle_id:     z.string(),
  seat_capacity:  z.number().int().min(1).max(20),
  fare:           z.number().positive(),
})

export async function createRouteSchedule(req: Request, res: Response) {
  try {
    const data      = CreateScheduleSchema.parse(req.body)
    const companyId = req.companyId!
    const routeId   = String(req.params.id)

    const route = await prisma.route.findFirst({ where: { id: routeId, companyId } })
    if (!route) { fail(res, 'Route not found for this company'); return }

    const vehicleId = BigInt(data.vehicle_id)

    const vehicle = await prisma.vehicle.findFirst({ where: { id: vehicleId, companyId } })
    if (!vehicle) { fail(res, 'Pool vehicle not found for this company'); return }

    const access = await prisma.driverVehicleAccess.findFirst({
      where: { vehicleId, driverId: data.driver_id, isActive: true },
    })
    if (!access) { fail(res, 'Driver does not have active access to this pool vehicle'); return }

    const schedule = await prisma.routeSchedule.create({
      data: {
        routeId,
        departureTime: data.departure_time,
        daysOfWeek:    data.days_of_week,
        driverId:      data.driver_id,
        vehicleId,
        seatCapacity:  data.seat_capacity,
        fare:          data.fare,
      },
    })

    ok(res, { id: schedule.id.toString() }, 'Schedule created')
  } catch (err) {
    serverError(res, err)
  }
}
