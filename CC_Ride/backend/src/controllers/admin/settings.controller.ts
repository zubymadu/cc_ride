import { Request, Response } from 'express'
import { prisma } from '../../lib/prisma'
import { ok, fail, serverError } from '../../lib/response'

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
      pricing_model:           s?.pricingModel ?? 'driver_set',
      default_base_fare:       Number(s?.defaultBaseFare ?? 500),
      default_fare_per_km:     Number(s?.defaultFarePerKm ?? 150),
      default_fare_per_min:    Number(s?.defaultFarePerMin ?? 10),
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

// GET /admin/geocode?address=... — proxies Google's Geocoding API using the
// key stored in PlatformSettings (never exposed to the browser — the admin
// panel's Settings page only ever shows a masked placeholder for it). Used
// by admin forms that take a free-text address (pool-ride route creation,
// branch address) so an entered address resolves to real coordinates
// instead of the caller having to type lat/lng by hand or the form quietly
// falling back to a hardcoded default point.
export async function geocodeAddress(req: Request, res: Response) {
  try {
    const address = String(req.query.address ?? '').trim()
    // These are genuine failures, not "found nothing" — must use fail(),
    // not ok(res, null, msg). The admin panel's api client (unwrap() in
    // admin/src/lib/api.ts) only ever surfaces ResponseMsg when Result is
    // "false"; ok() always sends Result:"true", so every one of these specific
    // reasons was silently discarded and the UI fell back to its own generic
    // "could not resolve" text no matter which of these actually happened.
    if (address.length < 3) { fail(res, 'Address too short to geocode'); return }

    const s = await prisma.platformSettings.findUnique({ where: { id: 1 } })
    if (!s?.googleMapsKey) { fail(res, 'No Google Maps key configured in Settings — add one under Settings > Google Maps Key'); return }

    const url = new URL('https://maps.googleapis.com/maps/api/geocode/json')
    url.searchParams.set('address', address)
    url.searchParams.set('region', 'ng')
    url.searchParams.set('key', s.googleMapsKey)

    const resp = await fetch(url.toString())
    const data = await resp.json() as any
    if (data.status !== 'OK' || !data.results?.[0]) {
      fail(res, `Could not resolve that address (${data.status ?? 'no results'})`)
      return
    }

    const top = data.results[0]
    ok(res, {
      formatted_address: top.formatted_address,
      lat: top.geometry.location.lat,
      lng: top.geometry.location.lng,
    })
  } catch (err) {
    serverError(res, err)
  }
}

// GET /admin/places-search?q=... — live address search-as-you-type, same
// idea as geocodeAddress above but returns several candidates instead of
// committing to Google's single top guess for a (possibly still
// mid-typing) query. Mirrors the Flutter app's own address search
// (map_suggetion_controlle.dart, Text Search + Nigeria bounding box) so an
// admin gets the same kind of pick-a-suggestion flow instead of typing a
// full address blind and hoping it resolves on blur.
export async function searchPlaces(req: Request, res: Response) {
  try {
    const q = String(req.query.q ?? '').trim()
    if (q.length < 2) { ok(res, []); return }

    const s = await prisma.platformSettings.findUnique({ where: { id: 1 } })
    if (!s?.googleMapsKey) { fail(res, 'No Google Maps key configured in Settings — add one under Settings > Google Maps Key'); return }

    const url = new URL('https://maps.googleapis.com/maps/api/place/textsearch/json')
    url.searchParams.set('query', q)
    url.searchParams.set('region', 'ng')
    url.searchParams.set('location', '9.0820,8.6753') // geographic centre of Nigeria — biases ranking only, never excludes
    url.searchParams.set('radius', '800000')
    url.searchParams.set('key', s.googleMapsKey)

    const resp = await fetch(url.toString())
    const data = await resp.json() as any
    if (data.status !== 'OK') {
      fail(res, `Places search failed: ${data.status}${data.error_message ? ` — ${data.error_message}` : ''}`)
      return
    }

    const results = (data.results ?? [])
      .filter((r: any) => {
        const lat = r.geometry?.location?.lat, lng = r.geometry?.location?.lng
        return lat != null && lng != null && lat >= 4.0 && lat <= 14.0 && lng >= 2.5 && lng <= 15.0
      })
      .slice(0, 8)
      .map((r: any) => ({
        description: r.name ? `${r.name}, ${r.formatted_address}` : r.formatted_address,
        formatted_address: r.formatted_address,
        lat: r.geometry.location.lat,
        lng: r.geometry.location.lng,
      }))

    ok(res, results)
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
    if (body.pricing_model           !== undefined) data.pricingModel           = body.pricing_model
    if (body.default_base_fare       !== undefined) data.defaultBaseFare        = body.default_base_fare
    if (body.default_fare_per_km     !== undefined) data.defaultFarePerKm       = body.default_fare_per_km
    if (body.default_fare_per_min    !== undefined) data.defaultFarePerMin      = body.default_fare_per_min
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
