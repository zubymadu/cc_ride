// Government identity anchor — NIN for a Nigerian, passport number
// otherwise. Shared by every registration path that requires one (driver,
// corporate employee) rather than duplicating the same exactly-one-of
// validation in each controller.

export type IdentityResolution =
  | { ok: true; nin: string | null; passportNumber: string | null }
  | { ok: false; error: string }

export function resolveRequiredIdentity(nin?: string | null, passportNumber?: string | null): IdentityResolution {
  const trimmedNin = nin?.trim() || null
  const trimmedPassport = passportNumber?.trim() || null
  if (trimmedNin && trimmedPassport) {
    return { ok: false, error: 'Provide either a NIN or a passport number, not both — whichever applies to this person' }
  }
  if (!trimmedNin && !trimmedPassport) {
    return { ok: false, error: 'A NIN (for a Nigerian) or a passport number (otherwise) is required' }
  }
  return { ok: true, nin: trimmedNin, passportNumber: trimmedPassport }
}
