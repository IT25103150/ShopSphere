import { useCallback, useEffect, useState } from 'react'
import { StatusBadge } from '../../components/Badge'
import { ErrorAlert, LoadingSpinner } from '../../components/Feedback'
import { Modal } from '../../components/Modal'
import { Pagination, Table } from '../../components/Table'
import { useToast } from '../../features/ToastContext'
import { fmtDate, label } from '../../features/format'
import { authApi, orderApi } from '../../services'
import { parseError } from '../../services/api'
import type { Page, Shipment, User } from '../../types'

const NEXT: Record<string, string> = { READY_FOR_DISPATCH: 'DISPATCHED', DISPATCHED: 'OUT_FOR_DELIVERY', OUT_FOR_DELIVERY: 'DELIVERED' }

export default function DeliveryManagement() {
  const toast = useToast()
  const [data, setData] = useState<Page<Shipment> | null>(null)
  const [status, setStatus] = useState('')
  const [assign, setAssign] = useState('')
  const [page, setPage] = useState(0)
  const [staff, setStaff] = useState<User[]>([])
  const [error, setError] = useState<string | null>(null)
  const [target, setTarget] = useState<Shipment | null>(null)
  const [pick, setPick] = useState('')

  const load = useCallback(() => {
    orderApi.shipments(status, page, 12).then(setData).catch((e) => setError(parseError(e).message))
  }, [status, page])
  useEffect(() => { load() }, [load])
  useEffect(() => { authApi.usersByRole('DELIVERY').then(setStaff).catch(() => {}) }, [])

  const doAssign = async () => {
    if (!target || !pick) return
    try { await orderApi.assign(target.id, Number(pick)); toast.ok('Delivery assigned'); setTarget(null); load() }
    catch (e) { toast.error(parseError(e).message) }
  }
  const advance = async (s: Shipment) => {
    try { await orderApi.updateShipment(s.id, NEXT[s.orderStatus]); toast.ok(`Shipment updated to ${label(NEXT[s.orderStatus])}`); load() }
    catch (e) { toast.error(parseError(e).message) }
  }

  const rows = (data?.content ?? []).filter((s) => (assign === 'yes' ? s.delivery : assign === 'no' ? !s.delivery : true))

  return (
    <>
      <div className="page-head"><div><span className="eyebrow">Logistics</span><h1 style={{ margin: 0 }}>Delivery management</h1></div></div>
      <div className="row" style={{ marginBottom: 16 }}>
        <select className="input" style={{ width: 'auto' }} value={status} onChange={(e) => { setStatus(e.target.value); setPage(0) }} aria-label="Shipment status">
          <option value="">All shipment statuses</option>
          {['PREPARING', 'DISPATCHED', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED'].map((s) => <option key={s} value={s}>{label(s)}</option>)}
        </select>
        <select className="input" style={{ width: 'auto' }} value={assign} onChange={(e) => setAssign(e.target.value)} aria-label="Assignment">
          <option value="">Assigned & unassigned</option><option value="no">Unassigned only</option><option value="yes">Assigned only</option>
        </select>
      </div>
      <ErrorAlert message={error} />
      {!data && !error && <LoadingSpinner />}
      {data && <>
        <Table rows={rows} rowKey={(s) => s.id} columns={[
          { header: 'Order', sortValue: (s) => s.orderNumber, cell: (s) => <><strong>{s.orderNumber}</strong><div className="muted small">{s.trackingNumber}</div></> },
          { header: 'Deliver to', cell: (s) => <>{s.customerName}<div className="muted small">{s.address}, {s.city}</div></> },
          { header: 'Order status', cell: (s) => <StatusBadge status={s.orderStatus} /> },
          { header: 'Shipment', cell: (s) => <StatusBadge status={s.status} /> },
          { header: 'ETA', cell: (s) => fmtDate(s.estimatedDelivery) },
          { header: 'Delivery person', cell: (s) => (s.delivery ? <>{s.delivery.staffName}<div><StatusBadge status={s.delivery.status} /></div></> : <span className="muted">Unassigned</span>) },
          { header: 'Actions', cell: (s) => (
            <div className="row" style={{ flexWrap: 'nowrap' }}>
              {!['DELIVERED', 'CANCELLED'].includes(s.status) && <button className="btn btn-sm" onClick={() => { setTarget(s); setPick(String(s.delivery?.staffId ?? '')) }}>{s.delivery ? 'Reassign' : 'Assign'}</button>}
              {NEXT[s.orderStatus] && <button className="btn btn-sm btn-outline" onClick={() => advance(s)}>Mark {label(NEXT[s.orderStatus]).toLowerCase()}</button>}
            </div>) },
        ]} />
        <Pagination page={data.page} totalPages={data.totalPages} onChange={setPage} />
      </>}
      {target && (
        <Modal title={`Assign delivery - ${target.orderNumber}`} onClose={() => setTarget(null)}
          footer={<><button className="btn btn-ghost" onClick={() => setTarget(null)}>Cancel</button><button className="btn" disabled={!pick} onClick={doAssign}>Assign</button></>}>
          <p>Deliver to <strong>{target.customerName}</strong>, {target.address}, {target.city}</p>
          <div className="field"><label htmlFor="staff">Delivery staff</label>
            <select id="staff" className="input" value={pick} onChange={(e) => setPick(e.target.value)}>
              <option value="">Select a delivery person...</option>{staff.map((u) => <option key={u.id} value={u.id}>{u.firstName} {u.lastName} - {u.phone}</option>)}
            </select></div>
        </Modal>
      )}
    </>
  )
}
