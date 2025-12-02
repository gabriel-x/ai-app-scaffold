// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { app } from './app.js'
import dotenv from 'dotenv'
dotenv.config()

const PORT = process.env.PORT ? Number(process.env.PORT) : 10000
app.listen(PORT, () => {
  console.log(`Node backend listening on http://localhost:${PORT}`)
})
