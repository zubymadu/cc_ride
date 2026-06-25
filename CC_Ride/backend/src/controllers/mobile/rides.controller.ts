import { Request, Response } from 'express'
import { prisma } from '../../lib/prisma'
import { ok, serverError } from '../../lib/response'

export async function getAvailableRides(req: Request, res: Response) {
  try {
    const { lat, lng, date } = req.query as { lat?: string; lng?: string; date?: string }

    const now = new Date()
    const whereDate = date ? new Date(date) : now

    const rides = await prisma.ride.findMany({
      where: {
        status:         { in: ['pending', 'driver_assigned'] },
        availableSeats: { gt: 0 },
        scheduledAt:    { gte: whereDate },
      },
      include: {
        driver: { select: { name: true, mobile: true, driverProfile: { select: { averageRating: true } } } },
        vehicle: { select: { licensePlate: true, model: { select: { title: true } }, color: { select: { title: true } } } },
      },
      orderBy: { scheduledAt: 'asc' },
      take: 30,
    })

    ok(res, rides.map((r) => ({
      id:                     r.id,
      driver_id:              r.driverId,
      driver_name:            r.driver.name,
      driver_phone:           r.driver.mobile,
      driver_rating:          r.driver.driverProfile?.averageRating ?? null,
      vehicle_plate:          r.vehicle?.licensePlate ?? null,
      vehicle_model:          r.vehicle?.model?.title ?? null,
      vehicle_color:          r.vehicle?.color?.title ?? null,
      origin_address:         r.originAddress,
      origin_lat:             r.originLat,
      origin_lng:             r.originLng,
      destination_address:    r.destinationAddress,
      destination_lat:        r.destinationLat,
      destination_lng:        r.destinationLng,
      scheduled_at:           r.scheduledAt.toISOString(),
      base_fare:              r.baseFare,
      available_seats:        r.availableSeats,
      status:                 r.status,
      trip_notes:             r.tripNotes,
      estimated_duration_min: r.estimatedDurationMin,
      estimated_distance_km:  r.estimatedDistanceKm,
    })))
  } catch (err) {
    serverError(res, err)
  }
}
