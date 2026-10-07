import { useCallback, useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { StatusBadge } from '../components/Badge'
import { ErrorAlert, LoadingSpinner } from '../components/Feedback'
import { ConfirmModal } from '../components/Modal'
import { ProductImage } from '../components/ProductImage'
import { Timeline } from '../components/Timeline'
import { useToast } from '../features/ToastContext'
import { fmtDate, fmtDateTime, label, money } from '../features/format'
import { orderApi } from '../services'
import { parseError } from '../services/api'
import type { OrderDetail } from '../types'

export default function OrderTracking() {
  const { id } = useParams()
  const toast = useToast()
  const [d, setD] = useState<OrderDetail | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [confirm, setConfirm] = useState(false)
  const [busy, setBusy] = useState(false)

  const load = useCallback(() => orderApi.get(Number(id)).then(setD).catch((e) => setError(parseError(e).message)), [id])
  useEffect(() => { load() }, [load])

  const cancel = async () => {
    setBusy(true)
    try { setD(await orderApi.cancel(Number(id))); toast.ok('Order cancelled - stock released and payment refunded') }
    catch (e) { toast.error(parseError(e).message) }
    finally { setBusy(false); setConfirm(false) }
  }

  if (error) return <div className="page container"><ErrorAlert message={error} /><Link to="/orders" className="btn btn-outline">My orders</Link></div>
  if (!d) return <div className="page container"><LoadingSpinner /></div>
  const { order, shipping, shipment, payment } = d
  const driver = shipment?.delivery

  return (
    <div className="page container">
      <p className="small muted"><Link to="/orders">My orders</Link> / {order.orderNumber}</p>
      <div className="page-head">
        <div><span className="eyebrow">Order tracking</span><h1 style={{ margin: 0 }}>{order.orderNumber}</h1><span className="muted small">Placed {fmtDateTime(order.createdDate)}</span></div>
        <div className="row"><StatusBadge status={order.status} />{d.canCancel && <button className="btn btn-sm btn-outline" onClick={() => setConfirm(true)}>Cancel order</button>}</div>
      </div>

      <div className="two-col">
        <div className="stack">
          <section className="card card-pad">
            <h3>Items</h3>
            {order.items.map((i) => (
              <div key={i.productId} className="row" style={{ flexWrap: 'nowrap', padding: '10px 0', borderBottom: '1px solid var(--line)' }}>
                <div style={{ width: 56, height: 56, borderRadius: 8, overflow: 'hidden', flex: 'none' }}><ProductImage src={i.imagePath} alt={i.productName} /></div>
                <div className="grow"><Link to={`/products/${i.productId}`} style={{ fontWeight: 600 }}>{i.productName}</Link><div className="muted small">{money(i.priceAtOrder)} × {i.quantity}</div></div>
                <div className="money">{money(i.lineTotal)}</div>
              </div>
            ))}
            <div className="summary" style={{ maxWidth: 320, marginLeft: 'auto', paddingTop: 12 }}>
              <div className="line"><span>Subtotal</span><span className="money">{money(order.totalAmount)}</span></div>
              <div className="line"><span>Discount{order.couponCode ? ` (${order.couponCode})` : ''}</span><span className="money">{money(order.discountApplied)}</span></div>
              <div className="line total"><span>Total</span><span className="money">{money(order.finalAmount)}</span></div>
            </div>
          </section>
          <div className="form-grid" style={{ gap: 16 }}>
            <section className="card card-pad">
              <h3>Delivery address</h3>
              <p style={{ margin: 0 }}>{shipping.firstName} {shipping.lastName}<br />{shipping.address}{shipping.apartment ? `, ${shipping.apartment}` : ''}<br />{shipping.city} {shipping.postalCode}, {shipping.country}<br />{shipping.phone}</p>
            </section>
            <section className="card card-pad">
              <h3>Payment</h3>
              {payment ? <p style={{ margin: 0 }}>{payment.cardBrand} •••• {payment.cardLast4}<br /><StatusBadge status={payment.status} /><br /><span className="muted small">{payment.transactionId}</span></p> : <p className="muted">Awaiting payment</p>}
            </section>
          </div>
        </div>

        <aside className="stack">
          <section className="card card-pad">
            <h3>Status</h3>
            <Timeline status={order.status} />
          </section>
          <section className="card card-pad">
            <h3>Shipment</h3>
            {shipment ? (
              <>
                <p style={{ margin: 0 }}>Tracking no.<br /><strong>{shipment.trackingNumber}</strong></p>
                <p>Shipment status: <StatusBadge status={shipment.status} /><br />Estimated delivery: <strong>{fmtDate(shipment.estimatedDelivery)}</strong></p>
                {driver ? (
                  <div className="alert alert-info" style={{ marginBottom: 0 }}>
                    <strong>Delivery person: {driver.staffName}</strong><br />{label(driver.status)}
                    {driver.staffPhone && <><br /><a href={`tel:${driver.staffPhone}`} className="btn btn-sm btn-dark" style={{ marginTop: 8 }}>Contact delivery staff · {driver.staffPhone}</a></>}
                  </div>
                ) : <p className="muted small" style={{ margin: 0 }}>A delivery person will be assigned once your parcel is ready.</p>}
              </>
            ) : <p className="muted">A shipment is created when your order is confirmed.</p>}
          </section>
        </aside>
      </div>
      {confirm && <ConfirmModal title="Cancel this order?" message="Your payment will be refunded and the items returned to stock. This cannot be undone." confirmLabel="Yes, cancel order" danger busy={busy} onConfirm={cancel} onCancel={() => setConfirm(false)} />}
    </div>
  )
}
