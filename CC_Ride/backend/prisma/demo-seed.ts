/**
 * DEMO SEED — populates the database with realistic demo data for client demos.
 * Safe to run multiple times: skips if demo data already exists.
 *
 *   npx ts-node --project tsconfig.seed.json prisma/demo-seed.ts
 */
import { PrismaClient, Prisma } from '@prisma/client'
import bcrypt from 'bcryptjs'

const prisma = new PrismaClient()
const D = (n: number) => new Prisma.Decimal(n)

// Lagos landmark coordinates for realistic routes
const PLACES = [
  { name: 'Victoria Island, Lagos',          lat: 6.4281, lng: 3.4219 },
  { name: 'Ikoyi, Lagos',                    lat: 6.4541, lng: 3.4316 },
  { name: 'Lekki Phase 1, Lagos',            lat: 6.4478, lng: 3.4723 },
  { name: 'Ikeja GRA, Lagos',                lat: 6.5833, lng: 3.3500 },
  { name: 'Murtala Muhammed Airport, Lagos', lat: 6.5774, lng: 3.3215 },
  { name: 'Yaba, Lagos',                     lat: 6.5095, lng: 3.3711 },
  { name: 'Surulere, Lagos',                 lat: 6.5059, lng: 3.3509 },
  { name: 'Apapa, Lagos',                    lat: 6.4500, lng: 3.3590 },
  { name: 'Festac Town, Lagos',              lat: 6.4667, lng: 3.2833 },
  { name: 'Ajah, Lagos',                     lat: 6.4667, lng: 3.5667 },
]

const rand    = (min: number, max: number) => Math.floor(Math.random() * (max - min + 1)) + min
const pick    = <T>(arr: T[]): T => arr[Math.floor(Math.random() * arr.length)]
const otp     = () => String(rand(1000, 9999))
const daysAgo = (d: number, hourOffset = 0) => new Date(Date.now() - d * 86_400_000 + hourOffset * 3_600_000)

async function main() {
  // Idempotency guard
  const existing = await prisma.company.findUnique({ where: { contactEmail: 'transport@nnpcgroup.demo' } })
  if (existing) {
    console.log('Demo data already present — nothing to do.')
    return
  }

  console.log('Seeding demo data…')
  const password = await bcrypt.hash('Demo@1234', 10)

  // ── Companies ────────────────────────────────────────────────────────────
  const companyDefs = [
    { name: 'NNPC Group',        industry: 'Oil & Gas',  contactName: 'Adaobi Okeke',    contactEmail: 'transport@nnpcgroup.demo',   commissionRate: 12 },
    { name: 'Zenith Bank Plc',   industry: 'Banking',    contactName: 'Tunde Bakare',    contactEmail: 'fleet@zenithbank.demo',      commissionRate: 15 },
    { name: 'Dangote Industries',industry: 'Manufacturing', contactName: 'Fatima Aliyu', contactEmail: 'logistics@dangote.demo',     commissionRate: 10 },
  ]
  const companies = []
  for (const def of companyDefs) {
    companies.push(await prisma.company.create({
      data: {
        ...def,
        commissionRate: D(def.commissionRate),
        address: `${rand(1, 99)} ${pick(['Adeola Odeku St', 'Broad Street', 'Awolowo Road'])}, Lagos`,
        city: 'Lagos',
        status: 'active',
        subscriptionActive: true,
        subscriptionExpiresAt: daysAgo(-90),
        contactPhone: `+23480${rand(10000000, 99999999)}`,
      },
    }))
  }

  // ── Departments + cost centres per company ───────────────────────────────
  const deptNames = ['Operations', 'Finance', 'Engineering', 'Human Resources']
  const departments: Record<string, { id: bigint; companyId: string }[]> = {}
  const costCentres: Record<string, { id: bigint }[]> = {}
  for (const co of companies) {
    departments[co.id] = []
    costCentres[co.id] = []
    for (const [i, dn] of deptNames.entries()) {
      const dept = await prisma.department.create({
        data: { companyId: co.id, name: dn, code: `D${i + 1}00` },
      })
      departments[co.id].push(dept)
      const cc = await prisma.costCentre.create({
        data: {
          companyId: co.id, departmentId: dept.id,
          name: `${dn} Travel`, code: `CC-${co.name.slice(0, 3).toUpperCase()}-${i + 1}0`,
        },
      })
      costCentres[co.id].push(cc)
    }
  }

  // ── Drivers (active, with vehicles + live GPS) ───────────────────────────
  const driverNames = ['Emeka Nwosu', 'Yusuf Ibrahim', 'Chinedu Obi', 'Segun Adeyemi', 'Blessing Eze', 'Musa Garba']
  const vehicleModels = await prisma.vehicleModel.findMany({ take: 10 })
  const vehicleTypes  = await prisma.vehicleType.findMany()
  const vehicleColors = await prisma.vehicleColor.findMany({ take: 6 })

  const drivers = []
  for (const [i, name] of driverNames.entries()) {
    const place = PLACES[i % PLACES.length]
    const user = await prisma.user.create({
      data: {
        name,
        email: `${name.toLowerCase().replace(' ', '.')}@driver.demo`,
        mobile: `080${rand(10000000, 99999999)}`,
        passwordHash: password,
        isDriver: true,
        isMobileVerified: true,
        status: 'active',
        driverProfile: {
          create: {
            licenseNumber: `LAG-DRV-${rand(10000, 99999)}`,
            licenseExpiry: daysAgo(-365),
            nin: String(rand(10000000000, 99999999999)),
            status: 'active',
            averageRating: D(4 + Math.random()),
            totalTrips: rand(40, 320),
            totalEarnings: D(rand(150000, 900000)),
            currentLocationLat: D(place.lat + (Math.random() - 0.5) * 0.01),
            currentLocationLng: D(place.lng + (Math.random() - 0.5) * 0.01),
            lastLocationAt: new Date(),
          },
        },
      },
    })
    const vehicle = await prisma.vehicle.create({
      data: {
        driverId: user.id,
        modelId: pick(vehicleModels).id,
        typeId:  pick(vehicleTypes).id,
        colorId: pick(vehicleColors).id,
        year: rand(2017, 2024),
        licensePlate: `LAG-${rand(100, 999)}-${['AB','KJ','EP','GG'][i % 4]}${rand(10, 99)}`,
        seatCapacity: 4,
        status: 'approved',
      },
    })
    drivers.push({ user, vehicle })
  }

  // ── Employees / passengers ───────────────────────────────────────────────
  const employeeNames = [
    'Ngozi Adichie', 'Babatunde Lawal', 'Amina Sani', 'Kelechi Iheanacho',
    'Folake Soyinka', 'Ibrahim Dantata', 'Chioma Ubah', 'Olu Jacobs',
    'Hauwa Mohammed', 'Daniel Etim',
  ]
  const passengers = []
  for (const [i, name] of employeeNames.entries()) {
    const co = companies[i % companies.length]
    const dept = departments[co.id][i % deptNames.length]
    const cc   = costCentres[co.id][i % deptNames.length]
    const user = await prisma.user.create({
      data: {
        name,
        email: `${name.toLowerCase().replace(' ', '.')}@employee.demo`,
        mobile: `081${rand(10000000, 99999999)}`,
        passwordHash: password,
        isMobileVerified: true,
        status: 'active',
        companyMemberships: {
          create: {
            companyId: co.id,
            departmentId: dept.id,
            costCentreId: cc.id,
            role: i % 5 === 0 ? 'manager' : 'employee',
            employeeNumber: `EMP-${rand(1000, 9999)}`,
            jobTitle: pick(['Analyst', 'Manager', 'Engineer', 'Accountant', 'Officer']),
            joinedAt: daysAgo(rand(60, 300)),
          },
        },
      },
    })
    passengers.push({ user, company: co, dept, cc })
  }

  // ── Approval workflows (one per company) ─────────────────────────────────
  const workflows: Record<string, bigint> = {}
  for (const co of companies) {
    const wf = await prisma.approvalWorkflow.create({
      data: {
        companyId: co.id,
        name: 'Default fare approval',
        requiresApproval: true,
        autoApproveBelow: D(10000),
        approverRole: 'manager',
        escalationHours: 2,
      },
    })
    workflows[co.id] = wf.id
  }

  // ── Historical completed rides + bookings (last 6 months) ────────────────
  console.log('Creating 6 months of ride history…')
  let bookingCount = 0
  for (let month = 5; month >= 0; month--) {
    const ridesThisMonth = rand(18, 34) + (5 - month) * 4   // growth trend
    for (let r = 0; r < ridesThisMonth; r++) {
      const day        = month * 30 + rand(1, 28)
      const driver     = pick(drivers)
      const p          = pick(passengers)
      const from       = pick(PLACES)
      let   to         = pick(PLACES)
      while (to === from) to = pick(PLACES)
      const fare       = rand(3500, 28000)
      const isCorporate = Math.random() < 0.7
      const commRate   = isCorporate ? Number(p.company.commissionRate ?? 15) : 15
      const commission = Math.round(fare * commRate / 100)
      const when       = daysAgo(day, rand(7, 20))

      const ride = await prisma.ride.create({
        data: {
          driverId: driver.user.id,
          vehicleId: driver.vehicle.id,
          originAddress: from.name, originLat: D(from.lat), originLng: D(from.lng),
          destinationAddress: to.name, destinationLat: D(to.lat), destinationLng: D(to.lng),
          scheduledAt: when,
          baseFare: D(fare),
          estimatedDistanceKm: D(rand(5, 38)),
          estimatedDurationMin: rand(15, 95),
          availableSeats: 4,
          status: 'completed',
          pickupOtp: otp(), dropoffOtp: otp(),
          startedAt: when,
          completedAt: new Date(when.getTime() + rand(20, 90) * 60_000),
          createdAt: when,
        },
      })

      await prisma.booking.create({
        data: {
          rideId: ride.id,
          passengerId: p.user.id,
          driverId: driver.user.id,
          companyId:    isCorporate ? p.company.id : null,
          departmentId: isCorporate ? p.dept.id : null,
          costCentreId: isCorporate ? p.cc.id : null,
          seatsBooked: 1,
          subtotal: D(fare),
          totalAmount: D(fare),
          driverEarning: D(fare - commission),
          platformCommission: D(commission),
          paymentGateway: isCorporate ? 'company_account' : pick(['paystack', 'flutterwave'] as const),
          paymentStatus: 'successful',
          paymentReference: `DEMO-${Date.now()}-${bookingCount}`,
          status: 'completed',
          confirmedAt: when,
          completedAt: new Date(when.getTime() + rand(20, 90) * 60_000),
          createdAt: when,
          passengerRating: Math.random() < 0.8 ? rand(4, 5) : rand(2, 3),
        },
      })
      bookingCount++
    }
  }
  console.log(`  ${bookingCount} completed bookings created`)

  // ── In-progress rides with GPS trail (for the live tracking map) ─────────
  console.log('Creating live in-progress rides…')
  for (let i = 0; i < 3; i++) {
    const driver = drivers[i]
    const p      = passengers[i]
    const from   = PLACES[i]
    const to     = PLACES[i + 4]
    const fare   = rand(6000, 18000)
    const start  = new Date(Date.now() - rand(10, 25) * 60_000)

    const ride = await prisma.ride.create({
      data: {
        driverId: driver.user.id,
        vehicleId: driver.vehicle.id,
        originAddress: from.name, originLat: D(from.lat), originLng: D(from.lng),
        destinationAddress: to.name, destinationLat: D(to.lat), destinationLng: D(to.lng),
        scheduledAt: start,
        baseFare: D(fare),
        availableSeats: 4,
        status: 'in_progress',
        pickupOtp: otp(), dropoffOtp: otp(),
        startedAt: start,
        createdAt: start,
      },
    })
    await prisma.booking.create({
      data: {
        rideId: ride.id,
        passengerId: p.user.id,
        driverId: driver.user.id,
        companyId: p.company.id, departmentId: p.dept.id, costCentreId: p.cc.id,
        seatsBooked: 1,
        subtotal: D(fare), totalAmount: D(fare),
        driverEarning: D(Math.round(fare * 0.85)),
        platformCommission: D(Math.round(fare * 0.15)),
        paymentGateway: 'company_account',
        paymentStatus: 'pending',
        status: 'in_progress',
        confirmedAt: start, startedAt: start, createdAt: start,
      },
    })
    // GPS breadcrumb trail interpolated along the route
    for (let t = 0; t <= 8; t++) {
      const frac = t / 10
      await prisma.rideTracking.create({
        data: {
          rideId: ride.id,
          driverId: driver.user.id,
          lat: D(from.lat + (to.lat - from.lat) * frac + (Math.random() - 0.5) * 0.002),
          lng: D(from.lng + (to.lng - from.lng) * frac + (Math.random() - 0.5) * 0.002),
          speedKmh: D(rand(20, 65)),
          recordedAt: new Date(start.getTime() + t * 2.5 * 60_000),
        },
      })
    }
  }

  // ── Pending approval requests (for the Approvals page) ───────────────────
  console.log('Creating pending approval requests…')
  for (let i = 0; i < 4; i++) {
    const p      = passengers[(i + 3) % passengers.length]
    const driver = pick(drivers)
    const from   = pick(PLACES)
    let   to     = pick(PLACES)
    while (to === from) to = pick(PLACES)
    const fare   = i < 2 ? rand(12000, 22000) : rand(27000, 45000)  // 2 within, 2 over budget
    const when   = daysAgo(-1, rand(1, 8))    // scheduled for tomorrow

    const ride = await prisma.ride.create({
      data: {
        driverId: driver.user.id,
        vehicleId: driver.vehicle.id,
        originAddress: from.name, originLat: D(from.lat), originLng: D(from.lng),
        destinationAddress: to.name, destinationLat: D(to.lat), destinationLng: D(to.lng),
        scheduledAt: when,
        baseFare: D(fare),
        availableSeats: 4,
        status: 'pending',
        pickupOtp: otp(), dropoffOtp: otp(),
      },
    })
    const booking = await prisma.booking.create({
      data: {
        rideId: ride.id,
        passengerId: p.user.id,
        driverId: driver.user.id,
        companyId: p.company.id, departmentId: p.dept.id, costCentreId: p.cc.id,
        seatsBooked: 1,
        subtotal: D(fare), totalAmount: D(fare),
        driverEarning: D(Math.round(fare * 0.85)),
        platformCommission: D(Math.round(fare * 0.15)),
        paymentGateway: 'company_account',
        paymentStatus: 'pending',
        status: 'pending',
        bookingMethod: 'scheduled',
      },
    })
    await prisma.approvalRequest.create({
      data: {
        workflowId: workflows[p.company.id],
        bookingId: booking.id,
        requesterId: p.user.id,
        originAddress: from.name,
        destinationAddress: to.name,
        estimatedFare: D(fare),
        scheduledAt: when,
        status: 'pending',
        expiresAt: daysAgo(-2),
      },
    })
  }

  // ── A couple of support tickets ──────────────────────────────────────────
  await prisma.supportTicket.create({
    data: {
      userId: passengers[0].user.id,
      subject: 'Receipt missing cost centre tag',
      description: 'My ride from VI to Ikeja last Tuesday is not showing the cost centre on the receipt. Finance needs this for reconciliation.',
      status: 'open',
      priority: 'medium',
    },
  }).catch(() => {})
  await prisma.supportTicket.create({
    data: {
      userId: drivers[1].user.id,
      subject: 'Payout delayed',
      description: 'My weekly payout has not arrived in my GTBank account.',
      status: 'open',
      priority: 'high',
    },
  }).catch(() => {})

  console.log('Demo seed complete!')
  console.log(`  Companies: ${companies.length}`)
  console.log(`  Drivers:   ${drivers.length} (all active with vehicles + GPS)`)
  console.log(`  Employees: ${passengers.length}`)
  console.log(`  Bookings:  ${bookingCount} completed + 3 in-progress + 4 pending approval`)
}

main()
  .catch((e) => { console.error(e); process.exit(1) })
  .finally(() => prisma.$disconnect())
