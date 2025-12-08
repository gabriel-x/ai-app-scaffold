// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { Link, useLocation } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'

export default function Navigation() {
  const location = useLocation()
  const { logout } = useAuth()
  
  const isActive = (path: string) => location.pathname === path
    ? 'font-semibold text-[var(--accent)]'
    : 'opacity-70 hover:opacity-100 hover:text-[var(--accent)] transition-all'

  return (
    <nav className="flex items-center justify-between p-4 border-b theme-border backdrop-blur-sm bg-[var(--surface)]/50 sticky top-0 z-10">
      <div className="flex gap-6">
        <Link to="/profile" className={isActive('/profile')}>个人主页</Link>
        <Link to="/account" className={isActive('/account')}>账号设置</Link>
      </div>
      <button 
        className="px-4 py-1.5 rounded-lg btn-accent text-sm font-medium shadow-md hover:shadow-lg transition-all active:scale-95" 
        onClick={logout}
      >
        退出
      </button>
    </nav>
  )
}

