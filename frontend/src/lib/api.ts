// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
const BASE = '/api'

async function request(path: string, init: RequestInit = {}, token?: string) {
  const headers = new Headers(init.headers)
  headers.set('Content-Type', 'application/json')
  if (token) headers.set('Authorization', `Bearer ${token}`)
  const res = await fetch(`${BASE}${path}`, { ...init, headers })
  const json = await res.json().catch(() => undefined)
  if (!res.ok) throw new Error('error')
  return json?.data ?? json
}

export const api = {
  get: (path: string, token?: string) => request(path, { method: 'GET' }, token),
  post: (path: string, body?: unknown, token?: string) => request(path, { method: 'POST', body: JSON.stringify(body) }, token),
  patch: (path: string, body?: unknown, token?: string) => request(path, { method: 'PATCH', body: JSON.stringify(body) }, token)
}
