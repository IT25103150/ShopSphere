import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { LoadingSpinner } from '../components/Feedback'
import { useAuth } from '../features/AuthContext'
import { homeFor } from '../features/format'
import type { Role } from '../types'

/** Any logged-in user. */
export function RequireAuth() {
  const { user, loading } = useAuth()
  const loc = useLocation()
  if (loading) return <LoadingSpinner />
  if (!user) return <Navigate to="/login" replace state={{ from: loc.pathname + loc.search }} />
  return <Outlet />
}

/** Only the listed roles; everybody else is sent to their own home page. */
export function RequireRole({ roles }: { roles: Role[] }) {
  const { user, loading } = useAuth()
  const loc = useLocation()
  if (loading) return <LoadingSpinner />
  if (!user) return <Navigate to="/login" replace state={{ from: loc.pathname }} />
  if (!roles.includes(user.role)) return <Navigate to={homeFor(user.role)} replace />
  return <Outlet />
}
