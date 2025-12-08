// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import React from 'react'
import { Outlet } from 'react-router-dom'

export function AuthLayout() {
  return (
    <div className="min-h-screen flex items-center justify-center theme-bg theme-text transition-colors duration-300">
      <div className="w-full max-w-md p-8 rounded-2xl shadow-2xl card theme-surface theme-border backdrop-blur-md relative overflow-hidden">
        {/* Glow Effect for Holographic Theme */}
        <div className="absolute top-0 right-0 w-32 h-32 bg-[var(--accent)] opacity-10 blur-[60px] rounded-full pointer-events-none" />
        <div className="absolute bottom-0 left-0 w-32 h-32 bg-purple-500 opacity-10 blur-[60px] rounded-full pointer-events-none" />
        <Outlet />
      </div>
    </div>
  )
}

