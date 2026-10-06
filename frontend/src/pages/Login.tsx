import { useState, type FormEvent } from 'react'
import { Link, Navigate, useLocation, useNavigate } from 'react-router-dom'
import { Alert, ErrorAlert } from '../components/Feedback'
import { FormInput } from '../components/Form'
import { useAuth } from '../features/AuthContext'
import { homeFor } from '../features/format'
import { parseError } from '../services/api'

const DEMOS = [
  ['Customer', 'customer@shopsphere.lk'], ['Admin', 'admin@shopsphere.lk'], ['Staff', 'staff@shopsphere.lk'],
  ['Warehouse', 'warehouse@shopsphere.lk'], ['Delivery', 'delivery@shopsphere.lk'],
]

export default function Login() {
  const { user, login } = useAuth()
  const nav = useNavigate()
  const loc = useLocation() as { state?: { from?: string }; search: string }
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  if (user) return <Navigate to={loc.state?.from ?? homeFor(user.role)} replace />

  const submit = async (e: FormEvent) => {
    e.preventDefault()
    const v: Record<string, string> = {}
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) v.email = 'Enter a valid email address'
    if (!password) v.password = 'Password is required'
    setErrors(v); setError(null)
    if (Object.keys(v).length) return
    setBusy(true)
    try {
      const u = await login(email.trim(), password)
      nav(loc.state?.from ?? homeFor(u.role), { replace: true })
    } catch (err) {
      setError(parseError(err).message)
    } finally { setBusy(false) }
  }

  return (
    <div className="auth-wrap">
      <div className="card auth-card">
        <h1>Welcome back</h1>
        <p className="muted">Log in to your ShopSphere account.</p>
        {new URLSearchParams(loc.search).get('expired') && <Alert kind="warn">Your session expired. Please log in again.</Alert>}
        <ErrorAlert message={error} />
        <form onSubmit={submit} noValidate>
          <FormInput label="Email" name="email" type="email" value={email} error={errors.email} onChange={(e) => setEmail(e.target.value)} autoComplete="username" autoFocus />
          <FormInput label="Password" name="password" type="password" value={password} error={errors.password} onChange={(e) => setPassword(e.target.value)} autoComplete="current-password" />
          <button className="btn btn-lg btn-block" type="submit" disabled={busy}>{busy ? 'Logging in...' : 'Log in'}</button>
        </form>
        <p className="small" style={{ marginTop: 16 }}>New here? <Link to="/register" style={{ textDecoration: 'underline' }}>Create an account</Link></p>
        <div className="demo-box">
          <strong>Demo accounts</strong> (password <code>Demo@123</code>) - click to fill:
          {DEMOS.map(([r, em]) => <button key={em} type="button" onClick={() => { setEmail(em); setPassword('Demo@123') }}>{r} · {em}</button>)}
        </div>
      </div>
    </div>
  )
}
