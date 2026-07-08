import { Request, Response } from 'express'
import { prisma } from '../../lib/prisma'
import { ok, serverError } from '../../lib/response'

export async function getSettings(_req: Request, res: Response) {
  try {
    const s = await prisma.platformSettings.findUnique({ where: { id: 1 } })
    ok(res, {
      app_name:                s?.appName ?? 'CC Ride',
      support_email:           s?.supportEmail ?? '',
      support_phone:           s?.supportPhone ?? '',
      default_commission_rate: Number(s?.platformCommission ?? 15),
      booking_fee:             Number(s?.bookingFee ?? 100),
      driver_payout_threshold: Number(s?.driverPayoutThreshold ?? 5000),
      max_cancellation_minutes: Number(s?.maxCancellationMinutes ?? 5),
      surge_multiplier_max:    Number(s?.surgeMultiplierMax ?? 2.5),
      maintenance_mode:        s?.maintenanceMode ?? false,
      paystack_public_key:          s?.paystackPublicKey ?? '',
      paystack_secret_key_masked:   s?.paystackSecretKey ? '••••••••' : '',
      flutterwave_public_key:       s?.flutterwavePublicKey ?? '',
      flutterwave_secret_key_masked: s?.flutterwaveSecretKey ? '••••••••' : '',
      google_maps_key_masked:       s?.googleMapsKey ? '••••••••' : '',
      firebase_project_id:          s?.firebaseProjectId ?? '',
      onesignal_app_id_masked:      s?.onesignalAppId ? '••••••••' : '',
      smtp_host:                    s?.smtpHost ?? '',
      smtp_port:                    s?.smtpPort ?? 587,
      smtp_user:                    s?.smtpUsername ?? '',
      smtp_pass_masked:             s?.smtpPassword ? '••••••••' : '',
    })
  } catch (err) {
    serverError(res, err)
  }
}

export async function updateSettings(req: Request, res: Response) {
  try {
    const body = req.body as Record<string, unknown>

    // Map camelCase field names expected by Prisma
    const data: Record<string, unknown> = {}
    if (body.app_name                !== undefined) data.appName                = body.app_name
    if (body.support_email           !== undefined) data.supportEmail           = body.support_email
    if (body.support_phone           !== undefined) data.supportPhone           = body.support_phone
    if (body.default_commission_rate !== undefined) data.platformCommission     = body.default_commission_rate
    if (body.booking_fee             !== undefined) data.bookingFee             = body.booking_fee
    if (body.driver_payout_threshold !== undefined) data.driverPayoutThreshold  = body.driver_payout_threshold
    if (body.max_cancellation_minutes !== undefined) data.maxCancellationMinutes = body.max_cancellation_minutes
    if (body.surge_multiplier_max    !== undefined) data.surgeMultiplierMax     = body.surge_multiplier_max
    if (body.maintenance_mode        !== undefined) data.maintenanceMode        = body.maintenance_mode
    if (body.paystack_public_key     !== undefined) data.paystackPublicKey      = body.paystack_public_key
    if (body.flutterwave_public_key  !== undefined) data.flutterwavePublicKey   = body.flutterwave_public_key
    if (body.firebase_project_id     !== undefined) data.firebaseProjectId      = body.firebase_project_id

    // Only update masked keys if a new non-empty value was provided
    if (body.paystack_secret_key_masked    && body.paystack_secret_key_masked !== '')    data.paystackSecretKey      = body.paystack_secret_key_masked
    if (body.flutterwave_secret_key_masked && body.flutterwave_secret_key_masked !== '') data.flutterwaveSecretKey   = body.flutterwave_secret_key_masked
    if (body.google_maps_key_masked        && body.google_maps_key_masked !== '')        data.googleMapsKey          = body.google_maps_key_masked
    if (body.onesignal_app_id_masked       && body.onesignal_app_id_masked !== '')       data.onesignalAppId         = body.onesignal_app_id_masked
    if (body.smtp_host  !== undefined) data.smtpHost     = body.smtp_host
    if (body.smtp_port  !== undefined) data.smtpPort     = body.smtp_port
    if (body.smtp_user  !== undefined) data.smtpUsername = body.smtp_user
    if (body.smtp_pass_masked && body.smtp_pass_masked !== '') data.smtpPassword = body.smtp_pass_masked

    await prisma.platformSettings.upsert({
      where:  { id: 1 },
      update: data,
      create: { id: 1, ...data },
    })

    ok(res, {}, 'Settings saved')
  } catch (err) {
    serverError(res, err)
  }
}
