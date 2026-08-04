import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Percent, Plus, Loader2, History, PowerOff, TrendingUp,
  Globe, Car, Building2, Clock, FileBarChart, Sparkles,
} from 'lucide-react'
import { get, post, patch } from '../lib/api'
import { fmt, badge, cn } from '../lib/utils'
import PageHeader from '../components/PageHeader'
import EmptyState from '../components/EmptyState'
import Modal from '../components/Modal'

// ─── Types ────────────────────────────────────────────────────────────────────

type Scope = 'global' | 'vehicle_type' | 'company' | 'time_window'

interface RateCard {
  id: string; scope: Scope
  vehicle_type_id: string | null; vehicle_type_title: string | null
  company_id: string | null; company_name: string | null
  days_of_week: number[]; time_from: string | null; time_to: string | null
  base_fare: number | null; fare_per_km: number | null; fare_per_min: number | null
  min_fare_floor: number | null; driver_earnings_floor: number | null
  commission_rate: number | null; surge_multiplier: number | null
  effective_from: string; effective_to: string | null; is_active: boolean
  created_at: string
}
interface ChangeLogEntry {
  id: string; field_changed: string; old_value: string | null; new_value: string | null
  reason: string | null; changed_by: string; changed_at: string
}
interface BenchmarkRate {
  id: string; vehicle_type_id: string | null; vehicle_type_title: string | null
  distance_band_km: string; competitor: string | null; sampled_fare: number
  sampled_at: string; source: string; is_active: boolean
}
interface SavingsReport {
  id: string; company_id: string; company_name: string
  period_start: string; period_end: string; total_rides: number
  total_market_benchmark_cost: number; total_org_spend: number
  total_savings: number; savings_percentage: number
  status: 'draft' | 'sent' | 'archived'; generated_at: string
}
interface VehicleType { id: string; title: string }
interface CompanyLite { id: string; name: string }

const SCOPE_LABEL: Record<Scope, string> = { global: 'Global', vehicle_type: 'Vehicle Type', company: 'Company', time_window: 'Time Window' }
const SCOPE_ICON: Record<Scope, typeof Globe> = { global: Globe, vehicle_type: Car, company: Building2, time_window: Clock }
const DAYS = [{ v: 1, l: 'Mon' }, { v: 2, l: 'Tue' }, { v: 3, l: 'Wed' }, { v: 4, l: 'Thu' }, { v: 5, l: 'Fri' }, { v: 6, l: 'Sat' }, { v: 7, l: 'Sun' }]
const DISTANCE_BANDS = ['0-5', '5-10', '10-20', '20-40', '40+']
const COMPETITORS = ['uber', 'bolt', 'indrive']

const FACTOR_FIELDS: Array<{ key: keyof typeof EMPTY_FACTORS; label: string; suffix?: string }> = [
  { key: 'base_fare', label: 'Base fare', suffix: '₦' },
  { key: 'fare_per_km', label: 'Fare / km', suffix: '₦' },
  { key: 'fare_per_min', label: 'Fare / min', suffix: '₦' },
  { key: 'min_fare_floor', label: 'Minimum fare floor', suffix: '₦' },
  { key: 'driver_earnings_floor', label: 'Driver earnings floor', suffix: '₦' },
  { key: 'commission_rate', label: 'Commission rate', suffix: '%' },
  { key: 'surge_multiplier', label: 'Max surge multiplier', suffix: '×' },
]

const EMPTY_FACTORS = {
  base_fare: '', fare_per_km: '', fare_per_min: '', min_fare_floor: '',
  driver_earnings_floor: '', commission_rate: '', surge_multiplier: '',
}

function factorsToPayload(f: typeof EMPTY_FACTORS) {
  const out: Record<string, number> = {}
  for (const k of Object.keys(f) as Array<keyof typeof f>) {
    if (f[k] !== '') out[k] = parseFloat(f[k])
  }
  return out
}

// ─── Page ─────────────────────────────────────────────────────────────────────

type Tab = 'rate-cards' | 'benchmarks' | 'savings'

export default function Pricing() {
  const [tab, setTab] = useState<Tab>('rate-cards')

  return (
    <div className="space-y-5">
      <PageHeader
        title="Pricing"
        sub="Fare factors, competitor benchmarks, and corporate savings reporting"
      />

      <div className="flex gap-1 border-b border-gray-200">
        {([
          ['rate-cards', 'Rate Cards', Percent],
          ['benchmarks', 'Market Benchmarks', TrendingUp],
          ['savings', 'Corporate Savings', FileBarChart],
        ] as const).map(([key, label, Icon]) => (
          <button key={key} onClick={() => setTab(key)}
            className={cn(
              'flex items-center gap-1.5 px-4 py-2.5 text-sm font-medium border-b-2 -mb-px transition-colors',
              tab === key ? 'border-brand-500 text-brand-600' : 'border-transparent text-gray-500 hover:text-gray-700',
            )}>
            <Icon className="w-4 h-4" /> {label}
          </button>
        ))}
      </div>

      {tab === 'rate-cards' && <RateCardsTab />}
      {tab === 'benchmarks' && <BenchmarksTab />}
      {tab === 'savings' && <SavingsReportsTab />}
    </div>
  )
}

// ─── Rate cards tab ─────────────────────────────────────────────────────────

function RateCardsTab() {
  const [showCreate, setShowCreate] = useState(false)
  const [supersedeTarget, setSupersedeTarget] = useState<RateCard | null>(null)
  const [historyTarget, setHistoryTarget] = useState<RateCard | null>(null)
  const [deactivateTarget, setDeactivateTarget] = useState<RateCard | null>(null)

  const { data: cards = [], isLoading } = useQuery<RateCard[]>({
    queryKey: ['pricing-rate-cards'],
    queryFn: () => get('/admin/pricing-rate-cards'),
  })

  if (isLoading) return <div className="flex justify-center py-16"><Loader2 className="w-6 h-6 animate-spin text-brand-500" /></div>

  const active = cards.filter((c) => c.is_active && !c.effective_to)
  const history = cards.filter((c) => !(c.is_active && !c.effective_to))

  return (
    <div className="space-y-5">
      <div className="flex justify-end">
        <button onClick={() => setShowCreate(true)} className="btn-primary text-sm">
          <Plus className="w-4 h-4" /> New Rate Card
        </button>
      </div>

      {active.length === 0 ? (
        <EmptyState icon={Percent} title="No active rate cards"
          sub="Fares fall back to Platform Settings defaults until a rate card is created." />
      ) : (
        <div className="card p-0 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-gray-500 text-xs uppercase">
              <tr>
                <th className="text-left px-4 py-2.5 font-medium">Scope</th>
                <th className="text-left px-4 py-2.5 font-medium">Applies to</th>
                <th className="text-left px-4 py-2.5 font-medium">Commission</th>
                <th className="text-left px-4 py-2.5 font-medium">Driver floor</th>
                <th className="text-left px-4 py-2.5 font-medium">Surge cap</th>
                <th className="text-left px-4 py-2.5 font-medium">Effective from</th>
                <th className="text-right px-4 py-2.5 font-medium">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {active.map((c) => {
                const Icon = SCOPE_ICON[c.scope]
                return (
                  <tr key={c.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <span className="inline-flex items-center gap-1.5 text-gray-700 font-medium">
                        <Icon className="w-3.5 h-3.5 text-gray-400" /> {SCOPE_LABEL[c.scope]}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-gray-500">
                      {c.scope === 'vehicle_type' && (c.vehicle_type_title ?? '—')}
                      {c.scope === 'company' && (c.company_name ?? '—')}
                      {c.scope === 'time_window' && `${c.time_from}–${c.time_to}${c.days_of_week.length ? ` (${c.days_of_week.map((d) => DAYS.find((x) => x.v === d)?.l).join(',')})` : ' (daily)'}`}
                      {c.scope === 'global' && 'All rides'}
                    </td>
                    <td className="px-4 py-3">{c.commission_rate != null ? fmt.percent(c.commission_rate) : <span className="text-gray-300">inherit</span>}</td>
                    <td className="px-4 py-3">{c.driver_earnings_floor != null ? fmt.naira(c.driver_earnings_floor) : <span className="text-gray-300">—</span>}</td>
                    <td className="px-4 py-3">{c.surge_multiplier != null ? `${c.surge_multiplier}×` : <span className="text-gray-300">—</span>}</td>
                    <td className="px-4 py-3 text-gray-500">{fmt.date(c.effective_from)}</td>
                    <td className="px-4 py-3 text-right space-x-1">
                      <button onClick={() => setHistoryTarget(c)} className="btn-secondary text-xs px-2 py-1" title="Change history">
                        <History className="w-3.5 h-3.5" />
                      </button>
                      <button onClick={() => setSupersedeTarget(c)} className="btn-secondary text-xs px-2 py-1">Edit</button>
                      <button onClick={() => setDeactivateTarget(c)} className="btn-danger text-xs px-2 py-1">
                        <PowerOff className="w-3.5 h-3.5" />
                      </button>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      )}

      {history.length > 0 && (
        <details className="text-sm">
          <summary className="cursor-pointer text-gray-500 font-medium">Superseded / deactivated ({history.length})</summary>
          <div className="mt-2 space-y-1.5">
            {history.map((c) => (
              <div key={c.id} className="flex items-center gap-3 text-xs text-gray-400 px-3 py-2 bg-gray-50 rounded-lg">
                <span className={badge(c.is_active ? 'completed' : 'cancelled')}>{c.is_active ? 'superseded' : 'deactivated'}</span>
                <span>{SCOPE_LABEL[c.scope]}</span>
                <span>{fmt.date(c.effective_from)} → {c.effective_to ? fmt.date(c.effective_to) : '—'}</span>
              </div>
            ))}
          </div>
        </details>
      )}

      <CreateRateCardModal open={showCreate} onClose={() => setShowCreate(false)} />
      {supersedeTarget && <SupersedeRateCardModal card={supersedeTarget} onClose={() => setSupersedeTarget(null)} />}
      {historyTarget && <RateCardHistoryModal card={historyTarget} onClose={() => setHistoryTarget(null)} />}
      {deactivateTarget && <DeactivateRateCardModal card={deactivateTarget} onClose={() => setDeactivateTarget(null)} />}
    </div>
  )
}

function useVehicleTypes() {
  return useQuery<VehicleType[]>({ queryKey: ['vehicle-types'], queryFn: () => get('/admin/vehicle-types') })
}
function useCompaniesLite() {
  return useQuery<CompanyLite[]>({ queryKey: ['companies-lite'], queryFn: () => get('/admin/companies') })
}

function FactorFields({ values, onChange }: { values: typeof EMPTY_FACTORS; onChange: (v: typeof EMPTY_FACTORS) => void }) {
  return (
    <div className="grid grid-cols-2 gap-3">
      {FACTOR_FIELDS.map(({ key, label, suffix }) => (
        <div key={key}>
          <label className="text-xs text-gray-500 mb-1 block">{label} {suffix && <span className="text-gray-300">({suffix})</span>}</label>
          <input type="number" step="0.01" className="input" placeholder="inherit"
            value={values[key]} onChange={(e) => onChange({ ...values, [key]: e.target.value })} />
        </div>
      ))}
    </div>
  )
}

function CreateRateCardModal({ open, onClose }: { open: boolean; onClose: () => void }) {
  const qc = useQueryClient()
  const { data: vehicleTypes = [] } = useVehicleTypes()
  const { data: companies = [] } = useCompaniesLite()
  const [scope, setScope] = useState<Scope>('global')
  const [vehicleTypeId, setVehicleTypeId] = useState('')
  const [companyId, setCompanyId] = useState('')
  const [days, setDays] = useState<number[]>([])
  const [timeFrom, setTimeFrom] = useState('22:00')
  const [timeTo, setTimeTo] = useState('05:00')
  const [factors, setFactors] = useState(EMPTY_FACTORS)
  const [err, setErr] = useState('')

  const reset = () => { setScope('global'); setVehicleTypeId(''); setCompanyId(''); setDays([]); setFactors(EMPTY_FACTORS); setErr('') }

  const create = useMutation({
    mutationFn: () => post('/admin/pricing-rate-cards', {
      scope,
      vehicle_type_id: scope === 'vehicle_type' ? vehicleTypeId : undefined,
      company_id: scope === 'company' ? companyId : undefined,
      days_of_week: scope === 'time_window' ? days : undefined,
      time_from: scope === 'time_window' ? timeFrom : undefined,
      time_to: scope === 'time_window' ? timeTo : undefined,
      ...factorsToPayload(factors),
    }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['pricing-rate-cards'] }); reset(); onClose() },
    onError: (e: any) => setErr(e?.message ?? 'Failed to create rate card'),
  })

  return (
    <Modal open={open} onClose={() => { reset(); onClose() }} title="New pricing rate card" size="lg">
      <div className="space-y-4">
        {err && <div className="bg-red-50 border border-red-200 text-red-700 text-xs px-3 py-2 rounded-lg">{err}</div>}

        <div>
          <label className="text-xs text-gray-500 mb-1 block">Scope</label>
          <div className="grid grid-cols-4 gap-2">
            {(Object.keys(SCOPE_LABEL) as Scope[]).map((s) => {
              const Icon = SCOPE_ICON[s]
              return (
                <button key={s} onClick={() => setScope(s)}
                  className={cn('flex flex-col items-center gap-1 py-2.5 rounded-lg border text-xs font-medium transition-colors',
                    scope === s ? 'border-brand-500 bg-brand-50 text-brand-600' : 'border-gray-200 text-gray-500 hover:border-gray-300')}>
                  <Icon className="w-4 h-4" /> {SCOPE_LABEL[s]}
                </button>
              )
            })}
          </div>
        </div>

        {scope === 'vehicle_type' && (
          <div>
            <label className="text-xs text-gray-500 mb-1 block">Vehicle type</label>
            <select className="input" value={vehicleTypeId} onChange={(e) => setVehicleTypeId(e.target.value)}>
              <option value="">Select vehicle type…</option>
              {vehicleTypes.map((v) => <option key={v.id} value={v.id}>{v.title}</option>)}
            </select>
          </div>
        )}

        {scope === 'company' && (
          <div>
            <label className="text-xs text-gray-500 mb-1 block">Company</label>
            <select className="input" value={companyId} onChange={(e) => setCompanyId(e.target.value)}>
              <option value="">Select company…</option>
              {companies.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </div>
        )}

        {scope === 'time_window' && (
          <div className="space-y-3">
            <div>
              <label className="text-xs text-gray-500 mb-1 block">Days (leave empty for every day)</label>
              <div className="flex gap-1.5">
                {DAYS.map((d) => (
                  <button key={d.v} onClick={() => setDays((p) => p.includes(d.v) ? p.filter((x) => x !== d.v) : [...p, d.v])}
                    className={cn('w-9 h-9 rounded-lg text-xs font-medium border transition-colors',
                      days.includes(d.v) ? 'border-brand-500 bg-brand-50 text-brand-600' : 'border-gray-200 text-gray-500')}>
                    {d.l}
                  </button>
                ))}
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs text-gray-500 mb-1 block">From</label>
                <input type="time" className="input" value={timeFrom} onChange={(e) => setTimeFrom(e.target.value)} />
              </div>
              <div>
                <label className="text-xs text-gray-500 mb-1 block">To</label>
                <input type="time" className="input" value={timeTo} onChange={(e) => setTimeTo(e.target.value)} />
              </div>
            </div>
          </div>
        )}

        <div className="border-t border-gray-100 pt-4">
          <p className="text-xs font-medium text-gray-500 mb-2">Factors — leave blank to inherit from a lower-priority layer</p>
          <FactorFields values={factors} onChange={setFactors} />
        </div>

        <button onClick={() => create.mutate()} disabled={create.isPending} className="btn-primary w-full justify-center">
          {create.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />} Create rate card
        </button>
      </div>
    </Modal>
  )
}

function SupersedeRateCardModal({ card, onClose }: { card: RateCard; onClose: () => void }) {
  const qc = useQueryClient()
  const [factors, setFactors] = useState({
    base_fare: card.base_fare?.toString() ?? '',
    fare_per_km: card.fare_per_km?.toString() ?? '',
    fare_per_min: card.fare_per_min?.toString() ?? '',
    min_fare_floor: card.min_fare_floor?.toString() ?? '',
    driver_earnings_floor: card.driver_earnings_floor?.toString() ?? '',
    commission_rate: card.commission_rate?.toString() ?? '',
    surge_multiplier: card.surge_multiplier?.toString() ?? '',
  })
  const [reason, setReason] = useState('')
  const [err, setErr] = useState('')

  const supersede = useMutation({
    mutationFn: () => patch(`/admin/pricing-rate-cards/${card.id}/supersede`, { ...factorsToPayload(factors), reason }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['pricing-rate-cards'] }); onClose() },
    onError: (e: any) => setErr(e?.message ?? 'Failed to update rate card'),
  })

  return (
    <Modal open onClose={onClose} title={`Edit ${SCOPE_LABEL[card.scope]} rate card`} size="lg">
      <div className="space-y-4">
        {err && <div className="bg-red-50 border border-red-200 text-red-700 text-xs px-3 py-2 rounded-lg">{err}</div>}
        <div className="bg-amber-50 border border-amber-200 text-amber-800 text-xs px-3 py-2 rounded-lg">
          This won't overwrite the existing row — it closes it and opens a new one, keeping full history.
        </div>
        <FactorFields values={factors} onChange={setFactors} />
        <div>
          <label className="text-xs text-gray-500 mb-1 block">Reason for this change *</label>
          <textarea className="input" rows={2} placeholder="e.g. Fuel price adjustment approved by finance"
            value={reason} onChange={(e) => setReason(e.target.value)} />
        </div>
        <button onClick={() => supersede.mutate()} disabled={supersede.isPending || reason.trim().length < 3}
          className="btn-primary w-full justify-center">
          {supersede.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Sparkles className="w-4 h-4" />} Save as new version
        </button>
      </div>
    </Modal>
  )
}

function DeactivateRateCardModal({ card, onClose }: { card: RateCard; onClose: () => void }) {
  const qc = useQueryClient()
  const [reason, setReason] = useState('')
  const [err, setErr] = useState('')

  const deactivate = useMutation({
    mutationFn: () => patch(`/admin/pricing-rate-cards/${card.id}/deactivate`, { reason }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['pricing-rate-cards'] }); onClose() },
    onError: (e: any) => setErr(e?.message ?? 'Failed to deactivate'),
  })

  return (
    <Modal open onClose={onClose} title="Deactivate rate card" size="sm">
      <div className="space-y-4">
        {err && <div className="bg-red-50 border border-red-200 text-red-700 text-xs px-3 py-2 rounded-lg">{err}</div>}
        <p className="text-sm text-gray-600">
          Removes this override — matching rides fall back to the next layer down (or Platform Settings defaults).
        </p>
        <div>
          <label className="text-xs text-gray-500 mb-1 block">Reason *</label>
          <textarea className="input" rows={2} value={reason} onChange={(e) => setReason(e.target.value)} />
        </div>
        <button onClick={() => deactivate.mutate()} disabled={deactivate.isPending || reason.trim().length < 3}
          className="btn-danger w-full justify-center">
          {deactivate.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <PowerOff className="w-4 h-4" />} Deactivate
        </button>
      </div>
    </Modal>
  )
}

function RateCardHistoryModal({ card, onClose }: { card: RateCard; onClose: () => void }) {
  const { data: log = [], isLoading } = useQuery<ChangeLogEntry[]>({
    queryKey: ['rate-card-history', card.id],
    queryFn: () => get(`/admin/pricing-rate-cards/${card.id}/history`),
  })

  return (
    <Modal open onClose={onClose} title={`Change history — ${SCOPE_LABEL[card.scope]}`} size="md">
      {isLoading ? (
        <div className="flex justify-center py-8"><Loader2 className="w-5 h-5 animate-spin text-brand-500" /></div>
      ) : log.length === 0 ? (
        <p className="text-sm text-gray-400 text-center py-6">No changes logged for this rate card yet.</p>
      ) : (
        <div className="space-y-2">
          {log.map((l) => (
            <div key={l.id} className="text-xs bg-gray-50 rounded-lg px-3 py-2.5">
              <div className="flex justify-between text-gray-500">
                <span className="font-medium text-gray-700">{l.field_changed}</span>
                <span>{fmt.datetime(l.changed_at)}</span>
              </div>
              <p className="mt-1 text-gray-600">{l.old_value ?? '—'} → {l.new_value ?? '—'}</p>
              {l.reason && <p className="mt-1 text-gray-400 italic">"{l.reason}"</p>}
              <p className="mt-1 text-gray-400">by {l.changed_by}</p>
            </div>
          ))}
        </div>
      )}
    </Modal>
  )
}

// ─── Market benchmarks tab ──────────────────────────────────────────────────

function BenchmarksTab() {
  const [showAdd, setShowAdd] = useState(false)
  const { data: rates = [], isLoading } = useQuery<BenchmarkRate[]>({
    queryKey: ['market-benchmark-rates'],
    queryFn: () => get('/admin/market-benchmark-rates'),
  })

  if (isLoading) return <div className="flex justify-center py-16"><Loader2 className="w-6 h-6 animate-spin text-brand-500" /></div>

  const active = rates.filter((r) => r.is_active)

  return (
    <div className="space-y-5">
      <div className="flex justify-between items-center">
        <p className="text-sm text-gray-500">Admin-entered competitor samples — kept separate from CC Ride's own rate cards so savings reports never grade CC Ride against itself.</p>
        <button onClick={() => setShowAdd(true)} className="btn-primary text-sm whitespace-nowrap ml-4">
          <Plus className="w-4 h-4" /> Add Sample
        </button>
      </div>

      {active.length === 0 ? (
        <EmptyState icon={TrendingUp} title="No benchmark samples yet"
          sub="Add competitor fares by distance band to unlock corporate savings reporting." />
      ) : (
        <div className="card p-0 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-gray-500 text-xs uppercase">
              <tr>
                <th className="text-left px-4 py-2.5 font-medium">Distance band</th>
                <th className="text-left px-4 py-2.5 font-medium">Vehicle type</th>
                <th className="text-left px-4 py-2.5 font-medium">Competitor</th>
                <th className="text-left px-4 py-2.5 font-medium">Sampled fare</th>
                <th className="text-left px-4 py-2.5 font-medium">Sampled</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {active.map((r) => (
                <tr key={r.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium text-gray-700">{r.distance_band_km} km</td>
                  <td className="px-4 py-3 text-gray-500">{r.vehicle_type_title ?? 'Any'}</td>
                  <td className="px-4 py-3 text-gray-500 capitalize">{r.competitor ?? 'Blended'}</td>
                  <td className="px-4 py-3">{fmt.naira(r.sampled_fare)}</td>
                  <td className="px-4 py-3 text-gray-500">{fmt.relative(r.sampled_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <AddBenchmarkModal open={showAdd} onClose={() => setShowAdd(false)} />
    </div>
  )
}

function AddBenchmarkModal({ open, onClose }: { open: boolean; onClose: () => void }) {
  const qc = useQueryClient()
  const { data: vehicleTypes = [] } = useVehicleTypes()
  const [form, setForm] = useState({ vehicle_type_id: '', distance_band_km: '0-5', competitor: '', sampled_fare: '' })
  const [err, setErr] = useState('')

  const create = useMutation({
    mutationFn: () => post('/admin/market-benchmark-rates', {
      vehicle_type_id: form.vehicle_type_id || undefined,
      distance_band_km: form.distance_band_km,
      competitor: form.competitor || undefined,
      sampled_fare: parseFloat(form.sampled_fare),
    }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['market-benchmark-rates'] })
      setForm({ vehicle_type_id: '', distance_band_km: '0-5', competitor: '', sampled_fare: '' })
      setErr('')
      onClose()
    },
    onError: (e: any) => setErr(e?.message ?? 'Failed to record sample'),
  })

  return (
    <Modal open={open} onClose={onClose} title="Add competitor fare sample">
      <div className="space-y-4">
        {err && <div className="bg-red-50 border border-red-200 text-red-700 text-xs px-3 py-2 rounded-lg">{err}</div>}

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="text-xs text-gray-500 mb-1 block">Distance band</label>
            <select className="input" value={form.distance_band_km} onChange={(e) => setForm((p) => ({ ...p, distance_band_km: e.target.value }))}>
              {DISTANCE_BANDS.map((b) => <option key={b} value={b}>{b} km</option>)}
            </select>
          </div>
          <div>
            <label className="text-xs text-gray-500 mb-1 block">Competitor</label>
            <select className="input" value={form.competitor} onChange={(e) => setForm((p) => ({ ...p, competitor: e.target.value }))}>
              <option value="">Blended average</option>
              {COMPETITORS.map((c) => <option key={c} value={c} className="capitalize">{c}</option>)}
            </select>
          </div>
        </div>

        <div>
          <label className="text-xs text-gray-500 mb-1 block">Vehicle type (optional)</label>
          <select className="input" value={form.vehicle_type_id} onChange={(e) => setForm((p) => ({ ...p, vehicle_type_id: e.target.value }))}>
            <option value="">Any vehicle type</option>
            {vehicleTypes.map((v) => <option key={v.id} value={v.id}>{v.title}</option>)}
          </select>
        </div>

        <div>
          <label className="text-xs text-gray-500 mb-1 block">Sampled fare (₦)</label>
          <input type="number" step="0.01" className="input" placeholder="e.g. 1800"
            value={form.sampled_fare} onChange={(e) => setForm((p) => ({ ...p, sampled_fare: e.target.value }))} />
        </div>

        <button onClick={() => create.mutate()} disabled={create.isPending || !form.sampled_fare} className="btn-primary w-full justify-center">
          {create.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />} Record sample
        </button>
      </div>
    </Modal>
  )
}

// ─── Corporate savings reports tab ──────────────────────────────────────────

function SavingsReportsTab() {
  const qc = useQueryClient()
  const { data: companies = [] } = useCompaniesLite()
  const [companyId, setCompanyId] = useState('')
  const [periodStart, setPeriodStart] = useState('')
  const [periodEnd, setPeriodEnd] = useState('')
  const [err, setErr] = useState('')

  const { data: reports = [], isLoading } = useQuery<SavingsReport[]>({
    queryKey: ['savings-reports'],
    queryFn: () => get('/admin/savings-reports'),
  })

  const generate = useMutation({
    mutationFn: () => post('/admin/savings-reports/generate', { company_id: companyId, period_start: periodStart, period_end: periodEnd }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['savings-reports'] }); setErr('') },
    onError: (e: any) => setErr(e?.message ?? 'Failed to generate report'),
  })

  const setStatus = useMutation({
    mutationFn: ({ id, status }: { id: string; status: string }) => patch(`/admin/savings-reports/${id}/status`, { status }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['savings-reports'] }),
  })

  return (
    <div className="space-y-5">
      <div className="card">
        <p className="text-sm font-medium text-gray-700 mb-3">Generate a report</p>
        {err && <div className="bg-red-50 border border-red-200 text-red-700 text-xs px-3 py-2 rounded-lg mb-3">{err}</div>}
        <div className="flex gap-3 items-end flex-wrap">
          <div className="flex-1 min-w-[180px]">
            <label className="text-xs text-gray-500 mb-1 block">Company</label>
            <select className="input" value={companyId} onChange={(e) => setCompanyId(e.target.value)}>
              <option value="">Select company…</option>
              {companies.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </div>
          <div>
            <label className="text-xs text-gray-500 mb-1 block">Period start</label>
            <input type="date" className="input" value={periodStart} onChange={(e) => setPeriodStart(e.target.value)} />
          </div>
          <div>
            <label className="text-xs text-gray-500 mb-1 block">Period end</label>
            <input type="date" className="input" value={periodEnd} onChange={(e) => setPeriodEnd(e.target.value)} />
          </div>
          <button onClick={() => generate.mutate()} disabled={generate.isPending || !companyId || !periodStart || !periodEnd}
            className="btn-primary h-10">
            {generate.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Sparkles className="w-4 h-4" />} Generate
          </button>
        </div>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-16"><Loader2 className="w-6 h-6 animate-spin text-brand-500" /></div>
      ) : reports.length === 0 ? (
        <EmptyState icon={FileBarChart} title="No savings reports yet"
          sub="Generate a report above once corporate rides have completed for the selected period." />
      ) : (
        <div className="grid gap-3 md:grid-cols-2">
          {reports.map((r) => (
            <div key={r.id} className="card">
              <div className="flex items-start justify-between">
                <div>
                  <p className="font-semibold text-gray-900">{r.company_name}</p>
                  <p className="text-xs text-gray-400">{fmt.date(r.period_start)} – {fmt.date(r.period_end)}</p>
                </div>
                <select className={cn(badge(r.status === 'sent' ? 'completed' : r.status === 'archived' ? 'inactive' : 'pending'), 'border-0 cursor-pointer')}
                  value={r.status} onChange={(e) => setStatus.mutate({ id: r.id, status: e.target.value })}>
                  <option value="draft">draft</option>
                  <option value="sent">sent</option>
                  <option value="archived">archived</option>
                </select>
              </div>
              <div className="grid grid-cols-2 gap-3 mt-4 text-sm">
                <div>
                  <p className="text-xs text-gray-400">Rides</p>
                  <p className="font-semibold text-gray-800">{r.total_rides}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-400">Savings</p>
                  <p className="font-semibold text-green-600">{fmt.naira(r.total_savings)} ({fmt.percent(r.savings_percentage)})</p>
                </div>
                <div>
                  <p className="text-xs text-gray-400">Market benchmark cost</p>
                  <p className="text-gray-700">{fmt.naira(r.total_market_benchmark_cost)}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-400">Actual org spend</p>
                  <p className="text-gray-700">{fmt.naira(r.total_org_spend)}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
