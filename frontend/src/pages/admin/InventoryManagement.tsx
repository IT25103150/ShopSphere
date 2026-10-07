import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { Badge, StatusBadge } from '../../components/Badge'
import { ErrorAlert, LoadingSpinner } from '../../components/Feedback'
import { FormInput, FormSelect } from '../../components/Form'
import { Modal } from '../../components/Modal'
import { Pagination, Table } from '../../components/Table'
import { useAuth } from '../../features/AuthContext'
import { useToast } from '../../features/ToastContext'
import { fmtDateTime } from '../../features/format'
import { inventoryApi } from '../../services'
import { parseError } from '../../services/api'
import type { InventoryRow, Page, StockMovement } from '../../types'

export default function InventoryManagement() {
  const { user } = useAuth()
  const toast = useToast()
  const canEdit = user?.role === 'ADMIN' || user?.role === 'WAREHOUSE'
  const [data, setData] = useState<Page<InventoryRow> | null>(null)
  const [search, setSearch] = useState('')
  const [low, setLow] = useState(false)
  const [page, setPage] = useState(0)
  const [error, setError] = useState<string | null>(null)
  const [adjust, setAdjust] = useState<InventoryRow | null>(null)
  const [hist, setHist] = useState<{ row: InventoryRow; page: Page<StockMovement> | null; n: number } | null>(null)
  const [form, setForm] = useState({ mode: 'set', quantity: '', reason: '', reorderLevel: '' })
  const [errors, setErrors] = useState<Record<string, string>>({})

  const load = useCallback(() => {
    inventoryApi.list({ search, lowStockOnly: low, page, size: 12 }).then(setData).catch((e) => setError(parseError(e).message))
  }, [search, low, page])
  useEffect(() => { load() }, [load])

  useEffect(() => {
    if (!hist) return
    inventoryApi.movements(hist.row.productId, hist.n, 8).then((p) => setHist((h) => h && { ...h, page: p })).catch((e) => toast.error(parseError(e).message))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hist?.row.productId, hist?.n])

  const openAdjust = (r: InventoryRow) => { setAdjust(r); setErrors({}); setForm({ mode: 'set', quantity: String(r.quantity), reason: '', reorderLevel: String(r.reorderLevel) }) }

  const save = async (e: FormEvent) => {
    e.preventDefault()
    if (!adjust) return
    const v: Record<string, string> = {}
    const qty = Number(form.quantity)
    if (form.quantity === '' || !Number.isInteger(qty) || qty < (form.mode === 'add' ? 1 : 0)) v.quantity = form.mode === 'add' ? 'Enter a whole number of at least 1' : 'Enter a whole number, 0 or more'
    if (!form.reason.trim()) v.reason = 'A reason is required'
    setErrors(v)
    if (Object.keys(v).length) return
    try {
      if (form.mode === 'add') await inventoryApi.restock(adjust.productId, { quantity: qty, reason: form.reason.trim() })
      else await inventoryApi.adjust(adjust.productId, { newQuantity: qty, reason: form.reason.trim(), reorderLevel: form.reorderLevel === '' ? undefined : Number(form.reorderLevel) })
      toast.ok('Stock updated'); setAdjust(null); load()
    } catch (err) { const p = parseError(err); setErrors(p.fieldErrors); toast.error(p.message) }
  }

  return (
    <>
      <div className="page-head"><div><span className="eyebrow">Stock</span><h1 style={{ margin: 0 }}>Inventory management</h1></div></div>
      <div className="row" style={{ marginBottom: 16 }}>
        <input className="input" style={{ maxWidth: 320 }} placeholder="Search product or SKU" value={search} onChange={(e) => { setSearch(e.target.value); setPage(0) }} aria-label="Search inventory" />
        <label className="checkbox"><input type="checkbox" checked={low} onChange={(e) => { setLow(e.target.checked); setPage(0) }} /> Low stock only</label>
        {!canEdit && <Badge tone="blue">Read-only for your role</Badge>}
      </div>
      <ErrorAlert message={error} />
      {!data && !error && <LoadingSpinner />}
      {data && <>
        <Table rows={data.content} rowKey={(r) => r.id} rowClass={(r) => (r.isLowStock ? 'low' : '')} columns={[
          { header: 'Product', sortValue: (r) => r.productName, cell: (r) => <strong>{r.productName}</strong> },
          { header: 'SKU', cell: (r) => r.sku },
          { header: 'In stock', sortValue: (r) => r.quantity, cell: (r) => <strong style={{ color: r.quantity === 0 ? 'var(--danger)' : undefined }}>{r.quantity}</strong> },
          { header: 'Reorder level', sortValue: (r) => r.reorderLevel, cell: (r) => r.reorderLevel },
          { header: 'Status', cell: (r) => (r.quantity === 0 ? <Badge tone="danger">Out of stock</Badge> : r.isLowStock ? <Badge tone="danger">Low stock</Badge> : <Badge tone="ok">OK</Badge>) },
          { header: 'Updated', cell: (r) => fmtDateTime(r.lastUpdated) },
          { header: 'Actions', cell: (r) => (
            <div className="row" style={{ flexWrap: 'nowrap' }}>
              {canEdit && <button className="btn btn-sm" onClick={() => openAdjust(r)}>Adjust stock</button>}
              <button className="btn btn-sm btn-outline" onClick={() => setHist({ row: r, page: null, n: 0 })}>History</button>
            </div>) },
        ]} />
        <Pagination page={data.page} totalPages={data.totalPages} onChange={setPage} />
      </>}

      {adjust && (
        <Modal title={`Adjust stock - ${adjust.productName}`} onClose={() => setAdjust(null)}
          footer={<><button className="btn btn-ghost" onClick={() => setAdjust(null)}>Cancel</button><button className="btn" type="submit" form="adj-form">Save</button></>}>
          <p className="muted">Current stock: <strong>{adjust.quantity}</strong> · reorder level {adjust.reorderLevel}</p>
          <form id="adj-form" onSubmit={save} noValidate>
            <FormSelect label="Action" name="mode" value={form.mode} onChange={(e) => setForm({ ...form, mode: e.target.value, quantity: e.target.value === 'add' ? '' : String(adjust.quantity) })}>
              <option value="set">Set stock to an exact number (stock take)</option><option value="add">Add received stock (restock)</option>
            </FormSelect>
            <FormInput label={form.mode === 'add' ? 'Quantity to add' : 'New quantity'} name="quantity" type="number" min={form.mode === 'add' ? 1 : 0} required value={form.quantity} error={errors.quantity || errors.newQuantity} onChange={(e) => setForm({ ...form, quantity: e.target.value })} />
            {form.mode === 'set' && <FormInput label="Reorder level" name="reorderLevel" type="number" min={0} value={form.reorderLevel} error={errors.reorderLevel} onChange={(e) => setForm({ ...form, reorderLevel: e.target.value })} />}
            <FormInput label="Reason for change" name="reason" required value={form.reason} error={errors.reason} placeholder="e.g. Supplier delivery PO-1234, damaged goods, stock take" onChange={(e) => setForm({ ...form, reason: e.target.value })} />
          </form>
        </Modal>
      )}

      {hist && (
        <Modal wide title={`Stock movements - ${hist.row.productName}`} onClose={() => setHist(null)} footer={<button className="btn btn-dark" onClick={() => setHist(null)}>Close</button>}>
          {!hist.page ? <LoadingSpinner /> : <>
            <Table rows={hist.page.content} rowKey={(m) => m.id} empty="No movements recorded." columns={[
              { header: 'Date', cell: (m) => fmtDateTime(m.createdDate) },
              { header: 'Type', cell: (m) => <StatusBadge status={m.movementType} /> },
              { header: 'Change', cell: (m) => <strong style={{ color: m.quantity < 0 ? 'var(--danger)' : 'var(--ok)' }}>{m.quantity > 0 ? '+' : ''}{m.quantity}</strong> },
              { header: 'Balance', cell: (m) => m.quantityAfter },
              { header: 'Reason', cell: (m) => m.reason },
              { header: 'By', cell: (m) => m.createdBy },
            ]} />
            <Pagination page={hist.page.page} totalPages={hist.page.totalPages} onChange={(n) => setHist({ ...hist, n })} />
          </>}
        </Modal>
      )}
    </>
  )
}
