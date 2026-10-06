import axios, { AxiosError } from 'axios'

const TOKEN_KEY = 'ss_token'
const REFRESH_KEY = 'ss_refresh'

export const session = {
  get token() { return localStorage.getItem(TOKEN_KEY) },
  get refresh() { return localStorage.getItem(REFRESH_KEY) },
  save(access: string, refresh: string) {
    localStorage.setItem(TOKEN_KEY, access)
    localStorage.setItem(REFRESH_KEY, refresh)
  },
  clear() {
    localStorage.removeItem(TOKEN_KEY)
    localStorage.removeItem(REFRESH_KEY)
  },
}

export const api = axios.create({ baseURL: '' })

api.interceptors.request.use((config) => {
  const token = session.token
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

let refreshing: Promise<string | null> | null = null

async function refreshAccessToken(): Promise<string | null> {
  const refresh = session.refresh
  if (!refresh) return null
  try {
    const res = await axios.post('/api/auth/refresh', { refreshToken: refresh })
    session.save(res.data.accessToken, res.data.refreshToken)
    return res.data.accessToken as string
  } catch {
    return null
  }
}

// On a 401 try once to refresh the access token; if that fails the user is sent to the login page.
api.interceptors.response.use(
  (r) => r,
  async (error: AxiosError) => {
    const original = error.config as (typeof error.config & { _retried?: boolean }) | undefined
    const isAuthCall = original?.url?.includes('/api/auth/')
    if (error.response?.status === 401 && original && !original._retried && !isAuthCall && session.token) {
      original._retried = true
      refreshing ??= refreshAccessToken().finally(() => { refreshing = null })
      const fresh = await refreshing
      if (fresh) {
        original.headers.Authorization = `Bearer ${fresh}`
        return api(original)
      }
      session.clear()
      if (!location.pathname.startsWith('/login')) location.href = '/login?expired=1'
    }
    return Promise.reject(error)
  },
)

export interface ParsedError {
  message: string
  fieldErrors: Record<string, string>
  status?: number
}

/** Turns any axios error into a readable message plus per-field errors from the backend. */
export function parseError(e: unknown): ParsedError {
  if (axios.isAxiosError(e)) {
    const data = e.response?.data as { message?: string; fieldErrors?: Record<string, string> } | undefined
    if (data?.message) {
      return { message: data.message, fieldErrors: data.fieldErrors ?? {}, status: e.response?.status }
    }
    if (!e.response) return { message: 'Cannot reach the server. Is the backend running?', fieldErrors: {} }
    return { message: `Request failed (${e.response.status})`, fieldErrors: {}, status: e.response.status }
  }
  return { message: e instanceof Error ? e.message : 'Something went wrong', fieldErrors: {} }
}
