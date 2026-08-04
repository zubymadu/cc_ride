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
import { flwVerifyByRef, flwVerifyById } from '../../lib/flutterwave'
import { notifyNearbyDriversOfRequest, notifyPassengerOfMatch } from '../../lib/notify'
import { sendMail } from '../../lib/mail'
import { distanceKm } from '../../lib/geo'
import { computeFareSplit, recordRideSavings, estimateFare } from '../../lib/pricingService'
import { checkPoolRideEligibility } from '../../lib/poolAccessService'
import { dec } from '../../lib/naira'

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

// The acting user is always the verified JWT subject (requireAuth populates
// req.user), never whatever uid/user_id the client puts in the body — the
// body value was previously trusted outright, letting any caller impersonate
// any account by simply naming a different uid.
function uid(req: Request): string | null {
  return req.user?.id ?? null
}

/** Return a profile pic URL that the app can resolve via imageurl prefix */
function picUrl(raw: string | null | undefined): string {
  if (!raw) return ''
  if (raw.startsWith('http')) return raw
  // Every stored path (profilePicUrl, vehicle photoUrl, etc.) is written
  // with a leading slash (e.g. "/api/uploads/profiles/xxx"), but every
  // Flutter call site concatenates this directly onto Confing.imageurl,
  // which already ends in "/" — producing a double slash
  // ("https://api.ccride.ng//api/uploads/...") that 404s. Strip the leading
  // slash here once, for every consumer, rather than fixing dozens of
  // "${Confing.imageurl}${field}" call sites client-side.
  return raw.startsWith('/') ? raw.slice(1) : raw
}

// The Flutter app's BookedUser models (book_trip_details_api_model.dart /
// trip_details_api_model.dart) read book_status as one of these exact
// capitalized labels and branch UI (Approve/Reject vs Processing vs
// Completed) on them — the raw lowercase BookingStatus enum value never
// matched any of those checks, so a driver's seating-plan screen rendered no
// action buttons at all for a real booking.
function bookStatusLabel(status: string): string {
  switch (status) {
    case 'pending': return 'Pending'
    case 'confirmed': return 'Booked'
    case 'processing':
    case 'in_progress': return 'Processing'
    case 'completed': return 'Completed'
    case 'no_show': return 'No Show'
    case 'cancelled': return 'Cancelled'
    default: return 'Pending'
  }
}

// Shared shape for the booked_users list on both legacyTripDetails (driver's
// seating-plan view) and legacyBookTripDetails (passenger's own booking
// view) — the app's BookedUser.fromJson expects exactly these keys.
function bookedUserPayload(
  b: { id: string; passengerId: string; seatsBooked: number; status: string; passenger: { name: string; mobile: string; profilePicUrl: string | null } },
  ride: { pickupOtp: string | null; dropoffOtp: string | null },
) {
  return {
    book_id:     b.id,
    user_id:     b.passengerId,
    user_name:   b.passenger.name,
    user_mobile: b.passenger.mobile,
    profile_pic: picUrl(b.passenger.profilePicUrl),
    total_seat:  b.seatsBooked,
    is_approve:  b.status === 'pending' ? 0 : (b.status === 'cancelled' || b.status === 'no_show' ? 2 : 1),
    book_status: bookStatusLabel(b.status),
    pickup_otp:  ride.pickupOtp ?? '',
    drop_otp:    ride.dropoffOtp ?? '',
  }
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
      include: {
        companyMemberships: {
          where: { isActive: true },
          take: 1,
          include: { company: { select: { name: true } } },
        },
      },
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
    const membership = user.companyMemberships[0]
    res.json({
      Result: 'true', ResponseMsg: 'Login successful', token,
      company_id:       membership?.companyId ?? null,
      // Surfaced so the app can show a "Welcome — Pool Driver at {company}"
      // banner and the required company employee ID once in pool mode.
      company_name:     membership?.company.name ?? null,
      employee_number:  membership?.employeeNumber ?? null,
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
    // dob and bio were both missing entirely — every save("userLogin", ...)
    // after a profile update (see legacyProfileEdit/legacyProImage below)
    // overwrote the client's local cache with an object lacking these two
    // fields, so a date of birth or bio the user had just set would read
    // back as empty/null the moment they reopened the screen, even though
    // both were correctly persisted server-side all along.
    dob:              user.dateOfBirth ? user.dateOfBirth.toISOString().split('T')[0] : '',
    bio:              user.bio ?? '',
    wallet:           Number(user.walletBalance),
    is_driver:        user.isDriver ? '1' : '0',
    status:           user.status,
    is_mobile_verify: user.isMobileVerified ? '1' : '0',
    is_email_verify:  user.isEmailVerified ? '1' : '0',
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
    const { name, email, mobile, ccode, password, dob, bio, nin, passport_number } = req.body as {
      name?: string; email?: string; mobile?: string; ccode?: string
      password?: string; dob?: string; bio?: string
      nin?: string; passport_number?: string
    }
    if (!name || !mobile || !password) {
      fail(res, 'Name, mobile and password are required'); return
    }
    // Optional for an ordinary passenger (unlike driver/corporate
    // registration, which requires one) — but if both are given, that's
    // still not valid, since only one ever applies to a real person.
    if (nin && passport_number) {
      fail(res, 'Provide either a NIN or a passport number, not both'); return
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
        nin: nin ? String(nin).trim() : null,
        passportNumber: passport_number ? String(passport_number).trim() : null,
        passwordHash: hash,
        bio: bio ? String(bio).trim() : null,
        dateOfBirth: dob && dob !== 'null' ? new Date(dob) : null,
        profilePicUrl,
        status: 'active',
        // No SMS OTP provider is wired up in this build — the mobile number
        // is already the account's login credential, so it's treated as
        // verified at registration rather than permanently blocking every
        // user on a verification step that can never complete. Email
        // verification (email_otp.php / verify_email.php) is real and
        // still required separately.
        isMobileVerified: true,
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
    if (err.code === 'P2002') {
      const field = err?.meta?.target?.[0]
      if (field === 'nin') { fail(res, 'An account already exists with this NIN'); return }
      if (field === 'passport_number') { fail(res, 'An account already exists with this passport number'); return }
      fail(res, 'Email or mobile already in use'); return
    }
    console.error('legacyRegUser:', err); fail(res, 'Server error')
  }
}

// ─── EMAIL VERIFICATION ───────────────────────────────────────────────────────

export async function legacyEmailOtp(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { email } = req.body as { email?: string }
    if (!email) { fail(res, 'Email is required'); return }

    const code = String(Math.floor(100000 + Math.random() * 900000))
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000)

    await prisma.user.update({
      where: { id: userId },
      data: { emailOtpCode: code, emailOtpExpiresAt: expiresAt },
    })

    const delivered = await sendMail(
      String(email).trim(),
      'Your CC Ride verification code',
      `<p>Your verification code is <strong>${code}</strong>. It expires in 10 minutes.</p>`,
    ).catch(err => { console.error('sendMail:', err); return false })

    // No SMTP configured yet — return the code directly so the flow is
    // still testable end-to-end. Remove once SMTP_HOST is set in production.
    const devFallback = !delivered && process.env.NODE_ENV !== 'production'

    res.json({
      Result: 'true', ResponseCode: '200',
      ResponseMsg: delivered ? 'Verification code sent' : 'Verification code generated (email not configured)',
      ...(devFallback ? { OTP: code } : {}),
    })
  } catch (err) {
    console.error('legacyEmailOtp:', err); fail(res, 'Server error')
  }
}

export async function legacyVerifyEmail(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { otp } = req.body as { otp?: string }
    if (!otp) { fail(res, 'otp is required'); return }

    const user = await prisma.user.findUnique({ where: { id: userId } })
    if (!user?.emailOtpCode || !user.emailOtpExpiresAt) {
      fail(res, 'No verification code was requested'); return
    }
    if (user.emailOtpExpiresAt < new Date()) {
      fail(res, 'Verification code has expired'); return
    }
    if (String(otp).trim() !== user.emailOtpCode) {
      fail(res, 'Invalid verification code'); return
    }

    const updated = await prisma.user.update({
      where: { id: userId },
      data: { isEmailVerified: true, emailOtpCode: null, emailOtpExpiresAt: null },
    })

    res.json({
      Result: 'true', ResponseMsg: 'Email verified',
      UserLogin: userLoginShape(updated),
    })
  } catch (err) {
    console.error('legacyVerifyEmail:', err); fail(res, 'Server error')
  }
}

// ─── MOBILE VERIFICATION ────────────────────────────────────────────────────
// No SMS OTP provider is wired up in this build (same reason registration
// already sets isMobileVerified: true for new accounts — see legacyRegUser).
// This exists only to give legacy accounts created before that change an
// escape hatch: the mobile number is already the account's login credential,
// so there's nothing left to actually verify via SMS.
export async function legacyVerifyMobile(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const updated = await prisma.user.update({
      where: { id: userId },
      data: { isMobileVerified: true },
    })
    res.json({
      Result: 'true', ResponseMsg: 'Mobile verified',
      UserLogin: userLoginShape(updated),
    })
  } catch (err) {
    console.error('legacyVerifyMobile:', err); fail(res, 'Server error')
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
        is_email_verify:  user.isEmailVerified ? '1' : '0',
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
    const userId = req.user.id
    const { name, email, bio, dob } = req.body
    const file = (req as any).file as { filename?: string } | undefined
    const updateData: any = {}
    if (name)  updateData.name  = String(name).trim()
    if (email) {
      const normalized = String(email).trim().toLowerCase()
      const current = await prisma.user.findUnique({ where: { id: userId }, select: { email: true } })
      updateData.email = normalized
      // Changing the email invalidates any prior verification.
      if (normalized !== current?.email) updateData.isEmailVerified = false
    }
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
    const userId = req.user.id
    const file = (req as any).file as { filename?: string } | undefined
    if (!file?.filename) { fail(res, 'photo required'); return }
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
    const userId = req.user.id
    const { model_id, type_id, color_id, year, license_plate, seat_capacity } = req.body
    if (!model_id || !type_id || !color_id || !year || !license_plate) {
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
    const userId = req.user.id
    const { vehicle_id, model_id, type_id, color_id, year, license_plate, seat_capacity } = req.body
    if (!vehicle_id) { fail(res, 'vehicle_id required'); return }
    const existing = await prisma.vehicle.findUnique({ where: { id: BigInt(vehicle_id) } })
    if (!existing || existing.driverId !== userId) { fail(res, 'Vehicle not found'); return }
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

// ─── Fixed routes: lazy materialization ────────────────────────────────────
//
// A Route is only a template. This turns "which of a route's recurring
// schedules fall on this date" into ordinary Ride rows (tagged with routeId)
// the very first time anyone searches that date — idempotent, so repeat
// searches for the same (route, date) find the existing Ride instead of
// duplicating it. Everything downstream (booking, seats, stops) then just
// works against a normal Ride, no separate code path needed.
async function materializeRouteRidesForDate(tripDate: string) {
  const dayStart = new Date(tripDate + 'T00:00:00')
  const dayOfWeek = dayStart.getDay() // 0=Sun .. 6=Sat

  const schedules = await prisma.routeSchedule.findMany({
    where: { isActive: true, daysOfWeek: { has: dayOfWeek }, route: { isActive: true } },
    include: { route: { include: { stops: { orderBy: { stopOrder: 'asc' } } } } },
  })

  for (const schedule of schedules) {
    const [hh, mm] = schedule.departureTime.split(':').map(Number)
    const scheduledAt = new Date(dayStart)
    scheduledAt.setHours(hh, mm, 0, 0)

    const existing = await prisma.ride.findFirst({
      where: { routeId: schedule.routeId, scheduledAt },
    })
    if (existing) continue

    // A route schedule needs an assigned pool driver to generate real
    // bookable rides — skip silently if the org hasn't assigned one yet.
    if (!schedule.driverId) continue

    const route = schedule.route
    const ride = await prisma.ride.create({
      data: {
        driverId:           schedule.driverId,
        vehicleId:          schedule.vehicleId,
        routeId:            schedule.routeId,
        originAddress:      route.originName,
        originLat:          route.originLat,
        originLng:          route.originLng,
        destinationAddress: route.destinationName,
        destinationLat:     route.destinationLat,
        destinationLng:     route.destinationLng,
        scheduledAt,
        scheduleType:       'one_time',
        baseFare:           schedule.fare,
        availableSeats:     schedule.seatCapacity,
        status:             'pending',
        pickupOtp:          String(Math.floor(1000 + Math.random() * 9000)),
        dropoffOtp:         String(Math.floor(1000 + Math.random() * 9000)),
        bookPreference:     schedule.bookPreference,
      },
    })

    if (route.stops.length > 0) {
      await prisma.rideStop.createMany({
        data: route.stops.map(s => ({
          rideId:    ride.id,
          stopOrder: s.stopOrder,
          address:   s.name,
          lat:       s.lat,
          lng:       s.lng,
        })),
      })
    }
  }
}

// Mirrors materializeRouteRidesForDate's idempotent lazy-generation pattern,
// but for ad-hoc rides a driver posted as "Recurring" rather than fixed
// Route schedules. The originally-posted Ride (parentRideId null,
// scheduleType recurring_daily) is the template: on any search for a given
// date, generate today's occurrence at the same time-of-day if one doesn't
// already exist, tagged with parentRideId so "My Trips" can group the
// series and cancelling/editing later can target the whole series via the
// parent. Instances themselves are never treated as templates (parentRideId
// is only ever set on generated instances, never on further-generated rows).
async function materializeRecurringRidesForDate(tripDate: string) {
  const dayStart = new Date(tripDate + 'T00:00:00')

  const templates = await prisma.ride.findMany({
    where: { scheduleType: 'recurring_daily', parentRideId: null, status: { not: 'cancelled' } },
    include: { stops: { orderBy: { stopOrder: 'asc' } } },
  })

  for (const template of templates) {
    // Recurrence only makes sense from the template's own start date onward.
    if (dayStart < new Date(template.scheduledAt.toDateString())) continue

    const scheduledAt = new Date(dayStart)
    scheduledAt.setHours(
      template.scheduledAt.getHours(),
      template.scheduledAt.getMinutes(), 0, 0,
    )

    // The template's own date is the template row itself — nothing to generate.
    if (scheduledAt.getTime() === template.scheduledAt.getTime()) continue

    const existing = await prisma.ride.findFirst({
      where: { parentRideId: template.id, scheduledAt },
    })
    if (existing) continue

    const instance = await prisma.ride.create({
      data: {
        driverId:           template.driverId,
        vehicleId:          template.vehicleId,
        parentRideId:       template.id,
        originAddress:      template.originAddress,
        originLat:          template.originLat,
        originLng:          template.originLng,
        destinationAddress: template.destinationAddress,
        destinationLat:     template.destinationLat,
        destinationLng:     template.destinationLng,
        scheduledAt,
        scheduleType:       'recurring_daily',
        baseFare:           template.baseFare,
        availableSeats:     template.availableSeats,
        luggageAllowed:     template.luggageAllowed,
        restrictions:       template.restrictions,
        tripNotes:          template.tripNotes,
        pickupOtp:          String(Math.floor(1000 + Math.random() * 9000)),
        dropoffOtp:         String(Math.floor(1000 + Math.random() * 9000)),
        status:             'pending',
      },
    })

    if (template.stops.length > 0) {
      await prisma.rideStop.createMany({
        data: template.stops.map(s => ({
          rideId:    instance.id,
          stopOrder: s.stopOrder,
          address:   s.address,
          lat:       s.lat,
          lng:       s.lng,
        })),
      })
    }
  }
}

// A ride is a match for a passenger's desired trip if their pickup point
// lies near *some* point on the ride's path (its own origin, an intermediate
// stop, or its destination) and their drop-off point lies near a *later*
// point on that same path — not just an exact origin/destination match.
// This is what lets "close to their route or goes through their route" work
// for both ad-hoc rides (RideStop) and fixed routes (materialized with the
// same RideStop rows — see materializeRouteRidesForDate above).
const ROUTE_MATCH_RADIUS_KM = 5

function rideMatchesTrip(
  ride: {
    originLat: unknown; originLng: unknown
    destinationLat: unknown; destinationLng: unknown
    stops?: Array<{ lat: unknown; lng: unknown }>
  },
  wantOriginLat: number, wantOriginLng: number,
  wantDestLat: number, wantDestLng: number,
): boolean {
  const path = [
    { lat: Number(ride.originLat), lng: Number(ride.originLng) },
    ...(ride.stops ?? []).map(s => ({ lat: Number(s.lat), lng: Number(s.lng) })),
    { lat: Number(ride.destinationLat), lng: Number(ride.destinationLng) },
  ]

  const pickupIndex = path.findIndex(
    p => distanceKm(wantOriginLat, wantOriginLng, p.lat, p.lng) <= ROUTE_MATCH_RADIUS_KM,
  )
  if (pickupIndex === -1) return false

  for (let j = path.length - 1; j > pickupIndex; j--) {
    if (distanceKm(wantDestLat, wantDestLng, path[j].lat, path[j].lng) <= ROUTE_MATCH_RADIUS_KM) {
      return true
    }
  }
  return false
}

export async function legacyFindTrip(req: Request, res: Response) {
  try {
    // Guest browsing is allowed here (optionalAuth) — only trust an
    // authenticated identity for personalization (excluding your own trips,
    // auto-queueing a request under your name), never a client-supplied uid.
    const userId = req.user?.id ?? null
    const {
      origin_lat, origin_long, destination_lat, destination_long, trip_date, status,
      origin_address, destination_address,
    } = req.body

    if (trip_date) {
      await materializeRouteRidesForDate(trip_date)
      await materializeRecurringRidesForDate(trip_date)
    }

    const trips = await prisma.ride.findMany({
      where: {
        status: { in: ['pending', 'driver_assigned'] },
        scheduledAt: trip_date
          ? { gte: new Date(trip_date + 'T00:00:00'), lt: new Date(trip_date + 'T23:59:59') }
          : undefined,
        // Ad-hoc rides disappear once full; route-based departures stay
        // visible so passengers can still join the waitlist.
        OR: [{ availableSeats: { gt: 0 } }, { routeId: { not: null } }],
      },
      include: {
        driver: true,
        vehicle: { include: { model: true, type: true } },
        bookings: { where: { status: { in: ['confirmed', 'processing', 'in_progress'] } } },
        route: true,
        stops: true,
      },
      orderBy: { scheduledAt: 'asc' },
      take: 50,
    })

    // Only apply corridor matching when the search actually carries real
    // coordinates — guest/partial searches fall back to the unfiltered list.
    const originLatNum      = parseFloat(origin_lat)
    const originLngNum      = parseFloat(origin_long)
    const destinationLatNum = parseFloat(destination_lat)
    const destinationLngNum = parseFloat(destination_long)
    const hasCoords = [originLatNum, originLngNum, destinationLatNum, destinationLngNum].every(Number.isFinite)

    const tripData = trips
      .filter(t => t.driverId !== userId)
      .filter(t => !hasCoords || rideMatchesTrip(t, originLatNum, originLngNum, destinationLatNum, destinationLngNum))
      .map(t => ({
        trip_id:         t.id,
        total_seat:      String(t.availableSeats),
        remain_seat:     t.availableSeats,
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
        route_id:        t.routeId ?? '',
        route_code:      t.route?.code ?? '',
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

    // No trips (and no route match) for this search — queue it as a ride
    // request so nearby drivers can see it and accept/create a matching
    // route, instead of the passenger just hitting a dead end. Only for
    // authenticated searches with real coordinates, and de-duplicated so
    // repeated searches for the same trip don't spam multiple requests.
    let autoQueued = false
    if (tripData.length === 0 && userId && userId !== '0' && destination_lat && destination_long) {
      const queueOriginLat = Number.isFinite(originLatNum) ? originLatNum : 0
      const queueOriginLng = Number.isFinite(originLngNum) ? originLngNum : 0
      const queueDestLat = destinationLatNum
      const queueDestLng = destinationLngNum
      const departureDate = new Date(trip_date || new Date().toISOString().split('T')[0])

      const existing = await prisma.rideRequest.findFirst({
        where: {
          passengerId: userId,
          isActive: true,
          departureDate,
          destinationLat: { gte: queueDestLat - 0.01, lte: queueDestLat + 0.01 },
          destinationLng: { gte: queueDestLng - 0.01, lte: queueDestLng + 0.01 },
        },
      })

      if (!existing) {
        const request = await prisma.rideRequest.create({
          data: {
            passengerId:        userId,
            originAddress:      origin_address ? String(origin_address) : `${queueOriginLat}, ${queueOriginLng}`,
            originLat:          queueOriginLat,
            originLng:          queueOriginLng,
            destinationAddress: destination_address ? String(destination_address) : `${queueDestLat}, ${queueDestLng}`,
            destinationLat:     queueDestLat,
            destinationLng:     queueDestLng,
            departureDate,
            seatsRequired:      1,
            notes:              'Auto-queued — no matching route was available at search time',
            isActive:           true,
          },
        })
        notifyNearbyDriversOfRequest(request).catch(err => console.error('notifyNearbyDriversOfRequest:', err))
        autoQueued = true
      }
    }

    ok(res, {
      Data: { TripData: tripData, RequestData: requestData },
      auto_queued: autoQueued,
    })
  } catch (err) {
    console.error('legacyFindTrip:', err); fail(res, 'Server error')
  }
}

// ─── NEARBY ROUTES (home screen) ───────────────────────────────────────────────
// Lightweight "shared routes near you" list for the home screen — active
// fixed Routes whose origin is within range of the passenger's current
// location, each with its next upcoming departure (if any) and price.

const NEARBY_ROUTES_RADIUS_KM = 20

// Scans forward day-by-day (today first, only times still ahead of now) to
// find the true next weekly occurrence — replaces a previous fallback to
// `schedules[0]` (an arbitrary array-order pick) that could surface a
// departure time already passed today, or on the wrong day entirely.
function nextScheduleOccurrence<T extends { departureTime: string; daysOfWeek: number[] }>(schedules: T[], now: Date) {
  const startDayOfWeek = now.getDay()
  const nowMinutes = now.getHours() * 60 + now.getMinutes()
  for (let offset = 0; offset < 7; offset++) {
    const day = (startDayOfWeek + offset) % 7
    const dayCandidates = schedules
      .filter(s => s.daysOfWeek.includes(day))
      .sort((a, b) => a.departureTime.localeCompare(b.departureTime))
    const match = offset === 0
      ? dayCandidates.find(s => {
          const [hh, mm] = s.departureTime.split(':').map(Number)
          return hh * 60 + mm >= nowMinutes
        })
      : dayCandidates[0]
    if (match) {
      const [hh, mm] = match.departureTime.split(':').map(Number)
      const occurrenceDate = new Date(now)
      occurrenceDate.setDate(now.getDate() + offset)
      occurrenceDate.setHours(hh, mm, 0, 0)
      return { schedule: match, occurrenceDate }
    }
  }
  return null
}

export async function legacyNearbyRoutes(req: Request, res: Response) {
  try {
    const lat = parseFloat(String(req.body.lat ?? req.query.lat))
    const lng = parseFloat(String(req.body.lng ?? req.query.lng))
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) { fail(res, 'lat and lng required'); return }

    const routes = await prisma.route.findMany({
      where: { isActive: true },
      include: {
        schedules: { where: { isActive: true } },
      },
      take: 100,
    })

    const now = new Date()

    const withOccurrence = routes.map(r => {
      const distance = distanceKm(lat, lng, Number(r.originLat), Number(r.originLng))
      const occurrence = nextScheduleOccurrence(r.schedules, now)
      return {
        route: r, distance,
        next: occurrence?.schedule,
        occurrenceDate: occurrence?.occurrenceDate,
        isServiced: r.schedules.length > 0,
      }
    })

    // Batch-check seat availability for every resolved occurrence in one
    // query rather than one round-trip per route. No matching Ride row yet
    // means nobody has booked this occurrence — treat as fully available
    // (capacity equals the schedule's seatCapacity) rather than excluding it.
    const occurrencePairs = withOccurrence
      .filter(c => c.next && c.occurrenceDate)
      .map(c => ({ routeId: c.route.id, scheduledAt: c.occurrenceDate! }))

    const existingRides = occurrencePairs.length > 0
      ? await prisma.ride.findMany({
          where: { OR: occurrencePairs.map(p => ({ routeId: p.routeId, scheduledAt: p.scheduledAt })) },
          select: { routeId: true, scheduledAt: true, availableSeats: true },
        })
      : []
    const seatsByOccurrence = new Map(
      existingRides.map(r => [`${r.routeId}|${r.scheduledAt.toISOString()}`, r.availableSeats]),
    )

    const candidates = withOccurrence
      .filter(c => c.distance <= NEARBY_ROUTES_RADIUS_KM)
      // A fully-booked occurrence shouldn't appear as available — but an
      // unserviced route (no active schedule at all) is unaffected, it was
      // never subject to a seat count in the first place.
      .filter(c => {
        if (!c.next || !c.occurrenceDate) return true
        const seats = seatsByOccurrence.get(`${c.route.id}|${c.occurrenceDate.toISOString()}`)
        return seats == null || seats > 0
      })

    // Any driver may "adopt" a corridor by publishing their own Route copy
    // (see legacyCreateDriverRoute), so the same origin→destination pair can
    // exist as several distinct Route rows — one per driver who runs it.
    // Passengers only care about the corridor, not which driver's copy it
    // is, so collapse to one card per corridor here rather than showing the
    // same trip repeated in the list. Prefer a serviced route over an
    // unserviced one, and among serviced routes the one departing soonest.
    const byCorridor = new Map<string, typeof candidates[number]>()
    for (const c of candidates) {
      const key = `${c.route.originName.trim().toLowerCase()}→${c.route.destinationName.trim().toLowerCase()}`
      const existing = byCorridor.get(key)
      if (!existing) { byCorridor.set(key, c); continue }
      if (c.isServiced && !existing.isServiced) { byCorridor.set(key, c); continue }
      if (c.isServiced === existing.isServiced && c.isServiced) {
        const cTime = c.next?.departureTime ?? '99:99'
        const eTime = existing.next?.departureTime ?? '99:99'
        if (cTime < eTime) byCorridor.set(key, c)
      }
    }

    const nearby = Array.from(byCorridor.values())
      .sort((a, b) => a.distance - b.distance)
      .slice(0, 15)

    ok(res, {
      Data: nearby.map(({ route, distance, next, isServiced }) => ({
        route_id:         route.id,
        route_code:       route.code,
        route_name:       route.name,
        origin_name:      route.originName,
        origin_lat:       Number(route.originLat),
        origin_long:      Number(route.originLng),
        destination_name: route.destinationName,
        destination_lat:  Number(route.destinationLat),
        destination_long: Number(route.destinationLng),
        distance_km:      Number(distance.toFixed(1)),
        next_departure:   next?.departureTime ?? '',
        seat_price:       next ? String(Number(next.fare)) : '',
        // No active schedule means the driver who created this route
        // deactivated it — the route itself stays visible as a suggestion
        // (per design: a killed route "may be available as suggestion for
        // other drivers... but unserviced until a driver adopts it")
        // rather than disappearing outright.
        is_serviced:      isServiced,
      })),
    })
  } catch (err) {
    console.error('legacyNearbyRoutes:', err); fail(res, 'Server error')
  }
}

// ─── DRIVER-CREATED ROUTES ─────────────────────────────────────────────────────
// Lets any driver (pool or own-car) publish a named, recurring route so
// passengers can discover and book it under "Shared routes near you" — the
// same mechanism used for admin/corporate-seeded routes like DEMO101, just
// opened up to individual drivers. Each route belongs to the driver who
// created it; deactivating it removes it from their own list but leaves the
// Route itself visible to others as an unserviced suggestion (no active
// schedule) until some driver "adopts" it by publishing their own route
// copied from it — adoption creates an entirely new Route + RouteSchedule
// rather than reassigning the original, so each driver's list only ever
// reflects routes they personally created.

function genRouteCode(): string {
  return `RT-${Date.now().toString(36).toUpperCase()}-${Math.floor(Math.random() * 1000)}`
}

export async function legacyCreateDriverRoute(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const {
      origin_address, origin_lat, origin_long,
      desti_address, desti_lat, desti_long,
      departure_time, days_of_week, seat_capacity, fare,
      vehicle_id, route_name, book_preference,
    } = req.body

    if (!origin_address || !desti_address || !departure_time || !seat_capacity || !fare) {
      fail(res, 'Required fields missing'); return
    }
    const daysArr = Array.isArray(days_of_week)
      ? days_of_week.map((d: unknown) => parseInt(String(d))).filter(Number.isFinite)
      : []
    if (daysArr.length === 0) { fail(res, 'Select at least one day of the week'); return }
    const seatCount = parseInt(seat_capacity)
    const fareAmt = parseFloat(fare)
    if (!Number.isFinite(seatCount) || seatCount < 1) { fail(res, 'Invalid seat_capacity'); return }
    if (!Number.isFinite(fareAmt) || fareAmt < 0) { fail(res, 'Invalid fare'); return }

    let usingVehicleId: bigint | null = null
    if (vehicle_id) {
      const vehicle = await prisma.vehicle.findUnique({ where: { id: BigInt(vehicle_id) } })
      if (!vehicle) { fail(res, 'Vehicle not found'); return }
      const ownsIt = vehicle.driverId === userId
      const poolGrant = vehicle.companyId
        ? await prisma.driverVehicleAccess.findFirst({ where: { vehicleId: vehicle.id, driverId: userId, isActive: true } })
        : null
      if (!ownsIt && !poolGrant) { fail(res, 'You do not have access to this vehicle'); return }
      usingVehicleId = vehicle.id
    }

    const route = await prisma.route.create({
      data: {
        code:            genRouteCode(),
        name:            route_name ? String(route_name) : `${origin_address}`.split(',')[0] + ' → ' + `${desti_address}`.split(',')[0],
        companyId:       null,
        originName:      String(origin_address),
        originLat:       parseFloat(origin_lat),
        originLng:       parseFloat(origin_long),
        destinationName: String(desti_address),
        destinationLat:  parseFloat(desti_lat),
        destinationLng:  parseFloat(desti_long),
        isActive:        true,
        schedules: {
          create: {
            departureTime: String(departure_time),
            daysOfWeek:    daysArr,
            driverId:      userId,
            vehicleId:     usingVehicleId,
            seatCapacity:  seatCount,
            fare:          fareAmt,
            isActive:      true,
            bookPreference: book_preference === 'Manual' ? 'Manual' : 'Auto',
          },
        },
      },
      include: { schedules: true },
    })

    await prisma.user.update({ where: { id: userId }, data: { isDriver: true } })

    ok(res, {
      route_id:   route.id,
      route_code: route.code,
    })
  } catch (err) {
    console.error('legacyCreateDriverRoute:', err); fail(res, 'Server error')
  }
}

export async function legacyEditDriverRoute(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const {
      route_id,
      origin_address, origin_lat, origin_long,
      desti_address, desti_lat, desti_long,
      departure_time, days_of_week, seat_capacity, fare,
      vehicle_id, route_name, book_preference,
    } = req.body

    if (!route_id) { fail(res, 'route_id required'); return }

    const schedule = await prisma.routeSchedule.findFirst({
      where: { routeId: String(route_id), driverId: userId, isActive: true },
    })
    if (!schedule) { fail(res, 'Route not found or not yours'); return }

    if (!origin_address || !desti_address || !departure_time || !seat_capacity || !fare) {
      fail(res, 'Required fields missing'); return
    }
    const daysArr = Array.isArray(days_of_week)
      ? days_of_week.map((d: unknown) => parseInt(String(d))).filter(Number.isFinite)
      : []
    if (daysArr.length === 0) { fail(res, 'Select at least one day of the week'); return }
    const seatCount = parseInt(seat_capacity)
    const fareAmt = parseFloat(fare)
    if (!Number.isFinite(seatCount) || seatCount < 1) { fail(res, 'Invalid seat_capacity'); return }
    if (!Number.isFinite(fareAmt) || fareAmt < 0) { fail(res, 'Invalid fare'); return }

    let usingVehicleId: bigint | null = null
    if (vehicle_id) {
      const vehicle = await prisma.vehicle.findUnique({ where: { id: BigInt(vehicle_id) } })
      if (!vehicle) { fail(res, 'Vehicle not found'); return }
      const ownsIt = vehicle.driverId === userId
      const poolGrant = vehicle.companyId
        ? await prisma.driverVehicleAccess.findFirst({ where: { vehicleId: vehicle.id, driverId: userId, isActive: true } })
        : null
      if (!ownsIt && !poolGrant) { fail(res, 'You do not have access to this vehicle'); return }
      usingVehicleId = vehicle.id
    }

    await prisma.$transaction([
      prisma.route.update({
        where: { id: String(route_id) },
        data: {
          name:            route_name ? String(route_name) : undefined,
          originName:      String(origin_address),
          originLat:       parseFloat(origin_lat),
          originLng:       parseFloat(origin_long),
          destinationName: String(desti_address),
          destinationLat:  parseFloat(desti_lat),
          destinationLng:  parseFloat(desti_long),
        },
      }),
      prisma.routeSchedule.update({
        where: { id: schedule.id },
        data: {
          departureTime: String(departure_time),
          daysOfWeek:    daysArr,
          vehicleId:     usingVehicleId,
          seatCapacity:  seatCount,
          fare:          fareAmt,
          bookPreference: book_preference === 'Manual' ? 'Manual' : 'Auto',
        },
      }),
    ])

    ok(res, {})
  } catch (err) {
    console.error('legacyEditDriverRoute:', err); fail(res, 'Server error')
  }
}

export async function legacyMyDriverRoutes(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { mode } = req.body
    // Same pool-vs-own-car separation as legacyTripList — a route driven
    // with a company vehicle stays out of the own-car list and vice versa.
    const vehicleFilter = mode === 'pool'
      ? { vehicle: { companyId: { not: null } } }
      : mode === 'own_car'
      ? { OR: [{ vehicleId: null }, { vehicle: { companyId: null } }] }
      : {}
    const schedules = await prisma.routeSchedule.findMany({
      where: { driverId: userId, isActive: true, ...vehicleFilter },
      include: { route: true, vehicle: { include: { model: true } } },
    })

    ok(res, {
      Data: schedules.map(s => ({
        route_id:         s.route.id,
        route_code:       s.route.code,
        route_name:       s.route.name,
        origin_name:      s.route.originName,
        origin_lat:       Number(s.route.originLat),
        origin_long:      Number(s.route.originLng),
        destination_name: s.route.destinationName,
        destination_lat:  Number(s.route.destinationLat),
        destination_long: Number(s.route.destinationLng),
        departure_time:   s.departureTime,
        days_of_week:     s.daysOfWeek,
        seat_capacity:    s.seatCapacity,
        fare:             String(Number(s.fare)),
        vehicle_id:       s.vehicleId ? String(s.vehicleId) : '',
        vehicle_title:    s.vehicle?.model?.title ?? '',
        book_preference:  s.bookPreference,
      })),
    })
  } catch (err) {
    console.error('legacyMyDriverRoutes:', err); fail(res, 'Server error')
  }
}

export async function legacyDeactivateDriverRoute(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { route_id } = req.body
    if (!route_id) { fail(res, 'route_id required'); return }

    const schedule = await prisma.routeSchedule.findFirst({
      where: { routeId: String(route_id), driverId: userId, isActive: true },
    })
    if (!schedule) { fail(res, 'Route not found or not yours'); return }

    // Deactivates the driver's own schedule only — the Route row stays
    // active so it keeps surfacing via nearby_routes.php as an unserviced
    // suggestion for other drivers to adopt.
    await prisma.routeSchedule.update({
      where: { id: schedule.id },
      data: { isActive: false },
    })

    ok(res, {})
  } catch (err) {
    console.error('legacyDeactivateDriverRoute:', err); fail(res, 'Server error')
  }
}

// Surfaces open passenger ride requests near a prospective route's corridor
// so a driver can gauge demand before publishing — informational only, no
// route is auto-generated or modified from this.
export async function legacyNearbyRequestsForRoute(req: Request, res: Response) {
  try {
    const originLat = parseFloat(String(req.body.origin_lat))
    const originLong = parseFloat(String(req.body.origin_long))
    if (!Number.isFinite(originLat) || !Number.isFinite(originLong)) {
      fail(res, 'origin_lat and origin_long required'); return
    }

    const requests = await prisma.rideRequest.findMany({
      where: { isActive: true, departureDate: { gte: new Date(new Date().toDateString()) } },
      include: { passenger: true },
      take: 50,
    })

    const nearby = requests
      .filter(r => distanceKm(originLat, originLong, Number(r.originLat), Number(r.originLng)) <= NEARBY_ROUTES_RADIUS_KM)
      .slice(0, 10)

    ok(res, {
      Data: nearby.map(r => ({
        request_id:     r.id,
        from_address:   r.originAddress,
        to_address:     r.destinationAddress,
        departure_date: r.departureDate.toISOString().split('T')[0],
        seat_require:   String(r.seatsRequired),
        user_title:     r.passenger.name,
      })),
    })
  } catch (err) {
    console.error('legacyNearbyRequestsForRoute:', err); fail(res, 'Server error')
  }
}

// ─── ESTIMATE FARE ──────────────────────────────────────────────────────────
// Always available regardless of pricing_model — the estimate itself is
// harmless to compute either way. What differs by mode is how the CLIENT
// should treat the number: authoritative "expected fare" for the passenger
// when platform_computed is active, or just an FYI suggestion alongside
// the driver's own price when driver_set is active. That decision is left
// to pricing_model in the response, not baked into whether this returns
// anything.

export async function legacyEstimateFare(req: Request, res: Response) {
  try {
    const { origin_lat, origin_long, desti_lat, desti_long, estimated_duration_min, vehicle_id } = req.body
    const oLat = parseFloat(origin_lat), oLng = parseFloat(origin_long)
    const dLat = parseFloat(desti_lat), dLng = parseFloat(desti_long)
    if (![oLat, oLng, dLat, dLng].every(Number.isFinite)) {
      fail(res, 'origin_lat, origin_long, desti_lat and desti_long are required'); return
    }

    const distance = distanceKm(oLat, oLng, dLat, dLng)
    const duration = estimated_duration_min != null ? parseFloat(estimated_duration_min) : undefined

    const estimate = await estimateFare({
      distanceKm: distance,
      durationMin: Number.isFinite(duration) ? duration : undefined,
      vehicleId: vehicle_id ? BigInt(vehicle_id) : null,
    })

    ok(res, {
      estimated_fare: estimate.estimatedFare,
      pricing_model:  estimate.pricingModel,
      distance_km:    Math.round(distance * 10) / 10,
      base_fare:      estimate.factorsUsed.baseFare,
      fare_per_km:    estimate.factorsUsed.farePerKm,
      fare_per_min:   estimate.factorsUsed.farePerMin,
    })
  } catch (err) {
    console.error('legacyEstimateFare:', err); fail(res, 'Server error')
  }
}

// ─── POST TRIP ────────────────────────────────────────────────────────────────

export async function legacyPostTrip(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const {
      origin_address, origin_lat, origin_long,
      desti_address, desti_lat, desti_long,
      trip_start_date, trip_start_time, total_seat, seat_price,
      vehicle_id, skip_vehicle, ride_schedule, trip_description,
      request_id, stopdata, book_preference,
    } = req.body

    if (!origin_address || !desti_address || !trip_start_date || !total_seat || !seat_price) {
      fail(res, 'Required fields missing'); return
    }
    const seatCount = parseInt(total_seat)
    const fare = parseFloat(seat_price)
    if (!Number.isFinite(seatCount) || seatCount < 1) { fail(res, 'Invalid total_seat'); return }
    if (!Number.isFinite(fare) || fare < 0) { fail(res, 'Invalid seat_price'); return }

    // Employees of a participating organisation may only drive using either
    // a pool vehicle they've been granted access to, or their own vehicle
    // once the org has approved it — never an arbitrary vehicle, and never
    // no vehicle at all (skip_vehicle) once they're bound by an org.
    const usingVehicleId = (vehicle_id && vehicle_id !== '' && skip_vehicle !== '1')
      ? BigInt(vehicle_id) : null

    const membership = await prisma.companyEmployee.findFirst({
      where: { userId, isActive: true },
    })
    if (membership) {
      if (!usingVehicleId) {
        fail(res, 'Select a vehicle to drive with — pool car or your approved personal vehicle'); return
      }
      const vehicle = await prisma.vehicle.findUnique({ where: { id: usingVehicleId } })
      if (!vehicle) { fail(res, 'Vehicle not found'); return }

      if (vehicle.companyId) {
        const grant = await prisma.driverVehicleAccess.findFirst({
          where: { vehicleId: usingVehicleId, driverId: userId, isActive: true },
        })
        if (!grant) { fail(res, 'You do not have access to this pool vehicle'); return }
      } else {
        if (vehicle.driverId !== userId) { fail(res, 'This vehicle does not belong to you'); return }
        if (!membership.personalVehicleApproved) {
          fail(res, 'Your organisation has not approved your personal vehicle yet'); return
        }
      }
    }

    // Mark user as driver
    await prisma.user.update({ where: { id: userId }, data: { isDriver: true } })

    const scheduledAt = new Date(`${trip_start_date}T${trip_start_time || '08:00'}:00`)

    const ride = await prisma.ride.create({
      data: {
        driverId:           userId,
        vehicleId:          usingVehicleId,
        originAddress:      String(origin_address),
        originLat:          parseFloat(origin_lat || '6.4550'),
        originLng:          parseFloat(origin_long || '3.3841'),
        destinationAddress: String(desti_address),
        destinationLat:     parseFloat(desti_lat || '6.5'),
        destinationLng:     parseFloat(desti_long || '3.4'),
        scheduledAt,
        // Flutter sends "recurring" (see ride_schedule_screen_view.dart),
        // not "recurring_daily" — this previously never matched, so every
        // trip silently saved as one_time regardless of driver's choice.
        scheduleType:       ride_schedule === 'recurring' ? 'recurring_daily' : 'one_time',
        baseFare:           fare,
        availableSeats:     seatCount,
        tripNotes:          trip_description ?? null,
        pickupOtp:          String(Math.floor(1000 + Math.random() * 9000)),
        dropoffOtp:         String(Math.floor(1000 + Math.random() * 9000)),
        status:             'pending',
        bookPreference:     book_preference === 'Manual' ? 'Manual' : 'Auto',
      },
    })

    // Persist any intermediate stops the driver added while composing the
    // route on the map screen — these previously vanished silently since the
    // handler never read stopdata from the request at all.
    if (Array.isArray(stopdata) && stopdata.length > 0) {
      await prisma.rideStop.createMany({
        data: stopdata.map((s: any, i: number) => ({
          rideId:    ride.id,
          stopOrder: i,
          address:   String(s.stop_address ?? ''),
          lat:       parseFloat(s.stop_lat ?? '0'),
          lng:       parseFloat(s.stop_long ?? '0'),
        })),
      })
    }

    // Driver is committing to a route/trip that matches a specific passenger
    // request — link it to this ride and let the passenger know, but don't
    // close the request out yet. It stays open until the passenger
    // explicitly confirms (see legacyConfirmMatchedRequest, which proceeds
    // to the normal book/pay flow) or declines (legacyDeclineMatchedRequest,
    // which kills the request) — a driver merely posting a matching trip
    // isn't the same as the passenger actually being booked on it.
    if (request_id && request_id !== '0') {
      const request = await prisma.rideRequest.findUnique({ where: { id: String(request_id) } })
      if (request && request.isActive) {
        await prisma.rideRequest.update({ where: { id: request.id }, data: { matchedRideId: ride.id } })
        notifyPassengerOfMatch(request, ride.id).catch(err => console.error('notifyPassengerOfMatch:', err))
      }
    }

    // The real ride id (a UUID) — trip_preview_screen_view.dart navigates
    // straight here after posting, using this value as tripId. It previously
    // sent a lossy numeric hash of the UUID instead, so the driver's own
    // just-posted trip could never actually be loaded afterwards.
    ok(res, { parent_trip_ids: [ride.id] })
  } catch (err) {
    console.error('legacyPostTrip:', err); fail(res, 'Server error')
  }
}

// ─── MY TRIP LIST ─────────────────────────────────────────────────────────────

export async function legacyTripList(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { trip_type, mode } = req.body

    let statusFilter: any = { in: ['pending', 'driver_assigned', 'driver_en_route', 'in_progress'] }
    if (trip_type === 'Recent' || trip_type === 'Completed') statusFilter = { in: ['completed'] }
    if (trip_type === 'Cancelled') statusFilter = { in: ['cancelled'] }

    // A driver who does both pool (company vehicle) and own-car trips would
    // otherwise see them all mixed together in one feed — keep them
    // separate per the mode the app is currently in (see DriverModeController
    // on the client). A ride's vehicle.companyId is the same signal already
    // used to route earnings to cash vs. points (see legacyBookSeat).
    const vehicleFilter = mode === 'pool'
      ? { vehicle: { companyId: { not: null } } }
      : mode === 'own_car'
      ? { OR: [{ vehicleId: null }, { vehicle: { companyId: null } }] }
      : {}

    const rides = await prisma.ride.findMany({
      where: { driverId: userId, status: statusFilter, ...vehicleFilter },
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
      is_recurring:    r.scheduleType === 'recurring_daily',
      parent_trip_id:  r.parentRideId ?? '',
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
        // 'pending' must be included — those are the just-booked seats a
        // driver hasn't approved/rejected yet. Excluding them meant a
        // passenger who booked a Manual-preference ride never showed up
        // anywhere in the driver's seating plan, so there was nothing to
        // approve and the booking sat pending forever.
        bookings: {
          where: { status: { in: ['pending', 'confirmed', 'processing', 'in_progress', 'completed'] } },
          include: { passenger: true },
        },
        stops: { orderBy: { stopOrder: 'asc' } },
        route: true,
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
        route_id:        ride.routeId ?? '',
        route_code:      ride.route?.code ?? '',
        user_profile:    picUrl(ride.driver.profilePicUrl),
        user_title:      ride.driver.name,
        user_id:         ride.driverId,
        user_mobile:     ride.driver.mobile,
        user_bio:        ride.driver.bio ?? '',
        user_dob:        ride.driver.dateOfBirth ? ride.driver.dateOfBirth.toISOString().split('T')[0] : '',
        user_joined:     ride.driver.createdAt.toISOString().split('T')[0],
        vehicle_title:   ride.vehicle ? ride.vehicle.model?.title ?? '' : '',
        vehicle_image:   ride.vehicle ? picUrl(ride.vehicle.photoUrl) : '',
        license_plate:   ride.vehicle?.licensePlate ?? '',
        year:            ride.vehicle ? String(ride.vehicle.year) : '',
        vehicle_color:   ride.vehicle?.color?.title ?? '',
        vehicle_type:    ride.vehicle?.type?.title ?? '',
        stops_details:   ride.stops.map(s => ({
          location: s.address,
          lat:      Number(s.lat),
          long:     Number(s.lng),
        })),
        restri_details:  ride.restrictions,
        luggage_details: ride.luggageAllowed,
        backrow_details: '',
        booked_seat:     bookedSeats,
        remain_seat:     ride.availableSeats,
        booked_users:    ride.bookings.map(b => bookedUserPayload(b, ride)),
      },
    })
  } catch (err) {
    console.error('legacyTripDetails:', err); fail(res, 'Server error')
  }
}

// ─── BOOK SEAT ────────────────────────────────────────────────────────────────

async function awardPoolPoints(driverId: string, bookingId: string) {
  const settings = await prisma.platformSettings.findUnique({ where: { id: 1 } })
  const pointsToAward = settings?.pointsPerTrip ?? 10
  const profile = await prisma.driverProfile.upsert({
    where:  { userId: driverId },
    update: { pointsBalance: { increment: pointsToAward } },
    create: {
      userId:        driverId,
      licenseNumber: '',
      licenseExpiry: new Date('2100-01-01'),
      pointsBalance: pointsToAward,
    },
  })
  await prisma.driverPointsTransaction.create({
    data: {
      driverId,
      bookingId,
      points:       pointsToAward,
      balanceAfter: profile.pointsBalance,
      description:  'Pool vehicle trip completed',
    },
  })
}

export async function legacyBookSeat(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { trip_id, seat, wallet_amount, coupon_code, transaction_id } = req.body
    if (!trip_id) { fail(res, 'trip_id required'); return }

    const ride = await prisma.ride.findUnique({ where: { id: String(trip_id) } })
    if (!ride) { fail(res, 'Trip not found'); return }

    const seatsToBook = parseInt(seat ?? '1') || 1
    if (ride.availableSeats < seatsToBook) {
      // Waitlisting only makes sense for a scheduled route ride (more seats
      // may free up if someone cancels, and the org runs this route again
      // tomorrow) — an ad-hoc ride that's full just stays full.
      if (ride.routeId) {
        await prisma.rideWaitlist.create({
          data: { rideId: ride.id, userId, seatsRequested: seatsToBook },
        })
        res.json({ Result: 'true', ResponseMsg: 'Joined waitlist', waitlisted: true })
        return
      }
      fail(res, 'Not enough available seats'); return
    }

    // Pool-vehicle eligibility must be checked before any payment is
    // captured below — rejecting after charging the passenger would be a
    // much worse failure mode than one extra lightweight lookup here.
    if (ride.vehicleId) {
      const vehicle = await prisma.vehicle.findUnique({ where: { id: ride.vehicleId }, select: { companyId: true, branchId: true } })
      if (vehicle?.companyId) {
        const eligibility = await checkPoolRideEligibility({
          passengerUserId: userId,
          poolCompanyId: vehicle.companyId,
          poolBranchId: vehicle.branchId != null ? vehicle.branchId.toString() : null,
        })
        if (!eligibility.allowed) { fail(res, eligibility.reason ?? 'You are not eligible to book this pool vehicle'); return }
      }
    }

    const subtotal = Number(ride.baseFare) * seatsToBook
    const [passenger, settings] = await Promise.all([
      prisma.user.findUnique({ where: { id: userId }, select: { walletBalance: true } }),
      prisma.platformSettings.findUnique({ where: { id: 1 } }),
    ])
    const walletAvailable = Number(passenger?.walletBalance ?? 0)

    // Coupon — validated and computed server-side, never trusted from the
    // client's cou_amt display value (that field is display-only now).
    // Reduces the ride fare before the booking fee and wallet are applied.
    // An invalid/expired/already-used coupon is silently dropped rather than
    // failing the whole booking — the passenger just doesn't get the discount.
    let appliedCoupon: { id: bigint } | null = null
    let couponDiscount = 0
    if (coupon_code) {
      const coupon = await prisma.coupon.findFirst({
        where: { code: String(coupon_code).toUpperCase(), isActive: true, expiresAt: { gt: new Date() } },
      })
      if (coupon && subtotal >= Number(coupon.minAmount) &&
          (coupon.maxUses == null || coupon.usesCount < coupon.maxUses)) {
        const alreadyUsed = await prisma.couponRedemption.findUnique({
          where: { couponId_userId: { couponId: coupon.id, userId } },
        })
        if (!alreadyUsed) {
          const rawDiscount = coupon.isPercentage
            ? subtotal * (Number(coupon.discountValue) / 100)
            : Number(coupon.discountValue)
          couponDiscount = Math.min(rawDiscount, subtotal)
          appliedCoupon = { id: coupon.id }
        }
      }
    }
    const discountedSubtotal = subtotal - couponDiscount

    // The flat platform booking fee — previously computed and shown to the
    // passenger client-side but never actually charged or recorded server
    // side at all, so it silently vanished between the UI and the ledger.
    const bookingFeeAmount = Number(settings?.bookingFee ?? 0)
    const grossDue = discountedSubtotal + bookingFeeAmount
    // Never trust the client's claimed wallet_amount beyond what they can
    // actually cover — previously this could push a balance negative by
    // simply claiming a larger wallet_amount than the account actually held.
    const walletUsed = Math.min(parseFloat(wallet_amount ?? '0') || 0, grossDue, walletAvailable)
    const total = grossDue - walletUsed
    // Wallet is applied to the (discounted) ride fare first, so driver
    // payout reflects the actual ride value regardless of how the booking
    // fee portion was covered — the booking fee itself is always platform
    // revenue.
    const rideNet = discountedSubtotal - Math.min(walletUsed, discountedSubtotal)

    // The client only reaches this call after its own WebView watches for a
    // gateway success redirect (see PaymentScreenController.webViewPaymentMethod)
    // — that's a client-side check and forgeable. Anyone with a valid session
    // token could otherwise call this endpoint directly with a fabricated
    // transaction_id and get a ride confirmed, seats decremented, and driver
    // earnings credited without ever paying the non-wallet remainder. Require
    // and independently verify the gateway charge here instead of trusting
    // the client's word for it — mirrors what /payment/verify already does
    // for the newer booking-payment flow.
    let confirmedGateway: 'paystack' | 'flutterwave' = 'paystack'
    if (total > 0.01) {
      if (!transaction_id) { fail(res, 'Payment was not completed'); return }
      const ref = String(transaction_id)
      let verifiedAmountNaira: number | null = null

      try {
        const result = await paystackVerify(ref)
        if (result.status === 'success') {
          verifiedAmountNaira = result.amount / 100
          confirmedGateway = 'paystack'
        }
      } catch { /* not a Paystack reference — fall through to Flutterwave */ }

      if (verifiedAmountNaira == null) {
        try {
          const numericId = Number(ref)
          const result = Number.isFinite(numericId) && String(numericId) === ref
            ? await flwVerifyById(numericId)
            : await flwVerifyByRef(ref)
          if (result.status === 'successful') {
            verifiedAmountNaira = result.amount
            confirmedGateway = 'flutterwave'
          }
        } catch { /* not a valid Flutterwave transaction either */ }
      }

      if (verifiedAmountNaira == null || verifiedAmountNaira < total - 1) {
        fail(res, 'Could not verify payment for this booking'); return
      }
    }

    // "Manual" rides (see legacyPostTrip/book_preference) sit as a pending
    // booking until the driver confirms or declines via
    // legacyConfirmBookingRequest/legacyDeclineBookingRequest — seat isn't
    // reserved and pool points aren't awarded until that happens. Payment is
    // still captured up front either way; a decline triggers a wallet refund.
    const isManual = ride.bookPreference === 'Manual'

    // Commission/driver-earning split resolved via the pricing engine
    // (super-admin configurable PricingRateCard layers + Company.commissionRate,
    // falling back to PlatformSettings.platformCommission) rather than a
    // hardcoded 85/15. Pool-vehicle detection (companyId set — driver earns
    // organisation points instead of cash) is resolved internally from
    // ride.vehicleId, so there's no separate vehicle fetch here.
    const { driverEarning, platformCommission, isPoolRide } = await computeFareSplit({
      subtotal: rideNet,
      bookingFeeAmount,
      vehicleId: ride.vehicleId,
      companyId: null, // personal-app booking — no sponsoring company for rate-card scope
    })

    const booking = await prisma.booking.create({
      data: {
        rideId:            ride.id,
        passengerId:       userId,
        driverId:          ride.driverId,
        seatsBooked:       seatsToBook,
        subtotal,
        couponDiscount:    couponDiscount,
        bookingFee:        bookingFeeAmount,
        totalAmount:       total,
        walletAmountUsed:  walletUsed,
        driverEarning,
        platformCommission,
        paymentGateway:    confirmedGateway,
        paymentStatus:     'successful',
        bookingMethod:     'instant',
        status:            isManual ? 'pending' : 'confirmed',
        confirmedAt:       isManual ? null : new Date(),
      },
    })

    if (appliedCoupon) {
      await prisma.$transaction([
        prisma.couponRedemption.create({
          data: { couponId: appliedCoupon.id, userId, bookingId: booking.id },
        }),
        prisma.coupon.update({
          where: { id: appliedCoupon.id },
          data: { usesCount: { increment: 1 } },
        }),
      ])
    }

    if (!isManual) {
      if (isPoolRide) await awardPoolPoints(ride.driverId, booking.id)

      // Decrement seats — deferred until confirmation for manual rides.
      await prisma.ride.update({
        where: { id: ride.id },
        data: { availableSeats: { decrement: seatsToBook } },
      })
    }

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

    ok(res, { book_id: booking.id, status: booking.status })
  } catch (err) {
    console.error('legacyBookSeat:', err); fail(res, 'Server error')
  }
}

// ─── MANUAL BOOKING APPROVAL ────────────────────────────────────────────────
// Only reachable for bookings on a "Manual" book_preference ride (see
// legacyPostTrip/legacyBookSeat) — those sit as status='pending' until the
// driver acts here. Auto-confirm bookings never reach 'pending' at all.

export async function legacyConfirmBookingRequest(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { booking_id } = req.body
    if (!booking_id) { fail(res, 'booking_id required'); return }

    const booking = await prisma.booking.findFirst({
      where: { id: String(booking_id), driverId: userId, status: 'pending' },
      include: { ride: { include: { vehicle: true } } },
    })
    if (!booking) { fail(res, 'Pending request not found'); return }

    if (booking.ride.availableSeats < booking.seatsBooked) {
      fail(res, 'Not enough seats left to confirm this request'); return
    }

    await prisma.$transaction([
      prisma.booking.update({
        where: { id: booking.id },
        data: { status: 'confirmed', confirmedAt: new Date() },
      }),
      prisma.ride.update({
        where: { id: booking.rideId },
        data: { availableSeats: { decrement: booking.seatsBooked } },
      }),
    ])

    if (booking.ride.vehicle?.companyId) {
      await awardPoolPoints(userId, booking.id)
    }

    ok(res, {})
  } catch (err) {
    console.error('legacyConfirmBookingRequest:', err); fail(res, 'Server error')
  }
}

export async function legacyDeclineBookingRequest(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { booking_id, reason } = req.body
    if (!booking_id) { fail(res, 'booking_id required'); return }

    const booking = await prisma.booking.findFirst({
      where: { id: String(booking_id), driverId: userId, status: 'pending' },
    })
    if (!booking) { fail(res, 'Pending request not found'); return }

    // Payment was captured up front when the request was made (see
    // legacyBookSeat) — refund the full amount to the passenger's wallet
    // since a decline means the ride never happens for them.
    await prisma.$transaction(async tx => {
      await tx.booking.update({
        where: { id: booking.id },
        data: {
          status: 'cancelled',
          cancelledAt: new Date(),
          cancellationReason: reason ? String(reason) : 'Declined by driver',
        },
      })
      const refundAmount = Number(booking.totalAmount)
      if (refundAmount > 0) {
        const passenger = await tx.user.update({
          where: { id: booking.passengerId },
          data: { walletBalance: { increment: refundAmount } },
        })
        await tx.walletTransaction.create({
          data: {
            userId: booking.passengerId,
            bookingId: booking.id,
            amount: refundAmount,
            balanceAfter: Number(passenger.walletBalance),
            description: 'Refund — booking request declined by driver',
          },
        })
      }
    })

    ok(res, {})
  } catch (err) {
    console.error('legacyDeclineBookingRequest:', err); fail(res, 'Server error')
  }
}

// Powers the per-route "requests" screen — Pending/Confirmed/Declined tabs
// for all bookings against rides materialized from this driver's route.
export async function legacyRouteBookingRequests(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { route_id } = req.body
    if (!route_id) { fail(res, 'route_id required'); return }

    const bookings = await prisma.booking.findMany({
      where: {
        driverId: userId,
        ride: { routeId: String(route_id) },
      },
      include: {
        passenger: true,
        pickupStop: true,
        dropoffStop: true,
        ride: true,
      },
      orderBy: { createdAt: 'desc' },
      take: 100,
    })

    const toItem = (b: typeof bookings[number]) => ({
      booking_id:     b.id,
      passenger_name: b.passenger.name,
      passenger_pic:  picUrl(b.passenger.profilePicUrl),
      pickup_address: b.pickupStop?.name ?? b.ride.originAddress,
      dropoff_address: b.dropoffStop?.name ?? b.ride.destinationAddress,
      seats_booked:   b.seatsBooked,
      created_at:     b.createdAt.toISOString(),
      status:         b.status,
    })

    ok(res, {
      Pending:   bookings.filter(b => b.status === 'pending').map(toItem),
      Confirmed: bookings.filter(b => b.status === 'confirmed').map(toItem),
      Declined:  bookings.filter(b => b.status === 'cancelled').map(toItem),
    })
  } catch (err) {
    console.error('legacyRouteBookingRequests:', err); fail(res, 'Server error')
  }
}

// ─── MY BOOKED TRIPS ─────────────────────────────────────────────────────────

// "current" = still active/upcoming; "past" = resolved one way or another.
// The client has always sent this distinction, but it was silently ignored
// server-side — both tabs got the same unfiltered list.
const CURRENT_STATUSES = ['pending', 'confirmed', 'processing', 'in_progress'] as const
const PAST_STATUSES = ['completed', 'cancelled', 'no_show'] as const

// A RideRequest that never got a driver (or got matched but the passenger
// never confirmed) never becomes a Booking row — so it was previously
// invisible in "my bookings" forever, with no trace the user ever tried.
// These synthetic statuses feed into the same current/past split above.
const REQUEST_CURRENT_STATUSES = ['searching', 'matched'] as const
const REQUEST_PAST_STATUSES = ['expired'] as const

export async function legacyMyBookTripList(req: Request, res: Response) {
  try {
    const userId = uid(req)
    if (!userId) { fail(res, 'uid required'); return }
    const { status } = req.body as { status?: string }

    const [bookings, requests] = await Promise.all([
      prisma.booking.findMany({
        where: {
          passengerId: userId,
          ...(status === 'current' ? { status: { in: [...CURRENT_STATUSES] } } : {}),
          ...(status === 'past' ? { status: { in: [...PAST_STATUSES] } } : {}),
        },
        include: {
          ride: {
            include: {
              driver: true,
              vehicle: { include: { model: true, type: true } },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: 10,
      }),
      prisma.rideRequest.findMany({
        where: { passengerId: userId },
        orderBy: { createdAt: 'desc' },
        take: 10,
      }),
    ])

    const bookedRideIds = new Set(bookings.map((b) => b.rideId))

    const bookingRows = bookings.map(b => ({
      occurred_at:     b.createdAt,
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
      status:          b.status as string,
      vehicle: {
        vehicle_title: b.ride.vehicle ? b.ride.vehicle.model?.title ?? '' : '',
        vehicle_image: b.ride.vehicle ? picUrl(b.ride.vehicle.photoUrl) : '',
        vehicle_type:  b.ride.vehicle ? b.ride.vehicle.type?.title ?? '' : '',
      },
    }))

    // Exclude requests that already converted into one of the bookings
    // above — that ride already has its own row, showing both would just
    // duplicate the same trip in the list.
    const requestRows = requests
      .filter((r) => !(r.matchedRideId && bookedRideIds.has(r.matchedRideId)))
      .map((r) => {
        const requestStatus = !r.isActive ? 'expired' : r.matchedRideId ? 'matched' : 'searching'
        return {
          occurred_at:     r.createdAt,
          trip_id:         r.matchedRideId ?? r.id,
          owner_id:        '',
          total_seat:      String(r.seatsRequired),
          seat_price:      '0',
          origin_address:  r.originAddress,
          origin_lat:      Number(r.originLat),
          origin_long:     Number(r.originLng),
          desti_address:   r.destinationAddress,
          desti_lat:       Number(r.destinationLat),
          desti_long:      Number(r.destinationLng),
          trip_start_date: r.departureDate.toISOString().split('T')[0],
          // A ride request has a target date but no confirmed time slot yet
          // (that only exists once a real Ride is posted/matched) — '00:00'
          // rather than '' so `"$date $time"` stays a value every client-side
          // DateTime.parse can actually parse, instead of silently breaking
          // on whichever screen assumes trip_start_time is never empty.
          trip_start_time: '00:00',
          trip_is_return:  '0', instant_approve: 1,
          total_rate:      0, total_driven: 0,
          user_profile:    '',
          user_title:      '',
          status:          requestStatus,
          vehicle: { vehicle_title: '', vehicle_image: '', vehicle_type: '' },
        }
      })
      .filter((r) => {
        if (status === 'current') return (REQUEST_CURRENT_STATUSES as readonly string[]).includes(r.status)
        if (status === 'past') return (REQUEST_PAST_STATUSES as readonly string[]).includes(r.status)
        return true
      })

    const tripData = [...bookingRows, ...requestRows]
      .sort((a, b) => b.occurred_at.getTime() - a.occurred_at.getTime())
      .slice(0, 10)
      .map(({ occurred_at, ...row }) => row)

    ok(res, { TripData: tripData })
  } catch (err) {
    console.error('legacyMyBookTripList:', err); fail(res, 'Server error')
  }
}

// ─── BOOK TRIP DETAILS ───────────────────────────────────────────────────────

export async function legacyBookTripDetails(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { trip_id } = req.body
    if (!trip_id) { fail(res, 'trip_id required'); return }

    const booking = await prisma.booking.findFirst({
      where: { rideId: String(trip_id), passengerId: userId },
      include: {
        ride: {
          include: {
            driver: true,
            vehicle: { include: { model: true, type: true, color: true } },
            bookings: { where: { status: { in: ['pending', 'confirmed', 'processing', 'in_progress', 'completed'] } }, include: { passenger: true } },
            stops: { orderBy: { stopOrder: 'asc' } },
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
        stops_details: ride.stops.map(s => ({
          location: s.address,
          lat:      Number(s.lat),
          long:     Number(s.lng),
        })),
        restri_details: ride.restrictions,
        luggage_details: ride.luggageAllowed, backrow_details: '',
        booked_seat: bookedSeats,
        remain_seat: ride.availableSeats,
        booked_users: ride.bookings.map(b => bookedUserPayload(b, ride)),
      },
    })
  } catch (err) {
    console.error('legacyBookTripDetails:', err); fail(res, 'Server error')
  }
}

// ─── CANCEL TRIP ─────────────────────────────────────────────────────────────

export async function legacyCancelTrip(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { trip_id } = req.body
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
    const userId = req.user.id
    const { trip_id } = req.body
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
      // Previously no date bound at all — a request for a departure date
      // long past stayed visible to every driver indefinitely, since
      // isActive is only ever cleared by an explicit confirm/decline.
      where: { isActive: true, departureDate: { gte: new Date(new Date().toDateString()) } },
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

// Powers the driver's seating-plan Approve/Reject/"Mark No Show" buttons
// (see SeatingPlanScreenController.makeDecisionApi) with { is_approve,
// book_id, book_uid }. This previously only handled a request_id field that
// this call site never sends at all, so tapping Approve/Reject silently did
// nothing server-side — the booking stayed 'pending' forever, seats were
// never decremented, and a pool driver's points were never awarded (compare
// legacyConfirmBookingRequest/legacyDeclineBookingRequest, which this
// mirrors for the non-route booking flow).
export async function legacyMakeDecision(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { request_id, is_approve, book_id } = req.body

    // Older ride-request decision path — kept for compatibility, though no
    // current client call site sends request_id here (see
    // legacyConfirmMatchedRequest/legacyDeclineMatchedRequest instead).
    if (request_id) {
      await prisma.rideRequest.updateMany({
        where: { id: String(request_id), passengerId: userId },
        data: { isActive: false },
      })
      ok(res, { message: 'Request updated' })
      return
    }

    if (!book_id) { fail(res, 'book_id required'); return }

    const booking = await prisma.booking.findFirst({
      where: { id: String(book_id), driverId: userId },
      include: { ride: { include: { vehicle: true } } },
    })
    if (!booking) { fail(res, 'Booking not found'); return }

    if (String(is_approve) === '1') {
      if (booking.status !== 'pending') { fail(res, 'This booking is no longer pending'); return }
      if (booking.ride.availableSeats < booking.seatsBooked) {
        fail(res, 'Not enough seats left to confirm this request'); return
      }

      await prisma.$transaction([
        prisma.booking.update({
          where: { id: booking.id },
          data: { status: 'confirmed', confirmedAt: new Date() },
        }),
        prisma.ride.update({
          where: { id: booking.rideId },
          data: { availableSeats: { decrement: booking.seatsBooked } },
        }),
      ])

      if (booking.ride.vehicle?.companyId) {
        await awardPoolPoints(userId, booking.id)
      }

      ok(res, { message: 'Booking approved' })
      return
    }

    // is_approve === '2' — either declining a still-pending request (full
    // refund, seat never reserved) or marking an already-confirmed booking
    // as a no-show once the trip is underway (no refund — the driver
    // showed up and waited).
    if (booking.status === 'pending') {
      await prisma.$transaction(async tx => {
        await tx.booking.update({
          where: { id: booking.id },
          data: {
            status: 'cancelled',
            cancelledAt: new Date(),
            cancellationReason: 'Declined by driver',
          },
        })
        const refundAmount = Number(booking.totalAmount)
        if (refundAmount > 0) {
          const passenger = await tx.user.update({
            where: { id: booking.passengerId },
            data: { walletBalance: { increment: refundAmount } },
          })
          await tx.walletTransaction.create({
            data: {
              userId: booking.passengerId,
              bookingId: booking.id,
              amount: refundAmount,
              balanceAfter: Number(passenger.walletBalance),
              description: 'Refund — booking request declined by driver',
            },
          })
        }
      })
      ok(res, { message: 'Booking declined' })
      return
    }

    if (['confirmed', 'processing', 'in_progress'].includes(booking.status)) {
      await prisma.booking.update({
        where: { id: booking.id },
        data: { status: 'no_show', cancelledAt: new Date(), cancellationReason: 'Marked no-show by driver' },
      })
      ok(res, { message: 'Marked as no-show' })
      return
    }

    fail(res, 'This booking cannot be updated')
  } catch (err) {
    console.error('legacyMakeDecision:', err); fail(res, 'Server error')
  }
}

// ─── TRIP REQUEST (passenger posts a request) ────────────────────────────────

export async function legacyTripRequest(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const {
      from_address, from_lat, from_long,
      to_address, to_lat, to_long,
      departure_date, seat_require, trip_description,
    } = req.body
    if (!from_address || !to_address) { fail(res, 'Required fields missing'); return }

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
    notifyNearbyDriversOfRequest(request).catch(err => console.error('notifyNearbyDriversOfRequest:', err))
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
      include: {
        passenger: true,
        matchedRide: { include: { driver: true, vehicle: { include: { model: true } } } },
      },
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
        // A driver has committed a trip against this request — the app
        // should show a Confirm/Decline card rather than leaving it as a
        // plain pending request (see legacyConfirmMatchedRequest/
        // legacyDeclineMatchedRequest).
        matched_trip_id:   r.matchedRideId,
        matched_driver_name: r.matchedRide?.driver.name ?? '',
        matched_vehicle_title: r.matchedRide?.vehicle?.model?.title ?? '',
        matched_seat_price: r.matchedRide ? String(Number(r.matchedRide.baseFare)) : '',
        matched_start_date: r.matchedRide?.scheduledAt.toISOString().split('T')[0] ?? '',
        matched_start_time: r.matchedRide?.scheduledAt.toTimeString().slice(0, 5) ?? '',
      })),
    })
  } catch (err) {
    console.error('legacyTripRequestList:', err); fail(res, 'Server error')
  }
}

// Passenger confirms a driver-matched request — resolves the request and
// hands back the matched ride so the client can proceed to the normal
// book/pay flow (legacyBookSeat) for it. Confirming here doesn't itself
// create a Booking — the passenger still picks seats/pays exactly as they
// would from a normal search result, just pre-navigated to this ride.
export async function legacyConfirmMatchedRequest(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { request_id } = req.body
    if (!request_id) { fail(res, 'request_id required'); return }

    const request = await prisma.rideRequest.findFirst({
      where: { id: String(request_id), passengerId: userId, isActive: true },
    })
    if (!request) { fail(res, 'Request not found'); return }
    if (!request.matchedRideId) { fail(res, 'This request has not been matched to a trip yet'); return }

    await prisma.rideRequest.update({
      where: { id: request.id },
      data: { isActive: false },
    })

    ok(res, { trip_id: request.matchedRideId })
  } catch (err) {
    console.error('legacyConfirmMatchedRequest:', err); fail(res, 'Server error')
  }
}

// Passenger declines a driver-matched request — kills the request outright
// (not returned to the open pool) since the passenger has explicitly said
// they no longer want it, distinct from it simply expiring unanswered.
export async function legacyDeclineMatchedRequest(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { request_id } = req.body
    if (!request_id) { fail(res, 'request_id required'); return }

    const request = await prisma.rideRequest.findFirst({
      where: { id: String(request_id), passengerId: userId, isActive: true },
    })
    if (!request) { fail(res, 'Request not found'); return }

    await prisma.rideRequest.update({
      where: { id: request.id },
      data: { isActive: false, matchedRideId: null },
    })

    ok(res, {})
  } catch (err) {
    console.error('legacyDeclineMatchedRequest:', err); fail(res, 'Server error')
  }
}

export async function legacyDeleteTripRequest(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { request_id } = req.body
    if (!request_id) { fail(res, 'request_id required'); return }
    await prisma.rideRequest.deleteMany({ where: { id: String(request_id), passengerId: userId } })
    ok(res, {})
  } catch (err) {
    console.error('legacyDeleteTripRequest:', err); fail(res, 'Server error')
  }
}

export async function legacyEditTripRequest(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { request_id, departure_date, seat_require, trip_description } = req.body
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

// Wallet top-ups are only credited against a Paystack reference that's been
// independently verified server-side — never against a client-declared
// amount. `payment_id` must be the Paystack transaction reference returned
// by legacyPaystackInit; the credited amount comes from Paystack's own
// verify response, not whatever the client claims. This is the only gateway
// with a real backend integration in this build (see legacyPaystackInit/
// legacyPaystackCallback above) — Razorpay/Stripe/Flutterwave/etc call sites
// in the Flutter app have no matching backend verification and will now
// correctly fail here rather than silently crediting an unverified amount.
export async function legacyWalletUp(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { payment_id: reference } = req.body
    if (!reference) { fail(res, 'payment_id (Paystack reference) required'); return }

    // Idempotent: WalletTransaction.reference is unique, so a retried/replayed
    // call with the same reference fails the create below rather than
    // double-crediting. Check up front too, for a clean error message.
    const existing = await prisma.walletTransaction.findUnique({ where: { reference: String(reference) } })
    if (existing) { fail(res, 'This payment has already been credited'); return }

    const settings = await prisma.platformSettings.findUnique({ where: { id: 1 } })
    let result
    try {
      result = await paystackVerify(String(reference), settings?.paystackSecretKey || undefined)
    } catch (err) {
      console.error('legacyWalletUp verify:', err)
      fail(res, 'Could not verify this payment reference'); return
    }
    if (result.status !== 'success') { fail(res, 'Payment was not successful'); return }

    const amt = result.amount / 100 // kobo -> naira, from Paystack's verified record

    const user = await prisma.user.update({
      where: { id: userId },
      data: { walletBalance: { increment: amt } },
    })
    await prisma.walletTransaction.create({
      data: {
        userId, amount: amt, balanceAfter: Number(user.walletBalance),
        description: 'Wallet top-up',
        reference: String(reference),
      },
    })
    ok(res, { wallet_balance: Number(user.walletBalance) })
  } catch (err: any) {
    if (err.code === 'P2002') { fail(res, 'This payment has already been credited'); return }
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
    const userId = req.user.id
    const { email, amount } = req.body
    if (!email || !amount) { fail(res, 'email and amount required'); return }

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
    const { mode } = req.body

    // Same pool-vs-own-car separation as legacyTripList/legacyMyDriverRoutes
    // — otherwise a driver who does both sees one blended earnings feed
    // (cash and points bookings mixed in the same "past trips" list).
    const rideVehicleFilter = mode === 'pool'
      ? { ride: { vehicle: { companyId: { not: null } } } }
      : mode === 'own_car'
      ? { ride: { OR: [{ vehicleId: null }, { vehicle: { companyId: null } }] } }
      : {}

    const [completedBookings, cancelledCount, pendingCount, settings, paidPayouts] = await Promise.all([
      prisma.booking.findMany({
        where: { driverId: userId, status: 'completed', ...rideVehicleFilter },
        include: { ride: true },
        orderBy: { completedAt: 'desc' },
        take: 50,
      }),
      prisma.booking.count({ where: { driverId: userId, status: 'cancelled', ...rideVehicleFilter } }),
      prisma.booking.count({ where: { driverId: userId, status: 'pending', ...rideVehicleFilter } }),
      prisma.platformSettings.findUnique({ where: { id: 1 } }),
      // Payouts are cash-only, so they never apply to pool activity — an
      // own-car filter still shows them; a pool filter shows none.
      mode === 'pool'
        ? Promise.resolve({ _sum: { amount: null } })
        : prisma.payoutRequest.aggregate({
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
    const userId = req.user.id
    const { amt, r_type, acc_number, bank_name, acc_name } = req.body
    if (!amt) { fail(res, 'amt required'); return }

    const amount = parseFloat(amt)
    if (!Number.isFinite(amount) || amount <= 0) { fail(res, 'Invalid amount'); return }

    // Only bank transfer is wired up to a real payout rail (Paystack/Flutterwave
    // transfers) in this market — UPI/PayPal are template leftovers from a
    // different market and aren't backed by any actual transfer integration.
    if (r_type !== 'BANK Transfer') {
      fail(res, `${r_type ?? 'This payout method'} is not available yet — use Bank Transfer.`)
      return
    }
    if (!acc_number || !bank_name || !acc_name) {
      fail(res, 'Bank name, account number and account name are required'); return
    }

    const bankAccount = await prisma.driverBankAccount.upsert({
      where: { driverId_accountNumber: { driverId: userId, accountNumber: acc_number } },
      update: { bankName: bank_name, accountName: acc_name },
      create: {
        driverId: userId, bankName: bank_name,
        accountNumber: acc_number, accountName: acc_name,
      },
    })

    await prisma.payoutRequest.create({
      data: {
        driverId: userId, bankAccountId: bankAccount.id,
        amount, method: 'paystack', status: 'pending',
      },
    })

    ok(res, { message: 'Withdrawal request submitted successfully.' })
  } catch (err) {
    console.error('legacyRequestWithdraw:', err); fail(res, 'Server error')
  }
}

export async function legacyPayoutList(req: Request, res: Response) {
  try {
    const userId = uid(req)
    if (!userId) { fail(res, 'uid required'); return }

    const payouts = await prisma.payoutRequest.findMany({
      where: { driverId: userId },
      include: { bankAccount: true },
      orderBy: { requestedAt: 'desc' },
      take: 50,
    })

    ok(res, {
      Payoutlist: payouts.map(p => ({
        payout_id:   p.id,
        amt:         Number(p.amount).toString(),
        status:      p.status,
        proof:       null,
        r_date:      p.requestedAt.toISOString(),
        r_type:      'BANK Transfer',
        acc_number:  p.bankAccount?.accountNumber ?? '',
        bank_name:   p.bankAccount?.bankName ?? '',
        acc_name:    p.bankAccount?.accountName ?? '',
        ifsc_code:   '',
        upi_id:      '',
        paypal_id:   '',
      })),
    })
  } catch (err) {
    console.error('legacyPayoutList:', err); fail(res, 'Server error')
  }
}

// ─── CONTENT ─────────────────────────────────────────────────────────────────

const FAQ_SEED_DATA = [
  // ── Getting started ──────────────────────────────────────────────────────
  { question: 'How does CC Ride work?',
    answer: 'CC Ride connects corporate employees with drivers for scheduled and on-demand rides. Book through the app, track your trip in real time, and pay seamlessly through your wallet or card — no cash needed.' },
  { question: 'Do I need to be part of a company to use CC Ride?',
    answer: 'No. CC Ride works for independent passengers and drivers too. If your employer participates, you\'ll also see corporate features like a company badge on your profile and, for drivers, access to pool vehicles.' },
  { question: 'How do I switch between passenger and driver mode?',
    answer: 'CC Ride asks how you\'re using the app each time you open it. You can also switch mid-session from your Profile — pick Passenger, Own-car driver, or (if your organisation has granted you pool access) Pool driver.' },

  // ── Booking as a passenger ───────────────────────────────────────────────
  { question: 'How do I book a ride as a passenger?',
    answer: 'Tap "Book a Ride" on the home screen, enter your destination, then choose a date/time on the trip-planning screen. You\'ll see both individual driver trips and shared routes that match — tap one and confirm to book your seat.' },
  { question: 'What\'s the difference between a one-time trip and a shared route?',
    answer: 'A one-time (or recurring) trip is a single journey a driver posts for a specific date. A shared route is a fixed corridor a driver publishes (e.g. an every-weekday commute) that stays bookable on a recurring schedule until they deactivate it — another driver can also adopt the same corridor if the first one stops running it.' },
  { question: 'I posted a ride request as a passenger — how will I know when a driver can take it?',
    answer: 'You\'ll get an in-app notification as soon as a driver posts a trip that matches your request. You can also check the Requests tab at any time to see if it\'s been picked up.' },
  { question: 'What if no driver has a trip that matches my search?',
    answer: 'Post a ride request instead — enter your pickup, destination and date, and nearby drivers are notified. Any driver who later posts a matching trip (or reviews open requests while creating one) can pick it up directly.' },
  { question: 'Why do I sometimes see a "confirm/decline" step after booking, instead of an instant confirmation?',
    answer: 'Some drivers set their route or trip to require manual approval rather than auto-confirming every booking. In that case your booking sits as pending until the driver reviews and confirms it — you\'re notified either way, and if they decline, any payment you made is refunded to your wallet automatically.' },
  { question: 'Can I book more than one seat?',
    answer: 'Yes — select the number of seats you need when booking, up to the seats the driver has marked available. The fare shown updates to reflect the total for all seats.' },
  { question: 'What happens if the driver cancels my trip?',
    answer: 'You\'ll be notified immediately and any payment already taken is refunded to your wallet. You can then search again for another matching trip or route.' },

  // ── Posting as a driver ──────────────────────────────────────────────────
  { question: 'How do I post a trip as a driver?',
    answer: 'Switch to driving mode from the home screen, tap "Post a Ride", set your route on the map, then fill in date, time, available seats and price per seat. Passengers searching that route will be able to find and book it.' },
  { question: 'How do I create or manage my driver routes?',
    answer: 'From the driver home screen, tap "My Routes" to see routes you\'ve published, or the "+" button to publish a new one — set your origin, destination, days of the week and departure time. Tap the pencil icon on an existing route to edit its details, or the trash icon to deactivate it.' },
  { question: 'What happens when I deactivate a route?',
    answer: 'It\'s removed from your own "My Routes" list, but the route itself stays visible to other drivers as a suggestion — nearby passengers will see it marked "unserviced" until another driver adopts and republishes it.' },
  { question: 'What does "Manually approve requests" mean when creating a route?',
    answer: 'It\'s off by default, meaning bookings on that route confirm instantly like normal. Turning it on means every booking sits as a pending request you review yourself — open the route from My Routes to see Pending, Confirmed and Declined tabs, and confirm or decline each one.' },
  { question: 'As a driver, how do I see and pick up passenger ride requests?',
    answer: 'Open the Trip Requests list from your driver tab to see nearby passenger requests. Tap one to review it, then invite the passenger to join a trip you\'re posting — completing that post automatically closes out their request and notifies them.' },
  { question: 'How do pool drivers get paid, versus own-car drivers?',
    answer: 'Own-car drivers earn cash directly per trip, paid out to a linked bank account from the Wallet screen. Pool drivers (using a company-owned vehicle) earn points/credit tracked through your organisation instead of direct cash — check your Earnings screen, which keeps pool and own-car activity in separate totals if you drive both.' },
  { question: 'I drive both a pool vehicle and my own car — will my trips and earnings get mixed up?',
    answer: 'No. My Rides, My Routes and Earnings all filter by whichever mode you\'re currently in, so pool activity and own-car activity are always kept separate rather than shown in one blended list.' },
  { question: 'How do I add or verify my vehicle?',
    answer: 'Go to Profile → My Vehicles → Add Vehicle, fill in your vehicle details and submit for approval. If you\'re part of an organisation, your personal vehicle also needs to be approved by them before you can drive with it — pool vehicles are assigned to you directly by your organisation.' },

  // ── Verification & safety ────────────────────────────────────────────────
  { question: 'How do I verify my phone number or email?',
    answer: 'Go to Profile → Personal Details and tap "Verify" next to your phone or email. Enter the code you receive to complete verification — this unlocks posting trips as a driver.' },
  { question: 'Is CC Ride safe?',
    answer: 'Yes. All drivers are verified, trips are tracked in real time with pickup/drop-off confirmation codes, and both driver and passenger ratings after every trip help ensure accountability.' },
  { question: 'How does the pickup/drop-off confirmation code work?',
    answer: 'Every trip generates a short numeric code for pickup and another for drop-off. Share the pickup code with your driver when you get in, and the drop-off code when you arrive — this confirms the right passenger got in and out at the right time.' },
  { question: 'How do ratings work?',
    answer: 'After a completed trip, passengers and drivers can rate each other and leave a short review. Your average rating and total trips are shown on your public profile.' },

  // ── Payments & wallet ────────────────────────────────────────────────────
  { question: 'What payment methods are accepted?',
    answer: 'We accept Paystack and Flutterwave for card payments, plus your in-app wallet balance — you can split a booking between wallet funds and a card charge for the remainder.' },
  { question: 'How do I top up my wallet?',
    answer: 'Go to Wallet → Top-up, enter an amount, and complete payment via Paystack. Your balance updates as soon as the payment is verified.' },
  { question: 'How do I withdraw my driver earnings?',
    answer: 'From the Earnings screen, tap Request Withdrawal once your cash balance is above the minimum payout threshold, and add or select a linked bank account. Payouts are processed by our team and reflected in your Payout History.' },
  { question: 'Do I get charged a booking fee?',
    answer: 'A small flat platform booking fee applies to each booking, shown clearly before you confirm — it\'s separate from the ride fare itself and goes toward keeping the platform running.' },
  { question: 'How do coupon codes work?',
    answer: 'Enter a valid coupon code at checkout to apply a discount to your ride fare, shown immediately in the price breakdown before you pay. Each coupon can only be used once per account and may have a minimum fare or expiry date.' },
  { question: 'How does the Refer & Earn program work?',
    answer: 'Share your referral code from the Refer screen. When a new user signs up with your code and completes their first ride, you both receive a bonus credited to your wallet.' },

  // ── Managing bookings & trips ────────────────────────────────────────────
  { question: 'How do I cancel a booking or trip?',
    answer: 'Open the trip from My Bookings (passenger) or My Rides (driver) and tap Cancel. Cancellation policies and any applicable fees are shown before you confirm.' },
  { question: 'Where can I see my past and upcoming trips?',
    answer: 'Passengers: My Bookings, split into Current and Past. Drivers: My Rides, split into Active, Completed and Cancelled tabs.' },
  { question: 'How do notifications work?',
    answer: 'You\'ll get an in-app notification (and a push alert, where enabled) for things like a driver matching your ride request, a booking being confirmed or declined, or a trip status change — check the bell icon on the home screen at any time.' },

  // ── Account & settings ───────────────────────────────────────────────────
  { question: 'How do I change my app language?',
    answer: 'Go to Profile → Language and pick from the supported languages — the whole app updates immediately, no restart needed.' },
  { question: 'How do I delete my account?',
    answer: 'Go to Profile → Close your account, confirm the prompt, and your account will be permanently deleted along with associated personal data, subject to any records we\'re required to retain.' },
  { question: 'Who do I contact if I have an issue with a ride?',
    answer: 'Use the Help & FAQ chat/support option in-app, or report the trip directly from its details screen — our support team reviews every report.' },

  // ── Identity verification (NIN / passport) ───────────────────────────────
  { question: 'Why is my National ID (NIN) or passport number being requested?',
    answer: 'It\'s how we confirm you\'re a real, single, verifiable person — the same anchor is used to prevent duplicate accounts and, for drivers and corporate employees, is a required part of onboarding. An ordinary passenger account can be created without it.' },
  { question: 'I\'m Nigerian — do I use NIN or passport?',
    answer: 'Use your NIN. Passport number is only for non-Nigerian applicants, and you only ever provide one or the other, never both.' },
  { question: 'Is it required for every account?',
    answer: 'No. Ordinary passengers can register and ride without providing either. It becomes mandatory the moment you register as a driver (own-car or pool) or as a corporate employee, since both come with organisation-level trust and access.' },
  { question: 'What if I already have an account with a different phone number or email than what my employer has on file?',
    answer: 'That\'s expected and handled automatically — your NIN or passport is what links a new corporate registration back to your existing personal account, not your email or phone. You\'ll keep your existing ride history, wallet balance and rating either way.' },

  // ── Corporate accounts & participating organisations ─────────────────────
  { question: 'What does it mean for my employer to be a "participating organisation"?',
    answer: 'It means your company has an account with CC Ride and can sponsor rides for its staff — through a company-owned pool vehicle fleet, wallet-funded ride payments, or both, depending on what your company admin has enabled.' },
  { question: 'How do I get added as an employee of my company\'s CC Ride account?',
    answer: 'Your company admin registers you — either one at a time or via a bulk CSV import for larger teams. You\'ll receive an email at your work address with a link to activate your account and set a password.' },
  { question: 'I got an activation email at my work email — will it create a separate account from the one I already use personally?',
    answer: 'No. If the NIN/passport, personal email or mobile number your employer registered you with matches your existing account, you\'re linked to that same account — the activation link just adds your employer\'s access on top, it never duplicates you.' },
  { question: 'What happens if I leave my company or am terminated as an employee?',
    answer: 'Your company admin can terminate your employment record at any time, which immediately removes every corporate privilege — pool-car access, company-wallet payment, budget spending — from your account. Your personal CC Ride account, wallet balance, ride history and rating are completely unaffected; only your ties to that specific company are removed.' },
  { question: 'Can I be an employee of more than one participating organisation at once?',
    answer: 'Yes. There\'s no limit on how many organisations can add you as an employee — each grants you separate, independent access (a pool car from one company doesn\'t give you access to another\'s), so having multiple affiliations never crosses wires between them.' },

  // ── Company pool cars & wallet payment ────────────────────────────────────
  { question: 'Can I use my company\'s pool cars as a passenger?',
    answer: 'Only if your company admin has switched on pool-car access for your account specifically — it\'s off by default for every employee. If it\'s off, you can ask your admin to enable it, or send a request for access directly from the app, which they can approve or decline.' },
  { question: 'My company enabled pool access for me — can I use it any time?',
    answer: 'Only if your admin left it unrestricted. They can also limit it to specific days of the week and hours (e.g. weekday mornings only), and cap how many pool rides you\'re allowed per day, week or month — outside those limits, booking a pool ride is blocked with a clear reason shown.' },
  { question: 'Can my company\'s pool cars be used by people from a different organisation?',
    answer: 'Only if your company has explicitly opted in to share its fleet with that specific partner organisation — by default a company\'s pool vehicles serve only its own employees. Sharing is never automatic just because two organisations are both on CC Ride.' },
  { question: 'What does "pay with company wallet" mean, and how do I get access?',
    answer: 'It lets a ride be charged directly to your employer\'s CC Ride balance instead of your personal wallet or card. Like pool access, it\'s off by default per employee, can be time-windowed by your admin, and you can request it directly from the app if it\'s not already turned on for you.' },
  { question: 'Can I top up or add money to my company\'s wallet myself?',
    answer: 'No — crediting a company\'s wallet balance is reserved for CC Ride\'s platform team, the same way it works for your own personal wallet top-ups going through a verified payment provider. No employee or company admin can add funds directly; every credit is logged with who authorised it and when.' },

  // ── For company admins ────────────────────────────────────────────────────
  { question: 'How do I register employees in bulk instead of one at a time?',
    answer: 'From the company console\'s Employees section, download the CSV template, fill in one row per employee (name, work email, mobile, and either NIN or passport number are required), and upload it — you\'ll get a per-row result showing exactly who was created, who was linked to an existing account, and any rows that need fixing.' },
  { question: 'Can I see how much my organisation is saving by using CC Ride?',
    answer: 'Yes — the console\'s savings reports compare what your organisation actually spent against an independently-sourced market benchmark (not CC Ride\'s own pricing), broken down by period, department and individual employee.' },
  { question: 'Can I change my company\'s commission rate or credit my own wallet as an admin?',
    answer: 'No — both are reserved for CC Ride\'s platform team by design, so a company\'s own admin can never unilaterally grant itself better terms or manufacture wallet balance. A company admin\'s console access is scoped to managing their own employees, fleet, and policies, not platform-level financial settings.' },
]

export async function legacyFaq(req: Request, res: Response) {
  try {
    let faqs = await prisma.faq.findMany({ where: { isActive: true }, orderBy: { sortOrder: 'asc' }, take: 50 })
    if (faqs.length === 0) {
      faqs = await prisma.faq.createManyAndReturn({
        data: FAQ_SEED_DATA.map((f, i) => ({ ...f, sortOrder: i })),
      })
    }
    const settings = await prisma.platformSettings.findUnique({ where: { id: 1 } })
    ok(res, {
      FaqData: faqs.map(f => ({
        id: String(f.id), question: f.question, answer: f.answer, status: '1',
      })),
      currency:    settings?.currencySymbol ?? '₦',
      // The Flutter FaqListApiModel declares booking_fee as a String — this
      // was previously a raw JSON number, which threw a TypeError the
      // instant faqListApiModelFromJson() tried to assign it, caught
      // silently by the calling method's try/catch (it only logs, never
      // shows an error), so the whole FAQ list stayed permanently empty no
      // matter what content existed on the backend.
      booking_fee: String(Number(settings?.bookingFee ?? 100)),
    })
  } catch (err) {
    console.error('legacyFaq:', err); fail(res, 'Server error')
  }
}

// POST /admin/faqs/reseed — super-admin only. legacyFaq above only seeds
// once, the first time the table is ever empty, so editing FAQ_SEED_DATA in
// this file has no effect on an already-seeded production database. This
// wipes and reseeds from the current constant, which is the only way to
// actually push updated FAQ content until a full FAQ CRUD admin UI exists.
export async function reseedFaqs(_req: Request, res: Response) {
  try {
    await prisma.$transaction([
      prisma.faq.deleteMany({}),
      prisma.faq.createMany({ data: FAQ_SEED_DATA.map((f, i) => ({ ...f, sortOrder: i })) }),
    ])
    ok(res, { count: FAQ_SEED_DATA.length, message: 'FAQs reseeded' })
  } catch (err) {
    console.error('reseedFaqs:', err); fail(res, 'Server error')
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
    const { coupon_code } = req.body
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
    const userId = req.user.id
    const {
      trip_id, origin_address, origin_lat, origin_long,
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
    const userId = req.user.id
    const { trip_id } = req.body
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
    const userId = req.user.id
    const { trip_id } = req.body
    if (!trip_id) { fail(res, 'trip_id required'); return }
    const ride = await prisma.ride.findUnique({ where: { id: String(trip_id) } })
    // Captured once and reused below as the savings-record rideDate, rather
    // than each call minting its own `new Date()` (which previously meant
    // `ride.completedAt` — read from the pre-update `ride` above — was
    // always null, so the savings record silently fell back to whatever
    // moment the background pass happened to run).
    const completedAt = new Date()
    await prisma.ride.updateMany({
      where: { id: String(trip_id), driverId: userId },
      data: { status: 'completed', completedAt },
    })
    await prisma.booking.updateMany({
      where: { rideId: String(trip_id), status: 'in_progress' },
      data: { status: 'completed', completedAt },
    })
    ok(res, {})

    // Fair pricing must always be advised to the passenger up front, but a
    // corporate booking still needs its cost computed backend-side at
    // completion — purely for reports/analytics showing the participating
    // organisation what CC Ride is saving it. Never affects what was
    // actually charged. Response is already sent above, so any failure here
    // is logged only — it must never reach the outer catch and attempt to
    // send a second response.
    try {
      if (ride) {
        const corporateBookings = await prisma.booking.findMany({
          where: { rideId: String(trip_id), status: 'completed', companyId: { not: null } },
        })
        if (corporateBookings.length > 0) {
          // Same ride for every booking in this loop — fetch the vehicle's
          // type once rather than re-querying it per co-passenger.
          const vehicleTypeId = ride.vehicleId
            ? (await prisma.vehicle.findUnique({ where: { id: ride.vehicleId }, select: { typeId: true } }))?.typeId ?? null
            : null

          for (const booking of corporateBookings) {
            if (!booking.companyId) continue
            try {
              const [pointsAwarded, employee] = await Promise.all([
                prisma.driverPointsTransaction.aggregate({
                  where: { bookingId: booking.id },
                  _sum: { points: true },
                }),
                prisma.companyEmployee.findUnique({
                  where: { companyId_userId: { companyId: booking.companyId, userId: booking.passengerId } },
                  select: { id: true },
                }),
              ])
              await recordRideSavings({
                bookingId: booking.id,
                companyId: booking.companyId,
                employeeId: employee?.id ?? null,
                computedFairFare: dec(booking.subtotal),
                actualOrgCost: dec(booking.totalAmount),
                driverPointsAwarded: pointsAwarded._sum.points ?? 0,
                distanceKm: ride.estimatedDistanceKm != null ? dec(ride.estimatedDistanceKm) : null,
                durationMinutes: ride.estimatedDurationMin ?? null,
                vehicleTypeId,
                rideDate: completedAt,
              })
            } catch (err) {
              console.error('legacyCompleteTrip: recordRideSavings failed for booking', booking.id, err)
            }
          }
        }
      }
    } catch (err) {
      console.error('legacyCompleteTrip: post-completion savings recording failed:', err)
    }
  } catch (err) {
    console.error('legacyCompleteTrip:', err); fail(res, 'Server error')
  }
}

export async function legacyRateUpdate(req: Request, res: Response) {
  try {
    const userId = req.user.id
    const { trip_id, total_rate, rate_desc } = req.body
    if (!trip_id || !total_rate) { fail(res, 'Required fields missing'); return }
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

// ─── NOTIFICATIONS ────────────────────────────────────────────────────────────

export async function legacyNotificationList(req: Request, res: Response) {
  try {
    const userId = uid(req)
    if (!userId) { fail(res, 'uid required'); return }

    const notifications = await prisma.notification.findMany({
      where: { userId },
      orderBy: { sentAt: 'desc' },
      take: 50,
    })

    ok(res, {
      Data: notifications.map(n => ({
        notification_id: String(n.id),
        type:             n.type,
        title:            n.title,
        body:             n.body,
        data:             n.data ?? {},
        is_read:          n.isRead,
        sent_at:          n.sentAt.toISOString(),
      })),
      unread_count: notifications.filter(n => !n.isRead).length,
    })
  } catch (err) {
    console.error('legacyNotificationList:', err); fail(res, 'Server error')
  }
}

export async function legacyNotificationRead(req: Request, res: Response) {
  try {
    const userId = uid(req)
    const { notification_id } = req.body
    if (!userId) { fail(res, 'uid required'); return }

    if (notification_id) {
      await prisma.notification.updateMany({
        where: { id: BigInt(notification_id), userId },
        data: { isRead: true, readAt: new Date() },
      })
    } else {
      await prisma.notification.updateMany({
        where: { userId, isRead: false },
        data: { isRead: true, readAt: new Date() },
      })
    }
    ok(res, {})
  } catch (err) {
    console.error('legacyNotificationRead:', err); fail(res, 'Server error')
  }
}

// A user can only ever delete their own notifications — scoped by userId in
// the where clause rather than trusting notification_id alone, same as every
// other user-owned-resource endpoint in this file.
export async function legacyNotificationDelete(req: Request, res: Response) {
  try {
    const userId = uid(req)
    const { notification_id } = req.body
    if (!userId) { fail(res, 'uid required'); return }

    if (notification_id) {
      await prisma.notification.deleteMany({ where: { id: BigInt(notification_id), userId } })
    } else {
      // No notification_id = "clear all", matching the same convention
      // legacyNotificationRead already uses for "mark all read".
      await prisma.notification.deleteMany({ where: { userId } })
    }
    ok(res, {})
  } catch (err) {
    console.error('legacyNotificationDelete:', err); fail(res, 'Server error')
  }
}

// ─── FALLBACK ─────────────────────────────────────────────────────────────────

export function legacyFallback(_req: Request, res: Response) {
  res.json({ Result: 'false', ResponseCode: '400', ResponseMsg: 'Endpoint not available in this build' })
}
