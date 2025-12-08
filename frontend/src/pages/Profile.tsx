// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { api } from '@/lib/api'
import { useState } from 'react'
import { useAuth } from '@/hooks/useAuth'
import { toast } from 'sonner'
import { useTheme } from '@/theme/useTheme'

export default function Profile() {
  const qc = useQueryClient()
  const { accessToken } = useAuth() as any
  const { palette } = useTheme()
  const isHolo = palette === 'holographic'
  
  const token = accessToken || localStorage.getItem('accessToken') || undefined
  const { data: me } = useQuery({ queryKey: ['me'], queryFn: () => api.get('/auth/me', token) })
  const { data: profile } = useQuery({ queryKey: ['profile'], queryFn: () => api.get('/accounts/profile', token) })
  const [name, setName] = useState('')
  const { updateProfile } = useAuth()

  async function onSave() {
    const ok = await updateProfile(name)
    if (ok) {
      toast.success('资料已更新')
      await Promise.all([
        qc.invalidateQueries({ queryKey: ['me'] }),
        qc.invalidateQueries({ queryKey: ['profile'] })
      ])
    } else {
      toast.error('更新失败')
    }
  }

  const accountView = {
    id: me?.id,
    email: me?.email,
    name: (profile?.name ?? me?.name) || ''
  }

  return (
    <div className="space-y-6 max-w-4xl mx-auto p-4 md:p-6 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <div className="flex items-center justify-between mb-2">
        <h1 className="text-2xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-[var(--text)] to-[var(--accent)]">个人主页</h1>
        {isHolo && <div className="h-1 w-20 bg-gradient-to-r from-transparent via-[var(--accent)] to-transparent opacity-50 rounded-full" />}
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="card p-6 space-y-4 relative overflow-hidden group hover:border-[var(--accent)]/30 transition-all duration-500">
          <div className="flex items-center gap-3 mb-2">
             <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[var(--accent)] to-purple-600 flex items-center justify-center text-white font-bold shadow-lg">
                {accountView.name?.charAt(0).toUpperCase() || 'U'}
             </div>
             <div className="font-semibold text-lg">账号信息</div>
          </div>
          
          <div className="space-y-3 pl-1">
            <div className="flex flex-col">
               <span className="text-xs text-[var(--text)] opacity-60 uppercase tracking-wider">ID</span>
               <span className="font-mono text-sm opacity-90">{accountView.id || '-'}</span>
            </div>
            <div className="flex flex-col">
               <span className="text-xs text-[var(--text)] opacity-60 uppercase tracking-wider">邮箱</span>
               <span className="text-sm opacity-90">{accountView.email || '-'}</span>
            </div>
            <div className="flex flex-col">
               <span className="text-xs text-[var(--text)] opacity-60 uppercase tracking-wider">当前昵称</span>
               <span className="text-sm opacity-90">{accountView.name || '-'}</span>
            </div>
          </div>
          
          {isHolo && <div className="absolute -right-10 -bottom-10 w-32 h-32 bg-[var(--accent)]/10 blur-[40px] rounded-full pointer-events-none" />}
        </div>

        <div className="card p-6 space-y-4 relative overflow-hidden group hover:border-[var(--accent)]/30 transition-all duration-500">
          <div className="font-semibold text-lg mb-2">更新资料</div>
          
          <div className="space-y-4">
            <div>
              <label className="text-xs text-[var(--text)] opacity-60 mb-1.5 block">新昵称</label>
              <input 
                className="w-full px-4 py-2.5 rounded-lg bg-[var(--surface)] border border-[var(--border)] focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] outline-none transition-all placeholder:text-[var(--text)]/30" 
                placeholder="请输入新的昵称" 
                value={name} 
                onChange={e => setName(e.target.value)} 
              />
            </div>
            
            <button 
              className="btn-accent w-full py-2.5 rounded-lg font-medium shadow-lg hover:shadow-[var(--accent)]/25 hover:brightness-110 active:scale-[0.98] transition-all" 
              onClick={onSave}
            >
              保存更改
            </button>
          </div>
          
          {isHolo && <div className="absolute top-0 right-0 w-full h-1 bg-gradient-to-r from-transparent via-[var(--accent)]/50 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />}
        </div>
      </div>
    </div>
  )
}
