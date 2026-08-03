import { useQuery } from '@tanstack/react-query'
import { Info } from 'lucide-react'
import { get } from '../lib/api'
import { estimateFare, haversineDistanceKm } from '../lib/fareEstimate'

interface Props {
  baseFare: string
  originLat: string
  originLng: string
  destinationLat: string
  destinationLng: string
}

/** Live "what will the passenger actually pay" preview shown while an admin
 * fills out a ride-creation form — mirrors the same formula used on the
 * driver's route-posting screen in the Flutter app. */
export default function FareEstimateBanner({ baseFare, originLat, originLng, destinationLat, destinationLng }: Props) {
  const { data: settings } = useQuery<{ booking_fee: number }>({
    queryKey: ['admin-settings-fee'],
    queryFn:  () => get('/admin/settings'),
    staleTime: 5 * 60 * 1000,
  })

  const base = parseFloat(baseFare)
  if (!base || Number.isNaN(base)) return null

  const bookingFee = settings?.booking_fee ?? 0
  const distanceKm = haversineDistanceKm(
    parseFloat(originLat), parseFloat(originLng),
    parseFloat(destinationLat), parseFloat(destinationLng),
  )
  const estimate = estimateFare({ baseFare: base, bookingFee })

  return (
    <div className="flex items-start gap-2 bg-brand-50 border border-brand-100 rounded-xl px-3 py-2.5 text-sm">
      <Info className="w-4 h-4 text-brand-600 flex-shrink-0 mt-0.5" />
      <div>
        <p className="text-brand-700 font-medium">
          Passengers pay ₦{estimate.toLocaleString(undefined, { maximumFractionDigits: 2 })} per seat
        </p>
        <p className="text-brand-600/70 text-xs mt-0.5">
          {bookingFee > 0 && <>Includes ₦{bookingFee.toLocaleString()} platform booking fee</>}
          {distanceKm > 0 && <> · ~{distanceKm.toFixed(1)} km route</>}
        </p>
      </div>
    </div>
  )
}
