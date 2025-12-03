// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { api } from '@/lib/api'
import { useState } from 'react'
import { useAuth } from '@/hooks/useAuth'
import { toast } from 'sonner'
export default function Profile() {
  const qc = useQueryClient()
  const { accessToken } = useAuth() as any
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
    <div className="space-y-4">
      <h1 className="text-xl font-semibold">个人主页</h1>
      <div className="p-4 rounded-xl border space-y-2">
        <div className="font-medium">账号信息</div>
        <div className="text-sm text-neutral-600 dark:text-neutral-300">ID：{accountView.id || '-'}</div>
        <div className="text-sm text-neutral-600 dark:text-neutral-300">邮箱：{accountView.email || '-'}</div>
        <div className="text-sm text-neutral-600 dark:text-neutral-300">昵称：{accountView.name || '-'}</div>
      </div>
      <div className="p-4 rounded-xl border space-y-2">
        <div className="font-medium">更新资料</div>
        <input className="w-full p-2 border rounded" placeholder="新的昵称" value={name} onChange={e => setName(e.target.value)} />
        <button className="px-3 py-2 rounded bg-black text-white dark:bg-white dark:text-black" onClick={onSave}>保存</button>
      </div>
    </div>
  )
}
