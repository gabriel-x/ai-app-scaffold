// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import React, { FormEvent, ChangeEvent, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { useAuth } from '@/hooks/useAuth'

export default function Register() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [name, setName] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const navigate = useNavigate()
  const { register } = useAuth()

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    if (!email || !password || password.length < 8) {
      toast.error('请输入有效邮箱，密码至少8位')
      return
    }
    
    setIsSubmitting(true)
    // Simulate a slight delay for better UX feel (dynamic effect)
    await new Promise(resolve => setTimeout(resolve, 800))
    
    const ok = await register(email, password, name)
    setIsSubmitting(false)
    
    if (ok) {
      toast.success('注册成功')
      navigate('/login', { replace: true })
    } else {
      toast.error('注册失败')
    }
  }

  return (
    <div className="space-y-6 relative z-10">
      <div className="text-center space-y-2">
        <h1 className="text-3xl font-bold tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-theme-text to-theme-accent">Register</h1>
        <p className="text-sm opacity-60">Create your account to get started</p>
      </div>
      <form className="space-y-4" onSubmit={onSubmit}>
        <div className="space-y-2">
           <input 
             className="w-full px-4 py-3 rounded-xl bg-black/5 dark:bg-white/5 border theme-border focus:border-[var(--accent)] focus:ring-2 focus:ring-[var(--accent)]/50 focus:outline-none transition-all placeholder:opacity-50 theme-text" 
             placeholder="Email" 
             value={email} 
             onChange={(e: ChangeEvent<HTMLInputElement>) => setEmail(e.target.value)} 
             disabled={isSubmitting}
           />
           <input 
             className="w-full px-4 py-3 rounded-xl bg-black/5 dark:bg-white/5 border theme-border focus:border-[var(--accent)] focus:ring-2 focus:ring-[var(--accent)]/50 focus:outline-none transition-all placeholder:opacity-50 theme-text" 
             placeholder="Password (min 8 chars)" 
             type="password" 
             value={password} 
             onChange={(e: ChangeEvent<HTMLInputElement>) => setPassword(e.target.value)} 
             disabled={isSubmitting}
           />
           <input 
             className="w-full px-4 py-3 rounded-xl bg-black/5 dark:bg-white/5 border theme-border focus:border-[var(--accent)] focus:ring-2 focus:ring-[var(--accent)]/50 focus:outline-none transition-all placeholder:opacity-50 theme-text" 
             placeholder="Nickname" 
             value={name} 
             onChange={(e: ChangeEvent<HTMLInputElement>) => setName(e.target.value)} 
             disabled={isSubmitting}
           />
        </div>
        <button 
          disabled={isSubmitting}
          className="w-full py-3 rounded-xl bg-gradient-to-r from-[var(--accent)] to-emerald-500 text-white font-semibold shadow-lg shadow-[var(--accent)]/20 hover:shadow-[var(--accent)]/40 hover:scale-[1.02] active:scale-[0.98] transition-all duration-300 disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center gap-2"
        >
          {isSubmitting ? (
            <>
              <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              Creating Account...
            </>
          ) : (
            'Sign Up'
          )}
        </button>
      </form>
      <div className="text-center text-sm opacity-80">
        Already have an account? <Link className="font-medium text-[var(--accent)] hover:underline hover:text-[var(--accent)]/80 transition-colors" to="/login">Sign in</Link>
      </div>
    </div>
  )
}
