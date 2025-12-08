// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { FormEvent, useState } from 'react'
import { useLocation, useNavigate, Link } from 'react-router-dom'
import { toast } from 'sonner'
import { useAuth } from '@/hooks/useAuth'

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const navigate = useNavigate()
  const location = useLocation() as any
  const { login } = useAuth()
  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    if (!email || !password || password.length < 8) {
      toast.error('请输入有效邮箱，密码至少8位')
      return
    }
    const ok = await login(email, password)
    if (ok) {
      toast.success('登录成功')
      const to = location.state?.from?.pathname || '/profile'
      navigate(to, { replace: true })
    } else {
      toast.error('登录失败')
    }
  }
  return (
    <div className="space-y-6 relative z-10">
      <div className="text-center space-y-2">
        <h1 className="text-3xl font-bold tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-theme-text to-theme-accent">Login</h1>
        <p className="text-sm opacity-60">Enter your credentials to access your account</p>
      </div>
      <form className="space-y-4" onSubmit={onSubmit}>
        <div className="space-y-2">
           <input className="w-full px-4 py-3 rounded-xl bg-black/5 dark:bg-white/5 border theme-border focus:border-[var(--accent)] focus:ring-2 focus:ring-[var(--accent)]/50 focus:outline-none transition-all placeholder:opacity-50 theme-text" placeholder="Email" value={email} onChange={e => setEmail(e.target.value)} />
           <input className="w-full px-4 py-3 rounded-xl bg-black/5 dark:bg-white/5 border theme-border focus:border-[var(--accent)] focus:ring-2 focus:ring-[var(--accent)]/50 focus:outline-none transition-all placeholder:opacity-50 theme-text" placeholder="Password" type="password" value={password} onChange={e => setPassword(e.target.value)} />
        </div>
        <button className="w-full py-3 rounded-xl bg-gradient-to-r from-[var(--accent)] to-emerald-500 text-white font-semibold shadow-lg shadow-[var(--accent)]/20 hover:shadow-[var(--accent)]/40 hover:scale-[1.02] active:scale-[0.98] transition-all duration-300">
          Sign In
        </button>
      </form>
      <div className="text-center text-sm opacity-80">
        Don't have an account? <Link className="font-medium text-[var(--accent)] hover:underline hover:text-[var(--accent)]/80 transition-colors" to="/register">Sign up</Link>
      </div>
    </div>
  )
}
