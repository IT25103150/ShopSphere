import type { ReactNode } from 'react'
import { label, statusTone } from '../features/format'

export function Badge({ tone = '', children }: { tone?: 'ok' | 'warn' | 'danger' | 'blue' | 'dark' | ''; children: ReactNode }) {
  return <span className={`badge ${tone ? `badge-${tone}` : ''}`}>{children}</span>
}

export function StatusBadge({ status }: { status: string }) {
  return <Badge tone={statusTone(status)}>{label(status)}</Badge>
}
