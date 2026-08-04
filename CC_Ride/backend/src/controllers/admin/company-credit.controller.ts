import { Request, Response } from 'express'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'
import { assertCompanyScope } from '../../lib/adminScope'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const db = prisma as any

export async function creditCompany(req: Request, res: Response) {
  try {
    const { id } = req.params
    const { amount, payment_method, reference, note } = req.body as {
      amount: number; payment_method: string; reference?: string; note?: string
    }
    const adminId = BigInt((req as any).admin.id)

    if (!amount || amount <= 0) { fail(res, 'Amount must be greater than zero'); return }
    if (!payment_method) { fail(res, 'Payment method is required'); return }

    const company = await db.company.findUnique({ where: { id }, select: { id: true, walletBalance: true, name: true } })
    if (!company) { fail(res, 'Company not found'); return }

    const newBalance = Number(company.walletBalance) + Number(amount)

    await prisma.$transaction([
      db.company.update({
        where: { id },
        data:  { walletBalance: newBalance },
      }),
      db.companyCredit.create({
        data: {
          companyId:    id,
          amount:       Number(amount),
          balanceAfter: newBalance,
          paymentMethod: payment_method,
          reference:    reference ?? null,
          note:         note ?? null,
          creditedById: adminId,
        },
      }),
    ])

    ok(res, { balance: newBalance }, `₦${Number(amount).toLocaleString()} credited to ${company.name}`)
  } catch (err) {
    serverError(res, err)
  }
}

export async function getCompanyCreditLedger(req: Request, res: Response) {
  try {
    const id = String(req.params.id)
    if (!assertCompanyScope(req, res, id)) return
    const page  = Math.max(1, parseInt(req.query.page as string) || 1)
    const limit = 20

    const [company, credits, total] = await Promise.all([
      db.company.findUnique({ where: { id }, select: { walletBalance: true } }),
      db.companyCredit.findMany({
        where:   { companyId: id },
        orderBy: { createdAt: 'desc' },
        skip:    (page - 1) * limit,
        take:    limit,
        include: { creditedBy: { select: { username: true } } },
      }),
      db.companyCredit.count({ where: { companyId: id } }),
    ])

    if (!company) { fail(res, 'Company not found'); return }

    ok(res, {
      wallet_balance: Number(company.walletBalance),
      credits: credits.map(c => ({
        id:             c.id.toString(),
        amount:         Number(c.amount),
        balance_after:  Number(c.balanceAfter),
        payment_method: c.paymentMethod,
        reference:      c.reference,
        note:           c.note,
        credited_by:    c.creditedBy.username,
        created_at:     c.createdAt,
      })),
      total,
      page,
      pages: Math.ceil(total / limit),
    })
  } catch (err) {
    serverError(res, err)
  }
}
