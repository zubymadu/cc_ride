/// Shared fare-estimate formula, mirrored in the admin console
/// (admin/src/lib/fareEstimate.ts) so every surface quotes the same number.
///
/// estimated_total = baseFare + (farePerKm × distanceKm) + bookingFee
///
/// `farePerKm`/`distanceKm` default to 0 wherever per-km pricing isn't
/// collected yet (e.g. a driver posting a flat per-seat price) — the formula
/// then reduces to `baseFare + bookingFee`.
double estimateFare({
  required double baseFare,
  double farePerKm = 0,
  double distanceKm = 0,
  double bookingFee = 0,
}) {
  final total = baseFare + (farePerKm * distanceKm) + bookingFee;
  return total < 0 ? 0 : total;
}
