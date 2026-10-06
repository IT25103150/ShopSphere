import { useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { ErrorAlert } from '../components/Feedback'
import { FormInput } from '../components/Form'
import { useAuth } from '../features/AuthContext'
import { useToast } from '../features/ToastContext'
import { label } from '../features/format'
import { authApi } from '../services'
import { parseError } from '../services/api'

export default function Profile() {
  const { user, setUser, logout } = useAuth()
  const toast = useToast()
  const nav = useNavigate()
  const [editing, setEditing] = useState(false)
  const [f, setF] = useState({ firstName: user?.firstName ?? '', lastName: user?.lastName ?? '', phone: user?.phone ?? '' })
  const [pw, setPw] = useState({ currentPassword: '', newPassword: '', confirm: '' })
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [pwErrors, setPwErrors] = useState<Record<string, string>>({})
  const [error, setError] = useState<string | null>(null)
  const [pwError, setPwError] = useState<string | null>(null)

  if (!user) return null

  const save = async (e: FormEvent) => {
    e.preventDefault(); setError(null); setErrors({})
    try { setUser(await authApi.updateProfile(f)); setEditing(false); toast.ok('Profile updated') }
    catch (err) { const p = parseError(err); setError(p.message); setErrors(p.fieldErrors) }
  }
  const changePw = async (e: FormEvent) => {
    e.preventDefault(); setPwError(null)
    const v: Record<string, string> = {}
    if (!pw.currentPassword) v.currentPassword = 'Enter your current password'
    if (!/^(?=.*[A-Za-z])(?=.*\d).{8,72}$/.test(pw.newPassword)) v.newPassword = 'At least 8 characters with a letter and a number'
    if (pw.confirm !== pw.newPassword) v.confirm = 'Passwords do not match'
    setPwErrors(v)
    if (Object.keys(v).length) return
    try { await authApi.changePassword({ currentPassword: pw.currentPassword, newPassword: pw.newPassword }); setPw({ currentPassword: '', newPassword: '', confirm: '' }); toast.ok('Password changed') }
    catch (err) { const p = parseError(err); setPwError(p.message); setPwErrors(p.fieldErrors) }
  }

  return (
    <div className="page container" style={{ maxWidth: 820 }}>
      <div className="page-head"><h1 style={{ margin: 0 }}>My profile</h1><button className="btn btn-outline" onClick={() => logout().then(() => nav('/'))}>Logout</button></div>
      <section className="card card-pad">
        <div className="row spread"><h3 style={{ margin: 0 }}>Personal details</h3>{!editing && <button className="btn btn-sm btn-outline" onClick={() => setEditing(true)}>Edit profile</button>}</div>
        {!editing ? (
          <dl style={{ display: 'grid', gridTemplateColumns: '140px 1fr', gap: '8px 16px', marginBottom: 0 }}>
            <dt className="muted">Name</dt><dd style={{ margin: 0 }}>{user.firstName} {user.lastName}</dd>
            <dt className="muted">Email</dt><dd style={{ margin: 0 }}>{user.email}</dd>
            <dt className="muted">Phone</dt><dd style={{ margin: 0 }}>{user.phone || '-'}</dd>
            <dt className="muted">Account type</dt><dd style={{ margin: 0 }}>{label(user.role)}</dd>
          </dl>
        ) : (
          <form onSubmit={save} noValidate style={{ marginTop: 16 }}>
            <ErrorAlert message={error} />
            <div className="form-grid">
              <FormInput label="First name" name="firstName" value={f.firstName} error={errors.firstName} onChange={(e) => setF({ ...f, firstName: e.target.value })} />
              <FormInput label="Last name" name="lastName" value={f.lastName} error={errors.lastName} onChange={(e) => setF({ ...f, lastName: e.target.value })} />
              <FormInput label="Phone" name="phone" type="tel" className="full" value={f.phone} error={errors.phone} onChange={(e) => setF({ ...f, phone: e.target.value })} />
            </div>
            <div className="row"><button className="btn" type="submit">Save changes</button><button type="button" className="btn btn-ghost" onClick={() => setEditing(false)}>Cancel</button></div>
          </form>
        )}
      </section>
      <section className="card card-pad mt">
        <h3>Change password</h3>
        <ErrorAlert message={pwError} />
        <form onSubmit={changePw} noValidate>
          <div className="form-grid">
            <FormInput label="Current password" name="currentPassword" type="password" className="full" value={pw.currentPassword} error={pwErrors.currentPassword} onChange={(e) => setPw({ ...pw, currentPassword: e.target.value })} autoComplete="current-password" />
            <FormInput label="New password" name="newPassword" type="password" value={pw.newPassword} error={pwErrors.newPassword} onChange={(e) => setPw({ ...pw, newPassword: e.target.value })} autoComplete="new-password" />
            <FormInput label="Confirm new password" name="confirm" type="password" value={pw.confirm} error={pwErrors.confirm} onChange={(e) => setPw({ ...pw, confirm: e.target.value })} autoComplete="new-password" />
          </div>
          <button className="btn btn-dark" type="submit">Update password</button>
        </form>
      </section>
      <p className="mt"><Link to="/addresses" className="btn btn-outline">Manage saved addresses</Link></p>
    </div>
  )
}
