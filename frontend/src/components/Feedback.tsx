import type { ReactNode } from 'react'

export function LoadingSpinner({ text = 'Loading...' }: { text?: string }) {
  return (
    <div className="spinner-wrap" role="status">
      <div className="spinner" />
      <span>{text}</span>
    </div>
  )
}

export function ErrorAlert({ message, onRetry }: { message?: string | null; onRetry?: () => void }) {
  if (!message) return null
  return (
    <div className="alert alert-error" role="alert">
      {message}
      {onRetry && <button className="btn btn-sm btn-outline" style={{ marginLeft: 12 }} onClick={onRetry}>Try again</button>}
    </div>
  )
}

export function Alert({ kind = 'info', children }: { kind?: 'info' | 'ok' | 'warn' | 'error'; children: ReactNode }) {
  return <div className={`alert alert-${kind}`}>{children}</div>
}

export function EmptyState({ title, children }: { title: string; children?: ReactNode }) {
  return (
    <div className="empty">
      <h3 style={{ color: 'var(--ink)' }}>{title}</h3>
      {children}
    </div>
  )
}
