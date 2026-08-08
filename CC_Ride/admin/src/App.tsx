import { BrowserRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom'
import { useAuthStore } from './store/auth'
import Layout, { SUPER_ADMIN_ONLY_PATHS } from './components/Layout'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Users from './pages/Users'
import Drivers from './pages/Drivers'
import Companies from './pages/Companies'
import Rides from './pages/Rides'
import LiveTracking from './pages/LiveTracking'
import Approvals from './pages/Approvals'
import Analytics from './pages/Analytics'
import Billing from './pages/Billing'
import Payments from './pages/Payments'
import Adverts from './pages/Adverts'
import Support from './pages/Support'
import Settings from './pages/Settings'
import Download from './pages/Download'
import Pricing from './pages/Pricing'
import ClaimInvite from './pages/ClaimInvite'
import ActivateEmployee from './pages/ActivateEmployee'
import Housekeeping from './pages/Housekeeping'

function RequireAuth({ children }: { children: React.ReactNode }) {
  const token = useAuthStore((s) => s.token)
  const admin = useAuthStore((s) => s.admin)
  const location = useLocation()
  if (!token) return <Navigate to="/login" replace />
  // Mirrors the backend's requireSuperAdmin gates — a scoped company admin
  // hitting one of these routes directly (bookmark, typed URL) would just
  // get a 403 from every API call on the page, so redirect instead of
  // rendering a broken screen.
  if (!admin?.isSuperAdmin && SUPER_ADMIN_ONLY_PATHS.some((p) => location.pathname.startsWith(p))) {
    return <Navigate to="/companies" replace />
  }
  return <>{children}</>
}

function DefaultRoute() {
  const admin = useAuthStore((s) => s.admin)
  return <Navigate to={admin?.isSuperAdmin ? '/dashboard' : '/companies'} replace />
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/download" element={<Download />} />
        <Route path="/claim-invite/:token" element={<ClaimInvite />} />
        <Route path="/activate/:token" element={<ActivateEmployee />} />
        <Route
          path="/"
          element={
            <RequireAuth>
              <Layout />
            </RequireAuth>
          }
        >
          <Route index element={<DefaultRoute />} />
          <Route path="dashboard"  element={<Dashboard />} />
          <Route path="users"      element={<Users />} />
          <Route path="drivers"    element={<Drivers />} />
          <Route path="companies"  element={<Companies />} />
          <Route path="rides"      element={<Rides />} />
          <Route path="tracking"   element={<LiveTracking />} />
          <Route path="approvals"  element={<Approvals />} />
          <Route path="analytics"  element={<Analytics />} />
          <Route path="billing"    element={<Billing />} />
          <Route path="pricing"    element={<Pricing />} />
          <Route path="payments"   element={<Payments />} />
          <Route path="adverts"    element={<Adverts />} />
          <Route path="support"    element={<Support />} />
          <Route path="settings"   element={<Settings />} />
          <Route path="housekeeping" element={<Housekeeping />} />
        </Route>
        <Route path="*" element={<DefaultRoute />} />
      </Routes>
    </BrowserRouter>
  )
}
