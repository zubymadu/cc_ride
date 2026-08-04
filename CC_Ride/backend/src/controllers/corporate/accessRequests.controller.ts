/**
 * Corporate — employee-initiated requests for pool-car or company-wallet
 * access. The company admin grants either directly too (see
 * admin/pool.controller.ts); this is just the ask/decide conversation.
 */
import { Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'

const CreateRequestSchema = z.object({
  request_type: z.enum(['pool_car', 'wallet_payment']),
  note: z.string().optional(),
})

// POST /corporate/access-requests
export async function createAccessRequest(req: Request, res: Response) {
  try {
    const companyId = req.companyId!
    const userId = req.user.id
    const data = CreateRequestSchema.parse(req.body)

    const membership = await prisma.companyEmployee.findFirst({
      where: { companyId, userId, isActive: true },
    })
    if (!membership) { fail(res, 'You are not an active member of this organisation'); return }

    // Already have the access — nothing to ask for.
    const alreadyGranted = data.request_type === 'pool_car' ? membership.poolAccessEnabled : membership.walletAccessEnabled
    if (alreadyGranted) { fail(res, 'You already have this access'); return }

    const existingPending = await prisma.employeeAccessRequest.findFirst({
      where: { employeeId: membership.id, requestType: data.request_type, status: 'pending' },
    })
    if (existingPending) { fail(res, 'You already have a pending request for this'); return }

    const request = await prisma.employeeAccessRequest.create({
      data: {
        companyId,
        employeeId: membership.id,
        requestType: data.request_type,
        note: data.note ?? null,
      },
    })

    ok(res, { id: request.id.toString() }, 'Request sent to your company admin')
  } catch (err) {
    serverError(res, err)
  }
}

// GET /corporate/access-requests/mine
export async function listMyAccessRequests(req: Request, res: Response) {
  try {
    const companyId = req.companyId!
    const userId = req.user.id

    const membership = await prisma.companyEmployee.findFirst({ where: { companyId, userId, isActive: true } })
    if (!membership) { fail(res, 'You are not an active member of this organisation'); return }

    const requests = await prisma.employeeAccessRequest.findMany({
      where: { employeeId: membership.id },
      orderBy: { requestedAt: 'desc' },
    })

    ok(res, requests.map((r) => ({
      id: r.id.toString(),
      request_type: r.requestType,
      status: r.status,
      note: r.note,
      requested_at: r.requestedAt.toISOString(),
      decided_at: r.decidedAt?.toISOString() ?? null,
      decision_note: r.decisionNote,
    })))
  } catch (err) {
    serverError(res, err)
  }
}
