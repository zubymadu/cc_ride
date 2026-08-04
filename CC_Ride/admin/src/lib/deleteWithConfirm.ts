import { del } from './api'

// Every housekeeping delete endpoint refuses by default when the target has
// real activity, returning a message that mentions `force=true` as the
// explicit override. This surfaces that message as a second confirmation
// rather than silently retrying — deleting real history should never be a
// one-click accident.
export async function deleteWithForceConfirm(path: string, itemLabel: string): Promise<boolean> {
  if (!confirm(`Delete ${itemLabel}? This cannot be undone.`)) return false
  try {
    await del(path)
    return true
  } catch (e: any) {
    const msg = e?.message ?? 'Failed to delete'
    if (msg.includes('force=true')) {
      if (!confirm(`${msg}\n\nForce delete anyway?`)) return false
      try {
        await del(path, { force: 'true' })
        return true
      } catch (e2: any) {
        alert(e2?.message ?? 'Failed to delete')
        return false
      }
    }
    alert(msg)
    return false
  }
}
