// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { Router, Request, Response } from 'express'
import { authGuard } from '../security/authGuard.js'

const router = Router()
const users = new Map<string, { id: string; email: string; name?: string }>()

router.get('/profile', authGuard, (_req: Request, res: Response) => {
  // demo：返回固定示例，真实实现应从数据层读取
  res.json({ id: '1', email: 'demo@example.com', name: 'Demo' })
})

router.patch('/profile', authGuard, (req: Request, res: Response) => {
  const { name } = req.body || {}
  if (!name) return res.status(400).json({ ok: false, error: { code: 'BAD_REQUEST', message: 'name required' } })
  res.json({ id: '1', email: 'demo@example.com', name })
})

export const accountsRouter = router
