// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import type { Config } from 'tailwindcss'

export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        blue: {
          bgLight: '#F9FAFB',
          surfaceLight: '#FFFFFF',
          borderLight: '#E5E7EB',
          textLight: '#111827',
          accentLight: '#2563EB',
          heroLight: '#F5F8FF',
          bubbleBgLight: '#E6F0FF',
          bubbleBorderLight: '#93C5FD',
          bubbleTextLight: '#1E3A8A',

          bgDark: '#0B1220',
          surfaceDark: '#0F172A',
          borderDark: '#1F2937',
          textDark: '#E5E7EB',
          accentDark: '#3B82F6',
          heroDark: '#0F172A',
          bubbleBgDark: '#17203A',
          bubbleBorderDark: '#3B82F6',
          bubbleTextDark: '#C7D2FE'
        },
        purple: {
          bgLight: '#FAF7FF',
          surfaceLight: '#FFFFFF',
          borderLight: '#E5E7EB',
          textLight: '#1F1F29',
          accentLight: '#7C3AED',
          heroLight: '#F8F5FF',
          bubbleBgLight: '#EFE7FF',
          bubbleBorderLight: '#C4B5FD',
          bubbleTextLight: '#5B21B6',

          bgDark: '#100B1A',
          surfaceDark: '#151022',
          borderDark: '#2A2140',
          textDark: '#EDEAF7',
          accentDark: '#8B5CF6',
          heroDark: '#151022',
          bubbleBgDark: '#22173B',
          bubbleBorderDark: '#8B5CF6',
          bubbleTextDark: '#DDD6FE'
        }
      }
    }
  },
  plugins: []
} satisfies Config
