import { useEffect, useRef, useState } from 'react'
import { MapPin, Loader2 } from 'lucide-react'
import { get } from '../lib/api'

interface PlaceResult {
  name: string
  formatted_address: string
  lat: number | null
  lng: number | null
}

interface Props {
  label: string
  placeholder?: string
  address: string
  onChange: (address: string, lat: string, lng: string) => void
}

/** Address field backed by Google Places search (via the admin/places/search
 * backend proxy) — typing shows live suggestions, and picking one fills the
 * address text together with its real lat/lng so rides are never created
 * with mismatched or made-up coordinates. */
export default function AddressAutocompleteInput({ label, placeholder, address, onChange }: Props) {
  const [query, setQuery] = useState(address)
  const [results, setResults] = useState<PlaceResult[]>([])
  const [loading, setLoading] = useState(false)
  const [open, setOpen] = useState(false)
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const boxRef = useRef<HTMLDivElement>(null)

  useEffect(() => setQuery(address), [address])

  useEffect(() => {
    function onClickOutside(e: MouseEvent) {
      if (boxRef.current && !boxRef.current.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', onClickOutside)
    return () => document.removeEventListener('mousedown', onClickOutside)
  }, [])

  function handleType(value: string) {
    setQuery(value)
    // Clear any previously-picked coordinates — free-typed text alone isn't
    // geocoded, so the address and lat/lng must never drift apart.
    onChange(value, '', '')

    if (debounceRef.current) clearTimeout(debounceRef.current)
    if (value.trim().length < 3) { setResults([]); setOpen(false); return }

    debounceRef.current = setTimeout(async () => {
      setLoading(true)
      try {
        const data = await get<PlaceResult[]>('/admin/places/search', { query: value })
        setResults(data)
        setOpen(true)
      } catch {
        setResults([])
      } finally {
        setLoading(false)
      }
    }, 350)
  }

  function select(r: PlaceResult) {
    setQuery(r.formatted_address)
    onChange(
      r.formatted_address,
      r.lat != null ? String(r.lat) : '',
      r.lng != null ? String(r.lng) : '',
    )
    setOpen(false)
    setResults([])
  }

  return (
    <div className="relative" ref={boxRef}>
      <label className="block text-xs font-medium text-gray-600 mb-1">{label}</label>
      <div className="relative">
        <input
          className="input pr-8"
          placeholder={placeholder}
          value={query}
          onChange={(e) => handleType(e.target.value)}
          onFocus={() => results.length > 0 && setOpen(true)}
          autoComplete="off"
        />
        {loading && (
          <Loader2 className="w-3.5 h-3.5 animate-spin absolute right-2.5 top-1/2 -translate-y-1/2 text-gray-400" />
        )}
      </div>
      {open && results.length > 0 && (
        <div className="absolute z-20 mt-1 w-full bg-white border border-gray-200 rounded-lg shadow-lg max-h-64 overflow-y-auto">
          {results.map((r, i) => (
            <button
              key={i}
              type="button"
              onClick={() => select(r)}
              className="w-full text-left px-3 py-2 hover:bg-gray-50 flex items-start gap-2 border-b border-gray-50 last:border-0"
            >
              <MapPin className="w-3.5 h-3.5 text-gray-400 mt-0.5 flex-shrink-0" />
              <span className="text-sm text-gray-700">{r.formatted_address}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
