// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  server: {
    port: 10100,
    host: true,
    strictPort: true,
    proxy: {
      '/api': {
        target: process.env.VITE_API_BASE_URL || 'http://localhost:10000',
        changeOrigin: true,
        secure: false,
        rewrite: (path) => path.replace(/^\/api/, '/api/v1'),
        configure: (proxy) => {
          proxy.on('error', (err, req, res) => {
            console.error('[proxy:error]', err?.message)
          })
          proxy.on('proxyReq', (proxyReq, req, res) => {
            console.info('[proxy:req]', req.method, req.url)
          })
          proxy.on('proxyRes', (proxyRes, req, res) => {
            console.info('[proxy:res]', req.method, req.url, proxyRes.statusCode)
          })
        }
      }
    }
  }
})
