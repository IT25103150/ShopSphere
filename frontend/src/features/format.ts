import type { Role } from '../types'

const lkr = new Intl.NumberFormat('en-LK', { style: 'currency', currency: 'LKR', minimumFractionDigits: 2 })
export const money = (n: number | undefined | null) => lkr.format(n ?? 0).replace('LKR', 'LKR ').replace(/\s+/g, ' ')

export const fmtDate = (s?: string) => (s ? new Date(s).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }) : '-')
export const fmtDateTime = (s?: string) =>
  s ? new Date(s).toLocaleString('en-GB', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '-'
export const isoDate = (d: Date) => d.toISOString().slice(0, 10)
export const daysAgo = (n: number) => { const d = new Date(); d.setDate(d.getDate() - n); return isoDate(d) }

export const label = (s: string) => s.replace(/_/g, ' ').toLowerCase().replace(/^\w/, (c) => c.toUpperCase())

export const ORDER_FLOW = ['PENDING', 'CONFIRMED', 'PROCESSING', 'READY_FOR_DISPATCH', 'DISPATCHED', 'OUT_FOR_DELIVERY', 'DELIVERED'] as const
export const ALL_STATUSES = [...ORDER_FLOW, 'CANCELLED']

export function statusTone(status: string): 'ok' | 'warn' | 'danger' | 'blue' | 'dark' | '' {
  switch (status) {
    case 'DELIVERED': case 'COMPLETED': case 'SUCCESS': case 'ACTIVE': case 'IN': return 'ok'
    case 'CANCELLED': case 'FAILED': case 'EXPIRED': case 'REFUNDED': case 'INACTIVE': case 'EXHAUSTED': return 'danger'
    case 'PENDING': case 'ASSIGNED': case 'PREPARING': case 'SCHEDULED': case 'ADJUSTMENT': return 'warn'
    case 'OUT_FOR_DELIVERY': case 'DISPATCHED': case 'IN_PROGRESS': return 'dark'
    default: return 'blue'
  }
}

/** Where each role lands after logging in. */
export const homeFor = (role: Role): string => {
  switch (role) {
    case 'ADMIN': return '/admin'
    case 'STAFF': return '/admin/orders'
    case 'WAREHOUSE': return '/admin/inventory'
    case 'DELIVERY': return '/admin/my-deliveries'
    default: return '/'
  }
}

export const isBackOffice = (role?: Role) => !!role && role !== 'CUSTOMER'
export const canShop = (role?: Role) => role === 'CUSTOMER' || role === 'STAFF'
