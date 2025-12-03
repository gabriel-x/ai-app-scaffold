// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { Router, Request, Response } from 'express'
import { authGuard } from '../security/authGuard.js'
import { UsersRepo } from '../data/users.js'

const router = Router()

router.get('/profile', authGuard, (req: Request, res: Response) => {
  const userId = (req as any).userId as string
  const u = UsersRepo.getById(userId)
  if (!u) return res.status(404).json({ ok: false, error: { code: 'NOT_FOUND', message: 'User not found' } })
  res.json({ id: u.id, email: u.email, name: u.name })
})

router.patch('/profile', authGuard, (req: Request, res: Response) => {
  const userId = (req as any).userId as string
  const { name } = req.body || {}
  if (!name || typeof name !== 'string' || name.trim().length === 0) {
    return res.status(400).json({ ok: false, error: { code: 'BAD_REQUEST', message: 'name required' } })
  }
  const u = UsersRepo.updateById(userId, { name: name.trim() })
  if (!u) return res.status(404).json({ ok: false, error: { code: 'NOT_FOUND', message: 'User not found' } })
  res.json({ id: u.id, email: u.email, name: u.name })
})

export const accountsRouter = router
