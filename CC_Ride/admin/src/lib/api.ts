import axios from 'axios'
import { useAuthStore } from '../store/auth'

export const api = axios.create({
  baseURL: '/api',
  timeout: 15_000,
})

api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      useAuthStore.getState().logout()
      window.location.href = '/login'
    }
    return Promise.reject(err)
  },
)

// Unwraps { Result, data } for the 200-with-Result:false case, and also
// turns non-2xx responses into a readable message instead of axios's raw
// "Request failed with status code 403" — that generic string was reaching
// users verbatim (e.g. a scoped company admin hitting a super-admin-only
// action like crediting a wallet), telling them nothing actionable. A 403
// always means an authorization gate, so it gets one consistent, friendly
// message app-wide rather than repeating the backend's raw ResponseMsg
// (which varies action-to-action, e.g. "Super-admin access required").
async function unwrap<T>(promise: Promise<{ data: any }>): Promise<T> {
  try {
    const { data } = await promise
    if (data.Result === 'false') throw new Error(data.ResponseMsg)
    return data.data as T
  } catch (err: any) {
    if (err.response?.status === 403) {
      throw new Error('You are not authorised to perform this action. Please contact CC Ride admin for support.')
    }
    const backendMsg = err.response?.data?.ResponseMsg
    if (backendMsg) throw new Error(backendMsg)
    throw err
  }
}

export async function get<T>(path: string, params?: Record<string, unknown>): Promise<T> {
  return unwrap<T>(api.get(path, { params }))
}

export async function post<T>(path: string, body?: unknown): Promise<T> {
  return unwrap<T>(api.post(path, body))
}

export async function patch<T>(path: string, body?: unknown): Promise<T> {
  return unwrap<T>(api.patch(path, body))
}

export async function del<T>(path: string, params?: Record<string, unknown>): Promise<T> {
  return unwrap<T>(api.delete(path, { params }))
}
