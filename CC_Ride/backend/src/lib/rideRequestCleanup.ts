import { prisma } from './prisma'

// Ride requests have no TTL of their own — a request is only ever
// deactivated by an explicit passenger/driver confirm-decline flow. Every
// read/matching query now filters by departureDate, but a request whose
// date has passed still sits in the table as isActive:true forever unless
// something flips it. Run a periodic sweep so "isActive" actually reflects
// reality rather than relying on every future query to remember the filter.
async function deactivateExpiredRideRequests() {
  try {
    const startOfToday = new Date(new Date().toDateString())
    const { count } = await prisma.rideRequest.updateMany({
      where: { isActive: true, departureDate: { lt: startOfToday } },
      data: { isActive: false },
    })
    if (count > 0) console.log(`[rideRequestCleanup] deactivated ${count} expired ride request(s)`)
  } catch (err) {
    console.error('[rideRequestCleanup] failed:', err)
  }
}

const SWEEP_INTERVAL_MS = 60 * 60 * 1000 // hourly — requests expire by calendar day, not by the minute

export function startRideRequestCleanup() {
  deactivateExpiredRideRequests()
  setInterval(deactivateExpiredRideRequests, SWEEP_INTERVAL_MS)
}
