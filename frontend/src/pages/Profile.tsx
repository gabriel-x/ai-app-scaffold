// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { useQuery } from '@tanstack/react-query'
import { api } from '@/lib/api'
export default function Profile() {
  const { data } = useQuery({ queryKey: ['me'], queryFn: () => api.get('/auth/me') })
  return (
    <div className="space-y-4">
      <h1 className="text-xl font-semibold">个人主页</h1>
      <div className="p-4 rounded-xl border">
        <pre>{JSON.stringify(data, null, 2)}</pre>
      </div>
    </div>
  )
}

