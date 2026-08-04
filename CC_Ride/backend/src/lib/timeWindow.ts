// Shared day/time-window matching — used by PricingRateCard's time_window
// scope and by per-employee facility access windows (pool car, wallet
// payment). Extracted here once both needed the identical logic.

export interface TimeWindow {
  daysOfWeek: number[]        // 1=Mon..7=Sun, ISO — empty means every day
  timeFrom: string | null     // "HH:MM"
  timeTo: string | null       // "HH:MM"
}

// 1=Mon..7=Sun — matches the convention already used by RidePolicy/checkPolicy.
export function isoDayOfWeek(at: Date) {
  const d = at.getDay()
  return d === 0 ? 7 : d
}

/** True if `at` falls inside the window. An unset window (no days, no
 *  times) always matches — "no restriction configured" rather than "never
 *  allowed". */
export function isWithinTimeWindow(window: TimeWindow, at: Date): boolean {
  if (window.daysOfWeek.length > 0 && !window.daysOfWeek.includes(isoDayOfWeek(at))) return false
  if (!window.timeFrom || !window.timeTo) return true
  const hhmm = `${String(at.getHours()).padStart(2, '0')}:${String(at.getMinutes()).padStart(2, '0')}`
  return window.timeFrom <= window.timeTo
    ? hhmm >= window.timeFrom && hhmm <= window.timeTo
    : hhmm >= window.timeFrom || hhmm <= window.timeTo // overnight window, e.g. 22:00-05:00
}
