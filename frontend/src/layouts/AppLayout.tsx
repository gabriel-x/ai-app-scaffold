// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { Outlet } from 'react-router-dom'
import Navigation from '@/components/Navigation'
import { Link } from 'react-router-dom'

export function AppLayout() {
  return (
    <div className="min-h-screen bg-white text-black dark:bg-black dark:text-white">
      <Navigation />
      <div className="p-2 text-sm text-neutral-600 dark:text-neutral-400 border-b">
        <Link to="/" className="underline">返回样板主页</Link>
      </div>
      <div className="p-6 max-w-4xl mx-auto">
        <Outlet />
      </div>
    </div>
  )
}
