// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { Request, Response, NextFunction } from 'express'
import jwt from 'jsonwebtoken'

export function authGuard(req: Request, res: Response, next: NextFunction) {
  const header = req.headers['authorization']
  if (!header?.startsWith('Bearer ')) return res.status(401).json({ ok: false, error: { code: 'UNAUTHORIZED', message: 'Missing token' } })
  const token = header.slice('Bearer '.length)
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET || 'dev-secret') as any
    ;(req as any).userId = payload.sub
    next()
  } catch {
    return res.status(401).json({ ok: false, error: { code: 'UNAUTHORIZED', message: 'Invalid token' } })
  }
}
