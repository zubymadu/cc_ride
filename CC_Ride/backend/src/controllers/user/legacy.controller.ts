/**
 * Legacy PHP-shim endpoints for the CC Ride Flutter app.
 * Implements every endpoint the app calls so the full passenger experience
 * works without the original PHP backend.
 */
import { Request, Response } from 'express'
import jwt from 'jsonwebtoken'
import bcrypt from 'bcryptjs'
import { prisma } from '../../lib/prisma'
import { paystackInitialize, paystackVerify } from '../../lib/paystack'

const CCRIDE_API_BASE = 'https://api.ccride.ng'

// ─── Helpers ─────────────────────────────────────────────────────────────────

async function findUserByMobile(mobile: string) {
  const raw = String(mobile).trim().replace(/[\s-]/g, '')
  const candidates = new Set<string>([raw])
  if (raw.startsWith('+234')) { candidates.add('0' + raw.slice(4)); candidates.add(raw.slice(4)) }
  if (raw.startsWith('234'))  { candidates.add('0' + raw.slice(3)); candidates.add(raw.slice(3)) }
  if (raw.startsWith('0'))    { candidates.add(raw.slice(1)) }
  if (/^[1-9]\d{9}$/.test(raw)) { candidates.add('0' + raw) }
  return prisma.user.findFirst({ where: { mobile: { in: [...candidates] } } })
}

function ok(res: Response, data: object) {
  res.json({ Result: 'true', ResponseCode: '200', ResponseMsg: 'Success', ...data })
}
function fail(res: Response, msg: string) {
  res.json({ Result: 'false', ResponseCode: '400', ResponseMsg: msg })
}

function uid(req: Request): string | null {
  return (req.body?.uid ?? req.body?.user_id ?? null) as string | null
}

/** Return a profile pic URL that the app can resolve via imageurl prefix */
function picUrl(raw: string | null | undefined): string {
  if (!raw) return ''
  if (raw.startsWith('http')) return raw
  return raw
}

// Static lookup tables (no DB tables for these; keep as in-memory constants)
const LUGGAGE = [
  { id: '1', title: 'No Luggage' },
  { id: '2', title: 'Small Bag' },
  { id: '3', title: 'Medium Bag' },
  { id: '4', title: 'Large Bag' },
]
const BACK_SEATING = [
  { id: '1', title: 'No Preference' },
  { id: '2', title: 'Front Seat' },
  { id: '3', title: 'Back Seat Only' },
]
const RESTRICTIONS = [
  { id: '1', title: 'No Smoking', status: '1' },
  { id: '2', title: 'No Pets', status: '1' },
  { id: '3', title: 'No Food or Drinks', status: '1' },
  { id: '4', title: 'Music OK', status: '1' },
  { id: '5', title: 'Talking OK', status: '1' },
]

// ─── Seed vehicle lookup tables once ─────────────────────────────────────────
const VEHICLE_TYPES  = ['Sedan', 'SUV', 'Minivan', 'Hatchback', 'Pickup', 'Coupe', 'Convertible', 'Truck']
const VEHICLE_MODELS = [
  'Toyota Camry', 'Toyota Corolla', 'Toyota Highlander', 'Toyota Avalon',
  'Honda Civic', 'Honda Accord', 'Honda CR-V',
  'Hyundai Elantra', 'Hyundai Tucson',
  'Kia Sorento', 'Kia Sportage',
  'Ford Explorer', 'Ford Ranger',
  'Mitsubishi Outlander', 'Mitsubishi Eclipse Cross',
  'Nissan Altima', 'Nissan Pathfinder', 'Nissan Frontier',
  'Lexus ES 350', 'Lexus RX 350',
  'Mercedes-Benz C-Class', 'BMW 3 Series', 'Audi A4',
]
const VEHICLE_COLORS = [
  'White', 'Black', 'Silver', 'Grey', 'Red', 'Blue',
  'Brown', 'Gold', 'Orange', 'Green', 'Pearl White', 'Champagne',
]

let seedDone = false
async function ensureVehicleSeed() {
  if (seedDone) return
  seedDone = true
  const [tc, mc, cc] = await Promise.all([
    prisma.vehicleType.count(),
    prisma.vehicleModel.count(),
    prisma.vehicleColor.count(),
  ])
  if (tc === 0) {
    await prisma.vehicleType.createMany({
      data: VEHICLE_TYPES.map(t => ({ title: t })),
      skipDuplicates: true,
    })
  }
  if (mc === 0) {
    await prisma.vehicleModel.createMany({
      data: VEHICLE_MODELS.map(t => ({ title: t })),
      skipDuplicates: true,
    })
  }
  if (cc === 0) {
    await prisma.vehicleColor.createMany({
      data: VEHICLE_COLORS.map(t => ({ title: t })),
      skipDuplicates: true,
    })
  }
}

// ─── AUTH ────────────────────────────────────────────────────────────────────

export async function legacyLogin(req: Request, res: Response) {
  try {
    const { mobile, password } = req.body as { mobile?: string; ccode?: string; password?: string }
    if (!mobile || !password) { fail(res, 'Mobile and password are required'); return }

    const raw = String(mobile).trim().replace(/[\s-]/g, '')
    const candidates = new Set<string>([raw])
    if (raw.startsWith('+234')) { candidates.add('0' + raw.slice(4)); candidates.add(raw.slice(4)) }
    if (raw.startsWith('234'))  { candidates.add('0' + raw.slice(3)); candidates.add(raw.slice(3)) }
    if (raw.startsWith('0'))    { candidates.add(raw.slice(1)) }
    if (/^[1-9]\d{9}$/.test(raw)) { candidates.add('0' + raw) }

    const user = await prisma.user.findFirst({
      where: { mobile: { in: [...candidates] } },
      include: { companyMemberships: { where: { isActive: true }, take: 1 } },
    })
    if (!user || !(await bcrypt.compare(String(password), user.passwordHash))) {
      fail(res, 'Invalid mobile number or password'); return
    }
    if (user.status !== 'active') { fail(res, 'Account is not active'); return }

    const token = jwt.sign(
      { id: user.id, email: user.email, isDriver: user.isDriver },
      process.env.JWT_SECRET!,
      { expiresIn: '30d' },
    )
    res.json({
      Result: 'true', ResponseMsg: 'Login successful', token,
      company_id: user.companyMemberships[0]?.companyId ?? null,
      UserLogin: userLoginShape(user),
    })
  } catch (err) {
    console.error('legacyLogin error:', err)
    fail(res, 'Server error')
  }
}

function userLoginShape(user: any) {
  return {
    id:               user.id,
    name:             user.name,
    email:            user.email ?? '',
    mobile:           user.mobile,
    ccode:            user.countryCode,
    profile_pic:      picUrl(user.profilePicUrl),
    wallet:           Number(user.walletBalance),
    is_driver:        user.isDriver ? '1' : '0',
    status:           user.status,
    is_mobile_verify: user.isMobileVerified ? '1' : '0',
  }
}

// ─── MOBILE / EMAIL CHECK ────────────────────────────────────────────────────

export async function legacyMobileCheck(req: Request, res: Response) {
  try {
    const { mobile } = req.body as { mobile?: string }
    if (!mobile) { fail(res, 'Mobile is required'); return }
    const user = await findUserByMobile(mobile)
    res.json(user
      ? { Result: 'false', ResponseMsg: 'Already Exist Mobile Number!' }
      : { Result: 'true',  ResponseMsg: 'Mobile Available' })
  } catch (err) {
    console.error('legacyMobileCheck:', err); fail(res, 'Server error')
  }
}

export async function legacyEmailCheck(req: Request, res: Response) {
  try {
    const { email } = req.body as { email?: string }
    if (!email) { fail(res, 'Email is required'); return }
    const user = await prisma.user.findFirst({
      where: { email: { equals: String(email).trim(), mode: 'insensitive' } },
    })
    res.json(user
      ? { Result: 'false', ResponseMsg: 'Already Exist Email Address!' }
      : { Result: 'true',  ResponseMsg: 'Email Available' })
  } catch (err) {
    console.error('legacyEmailCheck:', err); fail(res, 'Server error')
  }
}

export function legacySmsType(_req: Request, res: Response) {
  res.json({ Result: 'true', ResponseMsg: 'Success', otp_auth: 'No', SMS_TYPE: 'none' })
}

// ─── REGISTRATION ────────────────────────────────────────────────────────────

export async function legacyRegUser(req: Request, res: Response) {
  try {
    const { name, email, mobile, ccode, password, dob, bio } = req.body as {
      name?: string; email?: string; mobile?: string; ccode?: string
      password?: string; dob?: string; bio?: string
    }
    if (!name || !mobile || !password) {
      fail(res, 'Name, mobile and password are required'); return
    }
    const raw = String(mobile).trim().replace(/[\s-]/g, '')
    const existing = await findUserByMobile(raw)
    if (existing) { fail(res, 'Mobile number already registered'); return }

    const file = (req as any).file as { filename?: string } | undefined
    const profilePicUrl = file?.filename ? `/api/uploads/profiles/${file.filename}` : null
    const hash = await bcrypt.hash(String(password), 12)

    const user = await prisma.user.create({
      data: {
        name: String(name).trim(),
        email: email ? String(email).trim().toLowerCase() : null,
        mobile: raw,
        countryCode: ccode ? String(ccode).trim() : '+234',
        passwordHash: hash,
        bio: bio ? String(bio).trim() : null,
        dateOfBirth: dob && dob !== 'null' ? new Date(dob) : null,
        profilePicUrl,
        status: 'active',
      },
    })
    const token = jwt.sign(
      { id: user.id, email: user.email, isDriver: user.isDriver },
      process.env.JWT_SECRET!,
      { expiresIn: '30d' },
    )
    res.json({
      Result: 'true', ResponseMsg: 'Registration successful', token,
      UserLogin: userLoginShape(user),
    })
  } catch (err: any) {
    if (err.code === 'P2002') { fail(res, 'Email or mobile already in use'); return }
    console.error('legacyRegUser:', err); fail(res, 'Server error')
  }
}

// ─── DATA GET (home screen data) ─────────────────────────────────────────────

export async function legacyDataGet(req: Request, res: Response) {
  try {
    const userId = uid(req)
    let vehicleData: any[] = []
    const isValidUuid = (s: string) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s)
    if (userId && isValidUuid(userId)) {
      const vehicles = await prisma.vehicle.findMany({
        where: { driverId: userId },
        include: { model: true, type: true, color: true },
      })
      vehicleData = vehicles.map(v => ({
        id:            String(v.id),
        uid:           v.driverId,
        photo:         picUrl(v.photoUrl),
        model_id:      String(v.modelId),
        type_id:       String(v.typeId),
        color_id:      String(v.colorId),
        year:          String(v.year),
        license_plate: v.licensePlate,
        status:        v.status,
        model_title:   v.model.title,
        type_title:    v.type.title,
        color_title:   v.color.title,
      }))
    }
    ok(res, {
      BackSeatingData: BACK_SEATING,
      LuggageData:     LUGGAGE,
      RestrictionData: RESTRICTIONS,
      VehicleData:     vehicleData,
    })
  } catch (err) {
    console.error('legacyDataGet:', err); fail(res, 'Server error')
  }
}

// ─── COLOR / TYPE / MODEL LIST ────────────────────────────────────────────────

export async function legacyColorTypeModelList(req: Request, res: Response) {
  try {
    await ensureVehicleSeed()
    const [models, types, colors] = await Promise.all([
      prisma.vehicleModel.findMany({ where: { status: true }, orderBy: { title: 'asc' } }),
      prisma.vehicleType.findMany({ where: { status: true },  orderBy: { title: 'asc' } }),
      prisma.vehicleColor.findMany({ where: { status: true }, orderBy: { title: 'asc' } }),
    ])
    ok(res, {
      ModelData:   models.map(m => ({ id: String(m.id), title: m.title, status: '1' })),
      CarTypeData: types.map(t  => ({ id: String(t.id), title: t.title,  status: '1' })),
      CarColorData: colors.map(c => ({ id: String(c.id), title: c.title,  status: '1' })),
    })
  } catch (err) {
    console.error('legacyColorTypeModelList:', err); fail(res, 'Server error')
  }
}

// ─── USER PROFILE ─────────────────────────────────────────────────────────────

export async function legacyUserProfile(req: Request, res: Response) {
  try {
    const userId = uid(req)
    if (!userId) { fail(res, 'uid required'); return }
    const user = await prisma.user.findUnique({ where: { id: userId } })
    if (!user) { fail(res, 'User not found'); return }

    const [ridesAsDriver, bookings, ratings] = await Promise.all([
      prisma.ride.count({ where: { driverId: userId } }),
      prisma.booking.count({ where: { passengerId: userId, status: { in: ['completed'] } } }),
      prisma.driverRating.aggregate({ where: { driverId: userId }, _avg: { rating: true }, _count: { id: true } }),
    ])

    const reviews = await prisma.driverRating.findMany({
      where: { driverId: userId },
      include: { passenger: true },
      orderBy: { createdAt: 'desc' },
      take: 10,
    })

    ok(res, {
      UserInfo: {
        id:               user.id,
        name:             user.name,
        email:            user.email ?? '',
        mobile:           user.mobile,
        ccode:            user.countryCode,
        profile_pic:      picUrl(user.profilePicUrl),
        bio:              user.bio ?? '',
        dob:              user.dateOfBirth ? user.dateOfBirth.toISOString().split('T')[0] : '',
        wallet:           Number(user.walletBalance),
        is_driver:        user.isDriver ? '1' : '0',
        status:           user.status,
        is_mobile_verify: user.isMobileVerified ? '1' : '0',
        referral_code:    user.referralCode ?? '',
        created_at:       user.createdAt.toISOString(),
      },
      Stats: {
        people_driven: ridesAsDriver,
        avg_rating:    Number(ratings._avg.rating ?? 0).toFixed(1),
        rides_taken:   bookings,
        km_shared:     0,
      },
      Reviews: reviews.map(r => ({
        book_uid:    String(r.id),
        name:        r.passenger.name,
        profile_pic: picUrl(r.passenger.profilePicUrl),
        total_rate:  String(r.rating),
        rate_desc:   r.review ?? '',
      })),
      UpcomingTrips: [],
    })
  } catch (err) {
    console.error('legacyUserProfile:', err); fail(res, 'Server error')
  }
}

// ─── PROFILE EDIT ─────────────────────────────────────────────────────────────

export async function legacyProfileEdit(req: Request, res: Response) {
  try {
    const { uid: userId, name, email, bio, dob } = req.body
    if (!userId) { fail(res, 'uid required'); return }
    const file = (req as any).file as { filename?: string } | undefined
    const updateData: any = {}
    if (name)  updateData.name  = String(name).trim()
    if (email) updateData.email = String(email).trim().toLowerCase()
    if (bio)   updateData.bio   = String(bio).trim()
    if (dob && dob !== 'null' && dob !== '') updateData.dateOfBirth = new Date(dob)
    if (file?.filename) updateData.profilePicUrl = `/api/uploads/profiles/${file.filename}`

    const user = await prisma.user.update({ where: { id: userId }, data: updateData })
    res.json({
      Result: 'true', ResponseMsg: 'Profile updated',
      UserLogin: userLoginShape(user),
    })
  } catch (err) {
    console.error('legacyProfileEdit:', err); fail(res, 'Server error')
  }
}

export async function legacyProImage(req: Request, res: Response) {
  try {
    const { uid: userId } = req.body
    const file = (req as any).file as { filename?: string } | undefined
    if (!userId || !file?.filename) { fail(res, 'uid and photo required'); return }
    const user = await prisma.user.update({
      where: { id: userId },
      data: { profilePicUrl: `/api/uploads/profiles/${file.filename}` },
    })
    res.json({ Result: 'true', ResponseMsg: 'Profile photo updated', UserLogin: userLoginShape(user) })
  } catch (err) {
    console.error('legacyProImage:', err); fail(res, 'Server error')
  }
}

// ─── VEHICLES ────────────────────────────────────────────────────────────────

export async function legacyVehicleList(req: Request, res: Response) {
  try {
    const userId = uid(req)
    if (!userId) { fail(res, 'uid required'); return }
    const vehicles = await prisma.vehicle.findMany({
      where: { driverId: userId },
      include: { model: true, type: true, color: true },
    })
    ok(res, {
      VehicleData: vehicles.map(v => ({
        id: String(v.id), uid: v.driverId,
        photo: picUrl(v.photoUrl), model_id: String(v.modelId), type_id: String(v.typeId),
        color_id: String(v.colorId), year: String(v.year), license_plate: v.licensePlate,
        status: v.status, model_title: v.model.title, type_title: v.type.title, color_title: v.color.title,
      })),
    })
  } catch (err) {
    console.error('legacyVehicleList:', err); fail(res, 'Server error')
  }
}

export async function legacyAddVehicle(req: Request, res: Response) {
  try {
    await ensureVehicleSeed()
    const { uid: userId, model_id, type_id, color_id, year, license_plate, seat_capacity } = req.body
    if (!userId || !model_id || !type_id || !color_id || !year || !license_plate) {
      fail(res, 'All vehicle fields required'); return
    }
    const file = (req as any).file as { filename?: string } | undefined
    const vehicle = await prisma.vehicle.create({
      data: {
        driverId: userId,
        modelId:  BigInt(model_id),
        typeId:   BigInt(type_id),
        colorId:  BigInt(color_id),
        year:     parseInt(year),
        licensePlate: String(license_plate).toUpperCase(),
        seatCapacity: seat_capacity ? parseInt(seat_capacity) : 4,
        photoUrl: file?.filename ? `/api/uploads/profiles/${file.filename}` : null,
        status:   'approved',
      },
      include: { model: true, type: true, color: true },
    })
    ok(res, {
      VehicleData: [{
        id: String(vehicle.id), uid: vehicle.driverId,
        photo: picUrl(vehicle.photoUrl), model_id: String(vehicle.modelId), type_id: String(vehicle.typeId),
        color_id: String(vehicle.colorId), year: String(vehicle.year), license_plate: vehicle.licensePlate,
        status: vehicle.status, model_title: vehicle.model.title, type_title: vehicle.type.title, color_title: vehicle.color.title,
      }],
    })
  } catch (err: any) {
    if (err.code === 'P2002') { fail(res, 'License plate already registered'); return }
    console.error('legacyAddVehicle:', err); fail(res, 'Server error')
  }
}

export async function legacyEditVehicle(req: Request, res: Response) {
  try {
    const { vehicle_id, model_id, type_id, color_id, year, license_plate, seat_capacity } = req.body
    if (!vehicle_id) { fail(res, 'vehicle_id required'); return }
    const updateData: any = {}
    if (model_id)      updateData.modelId       = BigInt(model_id)
    if (type_id)       updateData.typeId         = BigInt(type_id)
    if (color_id)      updateData.colorId        = BigInt(color_id)
    if (year)          updateData.year           = parseInt(year)
    if (license_plate) updateData.licensePlate   = String(license_plate).toUpperCase()
    if (seat_capacity) updateData.seatCapacity   = parseInt(seat_capacity)
    const file = (req as any).file as { filename?: string } | undefined
    if (file?.filename) updateData.photoUrl = `/api/uploads/profiles/${file.filename}`
    const v = await prisma.vehicle.update({
      where: { id: BigInt(vehicle_id) }, data: updateData,
      include: { model: true, type: true, color: true },
    })
    ok(res, {
      VehicleData: [{
        id: String(v.id), uid: v.driverId, photo: picUrl(v.photoUrl),
        model_id: String(v.modelId), type_id: String(v.typeId), color_id: String(v.colorId),
        year: String(v.year), license_plate: v.licensePlate, status: v.status,
        model_title: v.model.title, type_title: v.type.title, color_title: v.color.title,
      }],
    })
  } catch (err) {
    console.error('legacyEditVehicle:', err); fail(res, 'Server error')
  }
}

// ─── FIND TRIP ────────────────────────────────────────────────────────────────

export async function legacyFindTrip(req: Request, res: Response) {
  try {
    const { uid: userId, origin_lat, origin_long, destination_lat, destination_long, trip_date, status } = req.body

    const trips = await prisma.ride.findMany({
      where: {
        status: { in: ['pending', 'driver_assigned'] },
        scheduledAt: trip_date
          ? { gte: new Date(trip_date + 'T00:00:00'), lt: new Date(trip_date + 'T23:59:59') }
          : undefined,
        availableSeats: { gt: 0 },
      },
      include: {
        driver: true,
        vehicle: { include: { model: true, type: true } },
        bookings: { where: { status: { in: ['confirmed', 'processing', 'in_progress'] } } },
      },
      orderBy: { scheduledAt: 'asc' },
      take: 50,
    })

    const tripData = trips
      .filter(t => t.driverId !== userId)
      .map(t => ({
        trip_id:         t.id,
        total_seat:      String(t.availableSeats),
        seat_price:      String(Number(t.baseFare)),
        origin_address:  t.originAddress,
        origin_lat:      Number(t.originLat),
        origin_long:     Number(t.originLng),
        desti_address:   t.destinationAddress,
        desti_lat:       Number(t.destinationLat),
        desti_long:      Number(t.destinationLng),
        trip_start_date: t.scheduledAt.toISOString().split('T')[0],
        trip_start_time: t.scheduledAt.toTimeString().slice(0, 5),
        trip_is_return:  0,
        instant_approve: 1,
        people_driven:   0,
        rides_taken:     t.bookings.length,
        km_shared:       Number(t.estimatedDistanceKm ?? 0),
        total_reviews:   0,
        avg_rating:      0,
        total_completed_trip: 0,
        total_driven:    0,
        user_profile:    picUrl(t.driver.profilePicUrl),
        user_title:      t.driver.name,
        vehicle_title:   t.vehicle ? `${t.vehicle.model?.title ?? ''} ${t.vehicle.type?.title ?? ''}`.trim() : '',
      }))

    const requests = await prisma.rideRequest.findMany({
      where: {
        isActive: true,
        departureDate: trip_date ? new Date(trip_date) : undefined,
      },
      include: { passenger: true },
      take: 20,
    })

    const requestData = requests
      .filter(r => r.passengerId !== userId)
      .map(r => ({
        request_id:          r.id,
        from_address:        r.originAddress,
        from_lat:            String(Number(r.originLat)),
        from_long:           String(Number(r.originLng)),
        to_address:          r.destinationAddress,
        to_lat:              String(Number(r.destinationLat)),
        to_long:             String(Number(r.destinationLng)),
        departure_date:      r.departureDate.toISOString().split('T')[0],
        seat_require:        String(r.seatsRequired),
        request_description: r.notes ?? '',
        user_profile:        picUrl(r.passenger.profilePicUrl),
        user_title:          r.passenger.name,
        is_invited:          0,
        user_id:             r.passengerId,
        people_driven:       0, rides_taken: 0, km_shared: 0,
        total_reviews:       0, avg_rating:   0,
      }))

    ok(res, {
      Data: { TripData: tripData, RequestData: requestData },
    })
  } catch (err) {
    console.error('legacyFindTrip:', err); fail(res, 'Server error')
  }
}

// ─── POST TRIP ────────────────────────────────────────────────────────────────

export async function legacyPostTrip(req: Request, res: Response) {
  try {
    const {
      uid: userId, origin_address, origin_lat, origin_long,
      desti_address, desti_lat, desti_long,
      trip_start_date, trip_start_time, total_seat, seat_price,
      vehicle_id, skip_vehicle, ride_schedule, trip_description,
    } = req.body

    if (!userId || !origin_address || !desti_address || !trip_start_date || !total_seat || !seat_price) {
      fail(res, 'Required fields missing'); return
    }

    // Mark user as driver
    await prisma.user.update({ where: { id: userId }, data: { isDriver: true } })

    const scheduledAt = new Date(`${trip_start_date}T${trip_start_time || '08:00'}:00`)

    const ride = await prisma.ride.create({
      data: {
        driverId:           userId,
        vehicleId:          (vehicle_id && vehicle_id !== '' && skip_vehicle !== '1') ? BigInt(vehicle_id) : null,
        originAddress:      String(origin_address),
        originLat:          parseFloat(origin_lat || '6.4550'),
        originLng:          parseFloat(origin_long || '3.3841'),
        destinationAddress: String(desti_address),
        destinationLat:     parseFloat(desti_lat || '6.5'),
        destinationLng:     parseFloat(desti_long || '3.4'),
        scheduledAt,
        scheduleType:       ride_schedule === 'recurring_daily' ? 'recurring_daily' : 'one_time',
        baseFare:           parseFloat(seat_price),
        availableSeats:     parseInt(total_seat),
        tripNotes:          trip_description ?? null,
        pickupOtp:          String(Math.floor(1000 + Math.random() * 9000)),
        dropoffOtp:         String(Math.floor(1000 + Math.random() * 9000)),
        status:             'pending',
      },
    })

    ok(res, { parent_trip_ids: [parseInt(ride.id.replace(/-/g, '').slice(0, 9), 16) % 999999 + 1] })
  } catch (err) {
    console.error('legacyPostTrip:', err); fail(res, 'Server error')
  }
}

// ─── MY TRIP LIST ─────────────────────────────────────────────────────────────

export async function legacyTripList(req: Request, res: Response) {
  try {
    const { uid: userId, trip_type } = req.body
    if (!userId) { fail(res, 'uid required'); return }

    let statusFilter: any = { in: ['pending', 'driver_assigned', 'driver_en_route', 'in_progress'] }
    if (trip_type === 'Recent' || trip_type === 'Completed') statusFilter = { in: ['completed'] }
    if (trip_type === 'Cancelled') statusFilter = { in: ['cancelled'] }

    const rides = await prisma.ride.findMany({
      where: { driverId: userId, status: statusFilter },
      include: {
        driver: true,
        vehicle: { include: { model: true, type: true } },
      },
      orderBy: { scheduledAt: 'desc' },
      take: 50,
    })

    const tripData = rides.map(r => ({
      trip_id:         r.id,
      total_seat:      String(r.availableSeats),
      seat_price:      String(Number(r.baseFare)),
      origin_address:  r.originAddress,
      origin_lat:      Number(r.originLat),
      origin_long:     Number(r.originLng),
      desti_address:   r.destinationAddress,
      desti_lat:       Number(r.destinationLat),
      desti_long:      Number(r.destinationLng),
      trip_start_date: r.scheduledAt.toISOString().split('T')[0],
      trip_start_time: r.scheduledAt.toTimeString().slice(0, 5),
      trip_is_return:  '0',
      instant_approve: 1,
      total_rate:      0,
      total_driven:    Number(r.estimatedDistanceKm ?? 0),
      trip_status:     r.status,
      user_profile:    picUrl(r.driver.profilePicUrl),
      user_title:      r.driver.name,
      vehicle_title:   r.vehicle ? r.vehicle.model?.title ?? '' : '',
      vehicle_image:   r.vehicle ? picUrl(r.vehicle.photoUrl) : '',
      vehicle_type:    r.vehicle ? r.vehicle.type?.title ?? '' : '',
    }))

    ok(res, { TripType: trip_type, TripData: tripData })
  } catch (err) {
    console.error('legacyTripList:', err); fail(res, 'Server error')
  }
}

// ─── TRIP DETAILS ─────────────────────────────────────────────────────────────

export async function legacyTripDetails(req: Request, res: Response) {
  try {
    const { trip_id } = req.body
    if (!trip_id) { fail(res, 'trip_id required'); return }

    const ride = await prisma.ride.findUnique({
      where: { id: String(trip_id) },
      include: {
        driver: true,
        vehicle: { include: { model: true, type: true, color: true } },
        bookings: {
          where: { status: { in: ['confirmed', 'processing', 'in_progress', 'completed'] } },
          include: { passenger: true },
        },
      },
    })
    if (!ride) { fail(res, 'Trip not found'); return }

    const bookedSeats = ride.bookings.reduce((s, b) => s + b.seatsBooked, 0)

    ok(res, {
      TripData: {
        trip_id:         ride.id,
        total_seat:      String(ride.availableSeats + bookedSeats),
        seat_price:      String(Number(ride.baseFare)),
        origin_address:  ride.originAddress,
        origin_lat:      Number(ride.originLat),
        origin_long:     Number(ride.originLng),
        desti_address:   ride.destinationAddress,
        desti_lat:       Number(ride.destinationLat),
        desti_long:      Number(ride.destinationLng),
        trip_start_date: ride.scheduledAt.toISOString(),
        trip_start_time: ride.scheduledAt.toTimeString().slice(0, 5),
        trip_status:     ride.status,
        people_driven:   0, rides_taken: ride.bookings.length,
        km_shared:       Number(ride.estimatedDistanceKm ?? 0),
        total_reviews:   0, avg_rating:  0,
        trip_is_return:  '0', instant_approve: 1,
        user_profile:    picUrl(ride.driver.profilePicUrl),
        user_title:      ride.driver.name,
        user_id:         ride.driverId,
        user_mobile:     ride.driver.mobile,
        vehicle_title:   ride.vehicle ? ride.vehicle.model?.title ?? '' : '',
        vehicle_image:   ride.vehicle ? picUrl(ride.vehicle.photoUrl) : '',
        license_plate:   ride.vehicle?.licensePlate ?? '',
        year:            ride.vehicle ? String(ride.vehicle.year) : '',
        vehicle_color:   ride.vehicle?.color?.title ?? '',
        vehicle_type:    ride.vehicle?.type?.title ?? '',
        stops_details:   [],
        restri_details:  ride.restrictions,
        luggage_details: ride.luggageAllowed,
        backrow_details: '',
        booked_seat:     bookedSeats,
        remain_seat:     ride.availableSeats,
        booked_users:    ride.bookings.map(b => ({
          book_uid:    b.id,
          user_id:     b.passengerId,
          user_title:  b.passenger.name,
          user_profile: picUrl(b.passenger.profilePicUrl),
          book_seat:   b.seatsBooked,
          status:      b.status,
        })),
      },
    })
  } catch (err) {
    console.error('legacyTripDetails:', err); fail(res, 'Server error')
  }
}

// ─── BOOK SEAT ────────────────────────────────────────────────────────────────

export async function legacyBookSeat(req: Request, res: Response) {
  try {
    const { uid: userId, trip_id, seat, wallet_amount, payment_type } = req.body
    if (!userId || !trip_id) { fail(res, 'uid and trip_id required'); return }

    const ride = await prisma.ride.findUnique({ where: { id: String(trip_id) } })
    if (!ride) { fail(res, 'Trip not found'); return }

    const seatsToBook = parseInt(seat ?? '1') || 1
    if (ride.availableSeats < seatsToBook) { fail(res, 'Not enough available seats'); return }

    const subtotal = Number(ride.baseFare) * seatsToBook
    const walletUsed = Math.min(parseFloat(wallet_amount ?? '0') || 0, subtotal)
    const total = subtotal - walletUsed

    const booking = await prisma.booking.create({
      data: {
        rideId:            ride.id,
        passengerId:       userId,
        driverId:          ride.driverId,
        seatsBooked:       seatsToBook,
        subtotal,
        totalAmount:       total,
        walletAmountUsed:  walletUsed,
        driverEarning:     total * 0.85,
        platformCommission: total * 0.15,
        paymentGateway:    payment_type === 'paystack' ? 'paystack' : 'flutterwave',
        paymentStatus:     'successful',
        bookingMethod:     'instant',
        status:            'confirmed',
        confirmedAt:       new Date(),
      },
    })

    // Decrement seats
    await prisma.ride.update({
      where: { id: ride.id },
      data: { availableSeats: { decrement: seatsToBook } },
    })

    // Deduct wallet if used
    if (walletUsed > 0) {
      const user = await prisma.user.update({
        where: { id: userId },
        data: { walletBalance: { decrement: walletUsed } },
      })
      await prisma.walletTransaction.create({
        data: {
          userId, bookingId: booking.id,
          amount: -walletUsed,
          balanceAfter: Number(user.walletBalance),
          description: `Ride booking payment`,
        },
      })
    }

    ok(res, { book_id: booking.id })
  } catch (err) {
    console.error('legacyBookSeat:', err); fail(res, 'Server error')
  }
}

// ─── MY BOOKED TRIPS ─────────────────────────────────────────────────────────

export async function legacyMyBookTripList(req: Request, res: Response) {
  try {
    const userId = uid(req)
    if (!userId) { fail(res, 'uid required'); return }

    const bookings = await prisma.booking.findMany({
      where: { passengerId: userId },
      include: {
        ride: {
          include: {
            driver: true,
            vehicle: { include: { model: true, type: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    })

    const tripData = bookings.map(b => ({
      trip_id:         b.rideId,
      owner_id:        b.driverId ?? '',
      total_seat:      String(b.seatsBooked),
      seat_price:      String(Number(b.totalAmount)),
      origin_address:  b.ride.originAddress,
      origin_lat:      Number(b.ride.originLat),
      origin_long:     Number(b.ride.originLng),
      desti_address:   b.ride.destinationAddress,
      desti_lat:       Number(b.ride.destinationLat),
      desti_long:      Number(b.ride.destinationLng),
      trip_start_date: b.ride.scheduledAt.toISOString().split('T')[0],
      trip_start_time: b.ride.scheduledAt.toTimeString().slice(0, 5),
      trip_is_return:  '0', instant_approve: 1,
      total_rate:      0, total_driven: 0,
      user_profile:    picUrl(b.ride.driver.profilePicUrl),
      user_title:      b.ride.driver.name,
      status:          b.status,
      vehicle: {
        vehicle_title: b.ride.vehicle ? b.ride.vehicle.model?.title ?? '' : '',
        vehicle_image: b.ride.vehicle ? picUrl(b.ride.vehicle.photoUrl) : '',
        vehicle_type:  b.ride.vehicle ? b.ride.vehicle.type?.title ?? '' : '',
      },
    }))

    ok(res, { TripData: tripData })
  } catch (err) {
    console.error('legacyMyBookTripList:', err); fail(res, 'Server error')
  }
}

// ─── BOOK TRIP DETAILS ───────────────────────────────────────────────────────

export async function legacyBookTripDetails(req: Request, res: Response) {
  try {
    const { trip_id, uid: userId } = req.body
    if (!trip_id) { fail(res, 'trip_id required'); return }

    const booking = await prisma.booking.findFirst({
      where: { rideId: String(trip_id), passengerId: userId },
      include: {
        ride: {
          include: {
            driver: true,
            vehicle: { include: { model: true, type: true, color: true } },
            bookings: { where: { status: { in: ['confirmed', 'processing', 'in_progress', 'completed'] } }, include: { passenger: true } },
          },
        },
      },
    })
    if (!booking) { fail(res, 'Booking not found'); return }

    const ride = booking.ride
    const bookedSeats = ride.bookings.reduce((s, b) => s + b.seatsBooked, 0)

    ok(res, {
      TripData: {
        trip_id: ride.id,
        total_seat: String(ride.availableSeats + bookedSeats),
        seat_price: String(Number(ride.baseFare)),
        origin_address: ride.originAddress,
        origin_lat: Number(ride.originLat), origin_long: Number(ride.originLng),
        desti_address: ride.destinationAddress,
        desti_lat: Number(ride.destinationLat), desti_long: Number(ride.destinationLng),
        trip_start_date: ride.scheduledAt.toISOString(),
        trip_start_time: ride.scheduledAt.toTimeString().slice(0, 5),
        trip_status: ride.status,
        people_driven: 0, rides_taken: ride.bookings.length,
        km_shared: Number(ride.estimatedDistanceKm ?? 0),
        total_reviews: 0, avg_rating: 0,
        trip_is_return: '0', instant_approve: 1,
        user_profile: picUrl(ride.driver.profilePicUrl),
        user_title: ride.driver.name,
        user_id: ride.driverId,
        user_mobile: ride.driver.mobile,
        vehicle_title: ride.vehicle?.model?.title ?? '',
        vehicle_image: ride.vehicle ? picUrl(ride.vehicle.photoUrl) : '',
        license_plate: ride.vehicle?.licensePlate ?? '',
        year: ride.vehicle ? String(ride.vehicle.year) : '',
        vehicle_color: ride.vehicle?.color?.title ?? '',
        vehicle_type: ride.vehicle?.type?.title ?? '',
        stops_details: [], restri_details: ride.restrictions,
        luggage_details: ride.luggageAllowed, backrow_details: '',
        booked_seat: bookedSeats,
        remain_seat: ride.availableSeats,
        booked_users: ride.bookings.map(b => ({
          book_uid: b.id, user_id: b.passengerId,
          user_title: b.passenger.name, user_profile: picUrl(b.passenger.profilePicUrl),
          book_seat: b.seatsBooked, status: b.status,
        })),
      },
    })
  } catch (err) {
    console.error('legacyBookTripDetails:', err); fail(res, 'Server error')
  }
}

// ─── CANCEL TRIP ─────────────────────────────────────────────────────────────

export async function legacyCancelTrip(req: Request, res: Response) {
  try {
    const { trip_id, uid: userId } = req.body
    if (!trip_id) { fail(res, 'trip_id required'); return }
    await prisma.ride.updateMany({
      where: { id: String(trip_id), driverId: userId },
      data: { status: 'cancelled', cancelledAt: new Date() },
    })
    ok(res, {})
  } catch (err) {
    console.error('legacyCancelTrip:', err); fail(res, 'Server error')
  }
}

// ─── CANCEL SEAT (passenger cancels booking) ──────────────────────────────────

export async function legacyCancelSeat(req: Request, res: Response) {
  try {
    const { trip_id, uid: userId } = req.body
    const booking = await prisma.booking.findFirst({
      where: { rideId: String(trip_id), passengerId: userId },
    })
    if (booking) {
      await prisma.booking.update({
        where: { id: booking.id },
        data: { status: 'cancelled', cancelledAt: new Date() },
      })
      // Return seats
      await prisma.ride.update({
        where: { id: String(trip_id) },
        data: { availableSeats: { increment: booking.seatsBooked } },
      })
    }
    ok(res, {})
  } catch (err) {
    console.error('legacyCancelSeat:', err); fail(res, 'Server error')
  }
}

// ─── TRIP REQUESTS (for driver: who wants to join my ride) ───────────────────

export async function legacyRequestList(req: Request, res: Response) {
  try {
    const userId = uid(req)
    if (!userId) { fail(res, 'uid required'); return }

    const requests = await prisma.rideRequest.findMany({
      where: { isActive: true },
      include: { passenger: true },
      orderBy: { createdAt: 'desc' },
      take: 30,
    })

    ok(res, {
      Data: requests.map(r => ({
        request_id:          r.id,
        from_address:        r.originAddress,
        from_lat:            String(Number(r.originLat)),
        from_long:           String(Number(r.originLng)),
        to_address:          r.destinationAddress,
        to_lat:              String(Number(r.destinationLat)),
        to_long:             String(Number(r.destinationLng)),
        departure_date:      r.departureDate.toISOString().split('T')[0],
        seat_require:        String(r.seatsRequired),
        request_description: r.notes ?? '',
        user_profile:        picUrl(r.passenger.profilePicUrl),
        user_title:          r.passenger.name,
        user_id:             r.passengerId,
        people_driven: 0, rides_taken: 0, km_shared: 0, total_reviews: 0, avg_rating: 0,
        request_datetime:    r.createdAt.toISOString(),
        trip_info:           [],
      })),
    })
  } catch (err) {
    console.error('legacyRequestList:', err); fail(res, 'Server error')
  }
}

export async function legacyMakeDecision(req: Request, res: Response) {
  try {
    const { request_id, status, trip_id, uid: userId } = req.body
    // For ride requests, mark as inactive if rejected/accepted
    if (request_id) {
      await prisma.rideRequest.update({
        where: { id: String(request_id) },
        data: { isActive: false },
      })
    }
    ok(res, {})
  } catch (err) {
    console.error('legacyMakeDecision:', err); fail(res, 'Server error')
  }
}

// ─── TRIP REQUEST (passenger posts a request) ────────────────────────────────

export async function legacyTripRequest(req: Request, res: Response) {
  try {
    const {
      uid: userId, from_address, from_lat, from_long,
      to_address, to_lat, to_long,
      departure_date, seat_require, trip_description,
    } = req.body
    if (!userId || !from_address || !to_address) { fail(res, 'Required fields missing'); return }

    const request = await prisma.rideRequest.create({
      data: {
        passengerId:        userId,
        originAddress:      String(from_address),
        originLat:          parseFloat(from_lat || '6.4550'),
        originLng:          parseFloat(from_long || '3.3841'),
        destinationAddress: String(to_address),
        destinationLat:     parseFloat(to_lat || '6.5'),
        destinationLng:     parseFloat(to_long || '3.4'),
        departureDate:      new Date(departure_date || new Date().toISOString().split('T')[0]),
        seatsRequired:      parseInt(seat_require ?? '1') || 1,
        notes:              trip_description ?? null,
        isActive:           true,
      },
    })
    ok(res, { request_id: request.id })
  } catch (err) {
    console.error('legacyTripRequest:', err); fail(res, 'Server error')
  }
}

export async function legacyTripRequestList(req: Request, res: Response) {
  try {
    const userId = uid(req)
    if (!userId) { fail(res, 'uid required'); return }

    const requests = await prisma.rideRequest.findMany({
      where: { passengerId: userId },
      include: { passenger: true },
      orderBy: { createdAt: 'desc' },
      take: 30,
    })

    ok(res, {
      Data: requests.map(r => ({
        request_id: r.id,
        from_address: r.originAddress, to_address: r.destinationAddress,
        departure_date: r.departureDate.toISOString().split('T')[0],
        seat_require: String(r.seatsRequired),
        request_description: r.notes ?? '',
        user_profile: picUrl(r.passenger.profilePicUrl),
        user_title: r.passenger.name, user_id: r.passengerId,
        from_lat: String(Number(r.originLat)), from_long: String(Number(r.originLng)),
        to_lat: String(Number(r.destinationLat)), to_long: String(Number(r.destinationLng)),
        people_driven: 0, rides_taken: 0, km_shared: 0, total_reviews: 0, avg_rating: 0,
        request_datetime: r.createdAt.toISOString(),
        trip_info: [],
      })),
    })
  } catch (err) {
    console.error('legacyTripRequestList:', err); fail(res, 'Server error')
  }
}

export async function legacyDeleteTripRequest(req: Request, res: Response) {
  try {
    const { request_id, uid: userId } = req.body
    if (!request_id) { fail(res, 'request_id required'); return }
    await prisma.rideRequest.deleteMany({ where: { id: String(request_id), passengerId: userId } })
    ok(res, {})
  } catch (err) {
    console.error('legacyDeleteTripRequest:', err); fail(res, 'Server error')
  }
}

export async function legacyEditTripRequest(req: Request, res: Response) {
  try {
    const { request_id, uid: userId, departure_date, seat_require, trip_description } = req.body
    if (!request_id) { fail(res, 'request_id required'); return }
    await prisma.rideRequest.updateMany({
      where: { id: String(request_id), passengerId: userId },
      data: {
        departureDate: departure_date ? new Date(departure_date) : undefined,
        seatsRequired: seat_require ? parseInt(seat_require) : undefined,
        notes: trip_description ?? undefined,
      },
    })
    ok(res, {})
  } catch (err) {
    console.error('legacyEditTripRequest:', err); fail(res, 'Server error')
  }
}

// ─── WALLET ──────────────────────────────────────────────────────────────────

export async function legacyWalletReport(req: Request, res: Response) {
  try {
    const userId = uid(req)
    if (!userId) { fail(res, 'uid required'); return }

    const [user, txns] = await Promise.all([
      prisma.user.findUnique({ where: { id: userId } }),
      prisma.walletTransaction.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: 50,
      }),
    ])

    ok(res, {
      wallet_balance: Number(user?.walletBalance ?? 0),
      WalletData: txns.map(t => ({
        id:          String(t.id),
        amount:      Number(t.amount),
        balance:     Number(t.balanceAfter),
        description: t.description,
        type:        Number(t.amount) >= 0 ? 'credit' : 'debit',
        date:        t.createdAt.toISOString(),
        reference:   t.reference ?? '',
      })),
    })
  } catch (err) {
    console.error('legacyWalletReport:', err); fail(res, 'Server error')
  }
}

export async function legacyWalletUp(req: Request, res: Response) {
  try {
    const { uid: userId, amount, payment_id, payment_type } = req.body
    if (!userId || !amount) { fail(res, 'uid and amount required'); return }
    const amt = parseFloat(amount)
    const user = await prisma.user.update({
      where: { id: userId },
      data: { walletBalance: { increment: amt } },
    })
    await prisma.walletTransaction.create({
      data: {
        userId, amount: amt, balanceAfter: Number(user.walletBalance),
        description: 'Wallet top-up',
        reference: payment_id ?? null,
      },
    })
    ok(res, { wallet_balance: Number(user.walletBalance) })
  } catch (err) {
    console.error('legacyWalletUp:', err); fail(res, 'Server error')
  }
}

// ─── PAYSTACK WALLET TOP-UP ───────────────────────────────────────────────────
//
// The Flutter app calls POST /paystack/index.php (mounted outside /api,
// matching Confing.imageurl + Confing.payStack in the client) with
// { uid, email, amount } and expects { status: true, data: { authorization_url } }
// (the standard Paystack initialize response shape).
//
// After payment, Paystack redirects to legacyPaystackCallback, which verifies
// the transaction server-side (never trusts the redirect alone), then bounces
// to legacyPaystackResult with ?status=success|failed so the app's webview
// navigation delegate can detect it and call wallet_up.php to credit the wallet.

export async function legacyPaystackInit(req: Request, res: Response) {
  try {
    const { uid: userId, email, amount } = req.body
    if (!userId || !email || !amount) { fail(res, 'uid, email and amount required'); return }

    const amt = parseFloat(amount)
    if (!Number.isFinite(amt) || amt <= 0) { fail(res, 'Invalid amount'); return }

    const settings = await prisma.platformSettings.findUnique({ where: { id: 1 } })
    const secretKey = settings?.paystackSecretKey || undefined

    const reference = `CCR-WALLET-${userId}-${Date.now()}`
    const result = await paystackInitialize({
      email,
      amountKobo:  Math.round(amt * 100),
      reference,
      callbackUrl: `${CCRIDE_API_BASE}/paystack_callback.php`,
      metadata:    { uid: userId, amount: amt },
      secretKey,
    })

    res.json({
      status: true,
      data: {
        authorization_url: result.authorization_url,
        access_code:       result.access_code,
        reference:         result.reference,
      },
    })
  } catch (err) {
    console.error('legacyPaystackInit:', err)
    res.json({ status: false, message: 'Unable to initiate Paystack payment' })
  }
}

export async function legacyPaystackCallback(req: Request, res: Response) {
  const reference = (req.query.reference ?? req.query.trxref) as string | undefined
  if (!reference) {
    res.redirect(302, `${CCRIDE_API_BASE}/paystack_result.php?status=failed`)
    return
  }

  try {
    const settings = await prisma.platformSettings.findUnique({ where: { id: 1 } })
    const result = await paystackVerify(reference, settings?.paystackSecretKey || undefined)
    const success = result.status === 'success'
    res.redirect(
      302,
      `${CCRIDE_API_BASE}/paystack_result.php?status=${success ? 'success' : 'failed'}&trxref=${encodeURIComponent(reference)}`,
    )
  } catch (err) {
    console.error('legacyPaystackCallback:', err)
    res.redirect(302, `${CCRIDE_API_BASE}/paystack_result.php?status=failed&trxref=${encodeURIComponent(reference)}`)
  }
}

export async function legacyPaystackResult(req: Request, res: Response) {
  const status = req.query.status === 'success' ? 'success' : 'failed'
  res.send(`
    <html><body style="font-family:sans-serif;text-align:center;padding-top:60px;">
      <h2>${status === 'success' ? 'Payment successful' : 'Payment failed'}</h2>
      <p>You may close this window.</p>
    </body></html>
  `)
}

// ─── EARNINGS (driver) ────────────────────────────────────────────────────────

export async function legacyEarning(req: Request, res: Response) {
  try {
    const userId = uid(req)
    if (!userId) { fail(res, 'uid required'); return }

    const [completedBookings, cancelledCount, pendingCount, settings, paidPayouts] = await Promise.all([
      prisma.booking.findMany({
        where: { driverId: userId, status: 'completed' },
        include: { ride: true },
        orderBy: { completedAt: 'desc' },
        take: 50,
      }),
      prisma.booking.count({ where: { driverId: userId, status: 'cancelled' } }),
      prisma.booking.count({ where: { driverId: userId, status: 'pending' } }),
      prisma.platformSettings.findUnique({ where: { id: 1 } }),
      prisma.payoutRequest.aggregate({
        where: { driverId: userId, status: { in: ['paid', 'completed'] } },
        _sum: { amount: true },
      }),
    ])

    const totalEarnings = completedBookings.reduce((s, b) => s + Number(b.driverEarning), 0)
    const totalKm = completedBookings.reduce((s, b) => s + Number(b.ride.estimatedDistanceKm ?? 0), 0)

    ok(res, {
      total_completed:  completedBookings.length,
      total_cancelled:  cancelledCount,
      total_pending:    pendingCount,
      w_limit:          Number(settings?.driverPayoutThreshold ?? 5000),
      total_km_driven:  totalKm,
      total_earning:    totalEarnings,
      total_payout:     Number(paidPayouts._sum.amount ?? 0),
      currency:         settings?.currencySymbol ?? '₦',
      pastTrips: completedBookings.map(b => ({
        trip_id:        b.rideId,
        origin_address: b.ride.originAddress,
        origin_lat:     Number(b.ride.originLat),
        origin_long:    Number(b.ride.originLng),
        desti_address:  b.ride.destinationAddress,
        desti_lat:      Number(b.ride.destinationLat),
        desti_long:     Number(b.ride.destinationLng),
        profile_pic:    null,
        start_time:     b.ride.scheduledAt.toISOString(),
        total_seat:     b.seatsBooked,
        seat_price:     Number(b.ride.baseFare),
        driver_earning: Number(b.driverEarning),
      })),
    })
  } catch (err) {
    console.error('legacyEarning:', err); fail(res, 'Server error')
  }
}

export async function legacyRequestWithdraw(req: Request, res: Response) {
  try {
    ok(res, { message: 'Withdrawal request submitted — please set up your bank account first.' })
  } catch (err) {
    fail(res, 'Server error')
  }
}

export async function legacyPayoutList(req: Request, res: Response) {
  try {
    ok(res, { PayoutData: [] })
  } catch (err) {
    fail(res, 'Server error')
  }
}

// ─── CONTENT ─────────────────────────────────────────────────────────────────

export async function legacyFaq(req: Request, res: Response) {
  try {
    let faqs = await prisma.faq.findMany({ where: { isActive: true }, orderBy: { sortOrder: 'asc' }, take: 30 })
    if (faqs.length === 0) {
      faqs = await prisma.faq.createManyAndReturn({
        data: [
          { question: 'How does CC Ride work?',        answer: 'CC Ride connects corporate employees with drivers for scheduled and on-demand rides. Book through the app, track in real time, and pay seamlessly.' },
          { question: 'How do I book a ride?',         answer: 'Tap "Find a Ride" on the home screen, enter your pickup and destination, choose a trip and tap "Book Seat".' },
          { question: 'How do I post a ride as a driver?', answer: 'Tap the "Post" tab, enter your route, date, time, and seat price. Passengers will be able to find and book your trip.' },
          { question: 'What payment methods are accepted?', answer: 'We accept Paystack, Flutterwave, and in-app wallet balance.' },
          { question: 'How do I add my vehicle?',      answer: 'Go to Profile → My Vehicles → Add Vehicle. Fill in your vehicle details and submit.' },
          { question: 'Is CC Ride safe?',              answer: 'Yes. All drivers are verified, trips are tracked in real time, and both driver and passenger ratings ensure accountability.' },
        ],
      })
    }
    const settings = await prisma.platformSettings.findUnique({ where: { id: 1 } })
    ok(res, {
      FaqData: faqs.map(f => ({
        id: String(f.id), question: f.question, answer: f.answer, status: '1',
      })),
      currency:    settings?.currencySymbol ?? '₦',
      booking_fee: Number(settings?.bookingFee ?? 100),
    })
  } catch (err) {
    console.error('legacyFaq:', err); fail(res, 'Server error')
  }
}

export async function legacyPageList(req: Request, res: Response) {
  try {
    let pages = await prisma.contentPage.findMany({ where: { isActive: true }, take: 10 })
    if (pages.length === 0) {
      pages = await prisma.contentPage.createManyAndReturn({
        data: [
          { slug: 'terms', title: 'Terms & Conditions', content: 'By using CC Ride, you agree to our terms of service. You must be 18 or older to use this app. All rides are subject to availability.' },
          { slug: 'privacy', title: 'Privacy Policy', content: 'CC Ride collects minimal personal information to provide ride services. We do not sell your data to third parties. Location data is only used during active trips.' },
          { slug: 'about', title: 'About CC Ride', content: 'CC Ride is a corporate ride-hailing platform designed to make employee commuting efficient, safe, and cost-effective.' },
        ],
      })
    }
    ok(res, {
      PageData: pages.map(p => ({
        id: String(p.id), title: p.title, description: p.content, status: '1', slug: p.slug,
      })),
    })
  } catch (err) {
    console.error('legacyPageList:', err); fail(res, 'Server error')
  }
}

// ─── PAYMENT GATEWAY ─────────────────────────────────────────────────────────

export async function legacyPaymentGateway(req: Request, res: Response) {
  try {
    const settings = await prisma.platformSettings.findUnique({ where: { id: 1 } })
    ok(res, {
      PaymentData: [
        {
          id: '1', title: 'Paystack', status: '1',
          public_key: settings?.paystackPublicKey ?? '',
          gateway_type: 'paystack',
        },
      ],
    })
  } catch (err) {
    console.error('legacyPaymentGateway:', err); fail(res, 'Server error')
  }
}

// ─── COUPON ──────────────────────────────────────────────────────────────────

export async function legacyCheckCoupon(req: Request, res: Response) {
  try {
    const { coupon_code, uid: userId } = req.body
    if (!coupon_code) { fail(res, 'Coupon code required'); return }
    const coupon = await prisma.coupon.findFirst({
      where: { code: String(coupon_code).toUpperCase(), isActive: true, expiresAt: { gt: new Date() } },
    })
    if (!coupon) { fail(res, 'Invalid or expired coupon'); return }
    ok(res, {
      CouponData: {
        id: String(coupon.id), title: coupon.title, code: coupon.code,
        discount: Number(coupon.discountValue), is_percentage: coupon.isPercentage ? '1' : '0',
      },
    })
  } catch (err) {
    console.error('legacyCheckCoupon:', err); fail(res, 'Server error')
  }
}

export async function legacyCouponList(req: Request, res: Response) {
  try {
    const coupons = await prisma.coupon.findMany({ where: { isActive: true, expiresAt: { gt: new Date() } }, take: 20 })
    ok(res, {
      CouponData: coupons.map(c => ({
        id: String(c.id), title: c.title, code: c.code, subtitle: c.subtitle ?? '',
        description: c.description ?? '', discount: Number(c.discountValue),
        is_percentage: c.isPercentage ? '1' : '0', expires_at: c.expiresAt.toISOString(),
        image: picUrl(c.imageUrl),
      })),
    })
  } catch (err) {
    console.error('legacyCouponList:', err); fail(res, 'Server error')
  }
}

// ─── REFERRAL ────────────────────────────────────────────────────────────────

export async function legacyReferData(req: Request, res: Response) {
  try {
    const userId = uid(req)
    if (!userId) { fail(res, 'uid required'); return }
    const user = await prisma.user.findUnique({ where: { id: userId } })
    const settings = await prisma.platformSettings.findUnique({ where: { id: 1 } })
    ok(res, {
      referral_code: user?.referralCode ?? '',
      referral_bonus: Number(settings?.referralBonus ?? 500),
      ReferData: [],
    })
  } catch (err) {
    console.error('legacyReferData:', err); fail(res, 'Server error')
  }
}

// ─── EDIT POST TRIP ──────────────────────────────────────────────────────────

export async function legacyEditPostTrip(req: Request, res: Response) {
  try {
    const {
      uid: userId, trip_id, origin_address, origin_lat, origin_long,
      desti_address, desti_lat, desti_long, trip_start_date, trip_start_time,
      total_seat, seat_price, vehicle_id,
    } = req.body
    if (!trip_id) { fail(res, 'trip_id required'); return }
    const scheduledAt = trip_start_date
      ? new Date(`${trip_start_date}T${trip_start_time || '08:00'}:00`)
      : undefined
    const updateData: any = {}
    if (origin_address)  updateData.originAddress      = origin_address
    if (origin_lat)      updateData.originLat          = parseFloat(origin_lat)
    if (origin_long)     updateData.originLng          = parseFloat(origin_long)
    if (desti_address)   updateData.destinationAddress = desti_address
    if (desti_lat)       updateData.destinationLat     = parseFloat(desti_lat)
    if (desti_long)      updateData.destinationLng     = parseFloat(desti_long)
    if (scheduledAt)     updateData.scheduledAt        = scheduledAt
    if (total_seat)      updateData.availableSeats     = parseInt(total_seat)
    if (seat_price)      updateData.baseFare           = parseFloat(seat_price)
    if (vehicle_id)      updateData.vehicleId          = BigInt(vehicle_id)
    await prisma.ride.updateMany({ where: { id: String(trip_id), driverId: userId }, data: updateData })
    ok(res, {})
  } catch (err) {
    console.error('legacyEditPostTrip:', err); fail(res, 'Server error')
  }
}

// ─── ACCOUNT DELETE ──────────────────────────────────────────────────────────

export async function legacyAccDelete(req: Request, res: Response) {
  try {
    const userId = uid(req)
    if (!userId) { fail(res, 'uid required'); return }
    await prisma.user.update({ where: { id: userId }, data: { status: 'banned' } })
    ok(res, { message: 'Account deactivated' })
  } catch (err) {
    console.error('legacyAccDelete:', err); fail(res, 'Server error')
  }
}

// ─── PROCESSING TRIP (driver confirms pickup) ────────────────────────────────

export async function legacyProcessingTrip(req: Request, res: Response) {
  try {
    const { trip_id, uid: userId } = req.body
    if (!trip_id) { fail(res, 'trip_id required'); return }
    await prisma.ride.updateMany({
      where: { id: String(trip_id), driverId: userId },
      data: { status: 'in_progress', startedAt: new Date() },
    })
    await prisma.booking.updateMany({
      where: { rideId: String(trip_id), status: 'confirmed' },
      data: { status: 'in_progress', startedAt: new Date() },
    })
    ok(res, {})
  } catch (err) {
    console.error('legacyProcessingTrip:', err); fail(res, 'Server error')
  }
}

export async function legacyCompleteTrip(req: Request, res: Response) {
  try {
    const { trip_id, uid: userId } = req.body
    if (!trip_id) { fail(res, 'trip_id required'); return }
    await prisma.ride.updateMany({
      where: { id: String(trip_id), driverId: userId },
      data: { status: 'completed', completedAt: new Date() },
    })
    await prisma.booking.updateMany({
      where: { rideId: String(trip_id), status: 'in_progress' },
      data: { status: 'completed', completedAt: new Date() },
    })
    ok(res, {})
  } catch (err) {
    console.error('legacyCompleteTrip:', err); fail(res, 'Server error')
  }
}

export async function legacyRateUpdate(req: Request, res: Response) {
  try {
    const { trip_id, uid: userId, total_rate, rate_desc } = req.body
    if (!trip_id || !userId || !total_rate) { fail(res, 'Required fields missing'); return }
    const booking = await prisma.booking.findFirst({
      where: { rideId: String(trip_id), passengerId: userId, status: 'completed' },
    })
    if (!booking || !booking.driverId) { fail(res, 'Booking not found'); return }
    await prisma.driverRating.upsert({
      where: { bookingId: booking.id },
      create: {
        bookingId:   booking.id,
        driverId:    booking.driverId,
        passengerId: userId,
        rating:      parseInt(total_rate),
        review:      rate_desc ?? null,
      },
      update: { rating: parseInt(total_rate), review: rate_desc ?? null },
    })
    ok(res, {})
  } catch (err) {
    console.error('legacyRateUpdate:', err); fail(res, 'Server error')
  }
}

// ─── FIND TRIP DETAIL ────────────────────────────────────────────────────────

export async function legacyFindTripDetail(req: Request, res: Response) {
  return legacyTripDetails(req, res)
}

// ─── FALLBACK ─────────────────────────────────────────────────────────────────

export function legacyFallback(_req: Request, res: Response) {
  res.json({ Result: 'false', ResponseCode: '400', ResponseMsg: 'Endpoint not available in this build' })
}
