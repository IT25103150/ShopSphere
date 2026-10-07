import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { StatusBadge } from '../components/Badge'
import { EmptyState, ErrorAlert, LoadingSpinner } from '../components/Feedback'
import { ProductImage } from '../components/ProductImage'
import { Pagination } from '../components/Table'
import { fmtDateTime, money } from '../features/format'
import { orderApi } from '../services'
import { parseError } from '../services/api'
import type { Order, Page } from '../types'

export default function MyOrders() {
  const [data, setData] = useState<Page<Order> | null>(null)
  const [page, setPage] = useState(0)
  const [sort, setSort] = useState('date_desc')
  const [error, setError] = useState<string | null>(null)

  useEffect(() => { setData(null); orderApi.mine(page, 8).then(setData).catch((e) => setError(parseError(e).message)) }, [page])

  const rows = useMemo(() => {
    const r = [...(data?.content ?? [])]
    if (sort === 'date_asc') r.sort((a, b) => a.createdDate.localeCompare(b.createdDate))
    if (sort === 'status') r.sort((a, b) => a.status.localeCompare(b.status))
    return r
  }, [data, sort])

  return (
    <div className="page container">
      <div className="page-head">
        <h1 style={{ margin: 0 }}>My orders</h1>
        <select className="input" style={{ width: 'auto' }} value={sort} onChange={(e) => setSort(e.target.value)} aria-label="Sort orders">
          <option value="date_desc">Newest first</option><option value="date_asc">Oldest first</option><option value="status">By status</option>
        </select>
      </div>
      <ErrorAlert message={error} />
      {!data && !error && <LoadingSpinner />}
      {data && data.content.length === 0 && <EmptyState title="You have not placed any orders yet"><Link to="/products" className="btn">Start shopping</Link></EmptyState>}
      <div className="stack">
        {rows.map((o) => (
          <Link key={o.id} to={`/orders/${o.id}`} className="card card-pad" style={{ display: 'block' }}>
            <div className="row spread">
              <div><strong>{o.orderNumber}</strong><div className="muted small">{fmtDateTime(o.createdDate)}</div></div>
              <StatusBadge status={o.status} />
              <div className="money" style={{ fontWeight: 700 }}>{money(o.finalAmount)}</div>
            </div>
            <div className="row" style={{ marginTop: 12 }}>
              {o.items.slice(0, 5).map((i) => (
                <div key={i.productId} style={{ width: 52, height: 52, borderRadius: 8, overflow: 'hidden' }} title={`${i.productName} × ${i.quantity}`}><ProductImage src={i.imagePath} alt={i.productName} /></div>
              ))}
              <span className="muted small">{o.itemCount} item{o.itemCount === 1 ? '' : 's'}: {o.items.map((i) => i.productName).join(', ').slice(0, 90)}</span>
            </div>
          </Link>
        ))}
      </div>
      {data && <Pagination page={data.page} totalPages={data.totalPages} onChange={setPage} />}
    </div>
  )
}
