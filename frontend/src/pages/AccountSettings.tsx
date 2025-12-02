// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api } from '@/lib/api'
import { toast } from 'sonner'
export default function AccountSettings() {
  const qc = useQueryClient()
  const { data } = useQuery({ queryKey: ['profile'], queryFn: () => api.get('/accounts/profile') })
  const [name, setName] = useState('')
  const m = useMutation({
    mutationFn: async () => api.patch('/accounts/profile', { name }),
    onSuccess: () => { toast.success('更新成功'); qc.invalidateQueries({ queryKey: ['profile'] }) },
    onError: () => toast.error('更新失败')
  })
  return (
    <div className="space-y-4">
      <h1 className="text-xl font-semibold">账号设置</h1>
      <div className="p-4 rounded-xl border space-y-3">
        <div className="text-sm">当前昵称：{data?.name || ''}</div>
        <input className="w-full p-2 border rounded" placeholder="新昵称" value={name} onChange={e => setName(e.target.value)} />
        <button className="px-3 py-2 rounded bg-black text-white dark:bg-white dark:text-black" onClick={() => m.mutate()}>更新</button>
      </div>
    </div>
  )
}

