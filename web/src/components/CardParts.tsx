import { QRCodeSVG } from 'qrcode.react'
import type { CardTheme } from '../data/themes'

// ─── Photo placeholder ────────────────────────────────────────────────────────

export function PhotoPlaceholder({ theme, size = 76 }: { theme: CardTheme; size?: number }) {
  return (
    <svg width={size} height={size * 1.2} viewBox="0 0 90 108" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect width="90" height="108" rx="4" fill={theme.holoBg} stroke={theme.borderColor} strokeWidth="1" />
      <circle cx="45" cy="38" r="20" fill={theme.accent} opacity="0.25" />
      <path d="M10 95C10 68 80 68 80 95" fill={theme.accent} opacity="0.2" />
      <text x="45" y="104" textAnchor="middle" fontSize="8" fill={theme.textSecondary} fontFamily="Share Tech Mono">PHOTO</text>
    </svg>
  )
}

// ─── Holographic strip ────────────────────────────────────────────────────────

export function HoloStrip({ theme }: { theme: CardTheme }) {
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, top: 0, bottom: 0,
      pointerEvents: 'none', overflow: 'hidden', borderRadius: 'inherit',
    }}>
      {[...Array(7)].map((_, i) => (
        <div key={i} style={{
          position: 'absolute',
          top: -100, left: `${i * 15 - 10}%`,
          width: '5%', height: '200%',
          background: `linear-gradient(transparent, ${theme.accent}14, transparent)`,
          transform: 'rotate(-25deg)',
          animation: `shimmer ${2.5 + i * 0.3}s ease-in-out infinite alternate`,
          animationDelay: `${i * 0.2}s`,
        }} />
      ))}
      <div style={{
        position: 'absolute', bottom: 8, right: 8,
        width: 28, height: 28, borderRadius: '50%',
        background: `conic-gradient(from 0deg, ${theme.accent}40, ${theme.accentAlt}60, #ffffff20, ${theme.accent}40)`,
        animation: 'holoPulse 3s linear infinite',
      }} />
    </div>
  )
}

// ─── Security micro-print ─────────────────────────────────────────────────────

export function SecurityOverlay({ theme }: { theme: CardTheme }) {
  const text = `SECURE·${theme.agency}·OFFICIAL·DOCUMENT·`
  return (
    <div style={{
      position: 'absolute', inset: 0, pointerEvents: 'none',
      overflow: 'hidden', borderRadius: 'inherit', opacity: 0.06,
    }}>
      {[...Array(6)].map((_, i) => (
        <div key={i} style={{
          position: 'absolute', top: `${i * 18}%`, left: '-20%',
          whiteSpace: 'nowrap', fontSize: 7, letterSpacing: 3,
          fontFamily: 'Share Tech Mono', color: theme.textPrimary,
          transform: 'rotate(-12deg)', width: '140%',
        }}>
          {text.repeat(6)}
        </div>
      ))}
    </div>
  )
}

// ─── QR Code ─────────────────────────────────────────────────────────────────

export function SecureQR({ value, theme, size = 46 }: { value: string; theme: CardTheme; size?: number }) {
  return (
    <div style={{
      padding: 3, background: '#fff', borderRadius: 3,
      boxShadow: `0 0 0 1px ${theme.borderColor}`,
    }}>
      <QRCodeSVG value={value} size={size} level="M" fgColor={theme.gradFrom} bgColor="#ffffff" />
    </div>
  )
}

// ─── Signature line ───────────────────────────────────────────────────────────

export function SignatureLine({ name, theme }: { name: string; theme: CardTheme }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
      <div style={{
        fontFamily: 'Oswald, sans-serif', fontSize: 13, fontWeight: 300,
        fontStyle: 'italic', color: theme.textPrimary, letterSpacing: 1,
        opacity: 0.85, transform: 'rotate(-1.5deg)',
        textShadow: `0 0 10px ${theme.accent}80`,
      }}>
        {name}
      </div>
      <div style={{ height: 1, background: `linear-gradient(90deg, ${theme.accent}80, transparent)`, marginTop: 1 }} />
      <div style={{ fontFamily: 'Share Tech Mono', fontSize: 7, color: theme.textSecondary, letterSpacing: 1, textTransform: 'uppercase', marginTop: 1 }}>
        Signature officielle
      </div>
    </div>
  )
}

// ─── Access level badge ───────────────────────────────────────────────────────

export function AccessBadge({ level, max = 5, theme }: { level: number; max?: number; theme: CardTheme }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
      <span style={{ fontFamily: 'Share Tech Mono', fontSize: 7, color: theme.textSecondary, letterSpacing: 1 }}>LEVEL</span>
      <div style={{ display: 'flex', gap: 2 }}>
        {[...Array(max)].map((_, i) => (
          <div key={i} style={{
            width: 7, height: 12, borderRadius: 2,
            background: i < level ? theme.accent : `${theme.accent}25`,
            boxShadow: i < level ? `0 0 5px ${theme.accent}80` : 'none',
          }} />
        ))}
      </div>
    </div>
  )
}

// ─── Status badge ─────────────────────────────────────────────────────────────

export function StatusBadge({ status }: { status: 'ACTIVE' | 'INACTIVE' | 'SUSPENDED' | 'VALID' | 'REVOKED' }) {
  const colors: Record<string, { bg: string; text: string; glow: string }> = {
    ACTIVE:    { bg: '#14532d', text: '#4ade80', glow: '#4ade8060' },
    VALID:     { bg: '#14532d', text: '#4ade80', glow: '#4ade8060' },
    INACTIVE:  { bg: '#1e293b', text: '#94a3b8', glow: 'transparent' },
    SUSPENDED: { bg: '#78350f', text: '#fbbf24', glow: '#fbbf2460' },
    REVOKED:   { bg: '#450a0a', text: '#f87171', glow: '#f8717160' },
  }
  const c = colors[status] ?? colors.INACTIVE
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      padding: '2px 8px', borderRadius: 20,
      background: c.bg, border: `1px solid ${c.text}40`,
      boxShadow: `0 0 6px ${c.glow}`,
    }}>
      <div style={{ width: 4, height: 4, borderRadius: '50%', background: c.text, boxShadow: `0 0 5px ${c.glow}`, animation: 'pulse 2s infinite' }} />
      <span style={{ fontFamily: 'Share Tech Mono', fontSize: 8, color: c.text, letterSpacing: 1 }}>{status}</span>
    </div>
  )
}

// ─── Field row ────────────────────────────────────────────────────────────────

export function Field({ label, value, mono = false, theme, large = false }:
  { label: string; value: string | number; mono?: boolean; theme: CardTheme; large?: boolean }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
      <span style={{ fontFamily: 'Share Tech Mono', fontSize: 7, letterSpacing: 1.5, color: theme.textSecondary, textTransform: 'uppercase' }}>
        {label}
      </span>
      <span style={{
        fontFamily: mono ? 'Share Tech Mono' : 'Rajdhani, sans-serif',
        fontSize: large ? 13 : 11, fontWeight: large ? 600 : 500,
        color: theme.textPrimary, lineHeight: 1.2, letterSpacing: mono ? 0.5 : 0,
      }}>
        {value}
      </span>
    </div>
  )
}

// ─── Chip ─────────────────────────────────────────────────────────────────────

export function Chip({ theme }: { theme: CardTheme }) {
  return (
    <div style={{
      width: 34, height: 26, borderRadius: 4,
      background: theme.chip, position: 'relative', flexShrink: 0,
      boxShadow: '0 2px 6px rgba(0,0,0,0.5)',
    }}>
      <div style={{ position: 'absolute', inset: 3, borderRadius: 2, border: '1px solid rgba(255,255,255,0.3)', background: 'linear-gradient(135deg, rgba(255,255,255,0.15), transparent)' }} />
      <div style={{ position: 'absolute', top: 9, left: 0, right: 0, height: 1, background: 'rgba(0,0,0,0.2)' }} />
      <div style={{ position: 'absolute', left: 9, top: 0, bottom: 0, width: 1, background: 'rgba(0,0,0,0.15)' }} />
      <div style={{ position: 'absolute', right: 9, top: 0, bottom: 0, width: 1, background: 'rgba(0,0,0,0.15)' }} />
    </div>
  )
}

// ─── Barcode ─────────────────────────────────────────────────────────────────

export function Barcode({ seed, theme }: { seed: string; theme: CardTheme }) {
  let h = 0
  for (let i = 0; i < seed.length; i++) { h = ((h * 31) + seed.charCodeAt(i)) >>> 0 }
  const bars: number[] = []
  for (let i = 0; i < 38; i++) {
    h = ((h * 1664525 + 1013904223) >>> 0)
    bars.push(h % 3 === 0 ? 3 : h % 5 === 0 ? 2 : 1)
  }
  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 1, height: 20 }}>
      {bars.map((w, i) => (
        <div key={i} style={{ width: w, height: 10 + (i % 4) * 2, background: theme.textSecondary, opacity: 0.7, borderRadius: 0.5 }} />
      ))}
    </div>
  )
}

// ─── Points gauge ─────────────────────────────────────────────────────────────

export function PointsGauge({ points, max, theme }: { points: number; max: number; theme: CardTheme }) {
  const pct = (points / max) * 100
  const color = pct > 66 ? '#4ade80' : pct > 33 ? '#fbbf24' : '#f87171'
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontFamily: 'Share Tech Mono', fontSize: 7, color: theme.textSecondary, letterSpacing: 1 }}>POINTS</span>
        <span style={{ fontFamily: 'Share Tech Mono', fontSize: 9, color, fontWeight: 600 }}>{points}/{max}</span>
      </div>
      <div style={{ height: 4, background: '#ffffff15', borderRadius: 2, overflow: 'hidden' }}>
        <div style={{ height: '100%', width: `${pct}%`, background: `linear-gradient(90deg, ${color}80, ${color})`, borderRadius: 2, boxShadow: `0 0 5px ${color}60` }} />
      </div>
    </div>
  )
}
