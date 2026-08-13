import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Inbox, Trash2, Loader2 } from 'lucide-react'
import { get, del } from '../lib/api'
import PageHeader from '../components/PageHeader'
import EmptyState from '../components/EmptyState'

interface WaitlistSubmission {
  id: string
  type: 'general' | 'organisation' | 'investor'
  name: string
  email: string
  organisation: string
  message: string
  created_at: string
}

const TYPE_LABEL: Record<WaitlistSubmission['type'], string> = {
  general: 'Waitlist',
  organisation: 'Organisation',
  investor: 'Investor',
}

const TYPE_BADGE: Record<WaitlistSubmission['type'], string> = {
  general: 'bg-gray-100 text-gray-700',
  organisation: 'bg-blue-100 text-blue-700',
  investor: 'bg-amber-100 text-amber-700',
}

export default function Waitlist() {
  const qc = useQueryClient()
  const [filter, setFilter] = useState<'all' | WaitlistSubmission['type']>('all')

  const { data: submissions = [], isLoading } = useQuery<WaitlistSubmission[]>({
    queryKey: ['admin-waitlist'],
    queryFn: () => get('/admin/waitlist'),
  })

  const remove = useMutation({
    mutationFn: (id: string) => del(`/admin/waitlist/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-waitlist'] }),
  })

  const filtered = filter === 'all' ? submissions : submissions.filter((s) => s.type === filter)

  return (
    <div className="space-y-6">
      <PageHeader
        title="Waitlist Submissions"
        sub={`${submissions.length} submission${submissions.length === 1 ? '' : 's'} from ccride.ng — no longer dependent on email arriving`}
      />

      <div className="flex gap-2">
        {(['all', 'general', 'organisation', 'investor'] as const).map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`btn text-xs px-3 py-1.5 ${
              filter === f ? 'bg-brand-500 text-white' : 'btn-secondary'
            }`}
          >
            {f === 'all' ? 'All' : TYPE_LABEL[f]}
          </button>
        ))}
      </div>

      {isLoading ? (
        <div className="flex justify-center py-20"><Loader2 className="w-7 h-7 text-brand-500 animate-spin" /></div>
      ) : filtered.length === 0 ? (
        <EmptyState icon={Inbox} title="No submissions yet" sub="Waitlist, organisation, and investor interest from ccride.ng will show up here" />
      ) : (
        <div className="card overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-xs text-gray-500 border-b border-gray-100">
                <th className="px-4 py-3 font-medium">Type</th>
                <th className="px-4 py-3 font-medium">Name</th>
                <th className="px-4 py-3 font-medium">Email</th>
                <th className="px-4 py-3 font-medium">Organisation</th>
                <th className="px-4 py-3 font-medium">Message</th>
                <th className="px-4 py-3 font-medium">Submitted</th>
                <th className="px-4 py-3 font-medium"></th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((s) => (
                <tr key={s.id} className="border-b border-gray-50 last:border-0 align-top">
                  <td className="px-4 py-3">
                    <span className={`badge ${TYPE_BADGE[s.type]}`}>{TYPE_LABEL[s.type]}</span>
                  </td>
                  <td className="px-4 py-3 font-medium text-gray-900">{s.name}</td>
                  <td className="px-4 py-3">
                    <a href={`mailto:${s.email}`} className="text-brand-500 hover:underline">{s.email}</a>
                  </td>
                  <td className="px-4 py-3 text-gray-600">{s.organisation || '—'}</td>
                  <td className="px-4 py-3 text-gray-600 max-w-xs truncate" title={s.message}>{s.message || '—'}</td>
                  <td className="px-4 py-3 text-gray-500 whitespace-nowrap">
                    {new Date(s.created_at).toLocaleString()}
                  </td>
                  <td className="px-4 py-3">
                    <button
                      onClick={() => { if (confirm(`Delete submission from "${s.name}"?`)) remove.mutate(s.id) }}
                      disabled={remove.isPending}
                      className="btn text-xs px-2 py-1 bg-red-50 text-red-600 border border-red-200 hover:bg-red-100">
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
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
