// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { ReactNode } from 'react'
import { useTheme } from './useTheme'

export function ThemeProvider({ children }: { children: ReactNode }) {
  useTheme()
  return <>{children}</>
}

