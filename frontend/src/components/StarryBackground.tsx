// SPDX-License-Identifier: MIT
// Copyright (c) 2025 Gabriel Xia(加百列)
import { useEffect, useRef } from 'react'
import { useTheme } from '@/theme/useTheme'

interface Star {
  x: number
  y: number
  baseX?: number // For constellations (relative to screen width)
  baseY?: number // For constellations (relative to screen height)
  radius: number
  vx: number
  vy: number
  alpha: number
  dAlpha: number
  color: string // "r, g, b"
  isConstellation?: boolean
  glow?: boolean
}

interface Constellation {
  name: string
  stars: { x: number, y: number }[] // Relative offsets
  connections: [number, number][] // Indices
  position: { x: number, y: number } // Base position (0-1)
}

const CONSTELLATIONS: Constellation[] = [
    {
        name: 'Taurus',
        stars: [
            { x: 0, y: 0 },       // Aldebaran
            { x: -0.02, y: 0.01 },
            { x: -0.04, y: 0.0 },
            { x: -0.02, y: -0.01 },
            { x: 0.06, y: -0.08 }, // Horn 1
            { x: 0.06, y: 0.08 },  // Horn 2
        ],
        connections: [[0,1], [1,2], [2,3], [0,4], [0,5]],
        position: { x: 0.8, y: 0.25 }
    },
    {
        name: 'Capricorn',
        stars: [
            { x: 0, y: 0 },
            { x: 0.03, y: -0.02 },
            { x: 0.06, y: 0 },
            { x: 0.03, y: 0.02 },
            { x: -0.03, y: -0.01 },
        ],
        connections: [[0,1], [1,2], [2,3], [3,0], [0,4]],
        position: { x: 0.15, y: 0.7 }
    }
]

export default function StarryBackground() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const { theme, palette } = useTheme()

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return

    const ctx = canvas.getContext('2d')
    if (!ctx) return

    let animationFrameId: number
    let stars: Star[] = []
    let constellationStars: Star[][] = [] // Grouped by constellation
    
    // Config
    const numRandomStars = 250 // Increased density
    const isDark = theme === 'dark'
    const isHolo = palette === 'holographic'
    
    // Base colors
    const starColorBase = isDark ? '255, 255, 255' : '71, 85, 105'
    const constellationColor = isDark ? '255, 255, 255' : '30, 41, 59'
    const lineColor = isDark ? '255, 255, 255' : '100, 116, 139'

    const resizeCanvas = () => {
      canvas.width = window.innerWidth
      canvas.height = window.innerHeight
      initStars()
    }

    const initStars = () => {
      stars = []
      constellationStars = []

      // 1. Initialize Constellations
      CONSTELLATIONS.forEach(constellation => {
          const cStars: Star[] = []
          const cx = constellation.position.x * canvas.width
          const cy = constellation.position.y * canvas.height
          const scale = Math.min(canvas.width, canvas.height) // Scale based on viewport

          constellation.stars.forEach(pos => {
              const x = cx + pos.x * scale
              const y = cy + pos.y * scale
              
              const star: Star = {
                  x, y,
                  baseX: constellation.position.x + pos.x * (scale / canvas.width), // Store relative
                  baseY: constellation.position.y + pos.y * (scale / canvas.height),
                  radius: Math.random() * 1.5 + 2.0, // Larger for constellation
                  vx: 0, vy: 0, // Fixed position relative to screen (or very slow drift?)
                  alpha: Math.random() * 0.5 + 0.5,
                  dAlpha: (Math.random() - 0.5) * 0.01,
                  color: constellationColor,
                  isConstellation: true,
                  glow: true
              }
              cStars.push(star)
              stars.push(star)
          })
          constellationStars.push(cStars)
      })

      // 2. Initialize Random Background Stars
      for (let i = 0; i < numRandomStars; i++) {
        const radius = Math.random() * 2.5 + 0.5 // Larger range (0.5 to 3.0)
        
        let color = starColorBase
        // Holographic colors
        if (isDark && isHolo) {
            const rand = Math.random()
            if (rand > 0.9) color = '34, 211, 238' // Cyan
            else if (rand > 0.8) color = '232, 121, 249' // Purple
            else if (rand > 0.7) color = '52, 211, 153' // Green
        }

        stars.push({
          x: Math.random() * canvas.width,
          y: Math.random() * canvas.height,
          radius,
          vx: (Math.random() - 0.5) * 0.2, // Slow movement
          vy: (Math.random() - 0.5) * 0.2,
          alpha: Math.random(),
          dAlpha: (Math.random() - 0.5) * 0.02,
          color,
          glow: radius > 2.0 // Glow for larger stars
        })
      }
    }

    const draw = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height)
      
      // 1. Draw Nebula/Background Glow (Dark Mode only)
      if (isDark) {
          const w = canvas.width
          const h = canvas.height
          
          // Main Nebula
          const glow1 = ctx.createRadialGradient(w * 0.2, h * 0.3, 0, w * 0.2, h * 0.3, w * 0.6)
          if (isHolo) {
             glow1.addColorStop(0, 'rgba(34, 211, 238, 0.08)')
             glow1.addColorStop(1, 'transparent')
          } else {
             glow1.addColorStop(0, 'rgba(56, 189, 248, 0.05)')
             glow1.addColorStop(1, 'transparent')
          }
          ctx.fillStyle = glow1
          ctx.fillRect(0, 0, w, h)
          
          // Secondary Nebula
          const glow2 = ctx.createRadialGradient(w * 0.8, h * 0.7, 0, w * 0.8, h * 0.7, w * 0.5)
           if (isHolo) {
             glow2.addColorStop(0, 'rgba(168, 85, 247, 0.08)')
             glow2.addColorStop(1, 'transparent')
          } else {
             glow2.addColorStop(0, 'rgba(99, 102, 241, 0.05)')
             glow2.addColorStop(1, 'transparent')
          }
          ctx.fillStyle = glow2
          ctx.fillRect(0, 0, w, h)
      }

      // 2. Draw Constellation Lines
      ctx.strokeStyle = `rgba(${lineColor}, 0.15)`
      ctx.lineWidth = 1
      
      constellationStars.forEach((cStars, index) => {
          const connections = CONSTELLATIONS[index].connections
          ctx.beginPath()
          connections.forEach(([startIdx, endIdx]) => {
              if (cStars[startIdx] && cStars[endIdx]) {
                  ctx.moveTo(cStars[startIdx].x, cStars[startIdx].y)
                  ctx.lineTo(cStars[endIdx].x, cStars[endIdx].y)
              }
          })
          ctx.stroke()
      })

      // 3. Draw Stars
      stars.forEach(star => {
        // Update
        if (!star.isConstellation) {
            star.x += star.vx
            star.y += star.vy
            
            // Wrap around
            if (star.x < 0) star.x = canvas.width
            if (star.x > canvas.width) star.x = 0
            if (star.y < 0) star.y = canvas.height
            if (star.y > canvas.height) star.y = 0
        }

        // Twinkle
        star.alpha += star.dAlpha
        if (star.alpha <= 0.2 || star.alpha >= 1) {
          star.dAlpha = -star.dAlpha
        }

        // Draw Glow (for large stars or constellations)
        if (star.glow && isDark) {
            ctx.beginPath()
            ctx.arc(star.x, star.y, star.radius * 2.5, 0, Math.PI * 2)
            ctx.fillStyle = `rgba(${star.color}, ${star.alpha * 0.3})`
            ctx.fill()
        }

        // Draw Core
        ctx.beginPath()
        ctx.arc(star.x, star.y, star.radius, 0, Math.PI * 2)
        ctx.fillStyle = `rgba(${star.color}, ${star.alpha})`
        ctx.fill()
      })

      animationFrameId = requestAnimationFrame(draw)
    }

    window.addEventListener('resize', resizeCanvas)
    resizeCanvas()
    draw()

    return () => {
      window.removeEventListener('resize', resizeCanvas)
      cancelAnimationFrame(animationFrameId)
    }
  }, [theme, palette])

  return (
    <canvas
      ref={canvasRef}
      className="fixed inset-0 z-0 pointer-events-none"
      style={{ width: '100vw', height: '100vh' }}
    />
  )
}
