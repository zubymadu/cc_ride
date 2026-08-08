import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Image as ImageIcon, Plus, Trash2, Loader2, Eye, EyeOff, GripVertical } from 'lucide-react'
import { get, post, patch, del } from '../lib/api'
import PageHeader from '../components/PageHeader'
import EmptyState from '../components/EmptyState'
import Modal from '../components/Modal'

interface Advert {
  id: string
  image_url: string
  title: string
  body: string
  link_url: string
  is_active: boolean
  sort_order: number
  created_at: string
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label className="text-xs text-gray-500 mb-1 block">{label}</label>
      {children}
    </div>
  )
}

export default function Adverts() {
  const qc = useQueryClient()
  const [showCreate, setShowCreate] = useState(false)

  const { data: adverts = [], isLoading } = useQuery<Advert[]>({
    queryKey: ['admin-adverts'],
    queryFn: () => get('/admin/adverts'),
  })

  const toggleActive = useMutation({
    mutationFn: ({ id, is_active }: { id: string; is_active: boolean }) =>
      patch(`/admin/adverts/${id}`, { is_active }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-adverts'] }),
  })

  const remove = useMutation({
    mutationFn: (id: string) => del(`/admin/adverts/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-adverts'] }),
  })

  return (
    <div className="space-y-6">
      <PageHeader
        title="Adverts"
        sub={`${adverts.length} card${adverts.length === 1 ? '' : 's'} · shown in the home-screen carousel on both the passenger and driver apps`}
        action={
          <button onClick={() => setShowCreate(true)} className="btn-primary text-sm">
            <Plus className="w-4 h-4" /> New Advert
          </button>
        }
      />

      {isLoading ? (
        <div className="flex justify-center py-20"><Loader2 className="w-7 h-7 text-brand-500 animate-spin" /></div>
      ) : adverts.length === 0 ? (
        <EmptyState icon={ImageIcon} title="No adverts yet" sub="Create your first advert card using the button above" />
      ) : (
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {adverts.map((a) => (
            <div key={a.id} className="card overflow-hidden">
              <div className="aspect-[16/9] bg-gray-100 relative">
                <img src={a.image_url} alt={a.title} className="w-full h-full object-cover" />
                <div className="absolute top-2 left-2 flex items-center gap-1 bg-black/50 text-white text-xs px-2 py-1 rounded-md">
                  <GripVertical className="w-3 h-3" /> #{a.sort_order}
                </div>
                <span className={`absolute top-2 right-2 badge ${a.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-500'}`}>
                  {a.is_active ? 'Live' : 'Hidden'}
                </span>
              </div>
              <div className="p-4 space-y-2">
                <p className="font-medium text-gray-900 text-sm line-clamp-1">{a.title}</p>
                {a.body && <p className="text-xs text-gray-500 line-clamp-2">{a.body}</p>}
                {a.link_url && <p className="text-xs text-brand-500 truncate">{a.link_url}</p>}
                <div className="flex gap-2 pt-2">
                  <button
                    onClick={() => toggleActive.mutate({ id: a.id, is_active: !a.is_active })}
                    disabled={toggleActive.isPending}
                    className="btn-secondary text-xs px-2 py-1 flex-1 justify-center">
                    {a.is_active ? <EyeOff className="w-3.5 h-3.5" /> : <Eye className="w-3.5 h-3.5" />}
                    {a.is_active ? 'Hide' : 'Show'}
                  </button>
                  <button
                    onClick={() => { if (confirm(`Delete "${a.title}"?`)) remove.mutate(a.id) }}
                    disabled={remove.isPending}
                    className="btn text-xs px-2 py-1 bg-red-50 text-red-600 border border-red-200 hover:bg-red-100">
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      <CreateAdvertModal open={showCreate} onClose={() => setShowCreate(false)} />
    </div>
  )
}

function CreateAdvertModal({ open, onClose }: { open: boolean; onClose: () => void }) {
  const qc = useQueryClient()
  const [form, setForm] = useState({ title: '', body: '', link_url: '', sort_order: '0' })
  const [file, setFile] = useState<File | null>(null)
  const [preview, setPreview] = useState<string | null>(null)
  const [err, setErr] = useState('')

  const create = useMutation({
    mutationFn: () => {
      const data = new FormData()
      data.append('title', form.title)
      if (form.body) data.append('body', form.body)
      if (form.link_url) data.append('link_url', form.link_url)
      data.append('sort_order', form.sort_order || '0')
      if (file) data.append('image', file)
      return post('/admin/adverts', data)
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-adverts'] })
      setForm({ title: '', body: '', link_url: '', sort_order: '0' })
      setFile(null)
      setPreview(null)
      setErr('')
      onClose()
    },
    onError: (e: any) => setErr(e?.message ?? 'Failed to create advert'),
  })

  const f = (k: keyof typeof form) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
    setForm((p) => ({ ...p, [k]: e.target.value }))

  const canSubmit = form.title.trim() && file

  return (
    <Modal open={open} onClose={onClose} title="New Advert" size="lg">
      <div className="space-y-4">
        {err && <div className="bg-red-50 border border-red-200 text-red-700 text-sm px-3 py-2 rounded-lg">{err}</div>}

        <Field label="Image *">
          <label className="relative flex items-center justify-center w-full aspect-[16/9] rounded-xl bg-brand-50 border-2 border-dashed border-brand-200 cursor-pointer overflow-hidden group">
            {preview ? (
              <img src={preview} alt="" className="w-full h-full object-cover" />
            ) : (
              <div className="flex flex-col items-center text-brand-500">
                <ImageIcon className="w-8 h-8 mb-1" />
                <span className="text-xs">Click to upload (JPG/PNG/WebP, up to 5MB)</span>
              </div>
            )}
            <input
              type="file"
              accept="image/png,image/jpeg,image/webp"
              className="hidden"
              onChange={(e) => {
                const f = e.target.files?.[0] ?? null
                setFile(f)
                setPreview(f ? URL.createObjectURL(f) : null)
              }}
            />
          </label>
        </Field>

        <Field label="Title *">
          <input className="input" placeholder="e.g. Refer a friend, earn ₦500" value={form.title} onChange={f('title')} />
        </Field>

        <Field label="Body text (optional)">
          <textarea className="input" rows={3} placeholder="Short supporting text shown under the title" value={form.body} onChange={f('body')} />
        </Field>

        <div className="grid grid-cols-2 gap-4">
          <Field label="Link URL (optional)">
            <input className="input" placeholder="https://…" value={form.link_url} onChange={f('link_url')} />
          </Field>
          <Field label="Sort order">
            <input className="input" type="number" value={form.sort_order} onChange={f('sort_order')} />
          </Field>
        </div>

        <button onClick={() => create.mutate()} disabled={create.isPending || !canSubmit} className="btn-primary w-full justify-center">
          {create.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
          Create Advert
        </button>
      </div>
    </Modal>
  )
}
