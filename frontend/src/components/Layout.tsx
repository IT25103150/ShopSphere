import { useState, type FormEvent } from 'react'
import { Link, NavLink, Outlet, useNavigate } from 'react-router-dom'
import { useAuth } from '../features/AuthContext'
import { useCart } from '../features/CartContext'
import { canShop, homeFor, isBackOffice, label } from '../features/format'
import type { Role } from '../types'

export function Navbar() {
  const { user, logout } = useAuth()
  const { count } = useCart()
  const nav = useNavigate()
  const [open, setOpen] = useState(false)
  const [q, setQ] = useState('')

  const search = (e: FormEvent) => {
    e.preventDefault()
    nav(`/products${q.trim() ? `?q=${encodeURIComponent(q.trim())}` : ''}`)
    setOpen(false)
  }
  const close = () => setOpen(false)

  return (
    <header className={`navbar ${open ? 'open' : ''}`}>
      <div className="container navbar-inner">
        <Link to="/" className="brand" onClick={close}>Shop<span>Sphere</span></Link>
        <button className="menu-toggle" onClick={() => setOpen(!open)} aria-label="Menu" aria-expanded={open}>{open ? '×' : '☰'}</button>
        <nav className="nav-links" onClick={close}>
          <NavLink to="/" end>Home</NavLink>
          <NavLink to="/products">Shop</NavLink>
          {user && !isBackOffice(user.role) && <NavLink to="/orders">My orders</NavLink>}
          {user && isBackOffice(user.role) && <NavLink to={homeFor(user.role)}>{user.role === 'DELIVERY' ? 'My deliveries' : 'Back office'}</NavLink>}
          {user && user.role === 'STAFF' && <NavLink to="/orders">My orders</NavLink>}
        </nav>
        <div className="nav-actions">
          <form className="nav-search" onSubmit={search} role="search">
            <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search products" aria-label="Search products" />
            <button type="submit">Go</button>
          </form>
          {canShop(user?.role) && (
            <Link to="/cart" className="cart-link" onClick={close}>Cart<span className="cart-count">{count}</span></Link>
          )}
          {user ? (
            <>
              <Link to="/profile" className="cart-link" onClick={close}>{user.firstName}</Link>
              <span className="role-pill">{label(user.role)}</span>
              <button className="btn btn-sm btn-ghost" style={{ color: '#fff' }} onClick={() => { close(); logout().then(() => nav('/')) }}>Logout</button>
            </>
          ) : (
            <>
              <Link to="/login" className="btn btn-sm" onClick={close}>Login</Link>
              <Link to="/register" className="btn btn-sm btn-outline" style={{ color: '#fff', borderColor: '#fff' }} onClick={close}>Register</Link>
            </>
          )}
        </div>
      </div>
    </header>
  )
}

export function Footer() {
  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-grid">
          <div>
            <div className="brand" style={{ color: '#fff', marginBottom: 8 }}>Shop<span>Sphere</span></div>
            <p>A university e-commerce project. Sri Lankan prices in LKR, sandbox payments only.</p>
          </div>
          <div>
            <h4>Shop</h4>
            <Link to="/products">All products</Link>
            <Link to="/products?sort=newest">New arrivals</Link>
            <Link to="/cart">Cart</Link>
          </div>
          <div>
            <h4>Account</h4>
            <Link to="/orders">My orders</Link>
            <Link to="/profile">Profile</Link>
            <Link to="/addresses">Addresses</Link>
          </div>
        </div>
        <div className="footer-bottom">© {new Date().getFullYear()} ShopSphere · Test/sandbox mode - no real payments are processed.</div>
      </div>
    </footer>
  )
}

export function PublicLayout() {
  return (
    <>
      <Navbar />
      <main><Outlet /></main>
      <Footer />
    </>
  )
}

interface NavItem { to: string; label: string; roles: Role[]; end?: boolean }
const ITEMS: NavItem[] = [
  { to: '/admin', label: '📊 Dashboard', roles: ['ADMIN'], end: true },
  { to: '/admin/orders', label: '🧾 Orders', roles: ['ADMIN', 'STAFF', 'WAREHOUSE'] },
  { to: '/admin/deliveries', label: '🚚 Deliveries', roles: ['ADMIN', 'STAFF'] },
  { to: '/admin/my-deliveries', label: '📦 My deliveries', roles: ['DELIVERY'] },
  { to: '/admin/inventory', label: '🏬 Inventory', roles: ['ADMIN', 'STAFF', 'WAREHOUSE'] },
  { to: '/admin/products', label: '🏷️ Products', roles: ['ADMIN'] },
  { to: '/admin/promotions', label: '🎟️ Promotions', roles: ['ADMIN'] },
  { to: '/admin/analytics', label: '📈 Analytics', roles: ['ADMIN'] },
  { to: '/admin/reports', label: '🗂️ Saved reports', roles: ['ADMIN'] },
]

export function Sidebar() {
  const { user } = useAuth()
  return (
    <aside className="sidebar" aria-label="Back office navigation">
      <h4>{user ? label(user.role) : ''} menu</h4>
      {ITEMS.filter((i) => user && i.roles.includes(user.role)).map((i) => (
        <NavLink key={i.to} to={i.to} end={i.end}>{i.label}</NavLink>
      ))}
      {canShop(user?.role) && <><h4>Store</h4><NavLink to="/products">🛍️ Browse shop</NavLink></>}
    </aside>
  )
}

export function AdminLayout() {
  return (
    <>
      <Navbar />
      <div className="admin-shell">
        <Sidebar />
        <main className="admin-main"><Outlet /></main>
      </div>
    </>
  )
}
