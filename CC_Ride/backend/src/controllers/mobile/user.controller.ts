import { Request, Response } from 'express'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'
import { getProfile, updateProfile } from '../auth.controller'

export { getProfile, updateProfile }

export async function getMyBookings(req: Request, res: Response) {
  try {
    const { status } = req.query as { status?: string }
    const bookings = await prisma.booking.findMany({
      where: {
        passengerId: req.user.id,
        ...(status ? { status: status as any } : {}),
      },
      include: {
        ride: {
          select: {
            originAddress:      true,
            destinationAddress: true,
            scheduledAt:        true,
            driver: { select: { name: true } },
            vehicle: { select: { licensePlate: true } },
          },
        },
        approvalRequests: {
          select: { id: true, status: true },
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    })

    const data = bookings.map((b) => ({
      id:                  b.id,
      ride_id:             b.rideId,
      passenger_id:        b.passengerId,
      company_id:          b.companyId,
      department_id:       b.departmentId?.toString() ?? null,
      cost_centre_id:      b.costCentreId?.toString() ?? null,
      seats_booked:        b.seatsBooked,
      subtotal:            b.subtotal,
      total_amount:        b.totalAmount,
      driver_earning:      b.driverEarning,
      status:              b.status,
      payment_status:      b.paymentStatus,
      booking_method:      b.bookingMethod,
      created_at:          b.createdAt.toISOString(),
      confirmed_at:        b.confirmedAt?.toISOString() ?? null,
      completed_at:        b.completedAt?.toISOString() ?? null,
      cancellation_reason: b.cancellationReason,
      approval_request_id: b.approvalRequests[0]?.id.toString() ?? null,
      approval_status:     b.approvalRequests[0]?.status ?? null,
      ride: b.ride ? {
        origin_address:      b.ride.originAddress,
        destination_address: b.ride.destinationAddress,
        scheduled_at:        b.ride.scheduledAt.toISOString(),
        driver_name:         b.ride.driver?.name ?? null,
        vehicle_plate:       b.ride.vehicle?.licensePlate ?? null,
      } : null,
    }))

    ok(res, data)
  } catch (err) {
    serverError(res, err)
  }
}

export async function getMyNotifications(req: Request, res: Response) {
  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: req.user.id },
      orderBy: { sentAt: 'desc' },
      take: 50,
    })
    ok(res, notifications.map((n) => ({
      id:      n.id.toString(),
      type:    n.type,
      title:   n.title,
      body:    n.body,
      data:    n.data,
      is_read: n.isRead,
      sent_at: n.sentAt.toISOString(),
    })))
  } catch (err) {
    serverError(res, err)
  }
}

export async function markNotificationRead(req: Request, res: Response) {
  try {
    const { id } = req.params
    await prisma.notification.updateMany({
      where: { id: BigInt(id), userId: req.user.id },
      data: { isRead: true, readAt: new Date() },
    })
    ok(res, { id }, 'Notification marked as read')
  } catch (err) {
    serverError(res, err)
  }
}

export async function getWallet(req: Request, res: Response) {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: { walletBalance: true },
    })
    ok(res, { balance: user?.walletBalance ?? 0 })
  } catch (err) {
    serverError(res, err)
  }
}

export async function getWalletTransactions(req: Request, res: Response) {
  try {
    const txns = await prisma.walletTransaction.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
      take: 50,
    })
    ok(res, txns.map((t) => ({
      id:           t.id.toString(),
      amount:       t.amount,
      balance_after: t.balanceAfter,
      description:  t.description,
      reference:    t.reference,
      created_at:   t.createdAt.toISOString(),
    })))
  } catch (err) {
    serverError(res, err)
  }
}
