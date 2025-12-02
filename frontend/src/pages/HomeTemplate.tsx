// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { Link } from 'react-router-dom'
import { useTheme } from '@/theme/useTheme'

export default function HomeTemplate() {
  return (
    <div className="min-h-screen theme-bg theme-text">
      <header className="p-4 flex items-center justify-between">
        <div className="font-semibold">AI Application Scaffold</div>
        <div className="flex items-center gap-3">
          <ThemeToggle />
          <ThemeSelect />
          <Link to="/login" className="px-3 py-1 rounded border theme-text">登录</Link>
        </div>
      </header>
      <main className="max-w-6xl mx-auto p-6 space-y-8">
        <section className="hero p-8 rounded-2xl card">
          <div className="text-3xl font-bold mb-3">AI Application Scaffold</div>
          <div className="opacity-80 mb-4">AI应用脚手架工程</div>
          <div className="flex items-center gap-3">
            <input className="flex-1 p-3 rounded border theme-border theme-surface" placeholder="搜索需要的服务..." />
            <button className="px-4 py-2 rounded btn-accent">搜索</button>
          </div>
        </section>
        <section className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Card title="统计概览" subtitle="模拟数据" badge="3 个指标">
            <div className="grid grid-cols-3 text-center">
              <Metric label="今日访问" value="1,248" />
              <Metric label="注册用户" value="5,732" />
              <Metric label="转化率" value="12.4%" />
            </div>
          </Card>
          <Card title="待办事项" subtitle="静态展示" badge="0 个条目">
            <ul className="list-disc pl-5 space-y-1 text-sm">
              <li>完善资料展示模块</li>
              <li>接入实时接口</li>
              <li>增加可视化组件</li>
            </ul>
          </Card>
          <Card title="公告" subtitle="样板内容" badge="2 条信息">
            <div className="text-sm space-y-2">
              <p>系统将于周五凌晨维护更新。</p>
              <p>欢迎体验光暗模式与主题切换功能。</p>
            </div>
          </Card>
        </section>
        <section className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Card title="示例表格" subtitle="静态数据" badge="示例">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left border-b theme-border">
                  <th className="py-2">名称</th>
                  <th className="py-2">状态</th>
                  <th className="py-2">更新时间</th>
                </tr>
              </thead>
              <tbody>
                {[
                  { name: '任务A', status: '进行中', time: '2025-12-02' },
                  { name: '任务B', status: '已完成', time: '2025-11-28' },
                  { name: '任务C', status: '待处理', time: '2025-11-27' },
                ].map((r, i) => (
                  <tr key={i} className="border-b theme-border last:border-0">
                    <td className="py-2">{r.name}</td>
                    <td className="py-2">{r.status}</td>
                    <td className="py-2">{r.time}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Card>
          <Card title="示例表单" subtitle="静态交互" badge="演示">
            <form className="space-y-3">
              <input className="w-full p-2 border rounded theme-surface theme-border" placeholder="输入名称" />
              <select className="w-full p-2 border rounded theme-surface theme-border">
                <option>进行中</option>
                <option>已完成</option>
                <option>待处理</option>
              </select>
              <button type="button" className="px-3 py-2 rounded btn-accent">提交</button>
            </form>
          </Card>
        </section>
      </main>
    </div>
  )
}

function Card({ title, subtitle, badge, children }: { title: string; subtitle?: string; badge?: string; children: React.ReactNode }) {
  return (
    <div className="p-4 rounded-2xl card">
      <div className="mb-3">
        <div className="flex items-center gap-3">
          <div className="text-base font-semibold">{title}</div>
          {badge ? <span className="bubble">{badge}</span> : null}
        </div>
        {subtitle ? <div className="text-xs opacity-75">{subtitle}</div> : null}
      </div>
      {children}
    </div>
  )
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="p-3">
      <div className="text-2xl font-bold">{value}</div>
      <div className="text-xs text-neutral-500 dark:text-neutral-400">{label}</div>
    </div>
  )
}

function ThemeToggle() {
  const { setLight, setDark, theme } = useTheme()
  const checked = theme === 'dark'
  return (
    <label className={`mode-switch ${checked ? 'is-checked' : ''}`}>
      <input type="checkbox" className="mode-switch__input" checked={checked} onChange={e => (e.target.checked ? setDark() : setLight())} />
      <span className={`mode-switch__label ${!checked ? 'is-active' : ''}`}>浅色</span>
      <span className="mode-switch__core">
        <div className="mode-switch__action" />
      </span>
      <span className={`mode-switch__label ${checked ? 'is-active' : ''}`}>深色</span>
    </label>
  )
}

function ThemeSelect() {
  const { palette, setPalette } = useTheme()
  return (
    <select value={palette} onChange={e => setPalette(e.target.value)} className="select select--small">
      <option value="blue">主题A（蓝色系）</option>
      <option value="purple">主题B（紫色系）</option>
    </select>
  )
}
