import { useState, useEffect, FormEvent } from 'react'
import { useParams, Link } from 'react-router-dom'
import { Car, Loader2, CheckCircle2 } from 'lucide-react'
import { api } from '../lib/api'

// Public page for an employee's first access after their org admin
// registers them — separate from ClaimInvite.tsx (which activates an
// AdminUser/console account). This just sets a password; the employee
// then signs in from the CC Ride mobile app, not this web console.
export default function ActivateEmployee() {
  const { token } = useParams<{ token: string }>()

  const [checking, setChecking] = useState(true)
  const [inviteError, setInviteError] = useState('')
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')

  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [done, setDone] = useState(false)

  useEffect(() => {
    if (!token) return
    api.get(`/admin/employee-invite/${token}`)
      .then(({ data }) => {
        if (data.Result === 'false') { setInviteError(data.ResponseMsg); return }
        setName(data.data.name)
        setEmail(data.data.email)
      })
      .catch(() => setInviteError('This invite link is invalid or has expired.'))
      .finally(() => setChecking(false))
  }, [token])

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError('')
    if (password !== confirm) { setError('Passwords do not match'); return }
    if (password.length < 8) { setError('Password must be at least 8 characters'); return }

    setLoading(true)
    try {
      const { data } = await api.post('/admin/employee-invite/claim', { token, password })
      if (data.Result === 'false') { setError(data.ResponseMsg); return }
      setDone(true)
    } catch {
      setError('Could not activate your account. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-950 px-4">
      <div className="w-full max-w-sm">
        <div className="flex flex-col items-center mb-8">
          <div className="w-14 h-14 rounded-2xl bg-brand-500 flex items-center justify-center shadow-lg mb-4">
            <Car className="w-7 h-7 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-white">CC Ride</h1>
          <p className="text-gray-400 text-sm mt-1">Set up your account</p>
        </div>

        <div className="bg-gray-900 rounded-2xl p-8 shadow-2xl border border-gray-800">
          {checking ? (
            <div className="flex justify-center py-6"><Loader2 className="w-6 h-6 animate-spin text-brand-500" /></div>
          ) : inviteError ? (
            <div className="space-y-4 text-center">
              <p className="text-red-400 text-sm">{inviteError}</p>
              <Link to="/login" className="text-brand-400 text-sm underline">Back to sign in</Link>
            </div>
          ) : done ? (
            <div className="space-y-3 text-center py-4">
              <CheckCircle2 className="w-10 h-10 text-green-500 mx-auto" />
              <p className="text-white font-semibold">Account activated</p>
              <p className="text-gray-400 text-sm">Open the CC Ride app and sign in with {email} to get started.</p>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-5">
              <div>
                <h2 className="text-lg font-semibold text-white">Welcome{name ? `, ${name}` : ''}</h2>
                <p className="text-gray-400 text-sm mt-1">Setting up your account for {email}</p>
              </div>

              {error && (
                <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-sm px-4 py-3 rounded-lg">
                  {error}
                </div>
              )}

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1.5">Password</label>
                <input
                  type="password"
                  className="w-full px-3 py-2.5 bg-gray-800 border border-gray-700 text-white rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 placeholder-gray-500"
                  placeholder="At least 8 characters"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-300 mb-1.5">Confirm password</label>
                <input
                  type="password"
                  className="w-full px-3 py-2.5 bg-gray-800 border border-gray-700 text-white rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 placeholder-gray-500"
                  value={confirm}
                  onChange={(e) => setConfirm(e.target.value)}
                  required
                />
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full py-2.5 bg-brand-500 text-white font-semibold rounded-lg hover:bg-brand-600 transition-colors disabled:opacity-60 flex items-center justify-center gap-2"
              >
                {loading && <Loader2 className="w-4 h-4 animate-spin" />}
                {loading ? 'Activating…' : 'Activate account'}
              </button>
            </form>
          )}
        </div>
      </div>
    </div>
  )
}
