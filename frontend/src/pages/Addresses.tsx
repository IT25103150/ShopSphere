import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { Badge } from '../components/Badge'
import { EmptyState, ErrorAlert, LoadingSpinner } from '../components/Feedback'
import { FormInput } from '../components/Form'
import { ConfirmModal, Modal } from '../components/Modal'
import { useToast } from '../features/ToastContext'
import { authApi } from '../services'
import { parseError } from '../services/api'
import type { Address } from '../types'

type Form = Omit<Address, 'id'>
const EMPTY: Form = { label: '', address: '', apartment: '', city: '', postalCode: '', country: 'Sri Lanka', phone: '', defaultAddress: false }

export default function Addresses() {
  const toast = useToast()
  const [list, setList] = useState<Address[] | null>(null)
  const [edit, setEdit] = useState<{ id: number | null; form: Form } | null>(null)
  const [del, setDel] = useState<Address | null>(null)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(() => authApi.addresses().then(setList).catch((e) => setError(parseError(e).message)), [])
  useEffect(() => { load() }, [load])

  const save = async (e: FormEvent) => {
    e.preventDefault()
    if (!edit) return
    const v: Record<string, string> = {}
    ;(['label', 'address', 'city', 'postalCode', 'country'] as const).forEach((k) => { if (!edit.form[k].trim()) v[k] = 'Required' })
    if (edit.form.phone && !/^\+?[0-9]{10,15}$/.test(edit.form.phone)) v.phone = 'Phone must be 10-15 digits'
    setErrors(v)
    if (Object.keys(v).length) return
    try { await authApi.saveAddress(edit.id, edit.form); toast.ok('Address saved'); setEdit(null); load() }
    catch (err) { const p = parseError(err); setErrors(p.fieldErrors); toast.error(p.message) }
  }

  const setF = (k: keyof Form, v: string | boolean) => { setEdit((s) => s && { ...s, form: { ...s.form, [k]: v } }); setErrors((e) => ({ ...e, [k]: '' })) }

  return (
    <div className="page container" style={{ maxWidth: 900 }}>
      <div className="page-head"><h1 style={{ margin: 0 }}>Saved addresses</h1><button className="btn" onClick={() => { setErrors({}); setEdit({ id: null, form: EMPTY }) }}>+ Add new address</button></div>
      <ErrorAlert message={error} />
      {!list && !error && <LoadingSpinner />}
      {list && list.length === 0 && <EmptyState title="No saved addresses yet">Add one to speed up checkout.</EmptyState>}
      <div className="form-grid" style={{ gap: 16 }}>
        {list?.map((a) => (
          <section key={a.id} className="card card-pad">
            <div className="row spread"><strong>{a.label}</strong>{a.defaultAddress && <Badge tone="dark">Default</Badge>}</div>
            <p style={{ margin: '8px 0' }}>{a.address}{a.apartment ? `, ${a.apartment}` : ''}<br />{a.city} {a.postalCode}<br />{a.country}{a.phone && <><br />{a.phone}</>}</p>
            <div className="row">
              <button className="btn btn-sm btn-outline" onClick={() => { setErrors({}); setEdit({ id: a.id, form: { label: a.label, address: a.address, apartment: a.apartment ?? '', city: a.city, postalCode: a.postalCode, country: a.country, phone: a.phone ?? '', defaultAddress: a.defaultAddress } }) }}>Edit</button>
              {!a.defaultAddress && <button className="btn btn-sm btn-ghost" onClick={() => authApi.makeDefaultAddress(a.id).then(() => { toast.ok('Default address updated'); load() })}>Set as default</button>}
              <button className="btn btn-sm btn-ghost" onClick={() => setDel(a)}>Delete</button>
            </div>
          </section>
        ))}
      </div>
      {edit && (
        <Modal title={edit.id ? 'Edit address' : 'New address'} onClose={() => setEdit(null)}
          footer={<><button className="btn btn-ghost" onClick={() => setEdit(null)}>Cancel</button><button className="btn" form="address-form" type="submit">Save</button></>}>
          <form id="address-form" onSubmit={save} noValidate>
            <div className="form-grid">
              <FormInput label="Label (Home, Office...)" name="label" required value={edit.form.label} error={errors.label} onChange={(e) => setF('label', e.target.value)} />
              <FormInput label="Phone" name="phone" type="tel" value={edit.form.phone ?? ''} error={errors.phone} onChange={(e) => setF('phone', e.target.value)} />
              <FormInput label="Address" name="address" required className="full" value={edit.form.address} error={errors.address} onChange={(e) => setF('address', e.target.value)} />
              <FormInput label="Apartment (optional)" name="apartment" className="full" value={edit.form.apartment ?? ''} onChange={(e) => setF('apartment', e.target.value)} />
              <FormInput label="City" name="city" required value={edit.form.city} error={errors.city} onChange={(e) => setF('city', e.target.value)} />
              <FormInput label="Postal code" name="postalCode" required value={edit.form.postalCode} error={errors.postalCode} onChange={(e) => setF('postalCode', e.target.value)} />
              <FormInput label="Country" name="country" required className="full" value={edit.form.country} error={errors.country} onChange={(e) => setF('country', e.target.value)} />
            </div>
            <label className="checkbox"><input type="checkbox" checked={edit.form.defaultAddress} onChange={(e) => setF('defaultAddress', e.target.checked)} /> Use as my default address</label>
          </form>
        </Modal>
      )}
      {del && <ConfirmModal title="Delete address" message={`Delete "${del.label}"?`} confirmLabel="Delete" danger onCancel={() => setDel(null)}
        onConfirm={() => authApi.deleteAddress(del.id).then(() => { toast.ok('Address deleted'); setDel(null); load() }).catch((e) => toast.error(parseError(e).message))} />}
    </div>
  )
}
