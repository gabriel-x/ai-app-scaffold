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
          bgLight: '#F0F9FF',
          surfaceLight: '#FFFFFF',
          borderLight: '#BAE6FD',
          textLight: '#0C4A6E',
          accentLight: '#0EA5E9',
          heroLight: '#F0F9FF',
          bubbleBgLight: '#E0F2FE',
          bubbleBorderLight: '#7DD3FC',
          bubbleTextLight: '#0369A1',

          bgDark: '#020617', // Very dark blue/black
          surfaceDark: '#0F172A', // Slate 900
          borderDark: '#22D3EE', // Cyan 400 (Neon border)
          textDark: '#F0F9FF', // Sky 50
          accentDark: '#00F0FF', // Neon Cyan
          heroDark: '#020617',
          bubbleBgDark: '#164E63', // Cyan 900
          bubbleBorderDark: '#22D3EE',
          bubbleTextDark: '#CFFAFE'
        },
        purple: {
          bgLight: '#FFFBEB',
          surfaceLight: '#FFFFFF',
          borderLight: '#FDE68A',
          textLight: '#451A03',
          accentLight: '#D97706',
          heroLight: '#FFFBEB',
          bubbleBgLight: '#FEF3C7',
          bubbleBorderLight: '#FCD34D',
          bubbleTextLight: '#92400E',

          bgDark: '#1A120B', // Dark brown/black
          surfaceDark: '#2C1F16', // Dark brown surface
          borderDark: '#8B5A2B', // Bronze
          textDark: '#E6DCC8', // Warm white
          accentDark: '#D4AF37', // Gold
          heroDark: '#1A120B',
          bubbleBgDark: '#3E2C20',
          bubbleBorderDark: '#CD7F32',
          bubbleTextDark: '#FFE4C4'
        },
        holographic: {
          bgLight: '#F0F2F5', // Light silver/grey
          surfaceLight: '#FFFFFF',
          borderLight: '#D1D5DB',
          textLight: '#111827',
          accentLight: '#10B981', // Emerald
          heroLight: '#E5E7EB',
          bubbleBgLight: '#D1FAE5',
          bubbleBorderLight: '#34D399',
          bubbleTextLight: '#065F46',

          bgDark: '#050510', // Deepest Black/Blue
          surfaceDark: 'rgba(20, 20, 35, 0.6)', // Glassy
          borderDark: '#2E325A', // Dark purple/blue border
          textDark: '#E2E8F0', // Slate 200
          accentDark: '#00FF9D', // Neon Green
          heroDark: '#050510',
          bubbleBgDark: 'rgba(0, 255, 157, 0.1)',
          bubbleBorderDark: '#00FF9D',
          bubbleTextDark: '#00FF9D'
        }
      }
    }
  },
  plugins: []
} satisfies Config
