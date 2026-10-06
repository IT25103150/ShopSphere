import { Link } from 'react-router-dom'

export default function NotFound() {
  return (
    <div className="page container" style={{ textAlign: 'center' }}>
      <p className="eyebrow">Error 404</p>
      <h1>We couldn't find that page</h1>
      <p className="muted">The link may be broken or the page may have moved.</p>
      <Link to="/" className="btn btn-lg">Back to home</Link>
    </div>
  )
}
