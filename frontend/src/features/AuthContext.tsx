import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import { authApi } from '../services'
import { session } from '../services/api'
import type { User } from '../types'

interface AuthCtx {
  user: User | null
  loading: boolean
  login: (email: string, password: string) => Promise<User>
  register: (b: { email: string; password: string; firstName: string; lastName: string; phone?: string }) => Promise<User>
  logout: () => Promise<void>
  setUser: (u: User) => void
}

const Ctx = createContext<AuthCtx | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(!!session.token)

  // Restore the session after a page refresh
  useEffect(() => {
    if (!session.token) return
    authApi.me().then(setUser).catch(() => session.clear()).finally(() => setLoading(false))
  }, [])

  const login = useCallback(async (email: string, password: string) => {
    const res = await authApi.login(email, password)
    session.save(res.accessToken, res.refreshToken)
    setUser(res.user)
    return res.user
  }, [])

  const register = useCallback(async (b: Parameters<AuthCtx['register']>[0]) => {
    const res = await authApi.register(b)
    session.save(res.accessToken, res.refreshToken)
    setUser(res.user)
    return res.user
  }, [])

  const logout = useCallback(async () => {
    try { await authApi.logout() } catch { /* stateless tokens: nothing to undo on the server */ }
    session.clear()
    localStorage.removeItem('ss_coupon')
    setUser(null)
  }, [])

  const value = useMemo(() => ({ user, loading, login, register, logout, setUser }), [user, loading, login, register, logout])
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>
}

export function useAuth() {
  const c = useContext(Ctx)
  if (!c) throw new Error('useAuth must be used inside AuthProvider')
  return c
}
