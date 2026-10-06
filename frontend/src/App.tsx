import { useEffect } from 'react'
import { BrowserRouter, useLocation } from 'react-router-dom'
import { AuthProvider } from './features/AuthContext'
import { CartProvider } from './features/CartContext'
import { ToastProvider } from './features/ToastContext'
import AppRoutes from './routes/AppRoutes'

function ScrollToTop() {
  const { pathname } = useLocation()
  useEffect(() => { window.scrollTo(0, 0) }, [pathname])
  return null
}

export default function App() {
  return (
    <BrowserRouter>
      <ToastProvider>
        <AuthProvider>
          <CartProvider>
            <ScrollToTop />
            <AppRoutes />
          </CartProvider>
        </AuthProvider>
      </ToastProvider>
    </BrowserRouter>
  )
}
