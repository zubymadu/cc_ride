import { prisma } from './prisma'
import { distanceKm } from './geo'

const NEARBY_RADIUS_KM = 15

// The Flutter app tags every logged-in session with OneSignal.User.addTags({
// "userid": <the user's id>}) right after init (see initPlatformState in
// main.dart) — so we can target a push at a specific user via a tag filter
// without needing to store/manage per-device player IDs server-side at all.
async function sendOneSignalPush(userIds: string[], title: string, body: string, data: Record<string, unknown>) {
  if (userIds.length === 0) return
  const settings = await prisma.platformSettings.findUnique({ where: { id: 1 } })
  if (!settings?.onesignalAppId || !settings?.onesignalApiKey) {
    console.warn('sendOneSignalPush: OneSignal app id / API key not configured in PlatformSettings — skipping push')
    return
  }
  try {
    await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Basic ${settings.onesignalApiKey}`,
      },
      body: JSON.stringify({
        app_id: settings.onesignalAppId,
        filters: userIds.flatMap((id, i) => i === 0
          ? [{ field: 'tag', key: 'userid', relation: '=', value: id }]
          : [{ operator: 'OR' }, { field: 'tag', key: 'userid', relation: '=', value: id }]),
        headings: { en: title },
        contents: { en: body },
        data,
      }),
    })
  } catch (err) {
    console.error('sendOneSignalPush:', err)
  }
}

// Notifies drivers within range of a new ride request — writes rows to the
// in-app Notification table (surfaced by the notification bell) and, if
// OneSignal is configured, also fires a real push so drivers don't have to
// have the app open to find out.
export async function notifyNearbyDriversOfRequest(request: {
  id: string
  originLat: number | { toString(): string }
  originLng: number | { toString(): string }
  originAddress: string
  destinationAddress: string
}) {
  const originLat = Number(request.originLat)
  const originLng = Number(request.originLng)

  const candidates = await prisma.driverProfile.findMany({
    where: {
      status: { in: ['active', 'on_trip'] },
      currentLocationLat: { not: null },
      currentLocationLng: { not: null },
    },
    select: { userId: true, currentLocationLat: true, currentLocationLng: true },
  })

  const nearby = candidates.filter(d =>
    distanceKm(
      originLat, originLng,
      Number(d.currentLocationLat), Number(d.currentLocationLng),
    ) <= NEARBY_RADIUS_KM,
  )

  if (nearby.length === 0) return

  const title = 'New ride request near you'
  const body = `${request.originAddress} → ${request.destinationAddress}`
  const data = { request_id: request.id, kind: 'ride_request' }

  await prisma.notification.createMany({
    data: nearby.map(d => ({
      userId: d.userId,
      type: 'general' as const,
      title,
      body,
      data,
    })),
  })

  await sendOneSignalPush(nearby.map(d => d.userId), title, body, data)
}

// Notifies a user that an admin replied to (or resolved) their support
// ticket — without this, replyToTicket/resolveTicket in the admin support
// controller were silent: the ticket updated in the database but the rider
// who raised it had no way to find out short of manually reopening the
// ticket list and refreshing.
export async function notifyUserOfTicketUpdate(params: {
  userId: string
  ticketId: string
  subject: string
  kind: 'reply' | 'resolved'
  preview?: string
}) {
  const title = params.kind === 'resolved'
    ? `Your ticket "${params.subject}" was resolved`
    : `New reply on "${params.subject}"`
  const body = params.kind === 'resolved'
    ? 'Support marked this ticket as resolved. Reply if you still need help.'
    : (params.preview ?? 'Tap to view the reply').slice(0, 140)
  const data = { ticket_id: params.ticketId, kind: 'support_ticket_update' }

  await prisma.notification.create({
    data: { userId: params.userId, type: 'general', title, body, data },
  })

  await sendOneSignalPush([params.userId], title, body, data)
}

// Notifies a passenger that a driver has posted a trip covering their request.
export async function notifyPassengerOfMatch(request: {
  id: string
  passengerId: string
  originAddress: string
  destinationAddress: string
}, tripId: string) {
  const title = 'A driver found your trip — confirm your seat'
  const body = `${request.originAddress} → ${request.destinationAddress}. Confirm to book, or decline to cancel your request.`
  const data = { request_id: request.id, trip_id: tripId, kind: 'request_matched' }

  await prisma.notification.create({
    data: { userId: request.passengerId, type: 'general', title, body, data },
  })

  await sendOneSignalPush([request.passengerId], title, body, data)
}
