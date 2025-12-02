// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { FormEvent, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { useAuth } from '@/hooks/useAuth'

export default function Register() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [name, setName] = useState('')
  const navigate = useNavigate()
  const { register } = useAuth()
  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    const ok = await register(email, password, name)
    if (ok) {
      toast.success('注册成功')
      navigate('/login', { replace: true })
    } else {
      toast.error('注册失败')
    }
  }
  return (
    <div className="space-y-4">
      <h1 className="text-xl font-semibold">注册</h1>
      <form className="space-y-3" onSubmit={onSubmit}>
        <input className="w-full p-2 border rounded" placeholder="邮箱" value={email} onChange={e => setEmail(e.target.value)} />
        <input className="w-full p-2 border rounded" placeholder="密码" type="password" value={password} onChange={e => setPassword(e.target.value)} />
        <input className="w-full p-2 border rounded" placeholder="昵称" value={name} onChange={e => setName(e.target.value)} />
        <button className="w-full p-2 rounded bg-black text-white dark:bg-white dark:text-black">注册</button>
      </form>
      <div className="text-sm">已有账号？<Link className="underline" to="/login">登录</Link></div>
    </div>
  )
}

