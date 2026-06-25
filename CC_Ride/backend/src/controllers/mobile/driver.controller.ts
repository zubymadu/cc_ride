import { Request, Response } from 'express'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'

export async function getDriverRides(req: Request, res: Response) {
  try {
    if (!req.user.isDriver) { fail(res, 'Driver account required', 403); return }
    const { status } = req.query as { status?: string }

    const rides = await prisma.ride.findMany({
      where: {
        driverId: req.user.id,
        ...(status ? { status: status as any } : {}),
      },
      include: {
        vehicle: { select: { licensePlate: true } },
        bookings: {
          select: { id: true, passengerId: true, seatsBooked: true, status: true },
        },
      },
      orderBy: { scheduledAt: 'desc' },
      take: 30,
    })

    ok(res, rides.map((r) => ({
      id:                    r.id,
      driver_id:             r.driverId,
      vehicle_plate:         r.vehicle?.licensePlate ?? null,
      origin_address:        r.originAddress,
      origin_lat:            r.originLat,
      origin_lng:            r.originLng,
      destination_address:   r.destinationAddress,
      destination_lat:       r.destinationLat,
      destination_lng:       r.destinationLng,
      scheduled_at:          r.scheduledAt.toISOString(),
      base_fare:             r.baseFare,
      available_seats:       r.availableSeats,
      status:                r.status,
      pickup_otp:            r.pickupOtp,
      dropoff_otp:           r.dropoffOtp,
      trip_notes:            r.tripNotes,
      estimated_duration_min: r.estimatedDurationMin,
      estimated_distance_km:  r.estimatedDistanceKm,
    })))
  } catch (err) {
    serverError(res, err)
  }
}

export async function updateDriverStatus(req: Request, res: Response) {
  try {
    if (!req.user.isDriver) { fail(res, 'Driver account required', 403); return }
    const { status } = req.body as { status: 'active' | 'offline' | 'on_trip' }

    const allowed = ['active', 'offline', 'on_trip']
    if (!allowed.includes(status)) { fail(res, 'Invalid status'); return }

    await prisma.driverProfile.update({
      where: { userId: req.user.id },
      data:  { status: status as any },
    })
    ok(res, { status }, 'Driver status updated')
  } catch (err) {
    serverError(res, err)
  }
}

export async function verifyOtp(req: Request, res: Response) {
  try {
    if (!req.user.isDriver) { fail(res, 'Driver account required', 403); return }
    const { ride_id, otp, type } = req.body as { ride_id: string; otp: string; type: 'pickup' | 'dropoff' }

    const ride = await prisma.ride.findFirst({
      where: { id: ride_id, driverId: req.user.id },
    })
    if (!ride) { fail(res, 'Ride not found', 404); return }

    if (type === 'pickup') {
      if (ride.pickupOtp !== otp) { fail(res, 'Invalid pickup OTP'); return }
      await prisma.ride.update({
        where: { id: ride_id },
        data:  { status: 'in_progress', startedAt: new Date() },
      })
      ok(res, { verified: true, new_status: 'in_progress' }, 'Pickup verified — ride started')
    } else {
      if (ride.dropoffOtp !== otp) { fail(res, 'Invalid dropoff OTP'); return }
      await prisma.ride.update({
        where: { id: ride_id },
        data:  { status: 'completed', completedAt: new Date() },
      })
      // Mark all bookings as completed
      await prisma.booking.updateMany({
        where: { rideId: ride_id, status: { in: ['confirmed', 'processing', 'in_progress'] } },
        data:  { status: 'completed', completedAt: new Date() },
      })
      // Update driver profile
      await prisma.driverProfile.update({
        where: { userId: req.user.id },
        data:  { status: 'active', totalTrips: { increment: 1 } },
      })
      ok(res, { verified: true, new_status: 'completed' }, 'Dropoff verified — ride completed')
    }
  } catch (err) {
    serverError(res, err)
  }
}

export async function getDriverEarnings(req: Request, res: Response) {
  try {
    if (!req.user.isDriver) { fail(res, 'Driver account required', 403); return }

    const profile = await prisma.driverProfile.findUnique({
      where: { userId: req.user.id },
      select: { totalTrips: true, totalEarnings: true, averageRating: true },
    })

    const thisMonthStart = new Date()
    thisMonthStart.setDate(1)
    thisMonthStart.setHours(0, 0, 0, 0)

    const monthlyBookings = await prisma.booking.aggregate({
      where: {
        driverId:    req.user.id,
        status:      'completed',
        completedAt: { gte: thisMonthStart },
      },
      _sum:   { driverEarning: true },
      _count: { id: true },
    })

    ok(res, {
      total_trips:      profile?.totalTrips ?? 0,
      total_earnings:   profile?.totalEarnings ?? 0,
      average_rating:   profile?.averageRating ?? 0,
      this_month_trips: monthlyBookings._count.id,
      this_month_earnings: monthlyBookings._sum.driverEarning ?? 0,
    })
  } catch (err) {
    serverError(res, err)
  }
}
