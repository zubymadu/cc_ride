// Shared fare-estimate formula, mirrored in the Flutter app
// (lib/utils/fare_calculator.dart) so every surface quotes the same number.
//
// estimated_total = baseFare + (farePerKm × distanceKm) + bookingFee
//
// farePerKm/distanceKm default to 0 wherever per-km pricing isn't collected
// yet — the formula then reduces to `baseFare + bookingFee`.

export function estimateFare({
  baseFare,
  farePerKm = 0,
  distanceKm = 0,
  bookingFee = 0,
}: {
  baseFare: number
  farePerKm?: number
  distanceKm?: number
  bookingFee?: number
}): number {
  const total = baseFare + farePerKm * distanceKm + bookingFee
  return total < 0 ? 0 : total
}

/** Great-circle (haversine) distance between two points, in kilometres —
 * a reasonable "as the crow flies" estimate when no routing API is called. */
export function haversineDistanceKm(
  lat1: number, lng1: number, lat2: number, lng2: number,
): number {
  if ([lat1, lng1, lat2, lng2].some((v) => Number.isNaN(v))) return 0
  const R = 6371 // Earth radius, km
  const dLat = ((lat2 - lat1) * Math.PI) / 180
  const dLng = ((lng2 - lng1) * Math.PI) / 180
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
}
