import { Request, Response } from 'express'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import crypto from 'crypto'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'
import { dec } from '../../lib/naira'
import { resolveRequiredIdentity } from '../../lib/identity'

export async function listDrivers(req: Request, res: Response) {
  try {
    const { status, search } = req.query as Record<string, string>
    const drivers = await prisma.driverProfile.findMany({
      where: {
        ...(status ? { status: status as any } : {}),  // enum cast: validated at DB level
        ...(search ? {
          user: {
            OR: [
              { name: { contains: search, mode: 'insensitive' } },
              { mobile: { contains: search } },
            ],
          },
        } : {}),
      },
      orderBy: { createdAt: 'desc' },
      take: 200,
      include: {
        user: {
          select: {
            name: true, email: true, mobile: true,
            // _count nested inside select (can't mix select + include)
            _count: { select: { ridesAsDriver: true } },
          },
        },
        documents: { where: { status: 'pending' }, select: { id: true } },
      },
    })

    ok(res, drivers.map((d) => ({
      user_id:           d.userId,
      name:              d.user.name,
      email:             d.user.email ?? '',
      mobile:            d.user.mobile,
      status:            d.status,
      average_rating:    dec(d.averageRating),
      total_trips:       d.user._count.ridesAsDriver,
      total_earnings:    dec(d.totalEarnings),
      license_expiry:    d.licenseExpiry?.toISOString().split('T')[0] ?? '',
      created_at:        d.createdAt.toISOString(),
      pending_documents: d.documents.length,
    })))
  } catch (err) {
    serverError(res, err)
  }
}

export async function approveDriver(req: Request, res: Response) {
  try {
    const { driver_id, action } = req.body as { driver_id: string; action: 'approve' | 'reject' }
    const newStatus = action === 'approve' ? 'active' : 'rejected'

    await prisma.$transaction([
      prisma.driverProfile.update({
        where: { userId: driver_id },
        data:  { status: newStatus as any },
      }),
      prisma.driverDocument.updateMany({
        where: { driverId: driver_id, status: 'pending' },
        data:  { status: action === 'approve' ? 'approved' : 'rejected' },
      }),
    ])

    ok(res, { driver_id, status: newStatus }, `Driver ${action}d`)
  } catch (err) {
    serverError(res, err)
  }
}

export async function updateDriverStatus(req: Request, res: Response) {
  try {
    const { driver_id, status } = req.body as { driver_id: string; status: string }
    const allowed = ['active', 'suspended', 'offline']
    if (!allowed.includes(status)) { fail(res, 'Invalid status'); return }

    await prisma.driverProfile.update({
      where: { userId: driver_id },
      data:  { status: status as any },
    })
    ok(res, { driver_id, status })
  } catch (err) {
    serverError(res, err)
  }
}

export async function listLiveRides(_req: Request, res: Response) {
  try {
    const bookings = await prisma.booking.findMany({
      where: { status: 'in_progress' },
      take: 100,
      include: {
        passenger: { select: { name: true } },
        driver:    { select: { name: true } },
        ride: {
          select: { originAddress: true, destinationAddress: true, startedAt: true },
          include: { tracking: { orderBy: { recordedAt: 'desc' }, take: 1 } },
        },
      },
    })

    ok(res, bookings.map((b) => ({
      id:          b.id,
      passenger:   b.passenger.name,
      driver:      b.driver?.name ?? '—',
      origin:      b.ride.originAddress,
      destination: b.ride.destinationAddress,
      driver_lat:  b.ride.tracking[0]?.lat ?? null,
      driver_lng:  b.ride.tracking[0]?.lng ?? null,
      started_at:  b.startedAt?.toISOString() ?? b.createdAt.toISOString(),
    })))
  } catch (err) {
    serverError(res, err)
  }
}

export async function listRides(req: Request, res: Response) {
  try {
    const { status } = req.query as Record<string, string>
    const bookings = await prisma.booking.findMany({
      where: status ? { status: status as any } : {},
      orderBy: { createdAt: 'desc' },
      take: 200,
      include: {
        passenger: { select: { name: true } },
        driver:    { select: { name: true } },
        ride:      { select: { originAddress: true, destinationAddress: true } },
        company:   { select: { name: true } },
      },
    })

    ok(res, bookings.map((b) => ({
      id:           b.id,
      // The row itself is booking-shaped (passenger/driver/fare view), but
      // editRide/deleteRide operate on the Ride record — a different id
      // space — so expose it explicitly for anything built against this list.
      ride_id:      b.rideId,
      passenger:    b.passenger.name,
      driver:       b.driver?.name ?? '—',
      company_name: b.company?.name ?? null,
      origin:       b.ride.originAddress,
      destination:  b.ride.destinationAddress,
      status:       b.status,
      total_amount: dec(b.totalAmount),
      created_at:   b.createdAt.toISOString(),
      is_corporate: !!b.companyId,
    })))
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /admin/drivers/create ───────────────────────────────────────────────

const CreateDriverSchema = z.object({
  name:            z.string().min(2),
  mobile:          z.string().min(7),
  email:           z.string().email().optional(),
  password:        z.string().min(6).optional(),
  license_number:  z.string().min(3),
  license_expiry:  z.string(), // ISO date YYYY-MM-DD
  nin:             z.string().optional(),
  passport_number: z.string().optional(),
  bvn:             z.string().optional(),
  auto_activate:   z.boolean().default(false),
})

export async function createDriver(req: Request, res: Response) {
  try {
    const data = CreateDriverSchema.parse(req.body)

    const identity = resolveRequiredIdentity(data.nin, data.passport_number)
    if (!identity.ok) { fail(res, identity.error); return }

    const exists = await prisma.user.findFirst({ where: { mobile: data.mobile } })
    if (exists) { fail(res, 'A user with this phone number already exists'); return }

    const password = data.password ?? crypto.randomBytes(8).toString('hex')
    const hash     = await bcrypt.hash(password, 10)

    const user = await prisma.user.create({
      data: {
        name:             data.name,
        mobile:           data.mobile,
        email:            data.email ?? null,
        nin:              identity.nin,
        passportNumber:   identity.passportNumber,
        passwordHash:     hash,
        isDriver:         true,
        isMobileVerified: true,
        status:           'active',
        driverProfile: {
          create: {
            licenseNumber: data.license_number,
            licenseExpiry: new Date(data.license_expiry),
            nin:    identity.nin, // mirrored here too — DriverProfile.nin predates the User-level field
            bvn:    data.bvn ?? null,
            status: data.auto_activate ? 'active' : 'pending',
          },
        },
      },
    })

    ok(res, {
      user_id: user.id,
      name:    user.name,
      mobile:  user.mobile,
      status:  data.auto_activate ? 'active' : 'pending',
      ...(data.password ? {} : { generated_password: password }),
    }, 'Driver registered')
  } catch (err: any) {
    if (err?.code === 'P2002') {
      const field = err?.meta?.target?.[0]
      if (field === 'nin') { fail(res, 'A different account already exists with this NIN'); return }
      if (field === 'passport_number') { fail(res, 'A different account already exists with this passport number'); return }
      fail(res, 'A user with this email already exists'); return
    }
    serverError(res, err)
  }
}

// ─── POST /admin/rides/create ─────────────────────────────────────────────────

const CreateRideAdminSchema = z.object({
  driver_id:              z.string().uuid(),
  origin_address:         z.string().min(5),
  origin_lat:             z.number(),
  origin_lng:             z.number(),
  destination_address:    z.string().min(5),
  destination_lat:        z.number(),
  destination_lng:        z.number(),
  scheduled_at:           z.string(),
  base_fare:              z.number().positive(),
  available_seats:        z.number().int().min(1).max(14).default(4),
  estimated_distance_km:  z.number().optional(),
  estimated_duration_min: z.number().int().optional(),
  trip_notes:             z.string().optional(),
})

export async function createRide(req: Request, res: Response) {
  try {
    const data = CreateRideAdminSchema.parse(req.body)

    const driver = await prisma.driverProfile.findUnique({ where: { userId: data.driver_id } })
    if (!driver) { fail(res, 'Driver not found'); return }

    const otp = () => String(Math.floor(100000 + Math.random() * 900000))

    const ride = await prisma.ride.create({
      data: {
        driverId:              data.driver_id,
        originAddress:         data.origin_address,
        originLat:             data.origin_lat,
        originLng:             data.origin_lng,
        destinationAddress:    data.destination_address,
        destinationLat:        data.destination_lat,
        destinationLng:        data.destination_lng,
        scheduledAt:           new Date(data.scheduled_at),
        baseFare:              data.base_fare,
        estimatedDistanceKm:   data.estimated_distance_km ?? null,
        estimatedDurationMin:  data.estimated_duration_min ?? null,
        availableSeats:        data.available_seats,
        tripNotes:             data.trip_notes ?? null,
        status:                'pending',
        pickupOtp:             otp(),
        dropoffOtp:            otp(),
      },
    })

    ok(res, {
      ride_id:      ride.id,
      driver_id:    ride.driverId,
      origin:       ride.originAddress,
      destination:  ride.destinationAddress,
      scheduled_at: ride.scheduledAt.toISOString(),
      base_fare:    dec(ride.baseFare),
      seats:        ride.availableSeats,
      status:       ride.status,
    }, 'Ride created')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── GET /admin/rides/live-positions ─────────────────────────────────────────
// Returns the latest GPS position for every active (in_progress) ride.
// Used as the initial snapshot when the admin tracking map loads.

export async function livePositions(_req: Request, res: Response) {
  try {
    // All rides currently in progress
    const rides = await prisma.ride.findMany({
      where: { status: 'in_progress' },
      select: {
        id:                true,
        driverId:          true,
        originAddress:     true,
        destinationAddress:true,
        bookings: {
          where:  { status: 'in_progress' },
          take:   1,
          select: {
            id:        true,
            passenger: { select: { name: true } },
          },
        },
        tracking: {
          orderBy: { recordedAt: 'desc' },
          take:    1,
          select:  { lat: true, lng: true, speedKmh: true, recordedAt: true },
        },
      },
    })

    // Fetch driver names separately (no mixed include/select at same level)
    const driverIds = [...new Set(rides.map((r) => r.driverId))]
    const drivers   = await prisma.user.findMany({
      where:  { id: { in: driverIds } },
      select: { id: true, name: true, mobile: true },
    })
    const driverMap = Object.fromEntries(drivers.map((d) => [d.id, d]))

    ok(res, rides.map((r) => {
      const pos  = r.tracking[0]
      const book = r.bookings[0]
      const drv  = driverMap[r.driverId]
      return {
        ride_id:      r.id,
        driver_id:    r.driverId,
        driver_name:  drv?.name ?? '—',
        driver_mobile:drv?.mobile ?? '',
        passenger:    book?.passenger?.name ?? '—',
        origin:       r.originAddress,
        destination:  r.destinationAddress,
        lat:          pos ? Number(pos.lat)      : null,
        lng:          pos ? Number(pos.lng)      : null,
        speed_kmh:    pos ? Number(pos.speedKmh) : null,
        last_seen:    pos?.recordedAt?.toISOString() ?? null,
      }
    }))
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Housekeeping: edit / delete a driver ───────────────────────────────────
// A "driver" is a User + DriverProfile pair — edits here correct data-entry
// mistakes (license details, contact info), not status (approveDriver/
// updateDriverStatus already own that, same reasoning as userAction vs
// editUser/deleteUser).

const EditDriverSchema = z.object({
  name:            z.string().min(2).optional(),
  email:           z.string().email().nullable().optional(),
  mobile:          z.string().min(7).optional(),
  license_number:  z.string().min(3).optional(),
  license_expiry:  z.string().optional(), // ISO date
  nin:             z.string().nullable().optional(),
  bvn:             z.string().nullable().optional(),
})

export async function editDriver(req: Request, res: Response) {
  try {
    const userId = String(req.params.id)
    const data = EditDriverSchema.parse(req.body)

    const driver = await prisma.driverProfile.findUnique({ where: { userId } })
    if (!driver) { fail(res, 'Driver not found'); return }

    const [user] = await prisma.$transaction([
      prisma.user.update({
        where: { id: userId },
        data: {
          ...(data.name   !== undefined ? { name: data.name }     : {}),
          ...(data.email  !== undefined ? { email: data.email }   : {}),
          ...(data.mobile !== undefined ? { mobile: data.mobile } : {}),
        },
      }),
      prisma.driverProfile.update({
        where: { userId },
        data: {
          ...(data.license_number !== undefined ? { licenseNumber: data.license_number }        : {}),
          ...(data.license_expiry !== undefined ? { licenseExpiry: new Date(data.license_expiry) } : {}),
          ...(data.nin            !== undefined ? { nin: data.nin }                              : {}),
          ...(data.bvn            !== undefined ? { bvn: data.bvn }                              : {}),
        },
      }),
    ])
    ok(res, { id: user.id, name: user.name, email: user.email, mobile: user.mobile }, 'Driver updated')
  } catch (err: any) {
    if (err?.code === 'P2002') { fail(res, 'Another account already uses that email or mobile number'); return }
    serverError(res, err)
  }
}

export async function deleteDriver(req: Request, res: Response) {
  try {
    const userId = String(req.params.id)
    const force = req.query.force === 'true'

    const driver = await prisma.driverProfile.findUnique({ where: { userId } })
    if (!driver) { fail(res, 'Driver not found'); return }

    if (!force) {
      const rideCount = await prisma.ride.count({ where: { driverId: userId, status: { in: ['completed', 'in_progress'] } } })
      if (rideCount > 0) {
        fail(res, `This driver has ${rideCount} real ride(s) on record — pass force=true to delete anyway (this permanently removes that history too)`)
        return
      }
    }

    // Deletes the underlying User row — DriverProfile cascades with it,
    // same as any other account deletion.
    await prisma.user.delete({ where: { id: userId } })
    ok(res, {}, 'Driver deleted')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Housekeeping: edit / delete a ride ─────────────────────────────────────

const EditRideSchema = z.object({
  origin_address:         z.string().min(5).optional(),
  origin_lat:             z.number().optional(),
  origin_lng:             z.number().optional(),
  destination_address:    z.string().min(5).optional(),
  destination_lat:        z.number().optional(),
  destination_lng:        z.number().optional(),
  scheduled_at:           z.string().optional(),
  base_fare:              z.number().positive().optional(),
  available_seats:        z.number().int().min(0).max(20).optional(),
  trip_notes:             z.string().nullable().optional(),
})

export async function editRide(req: Request, res: Response) {
  try {
    const id = String(req.params.id)
    const data = EditRideSchema.parse(req.body)

    const ride = await prisma.ride.findUnique({ where: { id } })
    if (!ride) { fail(res, 'Ride not found'); return }

    const updated = await prisma.ride.update({
      where: { id },
      data: {
        ...(data.origin_address      !== undefined ? { originAddress: data.origin_address }           : {}),
        ...(data.origin_lat          !== undefined ? { originLat: data.origin_lat }                    : {}),
        ...(data.origin_lng          !== undefined ? { originLng: data.origin_lng }                    : {}),
        ...(data.destination_address !== undefined ? { destinationAddress: data.destination_address }  : {}),
        ...(data.destination_lat     !== undefined ? { destinationLat: data.destination_lat }          : {}),
        ...(data.destination_lng     !== undefined ? { destinationLng: data.destination_lng }          : {}),
        ...(data.scheduled_at        !== undefined ? { scheduledAt: new Date(data.scheduled_at) }      : {}),
        ...(data.base_fare           !== undefined ? { baseFare: data.base_fare }                      : {}),
        ...(data.available_seats     !== undefined ? { availableSeats: data.available_seats }          : {}),
        ...(data.trip_notes          !== undefined ? { tripNotes: data.trip_notes }                    : {}),
      },
    })
    ok(res, { id: updated.id, status: updated.status }, 'Ride updated')
  } catch (err) {
    serverError(res, err)
  }
}

export async function deleteRide(req: Request, res: Response) {
  try {
    const id = String(req.params.id)
    const force = req.query.force === 'true'

    const ride = await prisma.ride.findUnique({ where: { id } })
    if (!ride) { fail(res, 'Ride not found'); return }

    if (!force) {
      const bookingCount = await prisma.booking.count({ where: { rideId: id, status: { in: ['completed', 'confirmed', 'in_progress'] } } })
      if (bookingCount > 0) {
        fail(res, `This ride has ${bookingCount} real booking(s) on record — pass force=true to delete anyway (this permanently removes that history too)`)
        return
      }
    }

    await prisma.ride.delete({ where: { id } })
    ok(res, {}, 'Ride deleted')
  } catch (err) {
    serverError(res, err)
  }
}
