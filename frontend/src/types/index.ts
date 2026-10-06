export type Role = 'ADMIN' | 'STAFF' | 'WAREHOUSE' | 'DELIVERY' | 'CUSTOMER'

export interface User {
  id: number
  email: string
  firstName: string
  lastName: string
  phone?: string
  role: Role
}

export interface AuthResponse {
  accessToken: string
  refreshToken: string
  user: User
}

export interface Page<T> {
  content: T[]
  page: number
  size: number
  totalElements: number
  totalPages: number
}

export interface NamedRef {
  id: number
  name: string
}

export interface ProductImage {
  id: number
  imagePath: string
  uploadedDate: string
}

export interface Product {
  id: number
  name: string
  description?: string
  price: number
  sku: string
  status: 'ACTIVE' | 'INACTIVE'
  category: NamedRef
  brand: NamedRef
  primaryImage?: string
  images: ProductImage[]
  stock: number
  inStock: boolean
  createdAt: string
}

export interface CartItem {
  id: number
  productId: number
  name: string
  sku?: string
  imagePath?: string
  unitPrice: number
  quantity: number
  lineTotal: number
  availableStock: number
  purchasable: boolean
  issue?: string
}

export interface Cart {
  cartId: number
  items: CartItem[]
  itemCount: number
  subtotal: number
  discountApplied: number
  totalPrice: number
  couponCode?: string
  couponValid?: boolean
  couponMessage?: string
}

export interface PaymentForm {
  cardHolder: string
  cardNumber: string
  expiryMonth: number
  expiryYear: number
  cvv: string
}

export interface CheckoutForm {
  email: string
  firstName: string
  lastName: string
  address: string
  apartment: string
  city: string
  postalCode: string
  country: string
  phone: string
  secondaryPhone: string
  couponCode?: string
  payment: PaymentForm
}

export interface CheckoutResponse {
  orderId: number
  orderNumber: string
  subtotal: number
  discountApplied: number
  totalAmount: number
  estimatedDelivery?: string
  status: string
  paymentStatus: string
  transactionId: string
  cardBrand: string
  cardLast4: string
}

export interface OrderItem {
  productId: number
  productName: string
  imagePath?: string
  quantity: number
  priceAtOrder: number
  lineTotal: number
}

export interface Order {
  id: number
  orderNumber: string
  userId: number
  customerName: string
  customerEmail: string
  items: OrderItem[]
  itemCount: number
  totalAmount: number
  discountApplied: number
  finalAmount: number
  couponCode?: string
  status: string
  createdDate: string
  updatedDate: string
}

export interface DeliveryInfo {
  id: number
  shipmentId: number
  staffId: number
  staffName: string
  staffPhone?: string
  status: string
  assignedDate: string
}

export interface Shipment {
  id: number
  orderId: number
  orderNumber: string
  orderStatus: string
  trackingNumber: string
  status: string
  estimatedDelivery?: string
  createdDate: string
  customerName: string
  customerPhone?: string
  address: string
  city: string
  delivery?: DeliveryInfo
}

export interface OrderDetail {
  order: Order
  shipping: {
    email: string; firstName: string; lastName: string; address: string; apartment?: string
    city: string; postalCode: string; country: string; phone: string; secondaryPhone?: string
  }
  payment?: { method: string; cardBrand?: string; cardLast4?: string; status: string; transactionId: string }
  shipment?: Shipment
  allowedNextStatuses: string[]
  canCancel: boolean
}

export interface InventoryRow {
  id: number
  productId: number
  productName: string
  sku: string
  quantity: number
  reorderLevel: number
  isLowStock: boolean
  lastUpdated: string
}

export interface StockMovement {
  id: number
  productId: number
  productName: string
  movementType: 'IN' | 'OUT' | 'ADJUSTMENT'
  quantity: number
  quantityAfter: number
  reason: string
  createdBy: string
  createdDate: string
}

export interface Promotion {
  id: number
  couponCode: string
  discountType: 'PERCENTAGE' | 'FIXED'
  discountValue: number
  startDate: string
  endDate: string
  isActive: boolean
  usageLimit?: number
  usageCount: number
  remainingUsage?: number
  status: 'ACTIVE' | 'INACTIVE' | 'EXPIRED' | 'SCHEDULED' | 'EXHAUSTED'
}

export interface CouponCheck {
  isValid: boolean
  discountAmount: number
  finalAmount: number
  message: string
}

export interface Address {
  id: number
  label: string
  address: string
  apartment?: string
  city: string
  postalCode: string
  country: string
  phone?: string
  defaultAddress: boolean
}

export interface TopProduct { productId: number; name: string; sku: string; imagePath?: string; unitsSold: number; revenue: number }
export interface CategorySales { categoryId: number; category: string; unitsSold: number; revenue: number }
export interface DatePoint { date: string; orders: number; revenue: number }

export interface Dashboard {
  from: string
  to: string
  totalRevenue: number
  orderCount: number
  averageOrderValue: number
  activeUsers: number
  topProducts: TopProduct[]
  salesByCategory: CategorySales[]
  salesByDate: DatePoint[]
  orderStatusSummary: Record<string, number>
  lowStockProducts: InventoryRow[]
  recentOrders: { id: number; orderNumber: string; customer: string; finalAmount: number; status: string; createdDate: string }[]
}

export interface SalesRow {
  orderNumber: string; orderDate: string; status: string; customer: string; product: string
  category: string; quantity: number; unitPrice: number; lineTotal: number
}

export interface SalesData { totalRevenue: number; totalUnits: number; orderCount: number; byDate: DatePoint[]; rows: SalesRow[] }

export interface Report {
  id: number
  reportName: string
  reportType: 'SALES_SUMMARY' | 'PRODUCT_PERFORMANCE' | 'CATEGORY_PERFORMANCE'
  startDate: string
  endDate: string
  productId?: number
  categoryId?: number
  orderStatus?: string
  exportFormat: 'CSV' | 'JSON'
  createdDate: string
  createdBy: string
}

export interface ReportDetail {
  report: Report
  data: { columns: string[]; rows: (string | number)[][]; totalRevenue: number; totalUnits: number }
}
