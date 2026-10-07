import { useCallback, useEffect, useState } from 'react'
import { StatusBadge } from '../../components/Badge'
import { EmptyState, ErrorAlert, LoadingSpinner } from '../../components/Feedback'
import { useToast } from '../../features/ToastContext'
import { fmtDate } from '../../features/format'
import { orderApi } from '../../services'
import { parseError } from '../../services/api'
import type { Shipment } from '../../types'

export default function MyDeliveries() {
  const toast = useToast()
  const [list, setList] = useState<Shipment[] | null>(null)
  const [error, setError] = useState<string | null>(null)
  const load = useCallback(() => { orderApi.myDeliveries().then(setList).catch((e) => setError(parseError(e).message)) }, [])
  useEffect(() => { load() }, [load])

  const act = async (s: Shipment, status: string, msg: string) => {
    if (!s.delivery) return
    try { await orderApi.updateDelivery(s.delivery.id, status); toast.ok(msg); load() } catch (e) { toast.error(parseError(e).message) }
  }

  const active = (list ?? []).filter((s) => !['COMPLETED', 'FAILED'].includes(s.delivery?.status ?? ''))
  const done = (list ?? []).filter((s) => ['COMPLETED', 'FAILED'].includes(s.delivery?.status ?? ''))

  const card = (s: Shipment, actions: boolean) => (
    <section key={s.id} className="card card-pad">
      <div className="row spread"><strong>{s.orderNumber}</strong><StatusBadge status={s.delivery?.status ?? s.status} /></div>
      <p style={{ margin: '8px 0' }}>{s.customerName}<br />{s.address}, {s.city}<br />
        {s.customerPhone && <a href={`tel:${s.customerPhone}`} style={{ textDecoration: 'underline' }}>{s.customerPhone}</a>}</p>
      <p className="muted small">Tracking {s.trackingNumber} · ETA {fmtDate(s.estimatedDelivery)} · Parcel status: {s.orderStatus.replace(/_/g, ' ').toLowerCase()}</p>
      {actions && (
        <div className="row">
          {s.orderStatus === 'DISPATCHED' && <button className="btn" onClick={() => act(s, 'IN_PROGRESS', 'Delivery started')}>Start delivery</button>}
          {s.orderStatus === 'OUT_FOR_DELIVERY' && <button className="btn" onClick={() => act(s, 'COMPLETED', 'Marked as delivered')}>Mark delivered</button>}
          {['DISPATCHED', 'OUT_FOR_DELIVERY'].includes(s.orderStatus) && <button className="btn btn-outline" onClick={() => act(s, 'FAILED', 'Marked as failed')}>Delivery failed</button>}
          {s.orderStatus !== 'DISPATCHED' && s.orderStatus !== 'OUT_FOR_DELIVERY' && <span className="muted small">Waiting for the warehouse to dispatch this parcel.</span>}
        </div>
      )}
    </section>
  )

  return (
    <>
      <div className="page-head"><div><span className="eyebrow">Driver</span><h1 style={{ margin: 0 }}>My deliveries</h1></div></div>
      <ErrorAlert message={error} />
      {!list && !error && <LoadingSpinner />}
      {list && list.length === 0 && <EmptyState title="No deliveries assigned to you yet" />}
      {active.length > 0 && <div className="form-grid" style={{ gap: 16 }}>{active.map((s) => card(s, true))}</div>}
      {done.length > 0 && <><h2 className="mt">Completed</h2><div className="form-grid" style={{ gap: 16 }}>{done.map((s) => card(s, false))}</div></>}
    </>
  )
}
