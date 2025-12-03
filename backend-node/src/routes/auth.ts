// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { Router, Request, Response } from 'express'
import bcrypt from 'bcrypt'
import jwt from 'jsonwebtoken'
import { z } from 'zod'
import { authGuard } from '../security/authGuard.js'
import { UsersRepo, User } from '../data/users.js'

const router = Router()

// 使用共享的 UsersRepo 统一管理用户

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
  if (UsersRepo.getByEmail(email)) return res.status(400).json({ ok: false, error: { code: 'ALREADY_EXISTS', message: 'Email exists' } })
  const passwordHash = await bcrypt.hash(password, 10)
  const id = `${UsersRepo.size() + 1}`
  UsersRepo.create(email, { id, email, name, passwordHash } as User)
  res.status(201).json({ ok: true, data: { id, email, name } })
})

router.post('/login', async (req: Request, res: Response) => {
  const parsed = LoginSchema.safeParse(req.body)
  if (!parsed.success) return res.status(400).json({ ok: false, error: { code: 'BAD_REQUEST', message: 'Invalid payload' } })
  const { email, password } = parsed.data
  const u = UsersRepo.getByEmail(email) as User | undefined
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
  const u = UsersRepo.getById(userId)
  if (!u) return res.status(401).json({ ok: false, error: { code: 'UNAUTHORIZED', message: 'Not found' } })
  res.json({ id: u.id, email: u.email, name: u.name })
})

export const authRouter = router
