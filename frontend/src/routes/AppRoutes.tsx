import { Route, Routes } from 'react-router-dom'
import { AdminLayout, PublicLayout } from '../components/Layout'
import Addresses from '../pages/Addresses'
import Analytics from '../pages/admin/Analytics'
import AdminDashboard from '../pages/admin/AdminDashboard'
import DeliveryManagement from '../pages/admin/DeliveryManagement'
import InventoryManagement from '../pages/admin/InventoryManagement'
import MyDeliveries from '../pages/admin/MyDeliveries'
import OrderManagement from '../pages/admin/OrderManagement'
import ProductManagement from '../pages/admin/ProductManagement'
import PromotionManagement from '../pages/admin/PromotionManagement'
import Reports from '../pages/admin/Reports'
import CartPage from '../pages/Cart'
import Checkout from '../pages/Checkout'
import Home from '../pages/Home'
import Login from '../pages/Login'
import MyOrders from '../pages/MyOrders'
import NotFound from '../pages/NotFound'
import OrderConfirmation from '../pages/OrderConfirmation'
import OrderTracking from '../pages/OrderTracking'
import ProductDetails from '../pages/ProductDetails'
import Products from '../pages/Products'
import Profile from '../pages/Profile'
import Register from '../pages/Register'
import { RequireAuth, RequireRole } from './guards'

export default function AppRoutes() {
  return (
    <Routes>
      <Route element={<PublicLayout />}>
        <Route index element={<Home />} />
        <Route path="products" element={<Products />} />
        <Route path="products/:id" element={<ProductDetails />} />
        <Route path="login" element={<Login />} />
        <Route path="register" element={<Register />} />

        <Route element={<RequireAuth />}>
          <Route path="profile" element={<Profile />} />
          <Route path="addresses" element={<Addresses />} />
          <Route path="orders" element={<MyOrders />} />
          <Route path="orders/:id" element={<OrderTracking />} />
        </Route>

        <Route element={<RequireRole roles={['CUSTOMER', 'STAFF']} />}>
          <Route path="cart" element={<CartPage />} />
          <Route path="checkout" element={<Checkout />} />
          <Route path="order-confirmation/:id" element={<OrderConfirmation />} />
        </Route>
        <Route path="*" element={<NotFound />} />
      </Route>

      <Route path="admin" element={<AdminLayout />}>
        <Route element={<RequireRole roles={['ADMIN']} />}>
          <Route index element={<AdminDashboard />} />
          <Route path="products" element={<ProductManagement />} />
          <Route path="promotions" element={<PromotionManagement />} />
          <Route path="analytics" element={<Analytics />} />
          <Route path="reports" element={<Reports />} />
        </Route>
        <Route element={<RequireRole roles={['ADMIN', 'STAFF', 'WAREHOUSE']} />}>
          <Route path="orders" element={<OrderManagement />} />
          <Route path="inventory" element={<InventoryManagement />} />
        </Route>
        <Route element={<RequireRole roles={['ADMIN', 'STAFF']} />}>
          <Route path="deliveries" element={<DeliveryManagement />} />
        </Route>
        <Route element={<RequireRole roles={['DELIVERY']} />}>
          <Route path="my-deliveries" element={<MyDeliveries />} />
        </Route>
      </Route>
    </Routes>
  )
}
