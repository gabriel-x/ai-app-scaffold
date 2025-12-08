// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api } from '@/lib/api'
import { toast } from 'sonner'
import { useTheme } from '@/theme/useTheme'
import { useAuth } from '@/hooks/useAuth'

export default function AccountSettings() {
  const qc = useQueryClient()
  const { palette } = useTheme()
  const { accessToken } = useAuth()
  const isHolo = palette === 'holographic'
  
  const token = accessToken || localStorage.getItem('accessToken') || undefined
  
  const { data } = useQuery({ 
    queryKey: ['profile'], 
    queryFn: () => api.get('/accounts/profile', token) 
  })
  
  const [name, setName] = useState('')
  
  const m = useMutation({
    mutationFn: async () => api.patch('/accounts/profile', { name }, token),
    onSuccess: () => { toast.success('更新成功'); qc.invalidateQueries({ queryKey: ['profile'] }) },
    onError: () => toast.error('更新失败')
  })

  return (
    <div className="space-y-6 max-w-2xl mx-auto p-4 md:p-6 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <div className="flex items-center justify-between mb-2">
        <h1 className="text-2xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-[var(--text)] to-[var(--accent)]">账号设置</h1>
      </div>
      
      <div className="card p-8 space-y-6 relative overflow-hidden hover:border-[var(--accent)]/30 transition-all duration-500">
        <div className="flex items-center gap-4 border-b border-[var(--border)] pb-6">
          <div className="w-16 h-16 rounded-full bg-gradient-to-tr from-[var(--accent)] to-blue-500 flex items-center justify-center text-white text-2xl font-bold shadow-lg">
            {data?.name?.charAt(0).toUpperCase() || 'U'}
          </div>
          <div>
            <div className="text-sm opacity-60">当前昵称</div>
            <div className="text-xl font-medium">{data?.name || '未设置'}</div>
          </div>
        </div>

        <div className="space-y-4">
          <div>
            <label className="text-sm font-medium mb-2 block opacity-80">修改昵称</label>
            <input 
              className="w-full px-4 py-3 rounded-lg bg-[var(--surface)] border border-[var(--border)] focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] outline-none transition-all placeholder:text-[var(--text)]/30" 
              placeholder="请输入新的昵称" 
              value={name} 
              onChange={e => setName(e.target.value)} 
            />
          </div>
          
          <button 
            className="btn-accent w-full py-3 rounded-lg font-medium shadow-lg hover:shadow-[var(--accent)]/25 hover:brightness-110 active:scale-[0.98] transition-all flex items-center justify-center gap-2" 
            onClick={() => m.mutate()}
            disabled={m.isPending}
          >
            {m.isPending ? '更新中...' : '确认更新'}
          </button>
        </div>
        
        {isHolo && (
          <>
            <div className="absolute top-0 right-0 w-32 h-32 bg-[var(--accent)]/5 blur-[50px] rounded-full pointer-events-none" />
            <div className="absolute bottom-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-[var(--accent)]/30 to-transparent" />
          </>
        )}
      </div>
    </div>
  )
}

