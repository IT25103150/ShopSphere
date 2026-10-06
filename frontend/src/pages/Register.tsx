import { useState, type FormEvent } from 'react'
import { Link, Navigate, useNavigate } from 'react-router-dom'
import { ErrorAlert } from '../components/Feedback'
import { FormInput } from '../components/Form'
import { useAuth } from '../features/AuthContext'
import { parseError } from '../services/api'

export default function Register() {
  const { user, register } = useAuth()
  const nav = useNavigate()
  const [f, setF] = useState({ firstName: '', lastName: '', email: '', phone: '', password: '', confirm: '' })
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const set = (k: keyof typeof f, v: string) => { setF((s) => ({ ...s, [k]: v })); setErrors((e) => ({ ...e, [k]: '' })) }

  if (user) return <Navigate to="/" replace />

  const submit = async (e: FormEvent) => {
    e.preventDefault()
    const v: Record<string, string> = {}
    if (!f.firstName.trim()) v.firstName = 'First name is required'
    if (!f.lastName.trim()) v.lastName = 'Last name is required'
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(f.email)) v.email = 'Enter a valid email address'
    if (f.phone && !/^\+?[0-9]{10,15}$/.test(f.phone)) v.phone = 'Phone must be 10-15 digits'
    if (!/^(?=.*[A-Za-z])(?=.*\d).{8,72}$/.test(f.password)) v.password = 'At least 8 characters with a letter and a number'
    if (f.confirm !== f.password) v.confirm = 'Passwords do not match'
    setErrors(v); setError(null)
    if (Object.keys(v).length) return
    setBusy(true)
    try {
      await register({ email: f.email.trim(), password: f.password, firstName: f.firstName.trim(), lastName: f.lastName.trim(), phone: f.phone || undefined })
      nav('/', { replace: true })
    } catch (err) {
      const p = parseError(err)
      setErrors(p.fieldErrors); setError(p.message)
    } finally { setBusy(false) }
  }

  return (
    <div className="auth-wrap">
      <div className="card auth-card" style={{ maxWidth: 520 }}>
        <h1>Create your account</h1>
        <ErrorAlert message={error} />
        <form onSubmit={submit} noValidate>
          <div className="form-grid">
            <FormInput label="First name" name="firstName" required value={f.firstName} error={errors.firstName} onChange={(e) => set('firstName', e.target.value)} autoComplete="given-name" />
            <FormInput label="Last name" name="lastName" required value={f.lastName} error={errors.lastName} onChange={(e) => set('lastName', e.target.value)} autoComplete="family-name" />
            <FormInput label="Email" name="email" type="email" required className="full" value={f.email} error={errors.email} onChange={(e) => set('email', e.target.value)} autoComplete="email" />
            <FormInput label="Phone (optional)" name="phone" type="tel" className="full" value={f.phone} error={errors.phone} onChange={(e) => set('phone', e.target.value)} />
            <FormInput label="Password" name="password" type="password" required value={f.password} error={errors.password} hint="8+ characters, letter and number" onChange={(e) => set('password', e.target.value)} autoComplete="new-password" />
            <FormInput label="Confirm password" name="confirm" type="password" required value={f.confirm} error={errors.confirm} onChange={(e) => set('confirm', e.target.value)} autoComplete="new-password" />
          </div>
          <button className="btn btn-lg btn-block" type="submit" disabled={busy}>{busy ? 'Creating account...' : 'Register'}</button>
        </form>
        <p className="small" style={{ marginTop: 16 }}>Already have an account? <Link to="/login" style={{ textDecoration: 'underline' }}>Log in</Link></p>
      </div>
    </div>
  )
}
