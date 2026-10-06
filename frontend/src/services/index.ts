import { api } from './api'
import type {
  Address, AuthResponse, Cart, CheckoutForm, CheckoutResponse, CouponCheck, Dashboard, InventoryRow, NamedRef, Order,
  OrderDetail, Page, Product, ProductImage, Promotion, Report, ReportDetail, SalesData, Shipment, StockMovement, User,
} from '../types'

const get = <T>(url: string, params?: object) => api.get<T>(url, { params }).then((r) => r.data)
const post = <T>(url: string, body?: unknown) => api.post<T>(url, body).then((r) => r.data)
const put = <T>(url: string, body?: unknown) => api.put<T>(url, body).then((r) => r.data)
const del = <T = void>(url: string) => api.delete<T>(url).then((r) => r.data)

/** Removes empty values so optional filters do not become "?q=&categoryId=" in the URL. */
const clean = (p: Record<string, unknown>) =>
  Object.fromEntries(Object.entries(p).filter(([, v]) => v !== '' && v !== undefined && v !== null))

export const authApi = {
  login: (email: string, password: string) => post<AuthResponse>('/api/auth/login', { email, password }),
  register: (b: { email: string; password: string; firstName: string; lastName: string; phone?: string }) =>
    post<AuthResponse>('/api/auth/register', b),
  logout: () => post<void>('/api/auth/logout'),
  me: () => get<User>('/api/users/me'),
  updateProfile: (b: { firstName: string; lastName: string; phone?: string }) => put<User>('/api/users/me', b),
  changePassword: (b: { currentPassword: string; newPassword: string }) => put<void>('/api/users/me/password', b),
  addresses: () => get<Address[]>('/api/users/me/addresses'),
  saveAddress: (id: number | null, b: Omit<Address, 'id'>) =>
    id ? put<Address>(`/api/users/me/addresses/${id}`, b) : post<Address>('/api/users/me/addresses', b),
  deleteAddress: (id: number) => del(`/api/users/me/addresses/${id}`),
  makeDefaultAddress: (id: number) => post<Address>(`/api/users/me/addresses/${id}/default`),
  usersByRole: (role: string) => get<User[]>('/api/users', { role }),
}

export interface ProductQuery {
  q?: string; categoryId?: number | ''; brandId?: number | ''; minPrice?: number | ''; maxPrice?: number | ''
  sort?: string; page?: number; size?: number; inStockOnly?: boolean; includeInactive?: boolean
}

export const productApi = {
  list: (q: ProductQuery) => get<Page<Product>>('/api/products', clean({ ...q })),
  get: (id: number) => get<Product>(`/api/products/${id}`),
  categories: () => get<NamedRef[]>('/api/categories'),
  brands: () => get<NamedRef[]>('/api/brands'),
  create: (b: unknown) => post<Product>('/api/products', b),
  update: (id: number, b: unknown) => put<Product>(`/api/products/${id}`, b),
  remove: (id: number) => del(`/api/products/${id}`),
  uploadImage: (id: number, file: File) => {
    const fd = new FormData()
    fd.append('file', file)
    return api.post<ProductImage>(`/api/products/${id}/image`, fd).then((r) => r.data)
  },
  deleteImage: (id: number, imageId: number) => del(`/api/products/${id}/images/${imageId}`),
}

export const cartApi = {
  get: (couponCode?: string) => get<Cart>('/api/cart', clean({ couponCode })),
  add: (productId: number, quantity: number) => post<Cart>('/api/cart/items', { productId, quantity }),
  update: (itemId: number, quantity: number) => put<Cart>(`/api/cart/items/${itemId}`, { quantity }),
  remove: (itemId: number) => del<Cart>(`/api/cart/items/${itemId}`),
  clear: () => del<Cart>('/api/cart'),
  checkout: (b: CheckoutForm) => post<CheckoutResponse>('/api/checkout', b),
}

export const orderApi = {
  mine: (page = 0, size = 10) => get<Page<Order>>('/api/orders', { page, size }),
  manage: (p: { status?: string; from?: string; to?: string; q?: string; page?: number; size?: number }) =>
    get<Page<Order>>('/api/orders/manage', clean(p)),
  get: (id: number) => get<OrderDetail>(`/api/orders/${id}`),
  updateStatus: (id: number, newStatus: string) => put<OrderDetail>(`/api/orders/${id}`, { newStatus }),
  cancel: (id: number) => del<OrderDetail>(`/api/orders/${id}`),
  shipments: (status?: string, page = 0, size = 15) => get<Page<Shipment>>('/api/shipments', clean({ status, page, size })),
  updateShipment: (id: number, status: string) => put<Shipment>(`/api/shipments/${id}`, { status }),
  assign: (shipmentId: number, staffId: number) => post<Shipment>('/api/deliveries/assign', { shipmentId, staffId }),
  myDeliveries: () => get<Shipment[]>('/api/deliveries/mine'),
  updateDelivery: (assignmentId: number, status: string) => put<Shipment>(`/api/deliveries/${assignmentId}/status`, { status }),
}

export const inventoryApi = {
  list: (p: { search?: string; lowStockOnly?: boolean; page?: number; size?: number }) => get<Page<InventoryRow>>('/api/inventory', clean(p)),
  adjust: (productId: number, b: { newQuantity: number; reason: string; reorderLevel?: number }) => put<InventoryRow>(`/api/inventory/${productId}`, b),
  restock: (productId: number, b: { quantity: number; reason: string }) => post<InventoryRow>(`/api/inventory/${productId}/restock`, b),
  movements: (productId: number, page = 0, size = 10) => get<Page<StockMovement>>(`/api/inventory/${productId}/movements`, { page, size }),
}

export const promoApi = {
  list: () => get<Promotion[]>('/api/promotions'),
  save: (id: number | null, b: unknown) => (id ? put<Promotion>(`/api/promotions/${id}`, b) : post<Promotion>('/api/promotions', b)),
  remove: (id: number) => del(`/api/promotions/${id}`),
  setActive: (id: number, active: boolean) => post<Promotion>(`/api/promotions/${id}/${active ? 'activate' : 'deactivate'}`),
  validate: (couponCode: string, orderAmount: number) => post<CouponCheck>('/api/promotions/validate', { couponCode, orderAmount }),
}

export const analyticsApi = {
  dashboard: (from?: string, to?: string) => get<Dashboard>('/api/analytics/dashboard', clean({ from, to })),
  sales: (p: { from?: string; to?: string; productId?: number | ''; categoryId?: number | ''; status?: string }) =>
    get<SalesData>('/api/analytics/sales', clean(p)),
  reports: () => get<Report[]>('/api/reports'),
  report: (id: number) => get<ReportDetail>(`/api/reports/${id}`),
  saveReport: (id: number | null, b: unknown) => (id ? put<Report>(`/api/reports/${id}`, b) : post<Report>('/api/reports', b)),
  deleteReport: (id: number) => del(`/api/reports/${id}`),
  exportReport: (id: number) => api.get(`/api/reports/${id}/export`, { responseType: 'blob' }).then((r) => r.data as Blob),
}
