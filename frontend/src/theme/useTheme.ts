// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { useEffect, useState } from 'react'

export function useTheme() {
  const [theme, setTheme] = useState<string>(() => localStorage.getItem('theme_v2') || 'dark')
  const [palette, setPalette] = useState<string>(() => localStorage.getItem('palette_v2') || 'holographic')

  useEffect(() => {
    const root = document.documentElement
    if (theme === 'dark') root.classList.add('dark')
    else root.classList.remove('dark')
    localStorage.setItem('theme_v2', theme)
  }, [theme])

  useEffect(() => {
    const root = document.documentElement
    root.setAttribute('data-theme', palette)
    localStorage.setItem('palette_v2', palette)
  }, [palette])

  function toggle() { setTheme(t => (t === 'dark' ? 'light' : 'dark')) }
  function setLight() { setTheme('light') }
  function setDark() { setTheme('dark') }

  return { theme, setTheme, toggle, setLight, setDark, palette, setPalette }
}
