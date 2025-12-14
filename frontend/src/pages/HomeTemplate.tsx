// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { Link, useNavigate } from 'react-router-dom'
import { useTheme } from '@/theme/useTheme'
import React, { useState, useEffect, FormEvent } from 'react'
import { useAuth } from '@/hooks/useAuth'
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import { Search, Bell, Menu, CheckCircle2, Circle, MoreHorizontal, User, LogIn, LogOut, Settings } from 'lucide-react'

// Mock Data for Chart
const data = [
  { name: 'Mon', value: 20 },
  { name: 'Tue', value: 60 },
  { name: 'Wed', value: 40 },
  { name: 'Thu', value: 80 },
  { name: 'Fri', value: 50 },
  { name: 'Sat', value: 90 },
  { name: 'Sun', value: 70 },
]

interface Todo {
  id: number;
  text: string;
  checked: boolean;
}

export default function HomeTemplate() {
  const { palette } = useTheme()
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const isHolo = palette === 'holographic'
  
  // Tab State
  const [activeTab, setActiveTab] = useState<'workspace' | 'formasform' | 'settings'>('workspace')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [submitStatus, setSubmitStatus] = useState<'idle' | 'success'>('idle')
  
  // Todo State
  const [todos, setTodos] = useState<Todo[]>([
    { id: 1, text: 'Add analytical enroll list', checked: true },
    { id: 2, text: 'Add tenable attachment to oracle', checked: true },
    { id: 3, text: 'Add confirmation', checked: true },
    { id: 4, text: 'Add nano-texture overlay', checked: false },
  ])

  const toggleTodo = (id: number) => {
    setTodos(prev => prev.map(t => t.id === id ? { ...t, checked: !t.checked } : t))
  }

  // Sample Table State
  const [selectedSamples, setSelectedSamples] = useState<number[]>([])

  const toggleSample = (id: number) => {
    setSelectedSamples(prev => 
      prev.includes(id) ? prev.filter(i => i !== id) : [...prev, id]
    )
  }

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    setIsSubmitting(true)
    setTimeout(() => {
      setIsSubmitting(false)
      setSubmitStatus('success')
      setTimeout(() => setSubmitStatus('idle'), 2000)
    }, 1500)
  }

  return (
    <div className="min-h-screen theme-text font-sans transition-colors duration-300">
      {/* Header */}
      <header className="sticky top-0 z-50 backdrop-blur-md border-b theme-border theme-surface px-6 py-4 flex items-center justify-between gap-4 transition-all duration-300">
        <div className="flex items-center gap-2 group cursor-pointer" onClick={() => navigate('/')}>
          <div className="w-8 h-8 rounded bg-gradient-to-tr from-green-400 to-blue-500 flex items-center justify-center text-white font-bold shadow-lg group-hover:shadow-green-500/50 transition-all duration-300">A</div>
          <span className="text-xl font-bold tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-theme-text to-theme-accent">AI Scaffold</span>
        </div>

        <div className="flex-1 max-w-md hidden md:block relative group">
          <div className="absolute left-3 top-1/2 -translate-y-1/2 opacity-50 group-focus-within:text-[var(--accent)] transition-colors"><Search size={18} /></div>
          <input 
            className="w-full pl-10 pr-4 py-2 rounded-full border theme-border bg-black/5 dark:bg-white/5 focus:outline-none focus:ring-2 focus:ring-[var(--accent)] focus:ring-opacity-50 theme-focus-ring transition-all duration-300" 
            placeholder="Search..." 
          />
        </div>

        <div className="flex items-center gap-4">
          <ThemeSelect />
          <ThemeToggle />
          <button className="p-2 rounded-full hover:bg-black/5 dark:hover:bg-white/5 transition-colors relative">
             <Bell size={20} />
             <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full animate-pulse" />
          </button>
          
          <div className="flex items-center gap-2 pl-4 border-l theme-border">
             {user ? (
               <div className="flex items-center gap-3">
                 <Link to="/profile" className="flex items-center gap-2 hover:opacity-80 transition-opacity">
                   <div className="w-8 h-8 rounded-full bg-gray-300 overflow-hidden ring-2 ring-[var(--accent)] ring-offset-2 ring-offset-[var(--surface)] transition-all">
                      {user.avatar ? (
                        <img src={user.avatar} alt="User" className="w-full h-full object-cover" />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-purple-500 to-pink-500 text-white text-xs">
                          {user.nickname?.charAt(0).toUpperCase() || 'U'}
                        </div>
                      )}
                   </div>
                   <span className="text-sm font-medium hidden sm:block">{user.nickname || user.username}</span>
                 </Link>
                 <button onClick={logout} className="p-1.5 rounded hover:bg-red-500/10 text-red-500 transition-colors" title="Logout">
                   <LogOut size={18} />
                 </button>
               </div>
             ) : (
               <div className="flex items-center gap-2">
                 <Link to="/login" className="px-4 py-1.5 rounded-full bg-[var(--accent)] text-white text-sm font-medium hover:brightness-110 transition-all shadow-lg hover:shadow-[var(--accent)]/30">
                    Login
                 </Link>
               </div>
             )}
          </div>
        </div>
      </header>

      <main className="p-4 md:p-6 max-w-[1600px] mx-auto space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700 relative z-10">
        {/* Dashboard Row */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Chart Section */}
          <div className="lg:col-span-2 card p-6 min-h-[320px] flex flex-col relative overflow-hidden group hover:border-[var(--accent)]/30 transition-all duration-500">
            <div className="flex justify-between items-center mb-6 z-10">
              <div>
                <h2 className="text-lg font-semibold bg-clip-text text-transparent bg-gradient-to-r from-[var(--text)] to-[var(--text)]/70">Dashboard</h2>
                <p className="text-xs opacity-70">Overview of system performance</p>
              </div>
              <div className="flex gap-2">
                <span className="text-xs px-2 py-1 rounded theme-surface border theme-border opacity-80 hover:opacity-100 cursor-pointer transition-opacity">Interactive</span>
                <span className="text-xs px-2 py-1 rounded theme-surface border theme-border opacity-80 hover:opacity-100 cursor-pointer transition-opacity">Animate</span>
              </div>
            </div>
            <div className="flex-1 w-full min-h-[200px]">
               <ResponsiveContainer width="100%" height="100%">
                 <AreaChart data={data}>
                   <defs>
                     <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
                       <stop offset="5%" stopColor="var(--accent)" stopOpacity={0.3}/>
                       <stop offset="95%" stopColor="var(--accent)" stopOpacity={0}/>
                     </linearGradient>
                   </defs>
                   <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" vertical={false} opacity={0.3} />
                   <XAxis dataKey="name" stroke="var(--text)" fontSize={12} tickLine={false} axisLine={false} opacity={0.6} />
                   <YAxis stroke="var(--text)" fontSize={12} tickLine={false} axisLine={false} opacity={0.6} />
                   <Tooltip 
                      contentStyle={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border)', borderRadius: '8px', backdropFilter: 'blur(8px)' }}
                      itemStyle={{ color: 'var(--text)' }}
                      cursor={{ stroke: 'var(--accent)', strokeWidth: 1, strokeDasharray: '4 4' }}
                   />
                   <Area 
                      type="monotone" 
                      dataKey="value" 
                      stroke="var(--accent)" 
                      strokeWidth={3} 
                      fillOpacity={1} 
                      fill="url(#colorValue)" 
                      animationDuration={2000}
                   />
                 </AreaChart>
               </ResponsiveContainer>
            </div>
            {/* Background decoration for holographic theme */}
            {isHolo && <div className="absolute top-0 right-0 w-64 h-64 bg-accent/10 blur-[100px] rounded-full pointer-events-none -z-0 animate-pulse" />}
          </div>

          {/* Stats Section */}
          <div className="card p-6 flex flex-col justify-center gap-8 relative overflow-hidden hover:border-[var(--accent)]/30 transition-all duration-500">
             <StatItem label="Today Visits" value="1,225" color="text-green-400" />
             <StatItem label="Registered Users" value="3,726" color="text-blue-400" />
             <StatItem label="Conversion Rate" value="5.00%" color="text-pink-500" />
             {isHolo && <div className="absolute bottom-0 left-0 w-full h-1/2 bg-gradient-to-t from-black/20 to-transparent pointer-events-none" />}
          </div>
        </div>

        {/* Content Row */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* To-Do List */}
          <div className="card p-6 flex flex-col hover:border-[var(--accent)]/30 transition-all duration-500">
            <div className="flex justify-between items-center mb-4">
              <h3 className="font-semibold text-lg">To-Do</h3>
              <div className="flex gap-1">
                 <button className="p-1 hover:bg-white/10 rounded transition-colors"><span className="text-xs">&lt;</span></button>
                 <button className="p-1 hover:bg-white/10 rounded transition-colors"><span className="text-xs">&gt;</span></button>
              </div>
            </div>
            <div className="space-y-3 flex-1 overflow-y-auto pr-2">
              {todos.map(todo => (
                <TodoItem key={todo.id} text={todo.text} checked={todo.checked} onToggle={() => toggleTodo(todo.id)} />
              ))}
            </div>
          </div>

          {/* Announcements */}
          <div className="card p-6 flex flex-col hover:border-[var(--accent)]/30 transition-all duration-500">
            <h3 className="font-semibold text-lg mb-4">Announcement</h3>
            <div className="space-y-4 flex-1">
              <AnnouncementItem 
                 title="Announcement with sacarpresia" 
                 desc="contasted by pumprates" 
                 time="8 days ago" 
                 color="from-green-500/20 to-blue-500/20"
              />
              <AnnouncementItem 
                 title="New vaccinients net Hymenotide" 
                 desc="pant by Announcement" 
                 time="7 days ago"
                 color="from-pink-500/20 to-purple-500/20"
              />
            </div>
          </div>

          {/* Workspace Tabs (Table & Form) */}
          <div className="card p-6 flex flex-col relative overflow-hidden hover:border-[var(--accent)]/30 transition-all duration-500">
             <div className="flex gap-6 border-b theme-border mb-4 pb-0 relative">
               <button 
                  onClick={() => setActiveTab('workspace')}
                  className={`pb-3 text-sm font-medium transition-all duration-300 relative ${activeTab === 'workspace' ? 'text-[var(--accent)]' : 'opacity-60 hover:opacity-100'}`}
               >
                 Workspace
                 {activeTab === 'workspace' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-[var(--accent)] shadow-[0_0_10px_var(--accent)]" />}
               </button>
               <button 
                  onClick={() => setActiveTab('formasform')}
                  className={`pb-3 text-sm font-medium transition-all duration-300 relative ${activeTab === 'formasform' ? 'text-[var(--accent)]' : 'opacity-60 hover:opacity-100'}`}
               >
                 Formasform
                 {activeTab === 'formasform' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-[var(--accent)] shadow-[0_0_10px_var(--accent)]" />}
               </button>
               <button 
                  onClick={() => setActiveTab('settings')}
                  className={`pb-3 text-sm font-medium transition-all duration-300 relative ${activeTab === 'settings' ? 'text-[var(--accent)]' : 'opacity-60 hover:opacity-100'}`}
               >
                 Settings
                 {activeTab === 'settings' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-[var(--accent)] shadow-[0_0_10px_var(--accent)]" />}
               </button>
             </div>
             
             <div className="flex-1 relative overflow-hidden">
                {/* Workspace Content */}
                <div className={`absolute inset-0 transition-all duration-500 transform ${activeTab === 'workspace' ? 'translate-x-0 opacity-100' : '-translate-x-full opacity-0 pointer-events-none'}`}>
                   <div className="flex flex-col h-full">
                      <h4 className="text-sm font-semibold mb-3 opacity-80">Sample Table</h4>
                      <div className="space-y-2 text-sm overflow-y-auto flex-1 pr-2">
                         {[1,2,3,4,5,6].map(i => {
                           const isChecked = selectedSamples.includes(i)
                           return (
                           <div 
                              key={i} 
                              onClick={() => toggleSample(i)}
                              className={`flex items-center gap-2 p-2 rounded transition-colors cursor-pointer group ${isChecked ? 'bg-white/5' : 'hover:bg-white/5'}`}
                           >
                              <div className={`w-4 h-4 rounded border transition-colors flex items-center justify-center ${isChecked ? 'bg-[var(--accent)] border-[var(--accent)]' : 'theme-border group-hover:border-[var(--accent)]'}`}>
                                {isChecked && <CheckCircle2 size={12} className="text-white" />}
                              </div>
                              <div className={`flex-1 transition-colors ${isChecked ? 'text-[var(--accent)] opacity-100' : 'opacity-80 group-hover:text-[var(--accent)]'}`}>Sample{i}</div>
                              <div className="opacity-50">Londwin</div>
                              <div className="opacity-50 font-mono text-xs">BI80800{i}</div>
                           </div>
                           )
                         })}
                      </div>
                      <div className="mt-4 flex justify-center gap-2 text-xs opacity-50">
                         <span className="cursor-pointer hover:text-[var(--accent)]">&lt;</span>
                         <span>Paper - 2 of 15</span>
                         <span className="cursor-pointer hover:text-[var(--accent)]">&gt;</span>
                      </div>
                   </div>
                </div>

                {/* Form Content */}
                <div className={`absolute inset-0 transition-all duration-500 transform ${activeTab === 'formasform' ? 'translate-x-0 opacity-100' : activeTab === 'workspace' ? 'translate-x-full opacity-0 pointer-events-none' : '-translate-x-full opacity-0 pointer-events-none'}`}>
                   <form onSubmit={handleSubmit} className="flex flex-col gap-3 h-full">
                      <h4 className="text-sm font-semibold opacity-80">Sample Form</h4>
                      <input className="w-full p-2 rounded bg-transparent border theme-border focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] text-sm outline-none transition-all" placeholder="Name" required />
                      <input className="w-full p-2 rounded bg-transparent border theme-border focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] text-sm outline-none transition-all" placeholder="Email" type="email" required />
                      <textarea className="w-full p-2 rounded bg-transparent border theme-border focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] text-sm h-20 resize-none outline-none transition-all" placeholder="Message" required />
                      <button 
                        type="submit" 
                        disabled={isSubmitting}
                        className={`w-full py-2 rounded bg-gradient-to-r from-green-400 to-emerald-500 text-black font-semibold shadow-lg hover:shadow-green-500/20 active:scale-95 transition-all flex items-center justify-center gap-2 ${isSubmitting ? 'opacity-80 cursor-wait' : ''}`}
                      >
                        {isSubmitting ? (
                          <>
                            <span className="w-4 h-4 border-2 border-black/30 border-t-black rounded-full animate-spin" />
                            Sending...
                          </>
                        ) : submitStatus === 'success' ? (
                          <>
                            <CheckCircle2 size={18} /> Sent!
                          </>
                        ) : (
                          'Submit'
                        )}
                      </button>
                      <div className="flex justify-between text-xs opacity-70 mt-1">
                         <span>Progress</span>
                         <span>{submitStatus === 'success' ? '100%' : '50%'}</span>
                      </div>
                      <div className="w-full h-1 bg-gray-700/50 rounded-full overflow-hidden">
                         <div className={`h-full bg-green-400 transition-all duration-1000 ${submitStatus === 'success' ? 'w-full' : 'w-1/2'}`} />
                      </div>
                   </form>
                </div>

                {/* Settings Content */}
                 <div className={`absolute inset-0 transition-all duration-500 transform ${activeTab === 'settings' ? 'translate-x-0 opacity-100' : 'translate-x-full opacity-0 pointer-events-none'}`}>
                    <div className="flex flex-col h-full items-center justify-center opacity-60">
                        <Settings size={48} className="mb-4 animate-spin-slow" />
                        <p>Settings Panel</p>
                        <p className="text-xs">Configure your workspace preferences here.</p>
                    </div>
                 </div>
             </div>
          </div>
        </div>
      </main>
    </div>
  )
}

function StatItem({ label, value, color }: { label: string, value: string, color: string }) {
  return (
    <div className="flex flex-col items-center md:items-start group cursor-default">
      <div className="text-sm opacity-60 mb-1 group-hover:text-[var(--accent)] transition-colors">{label}</div>
      <div className={`text-4xl font-bold tracking-tight ${color} drop-shadow-lg group-hover:scale-110 transition-transform origin-left`}>{value}</div>
    </div>
  )
}

function TodoItem({ text, checked, onToggle }: { text: string, checked?: boolean, onToggle: () => void }) {
  return (
    <div 
      onClick={onToggle}
      className={`group flex items-center gap-3 p-3 rounded-lg border theme-border transition-all cursor-pointer ${checked ? 'bg-gradient-to-r from-green-500/10 to-transparent border-green-500/30' : 'bg-white/5 hover:bg-white/10 hover:translate-x-1'}`}
    >
       <div className={`transition-transform duration-300 ${checked ? 'scale-110' : 'group-hover:scale-110'}`}>
         {checked ? <CheckCircle2 size={18} className="text-green-400" /> : <Circle size={18} className="opacity-40 group-hover:text-[var(--accent)]" />}
       </div>
       <span className={`text-sm transition-all duration-300 ${checked ? 'opacity-50 line-through' : 'opacity-90'}`}>{text}</span>
       {checked && <div className="ml-auto text-green-400 text-xs animate-in zoom-in duration-300">✓</div>}
    </div>
  )
}

function AnnouncementItem({ title, desc, time, color }: { title: string, desc: string, time: string, color: string }) {
  return (
     <div className={`p-4 rounded-xl border theme-border bg-gradient-to-br ${color} hover:opacity-100 hover:scale-[1.02] hover:shadow-lg transition-all duration-300 cursor-pointer group`}>
        <div className="font-medium text-sm mb-1 group-hover:text-white transition-colors">{title}</div>
        <div className="text-xs opacity-70 mb-2">{desc}</div>
        <div className="text-xs opacity-50 flex items-center gap-1">
          <span className="w-1.5 h-1.5 rounded-full bg-white/50 group-hover:animate-ping" />
          {time}
        </div>
     </div>
  )
}

function ThemeToggle() {
  const { setLight, setDark, theme } = useTheme()
  const checked = theme === 'dark'
  return (
    <label className={`mode-switch ${checked ? 'is-checked' : ''} cursor-pointer`}>
      <input type="checkbox" className="mode-switch__input" checked={checked} onChange={e => (e.target.checked ? setDark() : setLight())} />
      <span className={`mode-switch__label ${!checked ? 'is-active' : ''}`}>Light</span>
      <span className="mode-switch__core">
        <div className="mode-switch__action" />
      </span>
      <span className={`mode-switch__label ${checked ? 'is-active' : ''}`}>Dark</span>
    </label>
  )
}

function ThemeSelect() {
  const { palette, setPalette } = useTheme()
  return (
    <select value={palette} onChange={e => setPalette(e.target.value)} className="select select--small bg-transparent focus:ring-2 focus:ring-[var(--accent)] rounded cursor-pointer">
      <option value="holographic">Theme 1 (Holographic)</option>
      <option value="blue">Theme 2 (Neon)</option>
      <option value="purple">Theme 3 (Luxury)</option>
    </select>
  )
}
