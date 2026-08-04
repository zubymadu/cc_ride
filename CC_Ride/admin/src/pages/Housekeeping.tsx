import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Trash2, Pencil, Search, Loader2, AlertTriangle, Users, Car, MapPin,
  Building2, Wallet, Banknote, Check, X,
} from 'lucide-react'
import { get, post, patch, del } from '../lib/api'
import { fmt, badge, cn } from '../lib/utils'
import PageHeader from '../components/PageHeader'
import EmptyState from '../components/EmptyState'
import Modal from '../components/Modal'

// ─── Types ────────────────────────────────────────────────────────────────────

interface AdminUserRow { id: string; name: string; email: string; mobile: string; wallet_balance: number; is_driver: boolean; status: string; created_at: string }
interface AdminDriverRow { user_id: string; name: string; email: string; mobile: string; status: string; average_rating: number }
interface AdminRideRow { id: string; ride_id: string; passenger: string; driver: string; company_name: string | null; origin: string; destination: string; status: string; total_amount: number; created_at: string; is_corporate: boolean }
interface AdminCompanyRow { id: string; name: string; contact_email: string; status: string; wallet_balance?: number }
interface WalletTxnRow { id: string; passenger: string }
interface PayoutRow { id: string; driver: string; amount: number; status: string; requested_at: string; bank_name: string; account_number: string }
interface TransactionRow { id: string; reference: string; passenger: string; driver: string; amount: number; gateway: string; status: string; created_at: string; is_corporate: boolean }

// ─── Shared helpers ───────────────────────────────────────────────────────────

function useDeleteWithForce<T = unknown>(path: (row: T) => string, queryKey: string[]) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async ({ row, force }: { row: T; force: boolean }) =>
      del(path(row) + (force ? '?force=true' : '')),
    onSuccess: () => qc.invalidateQueries({ queryKey }),
  })
}

function DeleteButton<T>({ row, guardLabel, onConfirm }: { row: T; guardLabel: string; onConfirm: (row: T, force: boolean) => Promise<unknown> }) {
  const [busy, setBusy] = useState(false)
  const [err, setErr] = useState('')

  async function handleClick() {
    if (!confirm(`Delete this ${guardLabel}? This cannot be undone.`)) return
    setBusy(true); setErr('')
    try {
      await onConfirm(row, false)
    } catch (e: any) {
      const msg = e?.message ?? 'Failed'
      if (msg.toLowerCase().includes('force=true')) {
        if (confirm(`${msg}\n\nForce delete anyway?`)) {
          try {
            await onConfirm(row, true)
          } catch (e2: any) {
            setErr(e2?.message ?? 'Failed')
          }
        }
      } else {
        setErr(msg)
      }
    } finally {
      setBusy(false)
    }
  }

  return (
    <span className="inline-flex items-center gap-1">
      <button onClick={handleClick} disabled={busy} className="p-1.5 rounded-lg text-red-500 hover:bg-red-50 transition-colors" title="Delete">
        {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <Trash2 className="w-4 h-4" />}
      </button>
      {err && <span className="text-xs text-red-600 max-w-[200px] truncate" title={err}>{err}</span>}
    </span>
  )
}

// ─── Users tab ────────────────────────────────────────────────────────────────

function UsersTab() {
  const [search, setSearch] = useState('')
  const [editing, setEditing] = useState<AdminUserRow | null>(null)
  const qc = useQueryClient()

  const { data = [], isLoading } = useQuery<AdminUserRow[]>({
    queryKey: ['hk-users', search],
    queryFn: () => get('/admin/users', search ? { search } : undefined),
  })

  const deleteUser = useDeleteWithForce<AdminUserRow>((r) => `/admin/users/${r.id}`, ['hk-users'])
  const editUser = useMutation({
    mutationFn: (vars: { id: string; name: string; email: string; mobile: string }) =>
      patch(`/admin/users/${vars.id}`, { name: vars.name, email: vars.email || null, mobile: vars.mobile }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['hk-users'] }); setEditing(null) },
  })

  return (
    <div className="space-y-4">
      <div className="relative max-w-xs">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input className="input pl-9" placeholder="Search name, email, mobile…" value={search} onChange={(e) => setSearch(e.target.value)} />
      </div>

      {isLoading ? <div className="flex justify-center py-16"><Loader2 className="w-6 h-6 animate-spin text-brand-500" /></div>
      : data.length === 0 ? <EmptyState icon={Users} title="No users found" />
      : (
        <div className="card p-0 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-gray-500 text-xs uppercase">
              <tr>
                <th className="text-left px-4 py-2.5 font-medium">Name</th>
                <th className="text-left px-4 py-2.5 font-medium">Contact</th>
                <th className="text-left px-4 py-2.5 font-medium">Wallet</th>
                <th className="text-left px-4 py-2.5 font-medium">Status</th>
                <th className="text-right px-4 py-2.5 font-medium">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {data.map((u) => (
                <tr key={u.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium text-gray-800">{u.name} {u.is_driver && <span className={cn(badge('confirmed'), 'ml-1.5')}>driver</span>}</td>
                  <td className="px-4 py-3 text-gray-500">{u.email || '—'} · {u.mobile}</td>
                  <td className="px-4 py-3">{fmt.naira(u.wallet_balance)}</td>
                  <td className="px-4 py-3"><span className={badge(u.status)}>{u.status}</span></td>
                  <td className="px-4 py-3 text-right">
                    <button onClick={() => setEditing(u)} className="p-1.5 rounded-lg text-gray-400 hover:bg-gray-100 transition-colors mr-1" title="Edit">
                      <Pencil className="w-4 h-4" />
                    </button>
                    <DeleteButton row={u} guardLabel="user" onConfirm={(row, force) => deleteUser.mutateAsync({ row, force })} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {editing && (
        <Modal open onClose={() => setEditing(null)} title={`Edit ${editing.name}`} size="sm">
          <EditUserForm row={editing} onSave={(v) => editUser.mutate({ id: editing.id, ...v })} saving={editUser.isPending} />
        </Modal>
      )}
    </div>
  )
}

function EditUserForm({ row, onSave, saving }: { row: { name: string; email: string; mobile: string }; onSave: (v: { name: string; email: string; mobile: string }) => void; saving: boolean }) {
  const [name, setName] = useState(row.name)
  const [email, setEmail] = useState(row.email)
  const [mobile, setMobile] = useState(row.mobile)
  return (
    <div className="space-y-3">
      <div><label className="text-xs text-gray-500 mb-1 block">Name</label><input className="input" value={name} onChange={(e) => setName(e.target.value)} /></div>
      <div><label className="text-xs text-gray-500 mb-1 block">Email</label><input className="input" value={email} onChange={(e) => setEmail(e.target.value)} /></div>
      <div><label className="text-xs text-gray-500 mb-1 block">Mobile</label><input className="input" value={mobile} onChange={(e) => setMobile(e.target.value)} /></div>
      <button onClick={() => onSave({ name, email, mobile })} disabled={saving} className="btn-primary w-full justify-center">
        {saving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Check className="w-4 h-4" />} Save
      </button>
    </div>
  )
}

// ─── Drivers tab ──────────────────────────────────────────────────────────────

function DriversTab() {
  const [search, setSearch] = useState('')
  const { data = [], isLoading } = useQuery<AdminDriverRow[]>({
    queryKey: ['hk-drivers', search],
    queryFn: () => get('/admin/drivers', search ? { search } : undefined),
  })
  const deleteDriver = useDeleteWithForce<AdminDriverRow>((r) => `/admin/drivers/${r.user_id}`, ['hk-drivers'])

  return (
    <div className="space-y-4">
      <div className="relative max-w-xs">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input className="input pl-9" placeholder="Search name, email, mobile…" value={search} onChange={(e) => setSearch(e.target.value)} />
      </div>
      {isLoading ? <div className="flex justify-center py-16"><Loader2 className="w-6 h-6 animate-spin text-brand-500" /></div>
      : data.length === 0 ? <EmptyState icon={Car} title="No drivers found" />
      : (
        <div className="card p-0 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-gray-500 text-xs uppercase">
              <tr><th className="text-left px-4 py-2.5 font-medium">Name</th><th className="text-left px-4 py-2.5 font-medium">Contact</th><th className="text-left px-4 py-2.5 font-medium">Rating</th><th className="text-left px-4 py-2.5 font-medium">Status</th><th className="text-right px-4 py-2.5 font-medium">Actions</th></tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {data.map((d) => (
                <tr key={d.user_id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium text-gray-800">{d.name}</td>
                  <td className="px-4 py-3 text-gray-500">{d.email || '—'} · {d.mobile}</td>
                  <td className="px-4 py-3">{d.average_rating.toFixed(1)}★</td>
                  <td className="px-4 py-3"><span className={badge(d.status)}>{d.status}</span></td>
                  <td className="px-4 py-3 text-right">
                    <DeleteButton row={d} guardLabel="driver" onConfirm={(row, force) => deleteDriver.mutateAsync({ row, force })} />
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

// ─── Rides tab ────────────────────────────────────────────────────────────────

function RidesTab() {
  const { data = [], isLoading } = useQuery<AdminRideRow[]>({
    queryKey: ['hk-rides'],
    queryFn: () => get('/admin/rides'),
  })
  const deleteRide = useDeleteWithForce<AdminRideRow>((r) => `/admin/rides/${r.ride_id}`, ['hk-rides'])

  return (
    <div className="space-y-4">
      {isLoading ? <div className="flex justify-center py-16"><Loader2 className="w-6 h-6 animate-spin text-brand-500" /></div>
      : data.length === 0 ? <EmptyState icon={MapPin} title="No rides found" />
      : (
        <div className="card p-0 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-gray-500 text-xs uppercase">
              <tr><th className="text-left px-4 py-2.5 font-medium">Route</th><th className="text-left px-4 py-2.5 font-medium">Passenger / Driver</th><th className="text-left px-4 py-2.5 font-medium">Amount</th><th className="text-left px-4 py-2.5 font-medium">Status</th><th className="text-right px-4 py-2.5 font-medium">Actions</th></tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {data.map((r) => (
                <tr key={r.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-gray-700">{r.origin} → {r.destination}{r.company_name && <span className="ml-1.5 text-xs text-gray-400">({r.company_name})</span>}</td>
                  <td className="px-4 py-3 text-gray-500">{r.passenger} / {r.driver}</td>
                  <td className="px-4 py-3">{fmt.naira(r.total_amount)}</td>
                  <td className="px-4 py-3"><span className={badge(r.status)}>{r.status}</span></td>
                  <td className="px-4 py-3 text-right">
                    <DeleteButton row={r} guardLabel="ride" onConfirm={(row, force) => deleteRide.mutateAsync({ row, force })} />
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

// ─── Companies tab ────────────────────────────────────────────────────────────

function CompaniesTab() {
  const { data = [], isLoading } = useQuery<AdminCompanyRow[]>({
    queryKey: ['hk-companies'],
    queryFn: () => get('/admin/companies'),
  })
  const deleteCompany = useDeleteWithForce<AdminCompanyRow>((r) => `/admin/companies/${r.id}`, ['hk-companies'])

  return (
    <div className="space-y-4">
      {isLoading ? <div className="flex justify-center py-16"><Loader2 className="w-6 h-6 animate-spin text-brand-500" /></div>
      : data.length === 0 ? <EmptyState icon={Building2} title="No companies found" />
      : (
        <div className="card p-0 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-gray-500 text-xs uppercase">
              <tr><th className="text-left px-4 py-2.5 font-medium">Name</th><th className="text-left px-4 py-2.5 font-medium">Contact</th><th className="text-left px-4 py-2.5 font-medium">Status</th><th className="text-right px-4 py-2.5 font-medium">Actions</th></tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {data.map((c) => (
                <tr key={c.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium text-gray-800">{c.name}</td>
                  <td className="px-4 py-3 text-gray-500">{c.contact_email}</td>
                  <td className="px-4 py-3"><span className={badge(c.status)}>{c.status}</span></td>
                  <td className="px-4 py-3 text-right">
                    <DeleteButton row={c} guardLabel="company" onConfirm={(row, force) => deleteCompany.mutateAsync({ row, force })} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      <p className="text-xs text-gray-400">Editing a company's contact details, resetting its admin, and uploading its logo live on the Companies page — this tab is delete-only, for removing seeded/test organisations.</p>
    </div>
  )
}

// ─── Wallet transactions & payouts tab ───────────────────────────────────────

function PaymentsTab() {
  const { data: txns = [], isLoading: txLoading } = useQuery<TransactionRow[]>({
    queryKey: ['hk-transactions'],
    queryFn: () => get('/admin/payments/transactions'),
  })
  const { data: payouts = [], isLoading: poLoading } = useQuery<PayoutRow[]>({
    queryKey: ['hk-payouts'],
    queryFn: () => get('/admin/payments/payouts'),
  })
  const deleteTxn = useDeleteWithForce<WalletTxnRow>((r) => `/admin/wallet-transactions/${r.id}`, ['hk-transactions'])
  const deletePayout = useDeleteWithForce<PayoutRow>((r) => `/admin/payout-requests/${r.id}`, ['hk-payouts'])

  return (
    <div className="space-y-8">
      <div>
        <h3 className="text-sm font-semibold text-gray-700 mb-3">Booking payments</h3>
        <p className="text-xs text-gray-400 mb-3">These are real completed bookings — deletion isn't offered here. Remove the ride itself from the Rides tab if it's test data (that cascades its payment record too).</p>
        {txLoading ? <div className="flex justify-center py-10"><Loader2 className="w-5 h-5 animate-spin text-brand-500" /></div>
        : (
          <div className="card p-0 overflow-hidden">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 text-gray-500 text-xs uppercase">
                <tr><th className="text-left px-4 py-2.5 font-medium">Reference</th><th className="text-left px-4 py-2.5 font-medium">Passenger / Driver</th><th className="text-left px-4 py-2.5 font-medium">Amount</th><th className="text-left px-4 py-2.5 font-medium">Gateway</th></tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {txns.slice(0, 50).map((t) => (
                  <tr key={t.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 font-mono text-xs text-gray-500">{t.reference}</td>
                    <td className="px-4 py-3 text-gray-700">{t.passenger} / {t.driver}</td>
                    <td className="px-4 py-3">{fmt.naira(t.amount)}</td>
                    <td className="px-4 py-3 text-gray-500">{t.gateway}{t.is_corporate && ' (corporate)'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <div>
        <h3 className="text-sm font-semibold text-gray-700 mb-3">Driver payouts</h3>
        {poLoading ? <div className="flex justify-center py-10"><Loader2 className="w-5 h-5 animate-spin text-brand-500" /></div>
        : payouts.length === 0 ? <EmptyState icon={Banknote} title="No payout requests" />
        : (
          <div className="card p-0 overflow-hidden">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 text-gray-500 text-xs uppercase">
                <tr><th className="text-left px-4 py-2.5 font-medium">Driver</th><th className="text-left px-4 py-2.5 font-medium">Amount</th><th className="text-left px-4 py-2.5 font-medium">Bank</th><th className="text-left px-4 py-2.5 font-medium">Status</th><th className="text-right px-4 py-2.5 font-medium">Actions</th></tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {payouts.map((p) => (
                  <tr key={p.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 font-medium text-gray-800">{p.driver}</td>
                    <td className="px-4 py-3">{fmt.naira(p.amount)}</td>
                    <td className="px-4 py-3 text-gray-500">{p.bank_name} · {p.account_number}</td>
                    <td className="px-4 py-3"><span className={badge(p.status)}>{p.status}</span></td>
                    <td className="px-4 py-3 text-right">
                      {p.status === 'completed' ? (
                        <span className="text-xs text-gray-300" title="Already completed — cannot be deleted, the transfer already happened">
                          <X className="w-4 h-4 inline" />
                        </span>
                      ) : (
                        <DeleteButton row={p} guardLabel="payout request" onConfirm={(row, force) => deletePayout.mutateAsync({ row, force })} />
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────

type Tab = 'users' | 'drivers' | 'rides' | 'companies' | 'payments'

export default function Housekeeping() {
  const [tab, setTab] = useState<Tab>('users')

  return (
    <div className="space-y-5">
      <PageHeader
        title="Housekeeping"
        sub="Super-admin-only cleanup of seeded, test, and erroneous records — every delete refuses on real activity unless explicitly forced"
      />

      <div className="flex items-center gap-2 bg-amber-50 border border-amber-200 text-amber-800 px-4 py-2.5 rounded-xl text-xs">
        <AlertTriangle className="w-4 h-4 flex-shrink-0" />
        Deletion is permanent and cascades through related records. Every delete below is guarded — it refuses by default when the target has real activity, and only proceeds with an explicit force override.
      </div>

      <div className="flex gap-1 border-b border-gray-200">
        {([
          ['users', 'Users', Users],
          ['drivers', 'Drivers', Car],
          ['rides', 'Rides', MapPin],
          ['companies', 'Companies', Building2],
          ['payments', 'Payments', Wallet],
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

      {tab === 'users' && <UsersTab />}
      {tab === 'drivers' && <DriversTab />}
      {tab === 'rides' && <RidesTab />}
      {tab === 'companies' && <CompaniesTab />}
      {tab === 'payments' && <PaymentsTab />}
    </div>
  )
}
