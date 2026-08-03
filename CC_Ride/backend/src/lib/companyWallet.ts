import { Prisma } from '@prisma/client'

export class WalletError extends Error {}

/**
 * Deducts `amount` from a company's prepaid wallet within an existing
 * transaction. Throws WalletError (which the caller should catch and turn
 * into a clean 400 response) if the balance is insufficient, so the whole
 * booking transaction rolls back rather than leaving a charge with no
 * matching wallet debit.
 */
export async function debitCompanyWallet(
  tx: Prisma.TransactionClient,
  companyId: string,
  amount: number,
): Promise<number> {
  const company = await tx.company.findUnique({ where: { id: companyId }, select: { walletBalance: true } })
  if (!company) throw new WalletError('Company not found')

  if (Number(company.walletBalance) < amount) {
    throw new WalletError('Insufficient company wallet balance for this ride')
  }

  const updated = await tx.company.update({
    where: { id: companyId },
    data:  { walletBalance: { decrement: amount } },
  })
  return Number(updated.walletBalance)
}

/** Credits `amount` back to a company's wallet — used when a wallet-paid
 * booking is rejected or cancelled after the charge was already taken. */
export async function refundCompanyWallet(
  tx: Prisma.TransactionClient,
  companyId: string,
  amount: number,
): Promise<number> {
  const updated = await tx.company.update({
    where: { id: companyId },
    data:  { walletBalance: { increment: amount } },
  })
  return Number(updated.walletBalance)
}
