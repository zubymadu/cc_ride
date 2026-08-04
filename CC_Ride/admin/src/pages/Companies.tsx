import { useState, useEffect, useRef } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Search, CheckCircle, XCircle, Building2, Loader2,
  ChevronDown, Users, Car, Percent, AlertTriangle,
  Plus, Layers, MapPin, Wallet, History, GitBranch,
  Globe, Edit2, ToggleLeft, ToggleRight, UserPlus,
  Share2, Trash2, BarChart2, Sparkles, Clock, Check, X, Camera, Upload, FileSpreadsheet, Download,
} from 'lucide-react'
import { get, post, api } from '../lib/api'
import { fmt, badge, cn } from '../lib/utils'
import PageHeader from '../components/PageHeader'
import EmptyState from '../components/EmptyState'
import Modal from '../components/Modal'
import { useAuthStore } from '../store/auth'

// ─── Types ────────────────────────────────────────────────────────────────────

interface Company {
  id: string; name: string; logo_url: string | null; registration_number: string
  contact_name: string; contact_email: string; contact_phone: string
  status: string; total_employees: number; rides_this_month: number
  gmv_this_month: number; commission_rate: number; created_at: string
  wallet_balance: number
}
interface CreditEntry {
  id: string; amount: number; balance_after: number
  payment_method: string; reference: string | null; note: string | null
  credited_by: string; created_at: string
}
interface Region { id: string; name: string; code: string | null; is_active: boolean; branch_count: number }
interface Branch {
  id: string; company_id: string; region_id: string | null; region_name: string | null
  name: string; code: string | null; address: string | null; city: string | null; state: string
  contact_name: string | null; contact_phone: string | null; contact_email: string | null
  is_headquarters: boolean; is_active: boolean; billed_separately: boolean
  wallet_balance: number; employee_count: number; booking_count: number; created_at: string
}
interface Employee { id: string; name: string; email: string; mobile: string; role: string; is_active: boolean; joined_at: string; status: string }
interface CompanyRide { id: string; passenger: string; driver: string; origin: string; destination: string; status: string; total_amount: number; payment_status: string; created_at: string }
interface Department { id: string; name: string; code: string; employee_count: number }
interface CostCentre { id: string; name: string; code: string; description: string; department: string | null; employee_count: number; total_bookings: number }
interface AvailableDriver { id: string; name: string; mobile: string; rating: number }

type DetailTab = 'info' | 'employees' | 'rides' | 'departments' | 'cost-centres' | 'branches' | 'wallet' | 'pool-policy' | 'savings' | 'fleet' | 'tracking'

// ─── Field component ─────────────────────────────────────────────────────────

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label className="block text-xs font-medium text-gray-500 mb-1">{label}</label>
      {children}
    </div>
  )
}

// ─── Create Company Modal ─────────────────────────────────────────────────────

function CreateCompanyModal({ open, onClose }: { open: boolean; onClose: () => void }) {
  const qc = useQueryClient()
  const [form, setForm] = useState({
    name: '', contact_name: '', contact_email: '', contact_phone: '',
    registration_number: '', industry: '', address: '', city: '', state: 'Lagos',
    commission_rate: '15', notes: '', auto_approve: false,
  })
  const [logoFile, setLogoFile] = useState<File | null>(null)
  const [logoPreview, setLogoPreview] = useState<string | null>(null)
  const [err, setErr] = useState('')

  // POST /admin/companies only ever accepted a JSON body, so a logo picked
  // here can't ride along in the same request — create the company first,
  // then immediately upload the logo against the id it returns (the same
  // POST /admin/companies/:id/logo endpoint the Info tab's uploader uses),
  // before closing the modal. If the logo upload itself fails the company
  // still exists — that failure surfaces but doesn't roll back creation.
  const create = useMutation({
    mutationFn: async () => {
      const created = await post<{ id: string; name: string; status: string }>('/admin/companies', {
        ...form,
        commission_rate: form.commission_rate ? parseFloat(form.commission_rate) : undefined,
      })
      if (logoFile) {
        const logoForm = new FormData()
        logoForm.append('logo', logoFile)
        await post(`/admin/companies/${created.id}/logo`, logoForm)
      }
      return created
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-companies'] })
      onClose()
      setForm({ name: '', contact_name: '', contact_email: '', contact_phone: '', registration_number: '', industry: '', address: '', city: '', state: 'Lagos', commission_rate: '15', notes: '', auto_approve: false })
      setLogoFile(null)
      setLogoPreview(null)
      setErr('')
    },
    onError: (e: any) => setErr(e?.message ?? 'Failed to create company'),
  })

  const f = (k: keyof typeof form) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) =>
    setForm((p) => ({ ...p, [k]: e.target.value }))

  return (
    <Modal open={open} onClose={onClose} title="Create New Company" size="lg">
      <div className="space-y-4">
        {err && <div className="bg-red-50 border border-red-200 text-red-700 text-sm px-3 py-2 rounded-lg">{err}</div>}

        <div className="flex items-center gap-4">
          <label className="relative w-16 h-16 rounded-xl bg-brand-50 flex items-center justify-center overflow-hidden flex-shrink-0 cursor-pointer group border border-dashed border-brand-200">
            {logoPreview ? (
              <img src={logoPreview} alt="" className="w-full h-full object-cover" />
            ) : (
              <Building2 className="w-7 h-7 text-brand-500" />
            )}
            <span className="absolute inset-0 bg-black/0 group-hover:bg-black/40 flex items-center justify-center transition-colors">
              <Camera className="w-4 h-4 text-white opacity-0 group-hover:opacity-100 transition-opacity" />
            </span>
            <input
              type="file"
              accept="image/png,image/jpeg,image/webp"
              className="hidden"
              onChange={(e) => {
                const file = e.target.files?.[0] ?? null
                setLogoFile(file)
                setLogoPreview(file ? URL.createObjectURL(file) : null)
              }}
            />
          </label>
          <div>
            <p className="text-sm font-medium text-gray-800">Company logo (optional)</p>
            <p className="text-xs text-gray-500">Can also be added or changed later from the Info tab</p>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <Field label="Company Name *">
            <input className="input" placeholder="Acme Nigeria Ltd" value={form.name} onChange={f('name')} />
          </Field>
          <Field label="Industry">
            <input className="input" placeholder="e.g. Oil & Gas, Banking" value={form.industry} onChange={f('industry')} />
          </Field>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <Field label="Contact Person *">
            <input className="input" placeholder="Full name" value={form.contact_name} onChange={f('contact_name')} />
          </Field>
          <Field label="Contact Email *">
            <input className="input" type="email" placeholder="hr@company.com" value={form.contact_email} onChange={f('contact_email')} />
          </Field>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <Field label="Contact Phone">
            <input className="input" placeholder="+234 800 000 0000" value={form.contact_phone} onChange={f('contact_phone')} />
          </Field>
          <Field label="Reg. Number (CAC)">
            <input className="input" placeholder="RC-123456" value={form.registration_number} onChange={f('registration_number')} />
          </Field>
        </div>

        <div className="grid grid-cols-3 gap-4">
          <Field label="Address">
            <input className="input" placeholder="Street address" value={form.address} onChange={f('address')} />
          </Field>
          <Field label="City">
            <input className="input" placeholder="Lagos" value={form.city} onChange={f('city')} />
          </Field>
          <Field label="State">
            <select className="input" value={form.state} onChange={f('state')}>
              {['Lagos','Abuja','Rivers','Kano','Oyo','Delta','Ogun','Anambra','Enugu','Kaduna'].map((s) => (
                <option key={s}>{s}</option>
              ))}
            </select>
          </Field>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <Field label="Commission Rate (%)">
            <input className="input" type="number" min={0} max={50} step={0.5} value={form.commission_rate} onChange={f('commission_rate')} />
          </Field>
          <Field label="Notes (internal)">
            <input className="input" placeholder="Optional internal note" value={form.notes} onChange={f('notes')} />
          </Field>
        </div>

        <label className="flex items-center gap-3 p-3 bg-brand-50 rounded-xl cursor-pointer">
          <input type="checkbox" checked={form.auto_approve} onChange={(e) => setForm((p) => ({ ...p, auto_approve: e.target.checked }))}
            className="w-4 h-4 accent-brand-500" />
          <div>
            <p className="text-sm font-medium text-gray-800">Activate immediately</p>
            <p className="text-xs text-gray-500">Skip pending review — company can book rides right away</p>
          </div>
        </label>

        <div className="flex gap-3 pt-2">
          <button onClick={onClose} className="btn-secondary flex-1">Cancel</button>
          <button onClick={() => create.mutate()} disabled={create.isPending || !form.name || !form.contact_email || !form.contact_name}
            className="btn-primary flex-1">
            {create.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
            Create Company
          </button>
        </div>
      </div>
    </Modal>
  )
}

// ─── Address search field ──────────────────────────────────────────────────
//
// Live search-as-you-type over GET /admin/places-search, debounced so it
// doesn't fire a request per keystroke. Replaces the old "type a full
// address, tab out, hope it geocodes" flow — the admin picks from Google's
// actual candidates instead of typing blind, same idea as the rider app's
// own address search (map_suggetion_controlle.dart).
interface PlaceSuggestion { description: string; formatted_address: string; lat: number; lng: number }

function AddressSearchField({ placeholder, value, onSelect }: {
  placeholder: string
  value: string
  onSelect: (place: { address: string; lat: number; lng: number }) => void
}) {
  const [query, setQuery] = useState(value)
  const [suggestions, setSuggestions] = useState<PlaceSuggestion[]>([])
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const [searchErr, setSearchErr] = useState('')
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(() => setQuery(value), [value])

  const runSearch = (q: string) => {
    if (debounceRef.current) clearTimeout(debounceRef.current)
    if (q.trim().length < 2) { setSuggestions([]); setOpen(false); return }
    debounceRef.current = setTimeout(async () => {
      setLoading(true)
      setSearchErr('')
      try {
        const results = await get<PlaceSuggestion[]>(`/admin/places-search?q=${encodeURIComponent(q)}`)
        setSuggestions(results)
        setOpen(true)
      } catch (e: any) {
        setSearchErr(e?.message ?? 'Address search failed')
        setSuggestions([])
        setOpen(true)
      } finally {
        setLoading(false)
      }
    }, 350)
  }

  return (
    <div className="relative">
      <input
        className="input"
        placeholder={placeholder}
        value={query}
        onChange={(e) => { setQuery(e.target.value); runSearch(e.target.value) }}
        onFocus={() => { if (suggestions.length > 0 || searchErr) setOpen(true) }}
        onBlur={() => setTimeout(() => setOpen(false), 150)} // delay so a click on a suggestion registers first
      />
      {loading && (
        <Loader2 className="w-3.5 h-3.5 animate-spin text-gray-400 absolute right-3 top-1/2 -translate-y-1/2" />
      )}
      {open && (
        <div className="absolute z-20 mt-1 w-full bg-white border border-gray-200 rounded-lg shadow-lg max-h-56 overflow-y-auto">
          {searchErr ? (
            <p className="text-xs text-red-600 px-3 py-2">{searchErr}</p>
          ) : suggestions.length === 0 ? (
            !loading && <p className="text-xs text-gray-400 px-3 py-2">No matches yet — keep typing</p>
          ) : (
            suggestions.map((s, i) => (
              <button
                key={i}
                type="button"
                className="w-full text-left px-3 py-2 text-sm hover:bg-brand-50 border-b border-gray-50 last:border-0"
                onMouseDown={(e) => e.preventDefault()} // fires before input's onBlur closes the dropdown
                onClick={() => {
                  setQuery(s.formatted_address)
                  onSelect({ address: s.formatted_address, lat: s.lat, lng: s.lng })
                  setOpen(false)
                }}
              >
                {s.description}
              </button>
            ))
          )}
        </div>
      )}
    </div>
  )
}

// ─── Add Ride Modal ───────────────────────────────────────────────────────────

function AddRideModal({ companyId, onClose }: { companyId: string; onClose: () => void }) {
  const qc = useQueryClient()
  const [form, setForm] = useState({
    driver_id: '', origin_address: '', origin_lat: '', origin_lng: '',
    destination_address: '', destination_lat: '', destination_lng: '',
    scheduled_at: '', base_fare: '', available_seats: '4', trip_notes: '',
  })
  const [err, setErr] = useState('')

  const { data: drivers = [] } = useQuery<AvailableDriver[]>({
    queryKey: ['available-drivers'],
    queryFn:  () => get('/admin/drivers/available'),
  })

  const create = useMutation({
    mutationFn: () => post(`/admin/companies/${companyId}/rides`, {
      driver_id:           form.driver_id,
      origin_address:      form.origin_address,
      origin_lat:          parseFloat(form.origin_lat),
      origin_lng:          parseFloat(form.origin_lng),
      destination_address: form.destination_address,
      destination_lat:     parseFloat(form.destination_lat),
      destination_lng:     parseFloat(form.destination_lng),
      scheduled_at:        form.scheduled_at,
      base_fare:           parseFloat(form.base_fare),
      available_seats:     parseInt(form.available_seats),
      trip_notes:          form.trip_notes || undefined,
    }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['company-rides', companyId] })
      onClose()
    },
    onError: (e: any) => setErr(e?.message ?? 'Failed to create ride'),
  })

  const f = (k: keyof typeof form) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) =>
    setForm((p) => ({ ...p, [k]: e.target.value }))

  const canSubmit = form.driver_id && form.origin_address && form.destination_address
    && form.origin_lat && form.origin_lng && form.destination_lat && form.destination_lng
    && form.scheduled_at && form.base_fare

  return (
    <Modal open={true} onClose={onClose} title="Add Company Ride" size="lg">
      <div className="space-y-4">
        {err && <div className="bg-red-50 border border-red-200 text-red-700 text-sm px-3 py-2 rounded-lg">{err}</div>}

        <Field label="Assign Driver *">
          <select className="input" value={form.driver_id} onChange={f('driver_id')}>
            <option value="">— Select driver —</option>
            {drivers.map((d) => (
              <option key={d.id} value={d.id}>{d.name} · {d.mobile} · ⭐ {d.rating.toFixed(1)}</option>
            ))}
          </select>
        </Field>

        <div className="grid grid-cols-2 gap-4">
          <Field label="Pick-up Address *">
            <AddressSearchField
              placeholder="Start typing e.g. Victoria Island, Lagos"
              value={form.origin_address}
              onSelect={({ address, lat, lng }) => setForm((p) => ({
                ...p, origin_address: address, origin_lat: String(lat), origin_lng: String(lng),
              }))}
            />
          </Field>
          <Field label="Drop-off Address *">
            <AddressSearchField
              placeholder="Start typing e.g. Lekki Phase 1, Lagos"
              value={form.destination_address}
              onSelect={({ address, lat, lng }) => setForm((p) => ({
                ...p, destination_address: address, destination_lat: String(lat), destination_lng: String(lng),
              }))}
            />
          </Field>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <Field label={`Origin Lat, Lng ${form.origin_lat ? '· resolved' : '(pick a suggestion above, or enter manually)'}`}>
            <div className="flex gap-2">
              <input className="input" placeholder="6.4281" value={form.origin_lat} onChange={f('origin_lat')} />
              <input className="input" placeholder="3.4219" value={form.origin_lng} onChange={f('origin_lng')} />
            </div>
          </Field>
          <Field label={`Destination Lat, Lng ${form.destination_lat ? '· resolved' : '(pick a suggestion above, or enter manually)'}`}>
            <div className="flex gap-2">
              <input className="input" placeholder="6.4547" value={form.destination_lat} onChange={f('destination_lat')} />
              <input className="input" placeholder="3.5320" value={form.destination_lng} onChange={f('destination_lng')} />
            </div>
          </Field>
        </div>

        <div className="grid grid-cols-3 gap-4">
          <Field label="Scheduled Date & Time *">
            <input className="input" type="datetime-local" value={form.scheduled_at} onChange={f('scheduled_at')} />
          </Field>
          <Field label="Base Fare (₦) *">
            <input className="input" type="number" placeholder="2500" value={form.base_fare} onChange={f('base_fare')} />
          </Field>
          <Field label="Available Seats">
            <select className="input" value={form.available_seats} onChange={f('available_seats')}>
              {[1,2,3,4,5,6,7,8].map((n) => <option key={n}>{n}</option>)}
            </select>
          </Field>
        </div>

        <Field label="Trip Notes (optional)">
          <input className="input" placeholder="e.g. Airport pickup — check flight status" value={form.trip_notes} onChange={f('trip_notes')} />
        </Field>

        <div className="flex gap-3 pt-2">
          <button onClick={onClose} className="btn-secondary flex-1">Cancel</button>
          <button onClick={() => create.mutate()} disabled={create.isPending || !canSubmit} className="btn-primary flex-1">
            {create.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <MapPin className="w-4 h-4" />}
            Create Ride
          </button>
        </div>
      </div>
    </Modal>
  )
}

// ─── Departments & Cost Centres tab ──────────────────────────────────────────

function DepartmentsTab({ companyId }: { companyId: string }) {
  const qc = useQueryClient()
  const [newDept, setNewDept] = useState({ name: '', code: '' })
  const [err, setErr] = useState('')

  const { data: depts = [], isLoading } = useQuery<Department[]>({
    queryKey: ['company-depts', companyId],
    queryFn:  () => get(`/admin/companies/${companyId}/departments`),
  })

  const create = useMutation({
    mutationFn: () => post(`/admin/companies/${companyId}/departments`, newDept),
    onSuccess:  () => { qc.invalidateQueries({ queryKey: ['company-depts', companyId] }); setNewDept({ name: '', code: '' }); setErr('') },
    onError:    (e: any) => setErr(e?.message ?? 'Failed'),
  })

  if (isLoading) return <div className="flex justify-center py-8"><Loader2 className="w-5 h-5 animate-spin text-brand-500" /></div>

  return (
    <div className="space-y-4">
      {err && <div className="bg-red-50 border border-red-200 text-red-700 text-xs px-3 py-2 rounded-lg">{err}</div>}

      {/* Add department */}
      <div className="flex gap-2 items-end bg-white border border-brand-100 rounded-xl p-3">
        <div className="flex-1">
          <label className="text-xs text-gray-500 mb-1 block">Department name</label>
          <input className="input" placeholder="e.g. Engineering" value={newDept.name}
            onChange={(e) => setNewDept((p) => ({ ...p, name: e.target.value }))} />
        </div>
        <div className="w-28">
          <label className="text-xs text-gray-500 mb-1 block">Code (optional)</label>
          <input className="input" placeholder="ENG" value={newDept.code}
            onChange={(e) => setNewDept((p) => ({ ...p, code: e.target.value }))} />
        </div>
        <button onClick={() => create.mutate()} disabled={create.isPending || !newDept.name} className="btn-primary text-sm h-10">
          {create.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
          Add
        </button>
      </div>

      {/* List */}
      {depts.length === 0 ? (
        <p className="text-sm text-gray-400 text-center py-4">No departments yet — add one above</p>
      ) : (
        <div className="space-y-2">
          {depts.map((d) => (
            <div key={d.id} className="flex items-center gap-3 bg-white border border-gray-100 rounded-xl px-4 py-3">
              <div className="w-8 h-8 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center text-xs font-bold flex-shrink-0">
                {d.code ? d.code.slice(0, 3) : d.name.slice(0, 2).toUpperCase()}
              </div>
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900">{d.name}</p>
                {d.code && <p className="text-xs text-gray-400">Code: {d.code}</p>}
              </div>
              <span className="text-xs text-gray-400">{d.employee_count} employee{d.employee_count !== 1 ? 's' : ''}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

function CostCentresTab({ companyId }: { companyId: string }) {
  const qc = useQueryClient()
  const [form, setForm] = useState({ name: '', code: '', description: '', department_id: '' })
  const [err, setErr] = useState('')

  const { data: ccs = [], isLoading } = useQuery<CostCentre[]>({
    queryKey: ['company-ccs', companyId],
    queryFn:  () => get(`/admin/companies/${companyId}/cost-centres`),
  })
  const { data: depts = [] } = useQuery<Department[]>({
    queryKey: ['company-depts', companyId],
    queryFn:  () => get(`/admin/companies/${companyId}/departments`),
  })

  const create = useMutation({
    mutationFn: () => post(`/admin/companies/${companyId}/cost-centres`, {
      name: form.name, code: form.code, description: form.description || undefined,
      department_id: form.department_id || undefined,
    }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['company-ccs', companyId] }); setForm({ name: '', code: '', description: '', department_id: '' }); setErr('') },
    onError:   (e: any) => setErr(e?.message ?? 'Failed'),
  })

  if (isLoading) return <div className="flex justify-center py-8"><Loader2 className="w-5 h-5 animate-spin text-brand-500" /></div>

  return (
    <div className="space-y-4">
      {err && <div className="bg-red-50 border border-red-200 text-red-700 text-xs px-3 py-2 rounded-lg">{err}</div>}

      {/* Add cost centre */}
      <div className="grid grid-cols-2 gap-3 bg-white border border-brand-100 rounded-xl p-3">
        <div>
          <label className="text-xs text-gray-500 mb-1 block">Cost centre name *</label>
          <input className="input" placeholder="e.g. Engineering Travel" value={form.name}
            onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))} />
        </div>
        <div>
          <label className="text-xs text-gray-500 mb-1 block">Code * (unique per company)</label>
          <input className="input" placeholder="ENG-TRV" value={form.code}
            onChange={(e) => setForm((p) => ({ ...p, code: e.target.value.toUpperCase() }))} />
        </div>
        <div>
          <label className="text-xs text-gray-500 mb-1 block">Link to department</label>
          <select className="input" value={form.department_id} onChange={(e) => setForm((p) => ({ ...p, department_id: e.target.value }))}>
            <option value="">— None —</option>
            {depts.map((d) => <option key={d.id} value={d.id}>{d.name}</option>)}
          </select>
        </div>
        <div>
          <label className="text-xs text-gray-500 mb-1 block">Description</label>
          <input className="input" placeholder="Optional description" value={form.description}
            onChange={(e) => setForm((p) => ({ ...p, description: e.target.value }))} />
        </div>
        <div className="col-span-2 flex justify-end">
          <button onClick={() => create.mutate()} disabled={create.isPending || !form.name || !form.code} className="btn-primary text-sm">
            {create.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
            Add Cost Centre
          </button>
        </div>
      </div>

      {/* List */}
      {ccs.length === 0 ? (
        <p className="text-sm text-gray-400 text-center py-4">No cost centres yet — add one above</p>
      ) : (
        <div className="space-y-2">
          {ccs.map((c) => (
            <div key={c.id} className="flex items-center gap-3 bg-white border border-gray-100 rounded-xl px-4 py-3">
              <div className="w-8 h-8 rounded-lg bg-green-50 text-green-700 flex items-center justify-center text-[10px] font-bold flex-shrink-0 tracking-tight">
                {c.code.slice(0, 4)}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-gray-900">{c.name}</p>
                <p className="text-xs text-gray-400">
                  {c.code}
                  {c.department && ` · ${c.department}`}
                  {c.description && ` · ${c.description}`}
                </p>
              </div>
              <div className="text-right flex-shrink-0">
                <p className="text-xs text-gray-500">{c.employee_count} staff</p>
                <p className="text-xs text-gray-400">{c.total_bookings} rides</p>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

// ─── Sub-panel: Employees ────────────────────────────────────────────────────

function EmployeeList({ companyId }: { companyId: string }) {
  const qc = useQueryClient()
  const [showRegister, setShowRegister] = useState(false)
  const [showImport, setShowImport] = useState(false)

  const { data = [], isLoading } = useQuery<Employee[]>({
    queryKey: ['company-employees', companyId],
    queryFn:  () => get(`/admin/companies/${companyId}/employees`),
  })

  const terminate = useMutation({
    mutationFn: (employee_id: string) => post(`/admin/companies/${companyId}/employees/terminate`, { employee_id }),
    // A terminated employee may already be assigned to a department/cost
    // centre/branch (set via the mobile-app invite flow, which the web
    // register form here doesn't currently expose) — all four counts need
    // invalidating, or whichever tab the admin has open next shows a stale
    // number until a manual reload.
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['company-employees', companyId] })
      qc.invalidateQueries({ queryKey: ['admin-companies'] })
      qc.invalidateQueries({ queryKey: ['company-depts', companyId] })
      qc.invalidateQueries({ queryKey: ['company-ccs', companyId] })
      qc.invalidateQueries({ queryKey: ['company-branches', companyId] })
    },
  })

  const reinstate = useMutation({
    mutationFn: (employee_id: string) =>
      post<{ claim_url: string | null; emailed: boolean }>(`/admin/companies/${companyId}/employees/reinstate`, { employee_id }),
    onSuccess: (data) => {
      qc.invalidateQueries({ queryKey: ['company-employees', companyId] })
      qc.invalidateQueries({ queryKey: ['admin-companies'] })
      if (!data.emailed && data.claim_url) {
        alert(`Email couldn't be sent — share this activation link directly:\n\n${data.claim_url}`)
      }
    },
  })

  const roleColor: Record<string, string> = {
    company_admin: 'bg-purple-100 text-purple-700', manager: 'bg-blue-100 text-blue-700',
    company_finance: 'bg-green-100 text-green-700', company_hr: 'bg-pink-100 text-pink-700',
    employee: 'bg-gray-100 text-gray-600',
  }

  return (
    <div className="space-y-3">
      <div className="flex justify-end gap-2">
        <button onClick={() => setShowImport(true)} className="btn text-sm bg-white border border-gray-200 hover:bg-gray-50">
          <FileSpreadsheet className="w-4 h-4" /> Bulk import (CSV)
        </button>
        <button onClick={() => setShowRegister(true)} className="btn-primary text-sm">
          <Plus className="w-4 h-4" /> Register employee
        </button>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-8"><Loader2 className="w-5 h-5 animate-spin text-brand-500" /></div>
      ) : !data.length ? (
        <p className="text-sm text-gray-400 py-4 text-center">No employees yet</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead><tr className="text-left border-b border-gray-100">
              {['Name','Email','Role','Joined','Status',''].map((h) => <th key={h} className="pb-2 font-medium text-gray-500 text-xs">{h}</th>)}
            </tr></thead>
            <tbody className="divide-y divide-gray-50">
              {data.map((e) => (
                <tr key={e.id}>
                  <td className="py-2 font-medium text-gray-900">{e.name}</td>
                  <td className="py-2 text-gray-500 text-xs">{e.email}</td>
                  <td className="py-2"><span className={`badge text-xs ${roleColor[e.role] ?? 'bg-gray-100 text-gray-600'}`}>{e.role.replace('_', ' ')}</span></td>
                  <td className="py-2 text-gray-400 text-xs">{fmt.date(e.joined_at)}</td>
                  <td className="py-2"><span className={badge(e.is_active ? 'active' : 'inactive')}>{e.is_active ? 'Active' : 'Terminated'}</span></td>
                  <td className="py-2 text-right">
                    {e.is_active ? (
                      <button
                        onClick={() => { if (confirm(`Terminate ${e.name}? They will immediately lose all employee privileges — pool access, budgets, approvals.`)) terminate.mutate(e.id) }}
                        disabled={terminate.isPending}
                        className="text-xs text-red-500 hover:text-red-700 font-medium">
                        Terminate
                      </button>
                    ) : (
                      <button
                        onClick={() => reinstate.mutate(e.id)}
                        disabled={reinstate.isPending}
                        className="text-xs text-brand-600 hover:text-brand-700 font-medium">
                        {reinstate.isPending && reinstate.variables === e.id ? 'Sending…' : 'Reinstate & resend invite'}
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {showRegister && <RegisterEmployeeModal companyId={companyId} onClose={() => setShowRegister(false)} />}
      {showImport && <ImportEmployeesCsvModal companyId={companyId} onClose={() => setShowImport(false)} />}
    </div>
  )
}

interface CsvRowResult { row: number; name: string; status: 'created' | 'linked' | 'error'; message: string }
interface CsvImportResult { total: number; created: number; linked: number; errored: number; results: CsvRowResult[] }

function ImportEmployeesCsvModal({ companyId, onClose }: { companyId: string; onClose: () => void }) {
  const qc = useQueryClient()
  const [file, setFile] = useState<File | null>(null)
  const [result, setResult] = useState<CsvImportResult | null>(null)

  const importCsv = useMutation({
    mutationFn: () => {
      const form = new FormData()
      form.append('file', file as File)
      return post<CsvImportResult>(`/admin/companies/${companyId}/employees/import-csv`, form)
    },
    onSuccess: (data) => {
      setResult(data)
      qc.invalidateQueries({ queryKey: ['company-employees', companyId] })
      qc.invalidateQueries({ queryKey: ['admin-companies'] })
      // New department rows may have been auto-created (see
      // importEmployeesCsv on the backend) — refresh that list too so the
      // Departments tab reflects them without a manual reload.
      qc.invalidateQueries({ queryKey: ['company-depts', companyId] })
    },
  })

  const downloadTemplate = async () => {
    const res = await api.get(`/admin/companies/${companyId}/employees/import-template`, { responseType: 'blob' })
    const url = URL.createObjectURL(res.data)
    const a = document.createElement('a')
    a.href = url
    a.download = 'employee_import_template.csv'
    a.click()
    URL.revokeObjectURL(url)
  }

  if (result) {
    return (
      <Modal open onClose={onClose} title="Import results" size="md">
        <div className="space-y-3">
          <div className="grid grid-cols-3 gap-2 text-center">
            <div className="bg-green-50 border border-green-200 rounded-lg py-2">
              <p className="text-lg font-bold text-green-700">{result.created}</p>
              <p className="text-xs text-green-600">Created</p>
            </div>
            <div className="bg-blue-50 border border-blue-200 rounded-lg py-2">
              <p className="text-lg font-bold text-blue-700">{result.linked}</p>
              <p className="text-xs text-blue-600">Linked existing</p>
            </div>
            <div className="bg-red-50 border border-red-200 rounded-lg py-2">
              <p className="text-lg font-bold text-red-700">{result.errored}</p>
              <p className="text-xs text-red-600">Errors</p>
            </div>
          </div>
          <div className="max-h-64 overflow-y-auto border border-gray-100 rounded-lg divide-y divide-gray-50">
            {result.results.map((r) => (
              <div key={r.row} className="flex items-center gap-2 px-3 py-2 text-xs">
                <span className="text-gray-400 w-10 flex-shrink-0">Row {r.row}</span>
                <span className="font-medium text-gray-900 flex-shrink-0 max-w-[120px] truncate">{r.name || '—'}</span>
                <span className={cn(
                  'ml-auto flex-shrink-0',
                  r.status === 'created' ? 'text-green-600' : r.status === 'linked' ? 'text-blue-600' : 'text-red-600',
                )}>{r.message}</span>
              </div>
            ))}
          </div>
          <button onClick={onClose} className="btn-primary w-full justify-center">Done</button>
        </div>
      </Modal>
    )
  }

  return (
    <Modal open onClose={onClose} title="Bulk import employees" size="sm">
      <div className="space-y-3">
        {importCsv.isError && (
          <div className="bg-red-50 border border-red-200 text-red-700 text-xs px-3 py-2 rounded-lg">
            {(importCsv.error as Error).message}
          </div>
        )}
        <p className="text-xs text-gray-500">
          Upload a CSV of new hires — each row registers an employee and sends an activation
          invite. A <code className="bg-gray-100 px-1 rounded">department</code> column is
          optional; if the department named doesn't exist yet, it's created automatically.
        </p>
        <button onClick={downloadTemplate} type="button" className="btn text-sm bg-white border border-gray-200 hover:bg-gray-50 w-full justify-center">
          <Download className="w-4 h-4" /> Download CSV template
        </button>
        <label className="flex flex-col items-center justify-center gap-2 border-2 border-dashed border-gray-200 rounded-xl py-6 cursor-pointer hover:border-brand-300 hover:bg-brand-50/30 transition-colors">
          <Upload className="w-6 h-6 text-gray-400" />
          <span className="text-sm text-gray-600">{file ? file.name : 'Click to choose a CSV file'}</span>
          <input type="file" accept=".csv,text/csv" className="hidden"
            onChange={(e) => setFile(e.target.files?.[0] ?? null)} />
        </label>
        <button onClick={() => importCsv.mutate()} disabled={!file || importCsv.isPending} className="btn-primary w-full justify-center">
          {importCsv.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Import'}
        </button>
      </div>
    </Modal>
  )
}

function RegisterEmployeeModal({ companyId, onClose }: { companyId: string; onClose: () => void }) {
  const qc = useQueryClient()
  const [form, setForm] = useState({ name: '', work_email: '', mobile: '', personal_email: '', nin: '', passport_number: '', role: 'employee', department_id: '' })
  const [err, setErr] = useState('')
  const [result, setResult] = useState<{ claim_url: string | null; emailed: boolean; already_had_account: boolean } | null>(null)
  const identityValid = (!!form.nin) !== (!!form.passport_number) // exactly one, not both, not neither

  const { data: departments = [] } = useQuery<Department[]>({
    queryKey: ['company-depts', companyId],
    queryFn:  () => get(`/admin/companies/${companyId}/departments`),
  })

  const register = useMutation({
    mutationFn: () => post<{ claim_url: string | null; emailed: boolean; already_had_account: boolean }>(
      `/admin/companies/${companyId}/employees/register`,
      { ...form, personal_email: form.personal_email || undefined, department_id: form.department_id || undefined },
    ),
    onSuccess: (data) => {
      qc.invalidateQueries({ queryKey: ['company-employees', companyId] })
      qc.invalidateQueries({ queryKey: ['admin-companies'] })
      setResult(data)
    },
    onError: (e: any) => setErr(e?.message ?? 'Failed to register employee'),
  })

  if (result) {
    return (
      <Modal open onClose={onClose} title="Employee registered" size="sm">
        <div className="space-y-3 text-sm">
          {result.already_had_account ? (
            <p className="text-gray-600">This person already had a CC Ride account (matched by NIN/passport) and has been added as an employee — no invite needed.</p>
          ) : result.emailed ? (
            <p className="text-gray-600">An activation link was emailed to {form.work_email}.</p>
          ) : (
            <>
              <p className="text-gray-600">Email couldn't be sent — share this activation link with them directly:</p>
              <div className="bg-gray-50 rounded-lg p-3 font-mono text-xs break-all">{result.claim_url}</div>
            </>
          )}
          <button onClick={onClose} className="btn-primary w-full justify-center">Done</button>
        </div>
      </Modal>
    )
  }

  return (
    <Modal open onClose={onClose} title="Register employee" size="sm">
      <div className="space-y-3">
        {err && <div className="bg-red-50 border border-red-200 text-red-700 text-xs px-3 py-2 rounded-lg">{err}</div>}
        <p className="text-xs text-gray-500">They'll receive a link to set their own password and get first access to the app.</p>
        <input className="input" placeholder="Full name" value={form.name} onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))} />
        <input className="input" placeholder="Mobile number" value={form.mobile} onChange={(e) => setForm((p) => ({ ...p, mobile: e.target.value }))} />
        <div>
          <input className="input" placeholder="Work email (invite is sent here)" type="email" value={form.work_email} onChange={(e) => setForm((p) => ({ ...p, work_email: e.target.value }))} />
          <p className="text-[11px] text-gray-400 mt-1">Used for correspondence only — matching an existing account is by NIN/passport, so this can safely differ from the account they already use personally.</p>
        </div>
        <div>
          <p className="text-xs text-gray-500 mb-1">Identity document — NIN if Nigerian, passport number otherwise</p>
          <div className="grid grid-cols-2 gap-2">
            <input className="input" placeholder="11-digit NIN" value={form.nin}
              onChange={(e) => setForm((p) => ({ ...p, nin: e.target.value }))} disabled={!!form.passport_number} />
            <input className="input" placeholder="Passport number" value={form.passport_number}
              onChange={(e) => setForm((p) => ({ ...p, passport_number: e.target.value }))} disabled={!!form.nin} />
          </div>
        </div>
        <input className="input" placeholder="Personal email (optional, if known — helps match an existing account)" type="email" value={form.personal_email} onChange={(e) => setForm((p) => ({ ...p, personal_email: e.target.value }))} />
        <select className="input" value={form.department_id} onChange={(e) => setForm((p) => ({ ...p, department_id: e.target.value }))}>
          <option value="">No department</option>
          {departments.map((d) => <option key={d.id} value={d.id}>{d.name}</option>)}
        </select>
        <select className="input" value={form.role} onChange={(e) => setForm((p) => ({ ...p, role: e.target.value }))}>
          <option value="employee">Employee</option>
          <option value="manager">Manager</option>
          <option value="company_admin">Company Admin</option>
          <option value="company_finance">Company Finance</option>
          <option value="company_hr">Company HR</option>
        </select>
        <button onClick={() => register.mutate()} disabled={register.isPending || !form.name || !form.work_email || !form.mobile || !identityValid} className="btn-primary w-full justify-center">
          {register.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Register & send invite'}
        </button>
      </div>
    </Modal>
  )
}

// ─── Sub-panel: Company rides ────────────────────────────────────────────────

function CompanyRides({ companyId }: { companyId: string }) {
  const [status, setStatus] = useState('all')
  const [addRide, setAddRide] = useState(false)
  const qc = useQueryClient()

  const { data = [], isLoading } = useQuery<CompanyRide[]>({
    queryKey: ['company-rides', companyId, status],
    queryFn:  () => get(`/admin/companies/${companyId}/rides`, { status: status === 'all' ? undefined : status }),
  })
  const cancel = useMutation({
    mutationFn: (id: string) => post('/admin/rides/cancel', { booking_id: id, reason: 'Cancelled by admin' }),
    onSuccess:  () => qc.invalidateQueries({ queryKey: ['company-rides', companyId] }),
  })

  return (
    <div className="space-y-3">
      {addRide && <AddRideModal companyId={companyId} onClose={() => setAddRide(false)} />}

      <div className="flex flex-wrap gap-2 justify-between">
        <div className="flex gap-2 flex-wrap">
          {['all','confirmed','completed','cancelled','in_progress'].map((s) => (
            <button key={s} onClick={() => setStatus(s)}
              className={`px-3 py-1 rounded-lg text-xs font-medium border transition-colors ${status === s ? 'bg-brand-500 text-white border-brand-500' : 'bg-white text-gray-500 border-gray-200 hover:bg-gray-50'}`}>
              {s === 'all' ? 'All' : s.replace('_', ' ')}
            </button>
          ))}
        </div>
        <button onClick={() => setAddRide(true)} className="btn-primary text-xs">
          <Plus className="w-3 h-3" /> Add Ride
        </button>
      </div>

      {isLoading ? <div className="flex justify-center py-8"><Loader2 className="w-5 h-5 animate-spin text-brand-500" /></div> :
        !data.length ? <p className="text-sm text-gray-400 py-4 text-center">No rides found</p> : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead><tr className="text-left border-b border-gray-100">
                {['Passenger','Driver','Route','Amount','Status','Date',''].map((h) => <th key={h} className="pb-2 font-medium text-gray-500 text-xs">{h}</th>)}
              </tr></thead>
              <tbody className="divide-y divide-gray-50">
                {data.map((r) => (
                  <tr key={r.id}>
                    <td className="py-2 font-medium text-gray-900">{r.passenger}</td>
                    <td className="py-2 text-gray-500 text-xs">{r.driver}</td>
                    <td className="py-2 text-gray-500 text-xs">
                      {r.origin.split(',')[0]} <span className="text-gray-300">→</span> {r.destination.split(',')[0]}
                    </td>
                    <td className="py-2 font-medium">{fmt.naira(r.total_amount)}</td>
                    <td className="py-2"><span className={badge(r.status)}>{r.status}</span></td>
                    <td className="py-2 text-gray-400 text-xs">{fmt.date(r.created_at)}</td>
                    <td className="py-2">
                      {['confirmed','pending','in_progress'].includes(r.status) && (
                        <button onClick={() => { if (confirm('Cancel this ride?')) cancel.mutate(r.id) }}
                          className="text-xs text-red-500 hover:text-red-700 font-medium">Cancel</button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
    </div>
  )
}

// ─── Branches Tab ────────────────────────────────────────────────────────────

function BranchesTab({ company }: { company: Company }) {
  const qc = useQueryClient()
  const [showAddBranch, setShowAddBranch] = useState(false)
  const [showAddRegion, setShowAddRegion] = useState(false)
  const [editBranch, setEditBranch]       = useState<Branch | null>(null)
  const [showAdmins, setShowAdmins]       = useState<Branch | null>(null)

  const { data: regions = [], isLoading: loadingRegions } = useQuery<Region[]>({
    queryKey: ['company-regions', company.id],
    queryFn:  () => get(`/admin/companies/${company.id}/regions`),
  })
  const { data: branches = [], isLoading: loadingBranches } = useQuery<Branch[]>({
    queryKey: ['company-branches', company.id],
    queryFn:  () => get(`/admin/companies/${company.id}/branches`),
  })

  const toggle = useMutation({
    mutationFn: (b: Branch) => api.patch(`/admin/companies/${company.id}/branches/${b.id}`, { is_active: !b.is_active }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['company-branches', company.id] }),
  })

  const isLoading = loadingRegions || loadingBranches

  // Group branches by region
  const unzoned = branches.filter(b => !b.region_id)
  const byRegion = regions.map(r => ({
    region: r,
    branches: branches.filter(b => b.region_id === r.id),
  })).filter(g => g.branches.length > 0)

  const BranchCard = ({ b }: { b: Branch }) => (
    <div className={`bg-white border rounded-xl p-4 space-y-2 ${b.is_headquarters ? 'border-brand-300' : 'border-gray-100'}`}>
      <div className="flex items-start justify-between gap-2">
        <div className="flex items-center gap-2 min-w-0">
          {b.is_headquarters && (
            <span className="flex-shrink-0 text-[10px] font-bold uppercase tracking-wide bg-brand-100 text-brand-700 px-2 py-0.5 rounded-full">HQ</span>
          )}
          <p className="font-semibold text-gray-900 truncate">{b.name}</p>
          {b.code && <span className="text-xs text-gray-400 font-mono flex-shrink-0">{b.code}</span>}
        </div>
        <div className="flex items-center gap-1 flex-shrink-0">
          <button onClick={() => setEditBranch(b)} className="p-1.5 rounded-lg hover:bg-gray-100 text-gray-400 hover:text-gray-600" title="Edit">
            <Edit2 className="w-3.5 h-3.5" />
          </button>
          <button onClick={() => setShowAdmins(b)} className="p-1.5 rounded-lg hover:bg-gray-100 text-gray-400 hover:text-blue-600" title="Admins">
            <UserPlus className="w-3.5 h-3.5" />
          </button>
          <button onClick={() => toggle.mutate(b)} className="p-1.5 rounded-lg hover:bg-gray-100" title={b.is_active ? 'Deactivate' : 'Activate'}>
            {b.is_active
              ? <ToggleRight className="w-4 h-4 text-green-500" />
              : <ToggleLeft  className="w-4 h-4 text-gray-300" />}
          </button>
        </div>
      </div>

      {(b.city || b.state) && (
        <p className="text-xs text-gray-500 flex items-center gap-1">
          <MapPin className="w-3 h-3 flex-shrink-0" />
          {[b.address, b.city, b.state].filter(Boolean).join(', ')}
        </p>
      )}

      <div className="flex items-center gap-4 text-xs text-gray-500 pt-1 border-t border-gray-50">
        <span><Users className="w-3 h-3 inline mr-1" />{b.employee_count} staff</span>
        <span><Car className="w-3 h-3 inline mr-1" />{b.booking_count} rides</span>
        <span className="ml-auto font-semibold text-brand-600">₦{Number(b.wallet_balance).toLocaleString()}</span>
        {b.billed_separately && <span className="bg-purple-50 text-purple-600 px-1.5 py-0.5 rounded text-[10px] font-medium">Billed separately</span>}
      </div>
    </div>
  )

  return (
    <div className="space-y-4">
      {showAddBranch && <AddBranchModal companyId={company.id} regions={regions} onClose={() => { setShowAddBranch(false); qc.invalidateQueries({ queryKey: ['company-branches', company.id] }) }} />}
      {showAddRegion && <AddRegionModal companyId={company.id} onClose={() => { setShowAddRegion(false); qc.invalidateQueries({ queryKey: ['company-regions', company.id] }) }} />}
      {editBranch && <EditBranchModal branch={editBranch} companyId={company.id} regions={regions} onClose={() => { setEditBranch(null); qc.invalidateQueries({ queryKey: ['company-branches', company.id] }) }} />}
      {showAdmins && <BranchAdminsModal branch={showAdmins} companyId={company.id} onClose={() => setShowAdmins(null)} />}

      <div className="flex flex-wrap gap-2 justify-between items-center">
        <p className="text-sm text-gray-500">{branches.length} branch{branches.length !== 1 ? 'es' : ''} · {regions.length} region{regions.length !== 1 ? 's' : ''}</p>
        <div className="flex gap-2">
          <button onClick={() => setShowAddRegion(true)} className="btn-secondary text-xs"><Globe className="w-3.5 h-3.5" /> Add Region</button>
          <button onClick={() => setShowAddBranch(true)} className="btn-primary text-xs"><Plus className="w-3.5 h-3.5" /> Add Branch</button>
        </div>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-8"><Loader2 className="w-5 h-5 animate-spin text-brand-500" /></div>
      ) : branches.length === 0 ? (
        <p className="text-sm text-gray-400 text-center py-6">No branches yet — add one above</p>
      ) : (
        <div className="space-y-5">
          {/* Unzoned branches */}
          {unzoned.length > 0 && (
            <div className="space-y-2">
              <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide">No Region</p>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                {unzoned.map(b => <BranchCard key={b.id} b={b} />)}
              </div>
            </div>
          )}
          {/* Grouped by region */}
          {byRegion.map(({ region, branches: rBranches }) => (
            <div key={region.id} className="space-y-2">
              <div className="flex items-center gap-2">
                <Globe className="w-3.5 h-3.5 text-brand-400" />
                <p className="text-xs font-semibold text-brand-600 uppercase tracking-wide">{region.name}</p>
                {region.code && <span className="text-xs text-gray-400 font-mono">{region.code}</span>}
                <span className="text-xs text-gray-400">· {rBranches.length} branch{rBranches.length !== 1 ? 'es' : ''}</span>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                {rBranches.map(b => <BranchCard key={b.id} b={b} />)}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

function AddRegionModal({ companyId, onClose }: { companyId: string; onClose: () => void }) {
  const [form, setForm] = useState({ name: '', code: '' })
  const [err, setErr] = useState('')
  const create = useMutation({
    mutationFn: () => post(`/admin/companies/${companyId}/regions`, form),
    onSuccess: onClose,
    onError: (e: any) => setErr(e?.message ?? 'Failed'),
  })
  return (
    <Modal open={true} onClose={onClose} title="Add Region / Zone">
      <div className="space-y-4">
        {err && <div className="bg-red-50 border border-red-200 text-red-700 text-sm px-3 py-2 rounded-lg">{err}</div>}
        <Field label="Region Name *"><input className="input" placeholder="e.g. South-West Zone" value={form.name} onChange={e => setForm(p => ({ ...p, name: e.target.value }))} /></Field>
        <Field label="Code (optional)"><input className="input" placeholder="e.g. SW" value={form.code} onChange={e => setForm(p => ({ ...p, code: e.target.value.toUpperCase() }))} /></Field>
        <div className="flex gap-3 pt-2">
          <button onClick={onClose} className="btn-secondary flex-1">Cancel</button>
          <button onClick={() => create.mutate()} disabled={create.isPending || !form.name} className="btn-primary flex-1">
            {create.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Globe className="w-4 h-4" />} Add Region
          </button>
        </div>
      </div>
    </Modal>
  )
}

function BranchForm({ initial, regions, onSubmit, loading, err, submitLabel }: {
  initial: any; regions: Region[]
  onSubmit: (form: any) => void; loading: boolean; err: string; submitLabel: string
}) {
  const [form, setForm] = useState(initial)
  const f = (k: string) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) =>
    setForm((p: any) => ({ ...p, [k]: e.target.value }))
  const chk = (k: string) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setForm((p: any) => ({ ...p, [k]: e.target.checked }))

  return (
    <div className="space-y-4">
      {err && <div className="bg-red-50 border border-red-200 text-red-700 text-sm px-3 py-2 rounded-lg">{err}</div>}
      <div className="grid grid-cols-2 gap-3">
        <Field label="Branch Name *"><input className="input" placeholder="e.g. Victoria Island" value={form.name} onChange={f('name')} /></Field>
        <Field label="Code"><input className="input" placeholder="e.g. VGC-001" value={form.code} onChange={e => setForm((p: any) => ({ ...p, code: e.target.value.toUpperCase() }))} /></Field>
      </div>
      <Field label="Region / Zone">
        <select className="input" value={form.region_id} onChange={f('region_id')}>
          <option value="">— No region —</option>
          {regions.map(r => <option key={r.id} value={r.id}>{r.name}</option>)}
        </select>
      </Field>
      <div className="grid grid-cols-3 gap-3">
        <Field label="Address"><input className="input" placeholder="Street" value={form.address} onChange={f('address')} /></Field>
        <Field label="City"><input className="input" placeholder="Lagos" value={form.city} onChange={f('city')} /></Field>
        <Field label="State">
          <select className="input" value={form.state} onChange={f('state')}>
            {['Lagos','Abuja','Rivers','Kano','Oyo','Delta','Ogun','Anambra','Enugu','Kaduna'].map(s => <option key={s}>{s}</option>)}
          </select>
        </Field>
      </div>
      <div className="grid grid-cols-3 gap-3">
        <Field label="Contact Name"><input className="input" value={form.contact_name} onChange={f('contact_name')} /></Field>
        <Field label="Contact Phone"><input className="input" value={form.contact_phone} onChange={f('contact_phone')} /></Field>
        <Field label="Contact Email"><input className="input" type="email" value={form.contact_email} onChange={f('contact_email')} /></Field>
      </div>
      <div className="flex gap-6 pt-1">
        <label className="flex items-center gap-2 cursor-pointer text-sm text-gray-700">
          <input type="checkbox" className="accent-brand-500" checked={form.is_headquarters} onChange={chk('is_headquarters')} />
          Headquarters
        </label>
        <label className="flex items-center gap-2 cursor-pointer text-sm text-gray-700">
          <input type="checkbox" className="accent-purple-500" checked={form.billed_separately} onChange={chk('billed_separately')} />
          Billed separately
        </label>
      </div>
      <div className="flex gap-3 pt-2">
        <button type="button" className="btn-secondary flex-1" onClick={() => onSubmit(null)}>Cancel</button>
        <button type="button" onClick={() => onSubmit(form)} disabled={loading || !form.name} className="btn-primary flex-1">
          {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <GitBranch className="w-4 h-4" />} {submitLabel}
        </button>
      </div>
    </div>
  )
}

function AddBranchModal({ companyId, regions, onClose }: { companyId: string; regions: Region[]; onClose: () => void }) {
  const [err, setErr] = useState('')
  const create = useMutation({
    mutationFn: (form: any) => post(`/admin/companies/${companyId}/branches`, form),
    onSuccess: onClose,
    onError: (e: any) => setErr(e?.message ?? 'Failed'),
  })
  return (
    <Modal open={true} onClose={onClose} title="Add Branch" size="lg">
      <BranchForm
        initial={{ name: '', code: '', region_id: '', address: '', city: '', state: 'Lagos', contact_name: '', contact_phone: '', contact_email: '', is_headquarters: false, billed_separately: false }}
        regions={regions} loading={create.isPending} err={err} submitLabel="Create Branch"
        onSubmit={form => { if (!form) { onClose(); return } create.mutate(form) }}
      />
    </Modal>
  )
}

function EditBranchModal({ branch, companyId, regions, onClose }: { branch: Branch; companyId: string; regions: Region[]; onClose: () => void }) {
  const [err, setErr] = useState('')
  const update = useMutation({
    mutationFn: (form: any) => api.patch(`/admin/companies/${companyId}/branches/${branch.id}`, form),
    onSuccess: onClose,
    onError: (e: any) => setErr(e?.message ?? 'Failed'),
  })
  return (
    <Modal open={true} onClose={onClose} title={`Edit — ${branch.name}`} size="lg">
      <BranchForm
        initial={{ name: branch.name, code: branch.code ?? '', region_id: branch.region_id ?? '', address: branch.address ?? '', city: branch.city ?? '', state: branch.state, contact_name: branch.contact_name ?? '', contact_phone: branch.contact_phone ?? '', contact_email: branch.contact_email ?? '', is_headquarters: branch.is_headquarters, billed_separately: branch.billed_separately }}
        regions={regions} loading={update.isPending} err={err} submitLabel="Save Changes"
        onSubmit={form => { if (!form) { onClose(); return } update.mutate(form) }}
      />
    </Modal>
  )
}

function BranchAdminsModal({ branch, companyId, onClose }: { branch: Branch; companyId: string; onClose: () => void }) {
  const qc = useQueryClient()
  const [form, setForm] = useState({ username: '', email: '', password: '' })
  const [err, setErr] = useState('')

  const { data: admins = [], isLoading } = useQuery<any[]>({
    queryKey: ['branch-admins', branch.id],
    queryFn:  () => get(`/admin/companies/${companyId}/admins?branch_id=${branch.id}`),
  })

  const create = useMutation({
    mutationFn: () => post(`/admin/companies/${companyId}/admins`, { ...form, branch_id: branch.id }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['branch-admins', branch.id] }); setForm({ username: '', email: '', password: '' }); setErr('') },
    onError: (e: any) => setErr(e?.message ?? 'Failed'),
  })

  return (
    <Modal open={true} onClose={onClose} title={`Branch Admins — ${branch.name}`} size="lg">
      <div className="space-y-5">
        {/* Existing admins */}
        {isLoading ? <div className="flex justify-center py-4"><Loader2 className="w-5 h-5 animate-spin text-brand-500" /></div>
          : admins.length === 0 ? <p className="text-sm text-gray-400 text-center py-2">No admins yet</p>
          : (
            <div className="space-y-2">
              {admins.map((a: any) => (
                <div key={a.id} className="flex items-center gap-3 bg-gray-50 rounded-xl px-4 py-2.5 text-sm">
                  <div className="w-7 h-7 rounded-full bg-brand-100 text-brand-700 flex items-center justify-center text-xs font-bold flex-shrink-0">
                    {a.username[0].toUpperCase()}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-gray-900">{a.username}</p>
                    <p className="text-xs text-gray-400">{a.email}</p>
                  </div>
                  <span className={`text-xs px-2 py-0.5 rounded-full ${a.is_active ? 'bg-green-50 text-green-700' : 'bg-gray-100 text-gray-400'}`}>{a.is_active ? 'Active' : 'Inactive'}</span>
                  {a.last_login_at && <span className="text-xs text-gray-400 hidden sm:block">Last: {fmt.date(a.last_login_at)}</span>}
                </div>
              ))}
            </div>
          )}

        {/* Add admin */}
        <div className="border-t border-gray-100 pt-4 space-y-3">
          <p className="text-sm font-semibold text-gray-700">Add Admin</p>
          {err && <div className="bg-red-50 border border-red-200 text-red-700 text-xs px-3 py-2 rounded-lg">{err}</div>}
          <div className="grid grid-cols-2 gap-3">
            <Field label="Username"><input className="input" placeholder="branch.vi.admin" value={form.username} onChange={e => setForm(p => ({ ...p, username: e.target.value }))} /></Field>
            <Field label="Email"><input className="input" type="email" placeholder="admin@company.com" value={form.email} onChange={e => setForm(p => ({ ...p, email: e.target.value }))} /></Field>
          </div>
          <Field label="Temporary Password"><input className="input" type="password" placeholder="Min 8 characters" value={form.password} onChange={e => setForm(p => ({ ...p, password: e.target.value }))} /></Field>
          <button onClick={() => create.mutate()} disabled={create.isPending || !form.username || !form.email || !form.password} className="btn-primary w-full text-sm">
            {create.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <UserPlus className="w-4 h-4" />} Create Admin Account
          </button>
        </div>
        <button onClick={onClose} className="btn-secondary w-full text-sm">Close</button>
      </div>
    </Modal>
  )
}

// ─── Credit Company Modal ─────────────────────────────────────────────────────

function CreditModal({ company, onClose }: { company: Company; onClose: () => void }) {
  const qc = useQueryClient()
  const [form, setForm] = useState({ amount: '', payment_method: 'bank_transfer', reference: '', note: '' })
  const [err, setErr] = useState('')

  const credit = useMutation({
    mutationFn: () => post(`/admin/companies/${company.id}/credit`, {
      amount: parseFloat(form.amount),
      payment_method: form.payment_method,
      reference: form.reference || undefined,
      note: form.note || undefined,
    }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-companies'] })
      qc.invalidateQueries({ queryKey: ['company-credits', company.id] })
      onClose()
    },
    onError: (e: any) => setErr(e?.message ?? 'Failed to credit account'),
  })

  return (
    <Modal open={true} onClose={onClose} title={`Credit Account — ${company.name}`}>
      <div className="space-y-4">
        <div className="flex items-center gap-3 bg-brand-50 border border-brand-100 rounded-xl px-4 py-3">
          <Wallet className="w-5 h-5 text-brand-500 flex-shrink-0" />
          <div>
            <p className="text-xs text-gray-500">Current wallet balance</p>
            <p className="text-lg font-bold text-brand-700">₦{Number(company.wallet_balance ?? 0).toLocaleString('en-NG', { minimumFractionDigits: 2 })}</p>
          </div>
        </div>

        {err && <div className="bg-red-50 border border-red-200 text-red-700 text-sm px-3 py-2 rounded-lg">{err}</div>}

        <Field label="Amount (₦) *">
          <input className="input" type="number" min="1" placeholder="e.g. 500000"
            value={form.amount} onChange={(e) => setForm((p) => ({ ...p, amount: e.target.value }))} />
        </Field>

        <Field label="Payment Method *">
          <select className="input" value={form.payment_method} onChange={(e) => setForm((p) => ({ ...p, payment_method: e.target.value }))}>
            <option value="bank_transfer">Bank Transfer</option>
            <option value="cheque">Cheque</option>
            <option value="cash">Cash</option>
            <option value="pos">POS</option>
            <option value="other">Other</option>
          </select>
        </Field>

        <Field label="Payment Reference / Cheque No.">
          <input className="input" placeholder="e.g. TRF-2026062400123"
            value={form.reference} onChange={(e) => setForm((p) => ({ ...p, reference: e.target.value }))} />
        </Field>

        <Field label="Internal Note">
          <input className="input" placeholder="e.g. June prepayment for 50 rides"
            value={form.note} onChange={(e) => setForm((p) => ({ ...p, note: e.target.value }))} />
        </Field>

        {form.amount && !isNaN(parseFloat(form.amount)) && (
          <div className="bg-green-50 border border-green-200 text-green-800 text-sm px-4 py-2.5 rounded-lg">
            New balance after credit: <strong>₦{(Number(company.wallet_balance ?? 0) + parseFloat(form.amount)).toLocaleString('en-NG', { minimumFractionDigits: 2 })}</strong>
          </div>
        )}

        <div className="flex gap-3 pt-2">
          <button onClick={onClose} className="btn-secondary flex-1">Cancel</button>
          <button onClick={() => credit.mutate()} disabled={credit.isPending || !form.amount || parseFloat(form.amount) <= 0}
            className="btn-primary flex-1">
            {credit.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Wallet className="w-4 h-4" />}
            Credit Account
          </button>
        </div>
      </div>
    </Modal>
  )
}

// ─── Credit Ledger Tab ────────────────────────────────────────────────────────

function CreditLedgerTab({ company }: { company: Company }) {
  const { data, isLoading } = useQuery<{ wallet_balance: number; credits: CreditEntry[]; total: number }>({
    queryKey: ['company-credits', company.id],
    queryFn:  () => get(`/admin/companies/${company.id}/credits`),
  })
  const [creditOpen, setCreditOpen] = useState(false)

  const methodLabel: Record<string, string> = {
    bank_transfer: 'Bank Transfer', cheque: 'Cheque', cash: 'Cash', pos: 'POS', other: 'Other',
  }

  return (
    <div className="space-y-4">
      {creditOpen && <CreditModal company={{ ...company, wallet_balance: data?.wallet_balance ?? company.wallet_balance }} onClose={() => setCreditOpen(false)} />}

      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3 bg-brand-50 border border-brand-100 rounded-xl px-4 py-2.5">
          <Wallet className="w-4 h-4 text-brand-500" />
          <span className="text-sm text-gray-600">Wallet balance:</span>
          <span className="font-bold text-brand-700">₦{Number(data?.wallet_balance ?? company.wallet_balance ?? 0).toLocaleString('en-NG', { minimumFractionDigits: 2 })}</span>
        </div>
        <button onClick={() => setCreditOpen(true)} className="btn-primary text-sm">
          <Plus className="w-4 h-4" /> Credit Account
        </button>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-8"><Loader2 className="w-5 h-5 animate-spin text-brand-500" /></div>
      ) : !data?.credits.length ? (
        <p className="text-sm text-gray-400 text-center py-6">No credits recorded yet</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left border-b border-gray-100">
                {['Date', 'Amount', 'Balance After', 'Method', 'Reference', 'Note', 'By'].map((h) => (
                  <th key={h} className="pb-2 font-medium text-gray-500 text-xs">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {data.credits.map((c) => (
                <tr key={c.id}>
                  <td className="py-2 text-gray-400 text-xs whitespace-nowrap">{fmt.date(c.created_at)}</td>
                  <td className="py-2 font-semibold text-green-600">+₦{Number(c.amount).toLocaleString('en-NG', { minimumFractionDigits: 2 })}</td>
                  <td className="py-2 text-gray-700">₦{Number(c.balance_after).toLocaleString('en-NG', { minimumFractionDigits: 2 })}</td>
                  <td className="py-2"><span className="badge bg-blue-50 text-blue-700 text-xs">{methodLabel[c.payment_method] ?? c.payment_method}</span></td>
                  <td className="py-2 text-gray-500 text-xs font-mono">{c.reference ?? '—'}</td>
                  <td className="py-2 text-gray-500 text-xs max-w-[160px] truncate">{c.note ?? '—'}</td>
                  <td className="py-2 text-gray-400 text-xs">{c.credited_by}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

// ─── Pool policy tab ────────────────────────────────────────────────────────

interface PoolPolicy { allow_external_sharing: boolean; daily_limit: number | null; weekly_limit: number | null; monthly_limit: number | null }
interface SharingAgreement {
  id: string; partner_company_id: string; partner_company_name: string; partner_company_logo_url: string | null
  branch_id: string | null; branch_name: string | null
  is_active: boolean; created_at: string
}
interface EmployeePoolAccess {
  id: string; name: string; email: string; job_title: string
  pool_access_enabled: boolean; pool_daily_limit: number | null; pool_weekly_limit: number | null; pool_monthly_limit: number | null
  pool_access_days_of_week: number[]; pool_access_time_from: string | null; pool_access_time_to: string | null
  wallet_access_enabled: boolean
  wallet_access_days_of_week: number[]; wallet_access_time_from: string | null; wallet_access_time_to: string | null
}
interface AccessRequest {
  id: string; employee_id: string; employee_name: string; employee_email: string
  request_type: 'pool_car' | 'wallet_payment'; status: 'pending' | 'approved' | 'denied'
  note: string | null; requested_at: string
}
const ACCESS_DAYS = [{ v: 1, l: 'Mon' }, { v: 2, l: 'Tue' }, { v: 3, l: 'Wed' }, { v: 4, l: 'Thu' }, { v: 5, l: 'Fri' }, { v: 6, l: 'Sat' }, { v: 7, l: 'Sun' }]

function TimeWindowFields({ days, setDays, from, setFrom, to, setTo }: {
  days: number[]; setDays: (d: number[]) => void
  from: string; setFrom: (v: string) => void
  to: string; setTo: (v: string) => void
}) {
  return (
    <div className="space-y-2">
      <p className="text-xs text-gray-400 flex items-center gap-1"><Clock className="w-3 h-3" /> Available hours — leave blank for no restriction</p>
      <div className="flex gap-1">
        {ACCESS_DAYS.map((d) => (
          <button key={d.v} type="button" onClick={() => setDays(days.includes(d.v) ? days.filter((x) => x !== d.v) : [...days, d.v])}
            className={cn('w-8 h-8 rounded-md text-[10px] font-medium border transition-colors',
              days.includes(d.v) ? 'border-brand-500 bg-brand-50 text-brand-600' : 'border-gray-200 text-gray-400')}>
            {d.l}
          </button>
        ))}
      </div>
      <div className="grid grid-cols-2 gap-2">
        <input type="time" className="input" value={from} onChange={(e) => setFrom(e.target.value)} />
        <input type="time" className="input" value={to} onChange={(e) => setTo(e.target.value)} />
      </div>
    </div>
  )
}

function PoolPolicyTab({ companyId }: { companyId: string }) {
  const qc = useQueryClient()
  const [err, setErr] = useState('')
  const [showAddPartner, setShowAddPartner] = useState(false)
  const [editingEmployee, setEditingEmployee] = useState<EmployeePoolAccess | null>(null)

  const { data: policy, isLoading: policyLoading } = useQuery<PoolPolicy>({
    queryKey: ['pool-policy', companyId],
    queryFn: () => get(`/admin/companies/${companyId}/pool-policy`),
  })
  const { data: agreements = [], isLoading: agreementsLoading } = useQuery<SharingAgreement[]>({
    queryKey: ['pool-sharing', companyId],
    queryFn: () => get(`/admin/companies/${companyId}/pool-sharing`),
  })
  const { data: employees = [], isLoading: employeesLoading } = useQuery<EmployeePoolAccess[]>({
    queryKey: ['employee-pool-access', companyId],
    queryFn: () => get(`/admin/companies/${companyId}/employees/pool-access`),
  })
  const { data: requests = [] } = useQuery<AccessRequest[]>({
    queryKey: ['access-requests', companyId],
    queryFn: () => get(`/admin/companies/${companyId}/access-requests`, { status: 'pending' }),
  })

  const decide = useMutation({
    mutationFn: ({ id, approve }: { id: string; approve: boolean }) =>
      api.patch(`/admin/companies/${companyId}/access-requests/${id}/decide`, { approve }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['access-requests', companyId] })
      qc.invalidateQueries({ queryKey: ['employee-pool-access', companyId] })
    },
  })

  const updatePolicy = useMutation({
    mutationFn: (patch: Partial<PoolPolicy>) => api.patch(`/admin/companies/${companyId}/pool-policy`, patch),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['pool-policy', companyId] }); setErr('') },
    onError: (e: any) => setErr(e?.response?.data?.ResponseMsg ?? 'Failed to update policy'),
  })

  const revokeAgreement = useMutation({
    mutationFn: (agreementId: string) => api.patch(`/admin/companies/${companyId}/pool-sharing/${agreementId}/revoke`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['pool-sharing', companyId] }),
  })

  const activeAgreements = agreements.filter((a) => a.is_active)

  if (policyLoading) return <div className="flex justify-center py-8"><Loader2 className="w-5 h-5 animate-spin text-brand-500" /></div>

  return (
    <div className="space-y-5">
      {err && <div className="bg-red-50 border border-red-200 text-red-700 text-xs px-3 py-2 rounded-lg">{err}</div>}

      {/* Exclusivity + sharing toggle */}
      <div className="bg-white border border-gray-100 rounded-xl p-4">
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-sm font-semibold text-gray-900">Share pool cars with other organisations</p>
            <p className="text-xs text-gray-400 mt-1 max-w-md">
              By default, your pool vehicles only serve your own employees. Turning this on lets you selectively
              open your fleet to specific participating organisations below — it never shares automatically.
            </p>
          </div>
          <button onClick={() => updatePolicy.mutate({ allow_external_sharing: !policy?.allow_external_sharing })}
            disabled={updatePolicy.isPending} className="flex-shrink-0">
            {policy?.allow_external_sharing
              ? <ToggleRight className="w-9 h-9 text-brand-500" />
              : <ToggleLeft className="w-9 h-9 text-gray-300" />}
          </button>
        </div>

        {policy?.allow_external_sharing && (
          <div className="mt-4 pt-4 border-t border-gray-100 space-y-3">
            <div className="flex items-center justify-between">
              <p className="text-xs font-medium text-gray-500">Organisations that can use your pool cars</p>
              <button onClick={() => setShowAddPartner(true)} className="btn-secondary text-xs px-2.5 py-1.5">
                <UserPlus className="w-3.5 h-3.5" /> Add organisation
              </button>
            </div>
            {agreementsLoading ? (
              <Loader2 className="w-4 h-4 animate-spin text-brand-500" />
            ) : activeAgreements.length === 0 ? (
              <p className="text-xs text-gray-400">No partner organisations added yet.</p>
            ) : (
              <div className="space-y-1.5">
                {activeAgreements.map((a) => (
                  <div key={a.id} className="flex items-center gap-3 bg-gray-50 rounded-lg px-3 py-2">
                    <div className="w-6 h-6 rounded bg-brand-50 flex items-center justify-center overflow-hidden flex-shrink-0">
                      {a.partner_company_logo_url
                        ? <img src={a.partner_company_logo_url} alt={a.partner_company_name} className="w-full h-full object-cover" />
                        : <Building2 className="w-3.5 h-3.5 text-brand-500" />}
                    </div>
                    <div className="flex-1 min-w-0">
                      <span className="text-sm text-gray-700 truncate block">{a.partner_company_name}</span>
                      <span className="text-[11px] text-gray-400">
                        {a.branch_name ? `${a.branch_name} branch only` : 'All branches'}
                      </span>
                    </div>
                    <button onClick={() => revokeAgreement.mutate(a.id)} className="text-gray-300 hover:text-red-500">
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      {/* Pending employee requests */}
      {requests.length > 0 && (
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
          <p className="text-sm font-semibold text-amber-900 mb-2">Pending access requests ({requests.length})</p>
          <div className="space-y-2">
            {requests.map((r) => (
              <div key={r.id} className="flex items-center gap-3 bg-white rounded-lg px-3 py-2.5 border border-amber-100">
                <div className="flex-1 min-w-0">
                  <p className="text-sm text-gray-800">
                    <span className="font-medium">{r.employee_name}</span> wants{' '}
                    {r.request_type === 'pool_car' ? 'pool-car access' : 'company-wallet payment access'}
                  </p>
                  {r.note && <p className="text-xs text-gray-400 mt-0.5">"{r.note}"</p>}
                </div>
                <button onClick={() => decide.mutate({ id: r.id, approve: true })} disabled={decide.isPending}
                  className="btn-primary text-xs px-2.5 py-1.5"><Check className="w-3.5 h-3.5" /> Approve</button>
                <button onClick={() => decide.mutate({ id: r.id, approve: false })} disabled={decide.isPending}
                  className="btn-secondary text-xs px-2.5 py-1.5"><X className="w-3.5 h-3.5" /> Deny</button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Company-wide default rations */}
      <div className="bg-white border border-gray-100 rounded-xl p-4">
        <p className="text-sm font-semibold text-gray-900 mb-1">Default usage limit per employee</p>
        <p className="text-xs text-gray-400 mb-3">Leave blank for unlimited. An individual employee's own limit (below) overrides these.</p>
        <div className="grid grid-cols-3 gap-3">
          {(['daily_limit', 'weekly_limit', 'monthly_limit'] as const).map((key) => (
            <div key={key}>
              <label className="text-xs text-gray-500 mb-1 block capitalize">{key.replace('_limit', '')}</label>
              <input type="number" min={1} className="input" placeholder="Unlimited"
                defaultValue={policy?.[key] ?? ''}
                onBlur={(e) => {
                  const v = e.target.value ? parseInt(e.target.value) : null
                  if (v !== (policy?.[key] ?? null)) updatePolicy.mutate({ [key]: v })
                }} />
            </div>
          ))}
        </div>
      </div>

      {/* Per-employee access */}
      <div className="bg-white border border-gray-100 rounded-xl overflow-hidden">
        <p className="text-sm font-semibold text-gray-900 px-4 pt-4 pb-2">Employee pool-car access</p>
        {employeesLoading ? (
          <div className="flex justify-center py-6"><Loader2 className="w-5 h-5 animate-spin text-brand-500" /></div>
        ) : employees.length === 0 ? (
          <p className="text-xs text-gray-400 px-4 pb-4">No active employees yet.</p>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-gray-500 text-xs uppercase">
              <tr>
                <th className="text-left px-4 py-2 font-medium">Employee</th>
                <th className="text-left px-4 py-2 font-medium">Pool car</th>
                <th className="text-left px-4 py-2 font-medium">Limits (D/W/M)</th>
                <th className="text-left px-4 py-2 font-medium">Wallet pay</th>
                <th className="text-right px-4 py-2 font-medium">Edit</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {employees.map((e) => (
                <tr key={e.id}>
                  <td className="px-4 py-2.5">
                    <p className="font-medium text-gray-800">{e.name}</p>
                    <p className="text-xs text-gray-400">{e.email}</p>
                  </td>
                  <td className="px-4 py-2.5">
                    <span className={badge(e.pool_access_enabled ? 'active' : 'inactive')}>
                      {e.pool_access_enabled ? 'Enabled' : 'Disabled'}
                    </span>
                  </td>
                  <td className="px-4 py-2.5 text-gray-500 text-xs">
                    {e.pool_daily_limit ?? '—'} / {e.pool_weekly_limit ?? '—'} / {e.pool_monthly_limit ?? '—'}
                  </td>
                  <td className="px-4 py-2.5">
                    <span className={badge(e.wallet_access_enabled ? 'active' : 'inactive')}>
                      {e.wallet_access_enabled ? 'Enabled' : 'Disabled'}
                    </span>
                  </td>
                  <td className="px-4 py-2.5 text-right">
                    <button onClick={() => setEditingEmployee(e)} className="btn-secondary text-xs px-2 py-1">
                      <Edit2 className="w-3.5 h-3.5" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {showAddPartner && <AddPoolPartnerModal companyId={companyId} onClose={() => setShowAddPartner(false)} />}
      {editingEmployee && (
        <EditEmployeePoolAccessModal companyId={companyId} employee={editingEmployee} onClose={() => setEditingEmployee(null)} />
      )}
    </div>
  )
}

interface PartnerCompany { id: string; name: string; logo_url: string | null; city: string | null; industry: string | null }

function AddPoolPartnerModal({ companyId, onClose }: { companyId: string; onClose: () => void }) {
  const qc = useQueryClient()
  const [search, setSearch] = useState('')
  const [debounced, setDebounced] = useState('')
  const [err, setErr] = useState('')
  const [branchId, setBranchId] = useState('')

  const { data: branches = [] } = useQuery<Branch[]>({
    queryKey: ['company-branches', companyId],
    queryFn: () => get(`/admin/companies/${companyId}/branches`),
  })

  // Autosearch — debounced so it queries the server as the admin types
  // rather than requiring an explicit search action. This calls a
  // dedicated cross-tenant partner-search endpoint, not the regular
  // /admin/companies list (which is intentionally scoped to the caller's
  // own company and would never return other organisations to pick from).
  useEffect(() => {
    const t = setTimeout(() => setDebounced(search), 300)
    return () => clearTimeout(t)
  }, [search])

  const { data: companies = [], isFetching } = useQuery<PartnerCompany[]>({
    queryKey: ['partner-search', debounced, companyId],
    queryFn: () => get('/admin/companies/partner-search', { q: debounced || undefined, exclude: companyId }),
  })

  const add = useMutation({
    mutationFn: (partnerCompanyId: string) =>
      post(`/admin/companies/${companyId}/pool-sharing`, { partner_company_id: partnerCompanyId, branch_id: branchId || undefined }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['pool-sharing', companyId] }); onClose() },
    onError: (e: any) => setErr(e?.message ?? 'Failed to add organisation'),
  })

  return (
    <Modal open onClose={onClose} title="Add a participating organisation" size="sm">
      <div className="space-y-3">
        {err && <div className="bg-red-50 border border-red-200 text-red-700 text-xs px-3 py-2 rounded-lg">{err}</div>}
        {branches.length > 0 && (
          <div>
            <label className="text-xs text-gray-500 mb-1 block">Applies to</label>
            <select className="input" value={branchId} onChange={(e) => setBranchId(e.target.value)}>
              <option value="">All branches (company-wide)</option>
              {branches.map((b) => <option key={b.id} value={b.id}>{b.name} branch only</option>)}
            </select>
          </div>
        )}
        <div className="relative">
          <input className="input" placeholder="Search organisations by name, city or industry…" value={search} onChange={(e) => setSearch(e.target.value)} autoFocus />
          {isFetching && <Loader2 className="w-4 h-4 animate-spin text-gray-400 absolute right-3 top-1/2 -translate-y-1/2" />}
        </div>
        <div className="max-h-64 overflow-y-auto space-y-1">
          {companies.length === 0 ? (
            <p className="text-xs text-gray-400 text-center py-4">
              {search ? 'No matching active organisations' : 'Start typing to search participating organisations'}
            </p>
          ) : companies.map((c) => (
            <button key={c.id} onClick={() => add.mutate(c.id)} disabled={add.isPending}
              className="w-full flex items-center gap-2.5 px-3 py-2 rounded-lg hover:bg-gray-50 text-left">
              {c.logo_url ? (
                <img src={c.logo_url} alt="" className="w-6 h-6 rounded flex-shrink-0 object-cover" />
              ) : (
                <Building2 className="w-4 h-4 text-gray-400 flex-shrink-0" />
              )}
              <div className="min-w-0">
                <p className="text-sm text-gray-700 truncate">{c.name}</p>
                {(c.city || c.industry) && <p className="text-xs text-gray-400 truncate">{[c.city, c.industry].filter(Boolean).join(' · ')}</p>}
              </div>
            </button>
          ))}
        </div>
      </div>
    </Modal>
  )
}

function EditEmployeePoolAccessModal({ companyId, employee, onClose }: { companyId: string; employee: EmployeePoolAccess; onClose: () => void }) {
  const qc = useQueryClient()
  const [enabled, setEnabled] = useState(employee.pool_access_enabled)
  const [daily, setDaily] = useState(employee.pool_daily_limit?.toString() ?? '')
  const [weekly, setWeekly] = useState(employee.pool_weekly_limit?.toString() ?? '')
  const [monthly, setMonthly] = useState(employee.pool_monthly_limit?.toString() ?? '')
  const [poolDays, setPoolDays] = useState<number[]>(employee.pool_access_days_of_week)
  const [poolFrom, setPoolFrom] = useState(employee.pool_access_time_from ?? '')
  const [poolTo, setPoolTo] = useState(employee.pool_access_time_to ?? '')

  const [walletEnabled, setWalletEnabled] = useState(employee.wallet_access_enabled)
  const [walletDays, setWalletDays] = useState<number[]>(employee.wallet_access_days_of_week)
  const [walletFrom, setWalletFrom] = useState(employee.wallet_access_time_from ?? '')
  const [walletTo, setWalletTo] = useState(employee.wallet_access_time_to ?? '')

  const [err, setErr] = useState('')

  const save = useMutation({
    mutationFn: () => Promise.all([
      api.patch(`/admin/companies/${companyId}/employees/${employee.id}/pool-access`, {
        pool_access_enabled: enabled,
        pool_daily_limit:   daily   ? parseInt(daily)   : null,
        pool_weekly_limit:  weekly  ? parseInt(weekly)  : null,
        pool_monthly_limit: monthly ? parseInt(monthly) : null,
        pool_access_days_of_week: poolDays,
        pool_access_time_from: poolFrom || null,
        pool_access_time_to: poolTo || null,
      }),
      api.patch(`/admin/companies/${companyId}/employees/${employee.id}/wallet-access`, {
        wallet_access_enabled: walletEnabled,
        wallet_access_days_of_week: walletDays,
        wallet_access_time_from: walletFrom || null,
        wallet_access_time_to: walletTo || null,
      }),
    ]),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['employee-pool-access', companyId] }); onClose() },
    onError: (e: any) => setErr(e?.response?.data?.ResponseMsg ?? 'Failed to save'),
  })

  return (
    <Modal open onClose={onClose} title={employee.name} size="sm">
      <div className="space-y-5">
        {err && <div className="bg-red-50 border border-red-200 text-red-700 text-xs px-3 py-2 rounded-lg">{err}</div>}

        <div className="space-y-3 pb-4 border-b border-gray-100">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-gray-700 flex items-center gap-1.5"><Car className="w-4 h-4 text-gray-400" /> Pool-car access</span>
            <button onClick={() => setEnabled((v) => !v)}>
              {enabled ? <ToggleRight className="w-9 h-9 text-brand-500" /> : <ToggleLeft className="w-9 h-9 text-gray-300" />}
            </button>
          </div>

          {enabled && (
            <>
              <div>
                <p className="text-xs text-gray-500 mb-2">Personal limit overrides — leave blank to use the company default</p>
                <div className="grid grid-cols-3 gap-2">
                  <div>
                    <label className="text-xs text-gray-400 mb-1 block">Daily</label>
                    <input type="number" min={1} className="input" placeholder="Default" value={daily} onChange={(e) => setDaily(e.target.value)} />
                  </div>
                  <div>
                    <label className="text-xs text-gray-400 mb-1 block">Weekly</label>
                    <input type="number" min={1} className="input" placeholder="Default" value={weekly} onChange={(e) => setWeekly(e.target.value)} />
                  </div>
                  <div>
                    <label className="text-xs text-gray-400 mb-1 block">Monthly</label>
                    <input type="number" min={1} className="input" placeholder="Default" value={monthly} onChange={(e) => setMonthly(e.target.value)} />
                  </div>
                </div>
              </div>
              <TimeWindowFields days={poolDays} setDays={setPoolDays} from={poolFrom} setFrom={setPoolFrom} to={poolTo} setTo={setPoolTo} />
            </>
          )}
        </div>

        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-gray-700 flex items-center gap-1.5"><Wallet className="w-4 h-4 text-gray-400" /> Company-wallet ride payment</span>
            <button onClick={() => setWalletEnabled((v) => !v)}>
              {walletEnabled ? <ToggleRight className="w-9 h-9 text-brand-500" /> : <ToggleLeft className="w-9 h-9 text-gray-300" />}
            </button>
          </div>
          {walletEnabled && (
            <TimeWindowFields days={walletDays} setDays={setWalletDays} from={walletFrom} setFrom={setWalletFrom} to={walletTo} setTo={setWalletTo} />
          )}
        </div>

        <button onClick={() => save.mutate()} disabled={save.isPending} className="btn-primary w-full justify-center">
          {save.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Save'}
        </button>
      </div>
    </Modal>
  )
}

// ─── Fleet & drivers tab ────────────────────────────────────────────────────

interface PoolVehicle {
  id: string; photo: string; model_title: string; type_title: string; color_title: string
  year: number; license_plate: string; seat_capacity: number; status: string
  branch_id: string | null; branch_name: string | null
  assigned_drivers: { driver_id: string; name: string }[]
}
interface PoolDriver {
  employee_id: string; user_id: string; name: string; mobile: string; employee_number: string
  driver_status: string; rating: number
  assigned_vehicles: { vehicle_id: string; license_plate: string }[]
}
interface RefOption { id: string; title: string }

function FleetTab({ companyId }: { companyId: string }) {
  const [subTab, setSubTab] = useState<'vehicles' | 'drivers'>('vehicles')
  const [showAddVehicle, setShowAddVehicle] = useState(false)
  const [showAddDriver, setShowAddDriver] = useState(false)
  const qc = useQueryClient()

  const { data: vehicles = [], isLoading: vehiclesLoading } = useQuery<PoolVehicle[]>({
    queryKey: ['pool-vehicles', companyId],
    queryFn: () => get(`/admin/companies/${companyId}/pool-vehicles`),
  })
  const { data: drivers = [], isLoading: driversLoading } = useQuery<PoolDriver[]>({
    queryKey: ['pool-drivers', companyId],
    queryFn: () => get(`/admin/companies/${companyId}/pool-drivers`),
  })

  const revoke = useMutation({
    mutationFn: ({ vehicle_id, driver_id }: { vehicle_id: string; driver_id: string }) =>
      post(`/admin/companies/${companyId}/pool-drivers/revoke`, { vehicle_id, driver_id }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['pool-vehicles', companyId] })
      qc.invalidateQueries({ queryKey: ['pool-drivers', companyId] })
    },
  })

  const { data: branches = [] } = useQuery<Branch[]>({
    queryKey: ['company-branches', companyId],
    queryFn: () => get(`/admin/companies/${companyId}/branches`),
  })

  const assignBranch = useMutation({
    mutationFn: ({ vehicleId, branchId }: { vehicleId: string; branchId: string }) =>
      api.patch(`/admin/companies/${companyId}/pool-vehicles/${vehicleId}`, { branch_id: branchId || null }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['pool-vehicles', companyId] }),
  })

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex gap-1 bg-gray-100 rounded-lg p-1">
          <button onClick={() => setSubTab('vehicles')} className={cn('px-3 py-1.5 rounded-md text-xs font-medium', subTab === 'vehicles' ? 'bg-white shadow-sm text-gray-900' : 'text-gray-500')}>Vehicles ({vehicles.length})</button>
          <button onClick={() => setSubTab('drivers')} className={cn('px-3 py-1.5 rounded-md text-xs font-medium', subTab === 'drivers' ? 'bg-white shadow-sm text-gray-900' : 'text-gray-500')}>Drivers ({drivers.length})</button>
        </div>
        <button onClick={() => subTab === 'vehicles' ? setShowAddVehicle(true) : setShowAddDriver(true)} className="btn-primary text-sm">
          <Plus className="w-4 h-4" /> {subTab === 'vehicles' ? 'Add vehicle' : 'Add driver'}
        </button>
      </div>

      {subTab === 'vehicles' && (
        vehiclesLoading ? <div className="flex justify-center py-10"><Loader2 className="w-5 h-5 animate-spin text-brand-500" /></div>
        : vehicles.length === 0 ? <EmptyState icon={Car} title="No pool vehicles yet" sub="Add your first vehicle to start assigning drivers." />
        : (
          <div className="space-y-2">
            {vehicles.map((v) => (
              <div key={v.id} className="bg-white border border-gray-100 rounded-xl p-3">
                <div className="flex items-center justify-between gap-3">
                  <div className="min-w-0">
                    <p className="text-sm font-semibold text-gray-900">{v.license_plate} <span className={badge(v.status === 'approved' ? 'active' : v.status)}>{v.status}</span></p>
                    <p className="text-xs text-gray-400">{v.model_title} · {v.color_title} · {v.year} · {v.type_title} · {v.seat_capacity} seats</p>
                  </div>
                  {branches.length > 0 && (
                    <select
                      className="input text-xs py-1 w-40 flex-shrink-0"
                      value={v.branch_id ?? ''}
                      onChange={(e) => assignBranch.mutate({ vehicleId: v.id, branchId: e.target.value })}
                      title="Which branch operates this vehicle — controls which branch-scoped pool-sharing agreements apply to it">
                      <option value="">No branch (company-wide)</option>
                      {branches.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
                    </select>
                  )}
                </div>
                {v.assigned_drivers.length > 0 && (
                  <div className="mt-2 flex flex-wrap gap-1.5">
                    {v.assigned_drivers.map((d) => (
                      <span key={d.driver_id} className="inline-flex items-center gap-1 text-xs bg-blue-50 text-blue-700 rounded-full px-2 py-0.5">
                        {d.name}
                        <button onClick={() => revoke.mutate({ vehicle_id: v.id, driver_id: d.driver_id })} className="text-blue-400 hover:text-blue-700">×</button>
                      </span>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>
        )
      )}

      {subTab === 'drivers' && (
        driversLoading ? <div className="flex justify-center py-10"><Loader2 className="w-5 h-5 animate-spin text-brand-500" /></div>
        : drivers.length === 0 ? <EmptyState icon={Users} title="No pool drivers yet" sub="Pool drivers are always admin-created, with a company employee number assigned." />
        : (
          <div className="space-y-2">
            {drivers.map((d) => (
              <div key={d.employee_id} className="bg-white border border-gray-100 rounded-xl p-3">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-semibold text-gray-900">{d.name}</p>
                    <p className="text-xs text-gray-400">{d.mobile} · #{d.employee_number} · <span className={badge(d.driver_status)}>{d.driver_status}</span> {d.rating > 0 && `· ★${d.rating.toFixed(1)}`}</p>
                  </div>
                  {d.assigned_vehicles.length > 0 && (
                    <span className="text-xs text-gray-500">{d.assigned_vehicles.map((v) => v.license_plate).join(', ')}</span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )
      )}

      {showAddVehicle && <AddPoolVehicleModal companyId={companyId} onClose={() => setShowAddVehicle(false)} />}
      {showAddDriver && <AddPoolDriverModal companyId={companyId} vehicles={vehicles} onClose={() => setShowAddDriver(false)} />}
    </div>
  )
}

function AddPoolVehicleModal({ companyId, onClose }: { companyId: string; onClose: () => void }) {
  const qc = useQueryClient()
  const [form, setForm] = useState({ model_id: '', type_id: '', color_id: '', year: new Date().getFullYear().toString(), license_plate: '', seat_capacity: '4', branch_id: '' })
  const [err, setErr] = useState('')

  const { data: models = [] } = useQuery<RefOption[]>({ queryKey: ['vehicle-models'], queryFn: () => get('/admin/vehicle-models') })
  const { data: types = [] } = useQuery<RefOption[]>({ queryKey: ['vehicle-types'], queryFn: () => get('/admin/vehicle-types') })
  const { data: colors = [] } = useQuery<RefOption[]>({ queryKey: ['vehicle-colors'], queryFn: () => get('/admin/vehicle-colors') })
  const { data: branches = [] } = useQuery<Branch[]>({ queryKey: ['company-branches', companyId], queryFn: () => get(`/admin/companies/${companyId}/branches`) })

  const create = useMutation({
    mutationFn: () => post(`/admin/companies/${companyId}/pool-vehicles`, {
      ...form, year: parseInt(form.year), seat_capacity: parseInt(form.seat_capacity), branch_id: form.branch_id || undefined,
    }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['pool-vehicles', companyId] }); onClose() },
    onError: (e: any) => setErr(e?.message ?? 'Failed to add vehicle'),
  })

  return (
    <Modal open onClose={onClose} title="Add pool vehicle" size="sm">
      <div className="space-y-3">
        {err && <div className="bg-red-50 border border-red-200 text-red-700 text-xs px-3 py-2 rounded-lg">{err}</div>}
        <div className="grid grid-cols-2 gap-3">
          <div><label className="text-xs text-gray-500 mb-1 block">Model</label>
            <select className="input" value={form.model_id} onChange={(e) => setForm((p) => ({ ...p, model_id: e.target.value }))}>
              <option value="">Select…</option>{models.map((m) => <option key={m.id} value={m.id}>{m.title}</option>)}
            </select>
          </div>
          <div><label className="text-xs text-gray-500 mb-1 block">Type</label>
            <select className="input" value={form.type_id} onChange={(e) => setForm((p) => ({ ...p, type_id: e.target.value }))}>
              <option value="">Select…</option>{types.map((t) => <option key={t.id} value={t.id}>{t.title}</option>)}
            </select>
          </div>
          <div><label className="text-xs text-gray-500 mb-1 block">Color</label>
            <select className="input" value={form.color_id} onChange={(e) => setForm((p) => ({ ...p, color_id: e.target.value }))}>
              <option value="">Select…</option>{colors.map((c) => <option key={c.id} value={c.id}>{c.title}</option>)}
            </select>
          </div>
          <div><label className="text-xs text-gray-500 mb-1 block">Year</label>
            <input type="number" className="input" value={form.year} onChange={(e) => setForm((p) => ({ ...p, year: e.target.value }))} />
          </div>
          <div><label className="text-xs text-gray-500 mb-1 block">License plate</label>
            <input className="input" value={form.license_plate} onChange={(e) => setForm((p) => ({ ...p, license_plate: e.target.value }))} />
          </div>
          <div><label className="text-xs text-gray-500 mb-1 block">Seats</label>
            <input type="number" className="input" value={form.seat_capacity} onChange={(e) => setForm((p) => ({ ...p, seat_capacity: e.target.value }))} />
          </div>
          {branches.length > 0 && (
            <div className="col-span-2">
              <label className="text-xs text-gray-500 mb-1 block">Branch (optional — controls which branch-scoped sharing agreements apply)</label>
              <select className="input" value={form.branch_id} onChange={(e) => setForm((p) => ({ ...p, branch_id: e.target.value }))}>
                <option value="">No branch (company-wide)</option>
                {branches.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
              </select>
            </div>
          )}
        </div>
        <button onClick={() => create.mutate()} disabled={create.isPending || !form.model_id || !form.type_id || !form.color_id || !form.license_plate} className="btn-primary w-full justify-center">
          {create.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Add vehicle'}
        </button>
      </div>
    </Modal>
  )
}

function AddPoolDriverModal({ companyId, vehicles, onClose }: { companyId: string; vehicles: PoolVehicle[]; onClose: () => void }) {
  const qc = useQueryClient()
  const [form, setForm] = useState({ name: '', mobile: '', email: '', license_number: '', license_expiry: '', employee_number: '', vehicle_id: '' })
  const [err, setErr] = useState('')
  const [created, setCreated] = useState<{ generated_password: string } | null>(null)

  const create = useMutation({
    mutationFn: () => post<{ generated_password: string }>(`/admin/companies/${companyId}/pool-drivers`, {
      ...form,
      email: form.email || undefined,
      vehicle_id: form.vehicle_id || undefined,
    }),
    onSuccess: (data) => {
      qc.invalidateQueries({ queryKey: ['pool-drivers', companyId] })
      qc.invalidateQueries({ queryKey: ['pool-vehicles', companyId] })
      setCreated(data)
    },
    onError: (e: any) => setErr(e?.message ?? 'Failed to create driver'),
  })

  if (created) {
    return (
      <Modal open onClose={onClose} title="Pool driver created" size="sm">
        <div className="space-y-3 text-sm">
          <p className="text-gray-600">Share these temporary credentials with the driver — they should change the password on first login.</p>
          <div className="bg-gray-50 rounded-lg p-3 font-mono text-xs">
            mobile: {form.mobile}<br />temp password: {created.generated_password}
          </div>
          <button onClick={onClose} className="btn-primary w-full justify-center">Done</button>
        </div>
      </Modal>
    )
  }

  return (
    <Modal open onClose={onClose} title="Add pool driver" size="sm">
      <div className="space-y-3">
        {err && <div className="bg-red-50 border border-red-200 text-red-700 text-xs px-3 py-2 rounded-lg">{err}</div>}
        <p className="text-xs text-gray-500">Pool drivers are always admin-created and require a company employee number.</p>
        <input className="input" placeholder="Full name" value={form.name} onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))} />
        <input className="input" placeholder="Mobile number" value={form.mobile} onChange={(e) => setForm((p) => ({ ...p, mobile: e.target.value }))} />
        <input className="input" placeholder="Email (optional)" value={form.email} onChange={(e) => setForm((p) => ({ ...p, email: e.target.value }))} />
        <input className="input" placeholder="Employee number" value={form.employee_number} onChange={(e) => setForm((p) => ({ ...p, employee_number: e.target.value }))} />
        <div className="grid grid-cols-2 gap-3">
          <input className="input" placeholder="License number" value={form.license_number} onChange={(e) => setForm((p) => ({ ...p, license_number: e.target.value }))} />
          <input type="date" className="input" value={form.license_expiry} onChange={(e) => setForm((p) => ({ ...p, license_expiry: e.target.value }))} />
        </div>
        <div>
          <label className="text-xs text-gray-500 mb-1 block">Assign to vehicle (optional)</label>
          <select className="input" value={form.vehicle_id} onChange={(e) => setForm((p) => ({ ...p, vehicle_id: e.target.value }))}>
            <option value="">None yet</option>
            {vehicles.map((v) => <option key={v.id} value={v.id}>{v.license_plate}</option>)}
          </select>
        </div>
        <button onClick={() => create.mutate()} disabled={create.isPending || !form.name || !form.mobile || !form.license_number || !form.license_expiry || !form.employee_number} className="btn-primary w-full justify-center">
          {create.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Create driver'}
        </button>
      </div>
    </Modal>
  )
}

// ─── Pool car tracking tab ──────────────────────────────────────────────────

interface TrackedCar {
  ride_id: string; driver_name: string; vehicle_plate: string; vehicle_model: string
  ownership: 'own' | 'shared' | 'public'; shared_by_company: string | null
  origin: string; destination: string
  lat: number | null; lng: number | null; speed_kmh: number | null; recorded_at: string | null
}

const OWNERSHIP_STYLE: Record<TrackedCar['ownership'], string> = {
  own:    'bg-blue-50 text-blue-700 border-blue-200',
  shared: 'bg-purple-50 text-purple-700 border-purple-200',
  public: 'bg-green-50 text-green-700 border-green-200',
}
const OWNERSHIP_LABEL: Record<TrackedCar['ownership'], string> = { own: 'Own', shared: 'Shared', public: 'Public' }

function PoolTrackingTab({ companyId }: { companyId: string }) {
  const { data: cars = [], isLoading } = useQuery<TrackedCar[]>({
    queryKey: ['pool-tracking', companyId],
    queryFn: () => get(`/admin/companies/${companyId}/pool-tracking`),
    refetchInterval: 10_000,
  })

  if (isLoading) return <div className="flex justify-center py-10"><Loader2 className="w-5 h-5 animate-spin text-brand-500" /></div>

  return (
    <div className="space-y-3">
      <p className="text-xs text-gray-500">
        Own cars, cars shared with you by partner organisations, and publicly available cars only —
        another organisation's private pool is never visible here unless they've shared with you. Updates every 10s.
      </p>
      {cars.length === 0 ? (
        <EmptyState icon={MapPin} title="No cars currently on a trip" sub="Cars appear here once a ride is in progress." />
      ) : (
        <div className="space-y-2">
          {cars.map((c) => (
            <div key={c.ride_id} className="bg-white border border-gray-100 rounded-xl p-3 flex items-center gap-3">
              <span className={cn('text-xs font-medium px-2 py-1 rounded-lg border flex-shrink-0', OWNERSHIP_STYLE[c.ownership])}>
                {OWNERSHIP_LABEL[c.ownership]}{c.ownership === 'shared' && c.shared_by_company ? ` · ${c.shared_by_company}` : ''}
              </span>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-gray-900 truncate">{c.vehicle_plate} — {c.vehicle_model} · {c.driver_name}</p>
                <p className="text-xs text-gray-400 truncate">{c.origin} → {c.destination}</p>
              </div>
              {c.lat != null && c.lng != null ? (
                <a href={`https://www.google.com/maps?q=${c.lat},${c.lng}`} target="_blank" rel="noreferrer"
                  className="text-xs text-brand-600 hover:underline flex-shrink-0">
                  {c.speed_kmh != null ? `${Math.round(c.speed_kmh)} km/h` : 'View map'}
                </a>
              ) : <span className="text-xs text-gray-300 flex-shrink-0">No signal</span>}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

// ─── Savings report tab ─────────────────────────────────────────────────────

interface SavingsReport {
  id: string; period_start: string; period_end: string; total_rides: number
  total_market_benchmark_cost: number; total_org_spend: number
  total_savings: number; savings_percentage: number; status: string
}
interface SavingsBreakdownRow {
  key: string; label: string; total_rides: number
  total_market_benchmark_cost: number; total_org_spend: number
  total_savings: number; savings_percentage: number
}

function SavingsReportTab({ companyId }: { companyId: string }) {
  const qc = useQueryClient()
  const [periodStart, setPeriodStart] = useState('')
  const [periodEnd, setPeriodEnd] = useState('')
  const [groupBy, setGroupBy] = useState<'employee' | 'department'>('employee')
  const [err, setErr] = useState('')

  const { data: reports = [], isLoading } = useQuery<SavingsReport[]>({
    queryKey: ['savings-reports', companyId],
    queryFn: () => get('/admin/savings-reports', { company_id: companyId }),
  })

  const generate = useMutation({
    mutationFn: () => post('/admin/savings-reports/generate', { company_id: companyId, period_start: periodStart, period_end: periodEnd }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['savings-reports', companyId] }); setErr('') },
    onError: (e: any) => setErr(e?.message ?? 'Failed to generate report'),
  })

  const { data: breakdown = [], isLoading: breakdownLoading } = useQuery<SavingsBreakdownRow[]>({
    queryKey: ['savings-breakdown', companyId, periodStart, periodEnd, groupBy],
    queryFn: () => get('/admin/savings-reports/breakdown', { company_id: companyId, period_start: periodStart, period_end: periodEnd, group_by: groupBy }),
    enabled: !!periodStart && !!periodEnd,
  })

  return (
    <div className="space-y-5">
      {err && <div className="bg-red-50 border border-red-200 text-red-700 text-xs px-3 py-2 rounded-lg">{err}</div>}

      <div className="bg-white border border-gray-100 rounded-xl p-4">
        <p className="text-sm font-semibold text-gray-900 mb-3">Generate a savings report</p>
        <div className="flex gap-3 items-end flex-wrap">
          <div>
            <label className="text-xs text-gray-500 mb-1 block">Period start</label>
            <input type="date" className="input" value={periodStart} onChange={(e) => setPeriodStart(e.target.value)} />
          </div>
          <div>
            <label className="text-xs text-gray-500 mb-1 block">Period end</label>
            <input type="date" className="input" value={periodEnd} onChange={(e) => setPeriodEnd(e.target.value)} />
          </div>
          <button onClick={() => generate.mutate()} disabled={generate.isPending || !periodStart || !periodEnd} className="btn-primary h-10">
            {generate.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Sparkles className="w-4 h-4" />} Generate
          </button>
        </div>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-8"><Loader2 className="w-5 h-5 animate-spin text-brand-500" /></div>
      ) : reports.length === 0 ? (
        <p className="text-xs text-gray-400 text-center py-4">No savings reports generated yet — pick a period above.</p>
      ) : (
        <div className="grid gap-3 md:grid-cols-2">
          {reports.map((r) => (
            <div key={r.id} className="bg-white border border-gray-100 rounded-xl p-4">
              <p className="text-xs text-gray-400">{fmt.date(r.period_start)} – {fmt.date(r.period_end)}</p>
              <div className="grid grid-cols-2 gap-3 mt-2 text-sm">
                <div>
                  <p className="text-xs text-gray-400">Rides</p>
                  <p className="font-semibold text-gray-800">{r.total_rides}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-400">Savings</p>
                  <p className="font-semibold text-green-600">{fmt.naira(r.total_savings)} ({fmt.percent(r.savings_percentage)})</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {periodStart && periodEnd && (
        <div className="bg-white border border-gray-100 rounded-xl overflow-hidden">
          <div className="flex items-center justify-between px-4 pt-4 pb-2">
            <p className="text-sm font-semibold text-gray-900">Breakdown</p>
            <div className="flex gap-1">
              {(['employee', 'department'] as const).map((g) => (
                <button key={g} onClick={() => setGroupBy(g)}
                  className={`px-3 py-1 rounded-lg text-xs font-medium capitalize ${groupBy === g ? 'bg-brand-500 text-white' : 'bg-gray-100 text-gray-500'}`}>
                  {g}
                </button>
              ))}
            </div>
          </div>
          {breakdownLoading ? (
            <div className="flex justify-center py-6"><Loader2 className="w-5 h-5 animate-spin text-brand-500" /></div>
          ) : breakdown.length === 0 ? (
            <p className="text-xs text-gray-400 px-4 pb-4">No rides in this period yet.</p>
          ) : (
            <table className="w-full text-sm">
              <thead className="bg-gray-50 text-gray-500 text-xs uppercase">
                <tr>
                  <th className="text-left px-4 py-2 font-medium capitalize">{groupBy}</th>
                  <th className="text-left px-4 py-2 font-medium">Rides</th>
                  <th className="text-left px-4 py-2 font-medium">Savings</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {breakdown.map((row) => (
                  <tr key={row.key}>
                    <td className="px-4 py-2.5 text-gray-700">{row.label}</td>
                    <td className="px-4 py-2.5 text-gray-500">{row.total_rides}</td>
                    <td className="px-4 py-2.5 font-medium text-green-600">{fmt.naira(row.total_savings)} ({fmt.percent(row.savings_percentage)})</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  )
}

// ─── Main component ───────────────────────────────────────────────────────────

export default function Companies() {
  const isSuperAdmin = useAuthStore((s) => s.admin?.isSuperAdmin ?? false)
  const username = useAuthStore((s) => s.admin?.username)
  const [search, setSearch]         = useState('')
  const [tab, setTab]               = useState<'all'|'pending_approval'|'active'|'suspended'|'rejected'>('all')
  const [expanded, setExpanded]     = useState<string | null>(null)
  const [detailTab, setDetailTab]   = useState<DetailTab>('info')
  const [commission, setCommission] = useState<Record<string, string>>({})
  const [showCreate, setShowCreate] = useState(false)
  const qc = useQueryClient()

  const { data = [], isLoading } = useQuery<Company[]>({
    queryKey: ['admin-companies', tab],
    queryFn:  () => get('/admin/companies', { status: tab === 'all' ? undefined : tab }),
  })

  const action = useMutation({
    mutationFn: ({ id, act }: { id: string; act: string }) =>
      post('/admin/companies/action', { company_id: id, action: act }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-companies'] }),
  })

  const saveCommission = useMutation({
    mutationFn: ({ id, rate }: { id: string; rate: number }) =>
      post('/admin/companies/commission', { company_id: id, commission_rate: rate }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-companies'] }),
  })

  // The endpoint (POST /admin/companies/:id/logo, scoped via
  // assertCompanyScope) and the display of the resulting logo_url in this
  // header and the sidebar (see Layout.tsx) already existed — there was
  // just no UI anywhere to actually trigger an upload.
  const uploadLogo = useMutation({
    mutationFn: ({ id, file }: { id: string; file: File }) => {
      const form = new FormData()
      form.append('logo', file)
      return post(`/admin/companies/${id}/logo`, form)
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-companies'] }),
  })

  const filtered = data.filter((c) =>
    !search ||
    c.name.toLowerCase().includes(search.toLowerCase()) ||
    c.contact_email.toLowerCase().includes(search.toLowerCase()) ||
    c.contact_name.toLowerCase().includes(search.toLowerCase()),
  )

  const pending = data.filter((c) => c.status === 'pending_approval').length

  const DETAIL_TABS: { id: DetailTab; icon: any; label: (c: Company) => string }[] = [
    { id: 'info',         icon: Building2, label: () => 'Info & Actions' },
    { id: 'employees',    icon: Users,     label: (c) => `Employees (${c.total_employees})` },
    { id: 'rides',        icon: Car,       label: (c) => `Rides (${c.rides_this_month}/mo)` },
    { id: 'departments',  icon: Layers,      label: () => 'Departments' },
    { id: 'cost-centres', icon: Percent,     label: () => 'Cost Centres' },
    { id: 'branches',     icon: GitBranch,   label: () => 'Branches' },
    { id: 'wallet',       icon: History,     label: (c) => `Wallet (₦${Number(c.wallet_balance ?? 0).toLocaleString()})` },
    { id: 'pool-policy',  icon: Share2,      label: () => 'Pool Cars' },
    { id: 'fleet',        icon: Car,         label: () => 'Fleet & Drivers' },
    { id: 'tracking',     icon: MapPin,      label: () => 'Live Tracking' },
    { id: 'savings',      icon: BarChart2,   label: () => 'Savings Report' },
  ]

  const greeting = (() => {
    const h = new Date().getHours()
    if (h < 12) return 'Good morning'
    if (h < 18) return 'Good afternoon'
    return 'Good evening'
  })()

  return (
    <div className="space-y-6">
      {isSuperAdmin ? (
        <PageHeader
          title="Companies"
          sub={`${data.length} corporate clients${pending > 0 ? ` · ${pending} awaiting approval` : ''}`}
          action={
            <button onClick={() => setShowCreate(true)} className="btn-primary text-sm">
              <Plus className="w-4 h-4" /> New Company
            </button>
          }
        />
      ) : (
        <div className="flex items-center gap-4 bg-white border border-gray-100 rounded-2xl px-5 py-4 shadow-sm">
          <label className="relative w-14 h-14 rounded-xl bg-brand-50 flex items-center justify-center overflow-hidden flex-shrink-0 cursor-pointer group">
            {data[0]?.logo_url ? (
              <img src={data[0].logo_url} alt={data[0].name} className="w-full h-full object-cover" />
            ) : (
              <Building2 className="w-7 h-7 text-brand-500" />
            )}
            <span className="absolute inset-0 bg-black/0 group-hover:bg-black/40 flex items-center justify-center transition-colors">
              <Camera className="w-4 h-4 text-white opacity-0 group-hover:opacity-100 transition-opacity" />
            </span>
            <input
              type="file"
              accept="image/png,image/jpeg,image/webp"
              className="hidden"
              disabled={uploadLogo.isPending || !data[0]?.id}
              onChange={(e) => {
                const file = e.target.files?.[0]
                if (file && data[0]?.id) uploadLogo.mutate({ id: data[0].id, file })
                e.target.value = ''
              }}
            />
          </label>
          <div className="min-w-0">
            <h1 className="text-xl font-bold text-ink truncate">{greeting}, {username}</h1>
            <p className="text-sm text-ink-subtle mt-0.5 truncate">{data[0]?.name ?? 'Loading your company…'}</p>
            {uploadLogo.isPending && <p className="text-xs text-brand-500 mt-0.5">Uploading logo…</p>}
            {uploadLogo.isError && <p className="text-xs text-red-500 mt-0.5">{(uploadLogo.error as Error).message}</p>}
          </div>
        </div>
      )}

      {isSuperAdmin && <CreateCompanyModal open={showCreate} onClose={() => setShowCreate(false)} />}

      {isSuperAdmin && pending > 0 && (
        <div className="flex items-center gap-3 bg-amber-50 border border-amber-200 text-amber-800 px-4 py-3 rounded-xl text-sm">
          <AlertTriangle className="w-4 h-4 flex-shrink-0" />
          <span><strong>{pending}</strong> compan{pending > 1 ? 'ies' : 'y'} pending onboarding review</span>
          <button onClick={() => setTab('pending_approval')} className="ml-auto text-amber-700 underline font-medium">Review now</button>
        </div>
      )}

      {isSuperAdmin && (
        <div className="flex flex-wrap gap-3">
          <div className="relative flex-1 min-w-[200px]">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input className="input pl-9" placeholder="Search by name, email or contact…" value={search} onChange={(e) => setSearch(e.target.value)} />
          </div>
          {(['all','pending_approval','active','suspended','rejected'] as const).map((t) => (
            <button key={t} onClick={() => setTab(t)}
              className={`px-3 py-2 rounded-lg text-sm font-medium border transition-colors ${tab === t ? 'bg-brand-500 text-white border-brand-500' : 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'}`}>
              {t === 'pending_approval' ? 'Pending' : t[0].toUpperCase() + t.slice(1)}
              {t === 'pending_approval' && pending > 0 && (
                <span className="ml-1.5 inline-flex items-center justify-center w-4 h-4 rounded-full bg-amber-500 text-white text-[10px] font-bold">{pending}</span>
              )}
            </button>
          ))}
        </div>
      )}

      {isLoading ? (
        <div className="flex justify-center py-20"><Loader2 className="w-7 h-7 text-brand-500 animate-spin" /></div>
      ) : filtered.length === 0 ? (
        <EmptyState icon={Building2} title="No companies found"
          sub={isSuperAdmin ? 'Create your first company using the button above' : 'Your company record could not be loaded'} />
      ) : (
        <div className="space-y-3">
          {filtered.map((c) => {
            const isOpen   = expanded === c.id
            const commVal  = commission[c.id] ?? String(c.commission_rate)

            return (
              <div key={c.id} className="card overflow-hidden">
                <div className="flex items-center gap-4 px-5 py-4 cursor-pointer hover:bg-gray-50 transition-colors select-none"
                  onClick={() => { setExpanded(isOpen ? null : c.id); setDetailTab('info') }}>
                  <div className="w-10 h-10 rounded-xl bg-brand-50 text-brand-600 flex items-center justify-center font-bold text-lg flex-shrink-0">
                    {c.name[0]?.toUpperCase()}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold text-gray-900 truncate">{c.name}</p>
                    <p className="text-xs text-gray-400">{c.contact_email}</p>
                  </div>
                  <div className="hidden sm:flex items-center gap-6 text-center mr-2">
                    <div><p className="font-semibold text-sm text-gray-900">{c.total_employees}</p><p className="text-xs text-gray-400">Staff</p></div>
                    <div><p className="font-semibold text-sm text-gray-900">{c.rides_this_month}</p><p className="text-xs text-gray-400">Rides/mo</p></div>
                    <div><p className="font-semibold text-sm text-gray-900">{fmt.naira(c.gmv_this_month)}</p><p className="text-xs text-gray-400">GMV/mo</p></div>
                  </div>
                  <span className={badge(c.status)}>{c.status.replace('_', ' ')}</span>
                  <ChevronDown className={`w-4 h-4 text-gray-400 transition-transform flex-shrink-0 ${isOpen ? 'rotate-180' : ''}`} />
                </div>

                {isOpen && (
                  <div className="border-t border-gray-100">
                    <div className="flex gap-0 px-5 pt-3 border-b border-gray-100 overflow-x-auto">
                      {DETAIL_TABS.map(({ id, icon: Icon, label }) => (
                        <button key={id} onClick={() => setDetailTab(id)}
                          className={`flex items-center gap-1.5 px-3 py-2 text-xs font-medium border-b-2 whitespace-nowrap transition-colors ${detailTab === id ? 'border-brand-500 text-brand-600' : 'border-transparent text-gray-500 hover:text-gray-700'}`}>
                          <Icon className="w-3.5 h-3.5" /> {label(c)}
                        </button>
                      ))}
                    </div>

                    <div className="px-5 py-4 bg-gray-50">
                      {detailTab === 'info' && (
                        <div className="space-y-4">
                          {/* Every company admin (scoped or super) manages this
                              company's own branding from here — this was
                              previously only reachable as a small avatar in the
                              dashboard greeting for a scoped admin's OWN company,
                              with no equivalent for a super admin managing
                              someone else's company, and no path at all from the
                              actual company profile/detail view either. */}
                          <div className="flex items-center gap-4 bg-white border border-gray-200 rounded-xl p-3">
                            <label className="relative w-14 h-14 rounded-xl bg-brand-50 flex items-center justify-center overflow-hidden flex-shrink-0 cursor-pointer group">
                              {c.logo_url ? (
                                <img src={c.logo_url} alt={c.name} className="w-full h-full object-cover" />
                              ) : (
                                <Building2 className="w-7 h-7 text-brand-500" />
                              )}
                              <span className="absolute inset-0 bg-black/0 group-hover:bg-black/40 flex items-center justify-center transition-colors">
                                <Camera className="w-4 h-4 text-white opacity-0 group-hover:opacity-100 transition-opacity" />
                              </span>
                              <input
                                type="file"
                                accept="image/png,image/jpeg,image/webp"
                                className="hidden"
                                disabled={uploadLogo.isPending}
                                onChange={(e) => {
                                  const file = e.target.files?.[0]
                                  if (file) uploadLogo.mutate({ id: c.id, file })
                                  e.target.value = ''
                                }}
                              />
                            </label>
                            <div>
                              <p className="text-sm font-medium text-gray-800">Company logo</p>
                              <p className="text-xs text-gray-500">Shown on this company's console, on partner-sharing cards, and in the mobile app's company wallet picker</p>
                              {uploadLogo.isPending && <p className="text-xs text-brand-500 mt-0.5">Uploading…</p>}
                              {uploadLogo.isError && <p className="text-xs text-red-500 mt-0.5">{(uploadLogo.error as Error).message}</p>}
                            </div>
                          </div>
                          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                            <div><p className="text-gray-400 text-xs mb-0.5">Reg. Number</p><p className="font-medium">{c.registration_number || '—'}</p></div>
                            <div><p className="text-gray-400 text-xs mb-0.5">Contact Person</p><p className="font-medium">{c.contact_name}</p></div>
                            <div><p className="text-gray-400 text-xs mb-0.5">Phone</p><p className="font-medium">{c.contact_phone || '—'}</p></div>
                            <div><p className="text-gray-400 text-xs mb-0.5">Onboarded</p><p className="font-medium">{fmt.date(c.created_at)}</p></div>
                          </div>
                          {/* Approval, suspension, and commission are platform-level decisions —
                              the backend requires super-admin for all three. Commission rate is
                              also commercially sensitive (CC Ride's cut of the organisation's
                              rides), so a company's own scoped admin doesn't see this section at
                              all, not even read-only — the other actions still show a read-only
                              view instead of controls that would just 403. */}
                          {isSuperAdmin && (
                            <div className="flex items-center gap-3 bg-white border border-gray-200 rounded-xl p-3">
                              <Percent className="w-4 h-4 text-gray-400 flex-shrink-0" />
                              <label className="text-sm text-gray-600 font-medium">Commission rate</label>
                              <input type="number" value={commVal} min={0} max={40} step={0.5}
                                className="input w-20 text-center ml-auto"
                                onChange={(e) => setCommission((p) => ({ ...p, [c.id]: e.target.value }))}
                                onBlur={() => { const v = parseFloat(commVal); if (!isNaN(v) && v !== c.commission_rate) saveCommission.mutate({ id: c.id, rate: v }) }}
                              />
                              <span className="text-sm text-gray-400">% per ride</span>
                            </div>
                          )}
                          {isSuperAdmin && (
                            <div className="flex flex-wrap gap-2">
                              {c.status === 'pending_approval' && (
                                <>
                                  <button onClick={() => action.mutate({ id: c.id, act: 'approve' })} disabled={action.isPending} className="btn-primary text-sm"><CheckCircle className="w-4 h-4" /> Approve</button>
                                  <button onClick={() => { if (confirm(`Reject ${c.name}?`)) action.mutate({ id: c.id, act: 'reject' }) }} disabled={action.isPending} className="btn-danger text-sm"><XCircle className="w-4 h-4" /> Reject</button>
                                </>
                              )}
                              {c.status === 'active' && (
                                <button onClick={() => { if (confirm(`Suspend ${c.name}?`)) action.mutate({ id: c.id, act: 'suspend' }) }} disabled={action.isPending}
                                  className="btn text-sm bg-orange-50 text-orange-600 border border-orange-200 hover:bg-orange-100">Suspend</button>
                              )}
                              {(c.status === 'suspended' || c.status === 'rejected') && (
                                <button onClick={() => action.mutate({ id: c.id, act: 'activate' })} disabled={action.isPending} className="btn-primary text-sm"><CheckCircle className="w-4 h-4" /> Reinstate</button>
                              )}
                            </div>
                          )}
                        </div>
                      )}
                      {detailTab === 'employees'    && <EmployeeList companyId={c.id} />}
                      {detailTab === 'rides'        && <CompanyRides companyId={c.id} />}
                      {detailTab === 'departments'  && <DepartmentsTab companyId={c.id} />}
                      {detailTab === 'cost-centres' && <CostCentresTab companyId={c.id} />}
                      {detailTab === 'branches'     && <BranchesTab company={c} />}
                      {detailTab === 'wallet'       && <CreditLedgerTab company={c} />}
                      {detailTab === 'pool-policy'  && <PoolPolicyTab companyId={c.id} />}
                      {detailTab === 'fleet'        && <FleetTab companyId={c.id} />}
                      {detailTab === 'tracking'     && <PoolTrackingTab companyId={c.id} />}
                      {detailTab === 'savings'      && <SavingsReportTab companyId={c.id} />}
                    </div>
                  </div>
                )}
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
