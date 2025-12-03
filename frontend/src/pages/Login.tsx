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
    <div className="space-y-4">
      <h1 className="text-xl font-semibold">登录</h1>
      <form className="space-y-3" onSubmit={onSubmit}>
        <input className="w-full p-2 border rounded" placeholder="邮箱" value={email} onChange={e => setEmail(e.target.value)} />
        <input className="w-full p-2 border rounded" placeholder="密码" type="password" value={password} onChange={e => setPassword(e.target.value)} />
        <button className="w-full p-2 rounded bg-black text-white dark:bg-white dark:text-black">登录</button>
      </form>
      <div className="text-sm">没有账号？<Link className="underline" to="/register">注册</Link></div>
    </div>
  )
}
