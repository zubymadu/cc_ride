import bcrypt from 'bcryptjs'
import { prisma } from '../src/lib/prisma'

async function main() {
  const newPassword = process.argv[2]
  if (!newPassword) {
    console.error('Usage: npx tsx prisma/reset-admin-password.ts <new-password>')
    process.exit(1)
  }

  const hash = await bcrypt.hash(newPassword, 12)

  const result = await prisma.adminUser.update({
    where: { username: 'admin' },
    data: { passwordHash: hash },
    select: { id: true, username: true, email: true },
  })

  console.log(`Password reset for admin account:`)
  console.log(`  id:       ${result.id}`)
  console.log(`  username: ${result.username}`)
  console.log(`  email:    ${result.email}`)
  await prisma.$disconnect()
}

main().catch(err => {
  console.error(err)
  prisma.$disconnect()
  process.exit(1)
})
