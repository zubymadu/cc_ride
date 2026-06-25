import { Request, Response } from 'express'
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'
import { z } from 'zod'
import { prisma } from '../lib/prisma'
import { ok, fail, serverError } from '../lib/response'

const RegisterSchema = z.object({
  name:      z.string().min(2),
  mobile:    z.string().min(10),
  password:  z.string().min(6),
  email:     z.string().email().optional(),
  is_driver: z.boolean().default(false),
  country_code: z.string().default('+234'),
})

const LoginSchema = z.object({
  mobile:   z.string().min(10),
  password: z.string().min(1),
  country_code: z.string().default('+234'),
})

export async function register(req: Request, res: Response) {
  try {
    const data = RegisterSchema.parse(req.body)

    const existing = await prisma.user.findFirst({
      where: { mobile: data.mobile, countryCode: data.country_code },
    })
    if (existing) { fail(res, 'Phone number already registered'); return }

    const hash = await bcrypt.hash(data.password, 12)
    const user = await prisma.user.create({
      data: {
        name:         data.name,
        mobile:       data.mobile,
        countryCode:  data.country_code,
        email:        data.email,
        passwordHash: hash,
        isDriver:     data.is_driver,
        status:       'active',
      },
    })

    if (data.is_driver) {
      // Create a skeleton driver profile so the driver can be approved later
      // Minimal required fields are filled with placeholders until they complete onboarding
      await prisma.driverProfile.upsert({
        where:  { userId: user.id },
        create: {
          userId:        user.id,
          licenseNumber: 'PENDING',
          licenseExpiry: new Date('2099-01-01'),
          status:        'pending',
        },
        update: {},
      })
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, isDriver: user.isDriver },
      process.env.JWT_SECRET!,
      { expiresIn: '30d' },
    )

    ok(res, {
      token,
      user: _userPayload(user),
    }, 'Account created successfully')
  } catch (err) {
    serverError(res, err)
  }
}

export async function login(req: Request, res: Response) {
  try {
    const data = LoginSchema.parse(req.body)

    const user = await prisma.user.findFirst({
      where: { mobile: data.mobile, countryCode: data.country_code },
    })
    if (!user) { fail(res, 'Invalid credentials'); return }

    const valid = await bcrypt.compare(data.password, user.passwordHash)
    if (!valid) { fail(res, 'Invalid credentials'); return }

    if (user.status === 'banned')      { fail(res, 'Account banned'); return }
    if (user.status === 'suspended')   { fail(res, 'Account suspended'); return }

    // Fetch corporate membership if any
    const membership = await prisma.companyEmployee.findFirst({
      where:   { userId: user.id, isActive: true },
      include: { company: { select: { id: true, name: true } } },
    })

    const token = jwt.sign(
      { id: user.id, email: user.email, isDriver: user.isDriver },
      process.env.JWT_SECRET!,
      { expiresIn: '30d' },
    )

    await prisma.user.update({
      where: { id: user.id },
      data:  { lastActiveAt: new Date() },
    })

    ok(res, {
      token,
      user: {
        ..._userPayload(user),
        company_id:    membership?.companyId ?? null,
        department_id: membership?.departmentId?.toString() ?? null,
        cost_centre_id: membership?.costCentreId?.toString() ?? null,
        employee_role: membership?.role ?? null,
      },
    }, 'Login successful')
  } catch (err) {
    serverError(res, err)
  }
}

export async function getProfile(req: Request, res: Response) {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
    })
    if (!user) { fail(res, 'User not found', 404); return }

    const membership = await prisma.companyEmployee.findFirst({
      where: { userId: user.id, isActive: true },
    })

    ok(res, {
      ..._userPayload(user),
      company_id:    membership?.companyId ?? null,
      department_id: membership?.departmentId?.toString() ?? null,
      cost_centre_id: membership?.costCentreId?.toString() ?? null,
      employee_role: membership?.role ?? null,
    })
  } catch (err) {
    serverError(res, err)
  }
}

export async function updateProfile(req: Request, res: Response) {
  try {
    const { name, email, bio } = req.body as { name?: string; email?: string; bio?: string }
    const user = await prisma.user.update({
      where: { id: req.user.id },
      data: {
        ...(name  ? { name }  : {}),
        ...(email ? { email } : {}),
        ...(bio   ? { bio }   : {}),
      },
    })
    ok(res, _userPayload(user), 'Profile updated')
  } catch (err) {
    serverError(res, err)
  }
}

function _userPayload(user: { id: string; name: string; email: string | null; mobile: string; countryCode: string; profilePicUrl: string | null; walletBalance: unknown; isDriver: boolean; status: string }) {
  return {
    id:              user.id,
    name:            user.name,
    email:           user.email,
    mobile:          user.mobile,
    country_code:    user.countryCode,
    profile_pic_url: user.profilePicUrl,
    wallet_balance:  user.walletBalance,
    is_driver:       user.isDriver,
    status:          user.status,
  }
}
