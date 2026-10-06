import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react'

interface Toast { id: number; text: string; kind: 'ok' | 'error' }
interface ToastCtx { ok: (t: string) => void; error: (t: string) => void }

const Ctx = createContext<ToastCtx | null>(null)
let nextId = 1

/** SuccessToast: short-lived messages shown bottom-right after an action. */
export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([])
  const push = useCallback((text: string, kind: Toast['kind']) => {
    const id = nextId++
    setToasts((t) => [...t, { id, text, kind }])
    setTimeout(() => setToasts((t) => t.filter((x) => x.id !== id)), 4000)
  }, [])
  const value = useMemo(() => ({ ok: (t: string) => push(t, 'ok'), error: (t: string) => push(t, 'error') }), [push])
  return (
    <Ctx.Provider value={value}>
      {children}
      <div className="toasts" role="status" aria-live="polite">
        {toasts.map((t) => (
          <div key={t.id} className={`toast ${t.kind}`}>{t.text}</div>
        ))}
      </div>
    </Ctx.Provider>
  )
}

export function useToast() {
  const c = useContext(Ctx)
  if (!c) throw new Error('useToast must be used inside ToastProvider')
  return c
}
