/**
 * Super-admin housekeeping for financial ledger rows — wallet transactions
 * and payout requests. Deliberately separate from the credit/debit paths
 * themselves (creditCompany, the ride-payment wallet debit, etc.), which
 * stay untouched — this is only about removing seeded/test/erroneous rows
 * after the fact, not a way to move money.
 */
import { Request, Response } from 'express'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'
import { dec } from '../../lib/naira'

// DELETE /admin/wallet-transactions/:id
// A WalletTransaction is a ledger entry, not just a log line — it already
// changed User.walletBalance when it was created. Deleting the row without
// reversing that effect would silently corrupt the balance, so both happen
// atomically together, never one without the other.
export async function deleteWalletTransaction(req: Request, res: Response) {
  try {
    const id = BigInt(String(req.params.id))
    const force = req.query.force === 'true'

    const txn = await prisma.walletTransaction.findUnique({ where: { id } })
    if (!txn) { fail(res, 'Wallet transaction not found'); return }

    // A transaction tied to a real booking is evidence a real ride was
    // actually paid for this way — refuse by default, same as everywhere
    // else in housekeeping.
    if (!force && txn.bookingId) {
      fail(res, 'This transaction is linked to a real booking — pass force=true to delete anyway (the booking record itself is untouched, only this ledger entry and its balance effect)')
      return
    }

    await prisma.$transaction([
      // Reverse exactly what this entry recorded: if it was a +500 credit,
      // taking it back out means decrementing by 500 (and vice versa for a
      // debit) — never just deleting the row and leaving the balance as-is.
      prisma.user.update({
        where: { id: txn.userId },
        data: { walletBalance: { decrement: dec(txn.amount) } },
      }),
      prisma.walletTransaction.delete({ where: { id } }),
    ])

    ok(res, {}, 'Wallet transaction deleted and balance reversed')
  } catch (err) {
    serverError(res, err)
  }
}

// DELETE /admin/payout-requests/:id
export async function deletePayoutRequest(req: Request, res: Response) {
  try {
    const id = String(req.params.id)
    const force = req.query.force === 'true'

    const payout = await prisma.payoutRequest.findUnique({ where: { id } })
    if (!payout) { fail(res, 'Payout request not found'); return }

    // A completed payout already left the driver's wallet AND already left
    // the bank via the gateway — deleting the row can never undo either of
    // those, so it's refused even with force. A pending/failed/rejected
    // request never touched the balance (that only happens inside
    // processPayout on success), so it's safe to remove outright.
    if (payout.status === 'completed') {
      fail(res, 'This payout was already completed — the transfer already happened and cannot be undone by deleting this record. Contact the payment gateway if the transfer itself needs reversing.')
      return
    }
    if (!force && payout.status === 'processing') {
      fail(res, 'This payout is currently processing — pass force=true if you\'re certain it should be deleted anyway')
      return
    }

    await prisma.payoutRequest.delete({ where: { id } })
    ok(res, {}, 'Payout request deleted')
  } catch (err) {
    serverError(res, err)
  }
}
