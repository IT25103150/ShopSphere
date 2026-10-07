import { useCallback, useEffect, useState } from 'react'
import { StatusBadge } from '../../components/Badge'
import { ErrorAlert, LoadingSpinner } from '../../components/Feedback'
import { ConfirmModal, Modal } from '../../components/Modal'
import { ProductImage } from '../../components/ProductImage'
import { Pagination, Table } from '../../components/Table'
import { Timeline } from '../../components/Timeline'
import { useToast } from '../../features/ToastContext'
import { ALL_STATUSES, fmtDate, fmtDateTime, label, money } from '../../features/format'
import { orderApi } from '../../services'
import { parseError } from '../../services/api'
import type { Order, OrderDetail, Page } from '../../types'

export default function OrderManagement() {
  const toast = useToast()
  const [data, setData] = useState<Page<Order> | null>(null)
  const [f, setF] = useState({ status: '', from: '', to: '', q: '' })
  const [page, setPage] = useState(0)
  const [error, setError] = useState<string | null>(null)
  const [detail, setDetail] = useState<OrderDetail | null>(null)
  const [next, setNext] = useState('')
  const [confirmCancel, setConfirmCancel] = useState(false)
  const [busy, setBusy] = useState(false)

  const load = useCallback(() => {
    orderApi.manage({ ...f, page, size: 12 }).then(setData).catch((e) => setError(parseError(e).message))
  }, [f, page])
  useEffect(() => { load() }, [load])

  const open = async (o: Order) => { try { const d = await orderApi.get(o.id); setDetail(d); setNext(d.allowedNextStatuses.find((s) => s !== 'CANCELLED') ?? '') } catch (e) { toast.error(parseError(e).message) } }
  const applyStatus = async (status: string) => {
    if (!detail) return
    setBusy(true)
    try { const d = await orderApi.updateStatus(detail.order.id, status); setDetail(d); setNext(d.allowedNextStatuses.find((s) => s !== 'CANCELLED') ?? ''); toast.ok(`Order is now ${label(d.order.status)}`); load() }
    catch (e) { toast.error(parseError(e).message) } finally { setBusy(false); setConfirmCancel(false) }
  }
  const change = (k: keyof typeof f, v: string) => { setF({ ...f, [k]: v }); setPage(0) }

  return (
    <>
      <div className="page-head"><div><span className="eyebrow">Sales</span><h1 style={{ margin: 0 }}>Order management</h1></div></div>
      <div className="row" style={{ marginBottom: 16 }}>
        <input className="input" style={{ maxWidth: 240 }} placeholder="Order no. / customer" value={f.q} onChange={(e) => change('q', e.target.value)} aria-label="Search orders" />
        <select className="input" style={{ width: 'auto' }} value={f.status} onChange={(e) => change('status', e.target.value)} aria-label="Filter by status">
          <option value="">All statuses</option>{ALL_STATUSES.map((s) => <option key={s} value={s}>{label(s)}</option>)}
        </select>
        <input className="input" type="date" style={{ width: 'auto' }} value={f.from} onChange={(e) => change('from', e.target.value)} aria-label="From date" />
        <span>→</span>
        <input className="input" type="date" style={{ width: 'auto' }} value={f.to} onChange={(e) => change('to', e.target.value)} aria-label="To date" />
        <button className="btn btn-ghost btn-sm" onClick={() => { setF({ status: '', from: '', to: '', q: '' }); setPage(0) }}>Clear</button>
      </div>
      <ErrorAlert message={error} />
      {!data && !error && <LoadingSpinner />}
      {data && <>
        <Table rows={data.content} rowKey={(o) => o.id} empty="No orders match these filters." columns={[
          { header: 'Order', sortValue: (o) => o.orderNumber, cell: (o) => <strong>{o.orderNumber}</strong> },
          { header: 'Customer', sortValue: (o) => o.customerName, cell: (o) => <>{o.customerName}<div className="muted small">{o.customerEmail}</div></> },
          { header: 'Items', cell: (o) => o.itemCount },
          { header: 'Total', sortValue: (o) => o.finalAmount, cell: (o) => <span className="money">{money(o.finalAmount)}</span> },
          { header: 'Status', cell: (o) => <StatusBadge status={o.status} /> },
          { header: 'Placed', sortValue: (o) => o.createdDate, cell: (o) => fmtDateTime(o.createdDate) },
          { header: '', cell: (o) => <button className="btn btn-sm btn-outline" onClick={() => open(o)}>View</button> },
        ]} />
        <Pagination page={data.page} totalPages={data.totalPages} onChange={setPage} />
      </>}

      {detail && (
        <Modal wide title={`Order ${detail.order.orderNumber}`} onClose={() => setDetail(null)} footer={<button className="btn btn-dark" onClick={() => setDetail(null)}>Close</button>}>
          <div className="row spread" style={{ marginBottom: 16 }}>
            <div><StatusBadge status={detail.order.status} /> <span className="muted small">placed {fmtDateTime(detail.order.createdDate)}</span></div>
            <div className="row">
              {detail.allowedNextStatuses.filter((s) => s !== 'CANCELLED').length > 0 && <>
                <select className="input" style={{ width: 'auto' }} value={next} onChange={(e) => setNext(e.target.value)} aria-label="New status">
                  {detail.allowedNextStatuses.filter((s) => s !== 'CANCELLED').map((s) => <option key={s} value={s}>{label(s)}</option>)}
                </select>
                <button className="btn" disabled={busy || !next} onClick={() => applyStatus(next)}>Update status</button>
              </>}
              {detail.canCancel && <button className="btn btn-danger" onClick={() => setConfirmCancel(true)}>Cancel order</button>}
            </div>
          </div>
          <div className="form-grid" style={{ gap: 16 }}>
            <div>
              <h4>Customer & delivery address</h4>
              <p>{detail.shipping.firstName} {detail.shipping.lastName}<br />{detail.shipping.email}<br />{detail.shipping.phone}{detail.shipping.secondaryPhone && ` / ${detail.shipping.secondaryPhone}`}<br />{detail.shipping.address}{detail.shipping.apartment ? `, ${detail.shipping.apartment}` : ''}<br />{detail.shipping.city} {detail.shipping.postalCode}, {detail.shipping.country}</p>
              <h4>Payment</h4>
              <p>{detail.payment ? `${detail.payment.cardBrand} •••• ${detail.payment.cardLast4} · ${label(detail.payment.status)}` : 'No payment'}</p>
              <h4>Shipment</h4>
              {detail.shipment ? <p>{detail.shipment.trackingNumber} · {label(detail.shipment.status)}<br />ETA {fmtDate(detail.shipment.estimatedDelivery)}<br />Delivery person: {detail.shipment.delivery ? `${detail.shipment.delivery.staffName} (${label(detail.shipment.delivery.status)})` : 'not assigned'}</p> : <p className="muted">Created when the order is confirmed.</p>}
            </div>
            <div><h4>Progress</h4><Timeline status={detail.order.status} /></div>
          </div>
          <h4>Items</h4>
          {detail.order.items.map((i) => (
            <div key={i.productId} className="row" style={{ flexWrap: 'nowrap', padding: '6px 0', borderBottom: '1px solid var(--line)' }}>
              <div className="thumb" style={{ overflow: 'hidden', flex: 'none' }}><ProductImage src={i.imagePath} alt={i.productName} /></div>
              <div className="grow">{i.productName}<div className="muted small">{money(i.priceAtOrder)} × {i.quantity}</div></div>
              <div className="money">{money(i.lineTotal)}</div>
            </div>
          ))}
          <div className="right" style={{ marginTop: 10 }}>
            Subtotal {money(detail.order.totalAmount)} · Discount {money(detail.order.discountApplied)}{detail.order.couponCode && ` (${detail.order.couponCode})`}<br /><strong style={{ fontSize: '1.1rem' }}>Total {money(detail.order.finalAmount)}</strong>
          </div>
        </Modal>
      )}
      {confirmCancel && detail && <ConfirmModal title="Cancel order" danger busy={busy} confirmLabel="Cancel order" message={`Cancel ${detail.order.orderNumber}? Stock is returned, the payment is refunded and the coupon use is released.`} onConfirm={() => applyStatus('CANCELLED')} onCancel={() => setConfirmCancel(false)} />}
    </>
  )
}
