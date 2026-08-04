import { PrismaClient } from '@prisma/client'
import bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

async function main() {
  const company = await prisma.company.create({
    data: {
      name: 'Wallet Test Co',
      contactName: 'Test Contact',
      contactEmail: 'wallet-test@example.com',
      status: 'active',
      walletBalance: 5000,
    },
  })

  const passwordHash = await bcrypt.hash('testpass', 10)

  const driver = await prisma.user.create({
    data: {
      name: 'Test Driver', mobile: '08010000001', passwordHash,
      status: 'active', referralCode: 'DRVTEST1',
    },
  })

  const passenger = await prisma.user.create({
    data: {
      name: 'Test Passenger', mobile: '08010000002', passwordHash,
      status: 'active', referralCode: 'PAXTEST1', walletBalance: 2000,
    },
  })

  const ride = await prisma.ride.create({
    data: {
      driverId: driver.id,
      originAddress: 'A', originLat: 6.5, originLng: 3.3,
      destinationAddress: 'B', destinationLat: 6.6, destinationLng: 3.4,
      scheduledAt: new Date(),
      baseFare: 1500,
      availableSeats: 4,
      status: 'pending',
      pickupOtp: '111111', dropoffOtp: '222222',
    },
  })

  console.log(JSON.stringify({
    companyId: company.id,
    driverId: driver.id,
    passengerId: passenger.id,
    rideId: ride.id,
    companyWalletBefore: Number(company.walletBalance),
    passengerWalletBefore: Number(passenger.walletBalance),
    rideBaseFare: Number(ride.baseFare),
  }))
}

main().finally(() => prisma.$disconnect())
