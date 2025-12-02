// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import express from 'express'
import helmet from 'helmet'
import cors from 'cors'
import morgan from 'morgan'
import { authRouter } from './routes/auth.js'
import { accountsRouter } from './routes/accounts.js'

const BASE = process.env.BASE_PATH || '/api/v1'

export const app = express()
app.use(express.json())
app.use(helmet())
app.use(cors({ origin: process.env.ALLOWED_ORIGINS?.split(',') || '*' }))
app.use(morgan('dev'))

app.get('/health', (_req: express.Request, res: express.Response) => res.json({ status: 'ok' }))

app.use(`${BASE}/auth`, authRouter)
app.use(`${BASE}/accounts`, accountsRouter)

app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  const code = err.status || 500
  res.status(code).json({ ok: false, error: { code: 'INTERNAL_ERROR', message: 'Server error' } })
})
