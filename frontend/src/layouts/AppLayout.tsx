// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { Outlet } from 'react-router-dom'
import Navigation from '@/components/Navigation'
import { Link } from 'react-router-dom'

export function AppLayout() {
  return (
    <div className="min-h-screen theme-bg theme-text transition-colors duration-300">
      <Navigation />
      <div className="p-2 text-sm opacity-70 border-b theme-border">
        <Link to="/" className="underline hover:text-[var(--accent)] transition-colors">返回样板主页</Link>
      </div>
      <div className="p-6 max-w-4xl mx-auto">
        <Outlet />
      </div>
    </div>
  )
}
