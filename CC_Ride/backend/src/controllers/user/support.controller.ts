/**
 * User — support tickets
 *
 * Lets a rider/driver raise a support ticket from the app and reply on the
 * thread. Resolution happens on the admin side (see
 * ../admin/support.controller.ts) — this is deliberately the mirror image
 * of that file, scoped to the requesting user's own tickets only.
 */
import { Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'

const CreateTicketSchema = z.object({
  subject:     z.string().trim().min(3).max(200),
  description: z.string().trim().min(3).max(5000),
  category:    z.string().trim().max(50).optional(),
  booking_id:  z.string().uuid().optional(),
})

// ─── POST /user/support/tickets ────────────────────────────────────────────

export async function createTicket(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const data = CreateTicketSchema.parse(req.body)

    // A booking_id, if given, must actually belong to this user — otherwise
    // a rider could reference someone else's booking in their ticket.
    if (data.booking_id) {
      const booking = await prisma.booking.findFirst({
        where: { id: data.booking_id, passengerId: userId },
        select: { id: true },
      })
      if (!booking) { fail(res, 'Booking not found'); return }
    }

    const ticket = await prisma.supportTicket.create({
      data: {
        userId,
        bookingId:   data.booking_id ?? null,
        subject:     data.subject,
        description: data.description,
        category:    data.category ?? 'general',
      },
    })

    await prisma.supportMessage.create({
      data: {
        ticketId:   ticket.id,
        body:       data.description,
        senderType: 'user',
        senderId:   userId,
      },
    })

    ok(res, { ticket_id: ticket.id }, 'Ticket submitted — our team will respond soon')
  } catch (err) {
    serverError(res, err)
  }
}

// ─── GET /user/support/tickets ─────────────────────────────────────────────

export async function listMyTickets(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const tickets = await prisma.supportTicket.findMany({
      where:   { userId },
      orderBy: { createdAt: 'desc' },
      take:    100,
      include: { messages: { orderBy: { createdAt: 'desc' }, take: 1 } },
    })

    ok(res, tickets.map((t) => ({
      id:           t.id,
      subject:      t.subject,
      category:     t.category ?? 'general',
      status:       t.status,
      priority:     t.priority ?? 'medium',
      created_at:   t.createdAt.toISOString(),
      updated_at:   t.updatedAt.toISOString(),
      last_message: t.messages[0]?.body ?? t.subject,
    })))
  } catch (err) {
    serverError(res, err)
  }
}

// ─── GET /user/support/tickets/:id ─────────────────────────────────────────

export async function getMyTicket(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const ticketId = String(req.params.id)

    const ticket = await prisma.supportTicket.findFirst({
      where:   { id: ticketId, userId },
      include: { messages: { orderBy: { createdAt: 'asc' } } },
    })
    if (!ticket) { fail(res, 'Ticket not found'); return }

    ok(res, {
      id:          ticket.id,
      subject:     ticket.subject,
      description: ticket.description,
      category:    ticket.category ?? 'general',
      status:      ticket.status,
      priority:    ticket.priority ?? 'medium',
      created_at:  ticket.createdAt.toISOString(),
      messages:    ticket.messages.map((m) => ({
        id:          m.id.toString(),
        sender_type: m.senderType,
        body:        m.body,
        created_at:  m.createdAt.toISOString(),
      })),
    })
  } catch (err) {
    serverError(res, err)
  }
}

// ─── POST /user/support/tickets/:id/reply ──────────────────────────────────

const ReplySchema = z.object({ message: z.string().trim().min(1).max(5000) })

export async function replyToMyTicket(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const ticketId = String(req.params.id)
    const { message } = ReplySchema.parse(req.body)

    const ticket = await prisma.supportTicket.findFirst({ where: { id: ticketId, userId } })
    if (!ticket) { fail(res, 'Ticket not found'); return }
    if (ticket.status === 'closed') { fail(res, 'This ticket is closed'); return }

    await prisma.$transaction([
      prisma.supportMessage.create({
        data: { ticketId, body: message, senderType: 'user', senderId: userId },
      }),
      // A user reply to a resolved ticket reopens it — otherwise a
      // follow-up question would silently sit on a ticket the admin
      // console has already filtered out of its default "open" view.
      prisma.supportTicket.update({
        where: { id: ticketId },
        data:  { status: ticket.status === 'resolved' ? 'open' : ticket.status, updatedAt: new Date() },
      }),
    ])

    ok(res, { ticket_id: ticketId }, 'Reply sent')
  } catch (err) {
    serverError(res, err)
  }
}
