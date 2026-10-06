import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { LoadingSpinner } from '../components/Feedback'
import { ProductCard } from '../components/ProductCard'
import { productApi } from '../services'
import type { NamedRef, Product } from '../types'

export default function Home() {
  const [featured, setFeatured] = useState<Product[] | null>(null)
  const [cats, setCats] = useState<NamedRef[]>([])

  useEffect(() => {
    productApi.list({ sort: 'newest', size: 10, inStockOnly: true }).then((p) => setFeatured(p.content)).catch(() => setFeatured([]))
    productApi.categories().then(setCats).catch(() => setCats([]))
  }, [])

  return (
    <>
      <section className="hero">
        <div className="container hero-inner">
          <div>
            <span className="eyebrow" style={{ color: 'var(--blue)' }}>New season · Free island-wide delivery over LKR 15,000</span>
            <h1 style={{ marginTop: 12 }}>Everything you need, <em>delivered</em> across Sri Lanka.</h1>
            <p>Electronics, fashion, sports gear and home essentials at honest LKR prices - with real-time order tracking from our warehouse to your door.</p>
            <div className="row" style={{ marginTop: 24 }}>
              <Link to="/products" className="btn btn-lg">Shop now</Link>
              <Link to="/products?sort=price_asc" className="btn btn-lg btn-outline" style={{ color: '#fff', borderColor: '#fff' }}>Best value</Link>
            </div>
          </div>
          <div className="hero-collage" aria-hidden="true">
            <img src="/images/products/headphones-wireless.jpg" alt="" />
            <img src="/images/products/sneakers-casual.jpg" alt="" />
            <img src="/images/products/smartwatch-001.jpg" alt="" />
          </div>
        </div>
        <div className="strip">Use code <strong>WELCOME15</strong> at checkout for 15% off your order</div>
      </section>

      <section className="section container" aria-labelledby="cats">
        <div className="section-head">
          <div><span className="eyebrow">Browse</span><h2 id="cats" style={{ margin: 0 }}>Shop by category</h2></div>
        </div>
        <div className="cat-grid">
          {cats.map((c) => (
            <Link key={c.id} to={`/products?categoryId=${c.id}`} className="cat-card"><span>{c.name}</span><span aria-hidden="true">→</span></Link>
          ))}
        </div>
      </section>

      <section className="section container" aria-labelledby="feat">
        <div className="section-head">
          <div><span className="eyebrow">Just landed</span><h2 id="feat" style={{ margin: 0 }}>Featured products</h2></div>
          <Link to="/products" className="btn btn-outline btn-sm">View all</Link>
        </div>
        {featured === null ? <LoadingSpinner /> : (
          <div className="carousel">{featured.map((p) => <ProductCard key={p.id} product={p} />)}</div>
        )}
      </section>

      <section className="section container">
        <div className="card card-pad row spread" style={{ background: 'var(--black)', color: '#fff', borderColor: '#000' }}>
          <div>
            <h2 style={{ margin: 0 }}>Track every parcel</h2>
            <p style={{ margin: '6px 0 0', color: '#b4b4bd' }}>From "confirmed" to "delivered" - follow your order live in My orders.</p>
          </div>
          <Link to="/orders" className="btn btn-lg">Track my order</Link>
        </div>
      </section>
    </>
  )
}
