// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { create } from 'zustand'
import { api } from '@/lib/api'

type User = { id: string; email: string; name?: string }

type Store = {
  user?: User
  accessToken?: string
  refreshToken?: string
  setSession: (u: User | undefined, a?: string, r?: string) => void
  clear: () => void
  login: (email: string, password: string) => Promise<boolean>
  register: (email: string, password: string, name?: string) => Promise<boolean>
  logout: () => void
  isAuthenticated: () => boolean
  updateProfile: (name: string) => Promise<boolean>
}

const useStore = create<Store>((set, get) => ({
  user: undefined,
  accessToken: undefined,
  refreshToken: undefined,
  setSession: (u, a, r) => {
    set({ user: u, accessToken: a, refreshToken: r })
    if (a) localStorage.setItem('accessToken', a)
    if (r) localStorage.setItem('refreshToken', r)
  },
  clear: () => {
    set({ user: undefined, accessToken: undefined, refreshToken: undefined })
    localStorage.removeItem('accessToken')
    localStorage.removeItem('refreshToken')
  },
  login: async (email, password) => {
    try {
      const res = await api.post('/auth/login', { email, password })
      if (res?.accessToken) {
        const me = await api.get('/auth/me', res.accessToken)
        get().setSession(me, res.accessToken, res.refreshToken)
        return true
      }
      return false
    } catch {
      return false
    }
  },
  register: async (email, password, name) => {
    try {
      const r = await api.post('/auth/register', { email, password, name })
      return !!r
    } catch {
      return false
    }
  },
  logout: () => {
    get().clear()
  },
  isAuthenticated: () => {
    const a = get().accessToken || localStorage.getItem('accessToken')
    return !!a
  },
  updateProfile: async (name: string) => {
    try {
      const token = get().accessToken || localStorage.getItem('accessToken') || undefined
      await api.patch('/accounts/profile', { name }, token)
      const me = await api.get('/auth/me', token)
      const a = token
      const r = get().refreshToken || localStorage.getItem('refreshToken') || undefined
      get().setSession(me, a, r)
      return true
    } catch {
      return false
    }
  }
}))

export function useAuth() {
  return useStore()
}
