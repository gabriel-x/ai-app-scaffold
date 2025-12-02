// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { Link, useLocation } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'

export default function Navigation() {
  const location = useLocation()
  const { logout } = useAuth()
  return (
    <nav className="flex items-center justify-between p-4 border-b">
      <div className="flex gap-4">
        <Link to="/profile" className={location.pathname === '/profile' ? 'font-semibold' : ''}>个人主页</Link>
        <Link to="/account" className={location.pathname === '/account' ? 'font-semibold' : ''}>账号设置</Link>
      </div>
      <button className="px-3 py-1 rounded bg-black text-white dark:bg-white dark:text-black" onClick={logout}>退出</button>
    </nav>
  )
}

