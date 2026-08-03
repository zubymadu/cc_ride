import crypto from 'crypto'
import bcrypt from 'bcryptjs'
import { prisma } from './prisma'

/**
 * Finds an existing user by email, or creates a placeholder account for an
 * employee invited (singly or via CSV import) before they've registered in
 * the app themselves.
 *
 * The placeholder mobile number must be unique — `User` has a
 * `@@unique([mobile, countryCode])` constraint, so a hardcoded empty string
 * would collide on the second stub user created for any company.
 */
export async function findOrCreateStubUser(name: string, email: string) {
  const existing = await prisma.user.findFirst({ where: { email } })
  if (existing) return existing

  const tempPassword = crypto.randomBytes(16).toString('hex')
  return prisma.user.create({
    data: {
      name,
      email,
      mobile:       `pending-${crypto.randomBytes(6).toString('hex')}`,
      countryCode:  '',
      passwordHash: await bcrypt.hash(tempPassword, 12),
      status:       'pending_verification',
      referralCode: crypto.randomBytes(4).toString('hex').toUpperCase(),
    },
  })
}
