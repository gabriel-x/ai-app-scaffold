// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { Router, Request, Response } from 'express'
import bcrypt from 'bcrypt'
import jwt from 'jsonwebtoken'
import { z } from 'zod'
import { authGuard } from '../security/authGuard.js'

const router = Router()

const users = new Map<string, { id: string; email: string; name?: string; passwordHash: string }>()

const RegisterSchema = z.object({ email: z.string().email(), password: z.string().min(8), name: z.string().optional() })
const LoginSchema = z.object({ email: z.string().email(), password: z.string() })

function signTokens(userId: string) {
  const secret = process.env.JWT_SECRET || 'dev-secret'
  const accessToken = jwt.sign({ sub: userId }, secret, { expiresIn: '15m' })
  const refreshToken = jwt.sign({ sub: userId, type: 'refresh' }, secret, { expiresIn: '7d' })
  return { accessToken, refreshToken }
}

router.post('/register', async (req: Request, res: Response) => {
  const parsed = RegisterSchema.safeParse(req.body)
  if (!parsed.success) return res.status(400).json({ ok: false, error: { code: 'BAD_REQUEST', message: 'Invalid payload' } })
  const { email, password, name } = parsed.data
  if (users.has(email)) return res.status(400).json({ ok: false, error: { code: 'ALREADY_EXISTS', message: 'Email exists' } })
  const passwordHash = await bcrypt.hash(password, 10)
  const id = `${users.size + 1}`
  users.set(email, { id, email, name, passwordHash })
  res.status(201).json({ ok: true, data: { id, email, name } })
})

router.post('/login', async (req: Request, res: Response) => {
  const parsed = LoginSchema.safeParse(req.body)
  if (!parsed.success) return res.status(400).json({ ok: false, error: { code: 'BAD_REQUEST', message: 'Invalid payload' } })
  const { email, password } = parsed.data
  const u = users.get(email)
  if (!u) return res.status(401).json({ ok: false, error: { code: 'UNAUTHORIZED', message: 'Invalid credentials' } })
  const ok = await bcrypt.compare(password, u.passwordHash)
  if (!ok) return res.status(401).json({ ok: false, error: { code: 'UNAUTHORIZED', message: 'Invalid credentials' } })
  const t = signTokens(u.id)
  res.json({ accessToken: t.accessToken, refreshToken: t.refreshToken })
})

router.post('/refresh', (req: Request, res: Response) => {
  const { refreshToken } = req.body || {}
  try {
    const payload = jwt.verify(refreshToken, process.env.JWT_SECRET || 'dev-secret') as any
    if (payload?.type !== 'refresh') throw new Error('invalid')
    const { accessToken } = signTokens(payload.sub)
    res.json({ accessToken, refreshToken })
  } catch {
    res.status(401).json({ ok: false, error: { code: 'UNAUTHORIZED', message: 'Invalid refresh token' } })
  }
})

router.get('/me', authGuard, (req: Request, res: Response) => {
  const userId = (req as any).userId as string
  const u = [...users.values()].find(v => v.id === userId)
  if (!u) return res.status(401).json({ ok: false, error: { code: 'UNAUTHORIZED', message: 'Not found' } })
  res.json({ id: u.id, email: u.email, name: u.name })
})

export const authRouter = router
