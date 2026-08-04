import { Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'
import { dec } from '../../lib/naira'

export async function listUsers(req: Request, res: Response) {
  try {
    const { search, status } = req.query as Record<string, string>
    const users = await prisma.user.findMany({
      where: {
        ...(status ? { status: status as any } : {}),
        ...(search ? {
          OR: [
            { name:   { contains: search, mode: 'insensitive' } },
            { email:  { contains: search, mode: 'insensitive' } },
            { mobile: { contains: search } },
          ],
        } : {}),
      },
      orderBy: { createdAt: 'desc' },
      take: 200,
      include: {
        driverProfile: { select: { userId: true } },  // PK is userId
        _count:        { select: { bookings: true } },
      },
    })

    ok(res, users.map((u) => ({
      id:             u.id,
      name:           u.name,
      email:          u.email ?? '',
      mobile:         u.mobile,
      wallet_balance: dec(u.walletBalance),  // walletBalance lives on User directly
      is_driver:      !!u.driverProfile,
      status:         u.status,
      created_at:     u.createdAt.toISOString(),
      total_bookings: u._count.bookings,
    })))
  } catch (err) {
    serverError(res, err)
  }
}

export async function userAction(req: Request, res: Response) {
  try {
    const { user_id, action } = req.body as { user_id: string; action: 'suspend' | 'ban' | 'activate' }
    const statusMap = { suspend: 'suspended', ban: 'banned', activate: 'active' } as const
    const newStatus = statusMap[action]
    if (!newStatus) { fail(res, 'Invalid action'); return }

    await prisma.user.update({ where: { id: user_id }, data: { status: newStatus } })
    ok(res, { user_id, status: newStatus }, `User ${action}d`)
  } catch (err) {
    serverError(res, err)
  }
}

// ─── Housekeeping: edit / delete ────────────────────────────────────────────
// Distinct from userAction above (suspend/ban/activate, reversible status
// changes) — this is direct data correction and permanent removal, for
// fixing bad data entry or clearing genuinely erroneous/test accounts.
// Never touches walletBalance, status, or anything financial/ledger-backed —
// those stay behind their own dedicated, audited endpoints.

const EditUserSchema = z.object({
  name:   z.string().min(2).optional(),
  email:  z.string().email().nullable().optional(),
  mobile: z.string().min(7).optional(),
})

export async function editUser(req: Request, res: Response) {
  try {
    const id = String(req.params.id)
    const data = EditUserSchema.parse(req.body)

    const user = await prisma.user.findUnique({ where: { id } })
    if (!user) { fail(res, 'User not found'); return }

    const updated = await prisma.user.update({
      where: { id },
      data: {
        ...(data.name   !== undefined ? { name: data.name }     : {}),
        ...(data.email  !== undefined ? { email: data.email }   : {}),
        ...(data.mobile !== undefined ? { mobile: data.mobile } : {}),
      },
    })
    ok(res, { id: updated.id, name: updated.name, email: updated.email, mobile: updated.mobile }, 'User updated')
  } catch (err: any) {
    if (err?.code === 'P2002') { fail(res, 'Another account already uses that email or mobile number'); return }
    serverError(res, err)
  }
}

export async function deleteUser(req: Request, res: Response) {
  try {
    const id = String(req.params.id)
    const force = req.query.force === 'true'

    const user = await prisma.user.findUnique({ where: { id } })
    if (!user) { fail(res, 'User not found'); return }

    // A real ride/payment history is the kind of thing "housekeeping"
    // should never silently wipe — deletion cascades through every FK
    // (bookings, ride requests, wallet transactions, company membership).
    // Refuse by default for anything with real activity; ?force=true is an
    // explicit, deliberate override for when that's genuinely intended.
    if (!force) {
      const [bookingCount, rideCount, activeEmployment] = await Promise.all([
        prisma.booking.count({ where: { passengerId: id, status: { in: ['completed', 'confirmed', 'in_progress'] } } }),
        prisma.ride.count({ where: { driverId: id, status: { in: ['completed', 'in_progress'] } } }),
        // Booking/ride counts alone miss a currently-active employee who
        // hasn't taken a sponsored ride yet — their CompanyEmployee row
        // (and any granted pool/wallet access) would otherwise vanish
        // silently on cascade with no warning at all.
        prisma.companyEmployee.count({ where: { userId: id, isActive: true } }),
      ])
      if (bookingCount > 0 || rideCount > 0 || activeEmployment > 0) {
        fail(res, `This account has ${bookingCount} real booking(s), ${rideCount} real ride(s), and ${activeEmployment} active company membership(s) on record — pass force=true to delete anyway (this permanently removes that history too)`)
        return
      }
    }

    await prisma.user.delete({ where: { id } })
    ok(res, {}, 'User deleted')
  } catch (err) {
    serverError(res, err)
  }
}
