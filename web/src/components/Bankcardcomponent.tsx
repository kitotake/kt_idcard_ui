import type { BankCardData } from '../types'

// ─── Tailles FiveM : 440×265 au lieu de 520×310 ──────────────────────────────

const CARD_W = 440
const CARD_H = 265

function VisaLogo({ color }: { color: string }) {
  return (
    <svg width="46" height="16" viewBox="0 0 52 18" fill="none">
      <text x="0" y="16" fontFamily="Rajdhani, sans-serif" fontWeight="800" fontSize="20" fill={color} letterSpacing="1.5">VISA</text>
    </svg>
  )
}

function MastercardLogo() {
  return (
    <svg width="34" height="22" viewBox="0 0 40 26">
      <circle cx="14" cy="13" r="13" fill="#eb001b" opacity="0.9" />
      <circle cx="26" cy="13" r="13" fill="#f79e1b" opacity="0.9" />
      <ellipse cx="20" cy="13" rx="5" ry="13" fill="#ff5f00" opacity="0.6" />
    </svg>
  )
}

function AmexLogo({ color }: { color: string }) {
  return (
    <svg width="56" height="24" viewBox="0 0 66 28">
      <text x="0" y="13" fontFamily="Rajdhani, sans-serif" fontWeight="700" fontSize="12" fill={color} letterSpacing="1">AMERICAN</text>
      <text x="0" y="27" fontFamily="Rajdhani, sans-serif" fontWeight="700" fontSize="12" fill={color} letterSpacing="1.5">EXPRESS</text>
    </svg>
  )
}

function ChipSVG() {
  return (
    <svg width="38" height="30" viewBox="0 0 46 36" fill="none">
      <defs>
        <linearGradient id="cg" x1="0" y1="0" x2="46" y2="36" gradientUnits="userSpaceOnUse">
          <stop offset="0%" stopColor="#d4a843" />
          <stop offset="45%" stopColor="#f5d97a" />
          <stop offset="100%" stopColor="#a07428" />
        </linearGradient>
      </defs>
      <rect width="46" height="36" rx="6" fill="url(#cg)" />
      <line x1="0" y1="13" x2="46" y2="13" stroke="rgba(0,0,0,0.18)" strokeWidth="1" />
      <line x1="0" y1="23" x2="46" y2="23" stroke="rgba(0,0,0,0.18)" strokeWidth="1" />
      <line x1="16" y1="0" x2="16" y2="36" stroke="rgba(0,0,0,0.14)" strokeWidth="1" />
      <line x1="30" y1="0" x2="30" y2="36" stroke="rgba(0,0,0,0.14)" strokeWidth="1" />
      <rect x="14" y="11" width="18" height="14" rx="2" fill="rgba(255,255,255,0.2)" />
    </svg>
  )
}

function NFCIcon({ color }: { color: string }) {
  return (
    <svg width="18" height="18" viewBox="0 0 22 22" fill="none" opacity="0.45">
      <path d="M16 4.5a9 9 0 010 13" stroke={color} strokeWidth="1.8" strokeLinecap="round" />
      <path d="M13 7.5a5 5 0 010 7" stroke={color} strokeWidth="1.8" strokeLinecap="round" />
      <path d="M10 10a2 2 0 010 2.5" stroke={color} strokeWidth="1.8" strokeLinecap="round" />
    </svg>
  )
}

function fmtNumber(n: string): string {
  return n.replace(/\s/g, '').replace(/(.{4})/g, '$1 ').trim()
}

function fmtBalance(n?: number): string {
  if (n == null) return ''
  return new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(n)
}

interface CardBodyProps {
  data: BankCardData
  textColor: string
  subColor: string
  showAmex?: boolean
}

function CardBody({ data, textColor, subColor, showAmex }: CardBodyProps) {
  const mono: React.CSSProperties = { fontFamily: "'Share Tech Mono', monospace" }
  const raj: React.CSSProperties  = { fontFamily: "'Rajdhani', sans-serif" }

  return (
    <div style={{
      position: 'relative', zIndex: 2,
      width: '100%', height: '100%',
      padding: '18px 22px',
      display: 'flex', flexDirection: 'column',
      justifyContent: 'space-between',
    }}>
      {/* Row 1 — Bank name + solde */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div style={{ ...raj, fontSize: 17, fontWeight: 700, color: textColor, letterSpacing: 1 }}>
          {data.bankName}
        </div>
        {/* NEW : affichage du solde */}
        {data.balance != null && (
          <div style={{ textAlign: 'right' }}>
            <div style={{ ...mono, fontSize: 7, letterSpacing: 2, color: subColor }}>SOLDE</div>
            <div style={{ ...raj, fontSize: 13, fontWeight: 600, color: textColor }}>{fmtBalance(data.balance)}</div>
          </div>
        )}
      </div>

      {/* Row 2 — Chip + NFC */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <ChipSVG />
        <NFCIcon color={textColor} />
      </div>

      {/* Row 3 — Card number */}
      <div style={{ ...mono, fontSize: 17, letterSpacing: 3, color: textColor }}>
        {fmtNumber(data.cardNumber)}
      </div>

      {/* Row 4 — Holder / Expiry / CVV / Network */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
        <div>
          <div style={{ ...mono, fontSize: 7, letterSpacing: 2, color: subColor, marginBottom: 2 }}>CARD HOLDER</div>
          <div style={{ ...raj, fontSize: 12, fontWeight: 600, letterSpacing: 0.8, color: textColor }}>{data.holderName}</div>
        </div>
        <div style={{ display: 'flex', gap: 14, alignItems: 'flex-end' }}>
          <div>
            <div style={{ ...mono, fontSize: 7, letterSpacing: 2, color: subColor, marginBottom: 2 }}>EXPIRES</div>
            <div style={{ ...mono, fontSize: 11, letterSpacing: 2, color: textColor }}>{data.expiry}</div>
          </div>
          <div>
            <div style={{ ...mono, fontSize: 7, letterSpacing: 2, color: subColor, marginBottom: 2 }}>CVV</div>
            <div style={{ ...mono, fontSize: 11, letterSpacing: 2, color: textColor }}>{data.cvv}</div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center' }}>
            {data.cardNetwork === 'Visa'       && <VisaLogo color={textColor} />}
            {data.cardNetwork === 'Mastercard' && <MastercardLogo />}
            {data.cardNetwork === 'Amex'       && (showAmex ? <AmexLogo color={textColor} /> : <div style={{ fontFamily: 'Rajdhani', fontSize: 10, fontWeight: 700, color: textColor, letterSpacing: 1 }}>AMEX</div>)}
          </div>
        </div>
      </div>
    </div>
  )
}

function IBANBar({ iban, borderColor, textColor }: { iban: string; borderColor: string; textColor: string }) {
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      padding: '4px 22px',
      background: 'rgba(0,0,0,0.32)',
      borderTop: `1px solid ${borderColor}`,
      fontFamily: "'Share Tech Mono', monospace",
      fontSize: 7, letterSpacing: 1.5,
      color: textColor,
    }}>{iban}</div>
  )
}

function Shimmer({ gradient, delay = '0s' }: { gradient: string; delay?: string }) {
  return (
    <div style={{
      position: 'absolute', top: 0, bottom: 0, width: '55%',
      transform: 'skewX(-20deg)',
      background: gradient,
      animation: `shimmer 3s ease-in-out ${delay} infinite`,
      pointerEvents: 'none', zIndex: 1,
    }} />
  )
}

// ─── CLASSIC ─────────────────────────────────────────────────────────────────

function ClassicBankCard({ data }: { data: BankCardData }) {
  return (
    <div style={{
      position: 'relative', width: CARD_W, height: CARD_H,
      borderRadius: 15, overflow: 'hidden',
      background: 'linear-gradient(135deg,#111827 0%,#0f172a 45%,#1a2540 100%)',
      border: '1px solid rgba(100,140,220,0.22)',
      boxShadow: '0 22px 55px rgba(0,0,0,0.88), 0 0 0 1px rgba(100,140,255,0.08)',
      animation: 'cardIn 0.45s cubic-bezier(0.22,1,0.36,1) forwards',
    }}>
      <div style={{ position: 'absolute', top: -60, right: -40, width: 200, height: 200, borderRadius: '50%', background: 'radial-gradient(circle,rgba(59,130,246,0.1),transparent 68%)', pointerEvents: 'none' }} />
      {Array.from({ length: 9 }, (_, i) => (
        <div key={i} style={{ position: 'absolute', left: 0, right: 0, top: `${i * 12}%`, height: 1, background: 'rgba(255,255,255,0.02)', pointerEvents: 'none' }} />
      ))}
      <div style={{ position: 'absolute', left: 0, top: 20, bottom: 20, width: 3, background: 'linear-gradient(to bottom,transparent,#3b82f6,transparent)', borderRadius: '0 2px 2px 0' }} />
      <Shimmer gradient="linear-gradient(90deg,transparent,rgba(255,255,255,0.025),transparent)" />
      <CardBody data={data} textColor="rgba(215,228,255,0.9)" subColor="rgba(148,163,200,0.6)" />
      {data.iban && <IBANBar iban={data.iban} borderColor="rgba(255,255,255,0.04)" textColor="rgba(120,140,190,0.35)" />}
    </div>
  )
}

// ─── GOLD ─────────────────────────────────────────────────────────────────────

function GoldBankCard({ data }: { data: BankCardData }) {
  return (
    <div style={{
      position: 'relative', width: CARD_W, height: CARD_H,
      borderRadius: 15, overflow: 'hidden',
      background: 'linear-gradient(135deg,#1a1000 0%,#2d1c00 40%,#1a1000 65%,#3a2800 100%)',
      border: '1px solid rgba(212,175,55,0.45)',
      boxShadow: '0 22px 55px rgba(0,0,0,0.92), 0 0 0 1px rgba(212,175,55,0.18), 0 0 28px rgba(212,175,55,0.1)',
      animation: 'cardIn 0.45s cubic-bezier(0.22,1,0.36,1) forwards',
    }}>
      <div style={{ position: 'absolute', top: -70, right: -50, width: 250, height: 250, borderRadius: '50%', background: 'radial-gradient(circle,rgba(212,175,55,0.16),transparent 62%)', pointerEvents: 'none' }} />
      {[-3,-2,-1,0,1,2,3,4].map(i => (
        <div key={i} style={{ position: 'absolute', top: -200, left: `${28 + i * 9}%`, width: 1, height: 550, background: 'linear-gradient(to bottom,transparent,rgba(212,175,55,0.07),transparent)', transform: 'rotate(22deg)', pointerEvents: 'none' }} />
      ))}
      <div style={{ position: 'absolute', left: 0, top: 18, bottom: 18, width: 3, background: 'linear-gradient(to bottom,transparent,#d4af37,#ffd700,#d4af37,transparent)', borderRadius: '0 3px 3px 0', boxShadow: '0 0 10px rgba(212,175,55,0.5)' }} />
      <div style={{ position: 'absolute', top: 16, right: 22, zIndex: 3, padding: '2px 10px', borderRadius: 20, background: 'rgba(212,175,55,0.12)', border: '1px solid rgba(212,175,55,0.38)', fontFamily: "'Share Tech Mono',monospace", fontSize: 8, letterSpacing: 3, color: '#d4af37' }}>GOLD</div>
      <Shimmer gradient="linear-gradient(90deg,transparent,rgba(255,215,0,0.07),rgba(255,255,255,0.04),transparent)" delay="0.4s" />
      <CardBody data={data} textColor="rgba(255,230,140,0.92)" subColor="rgba(212,175,55,0.55)" />
      {data.iban && <IBANBar iban={data.iban} borderColor="rgba(212,175,55,0.08)" textColor="rgba(212,175,55,0.28)" />}
    </div>
  )
}

// ─── DIAMOND ──────────────────────────────────────────────────────────────────

const SPARKLE_POS = [
  { x:'11%', y:'16%', s:3, delay:'0s',   dur:'2.4s' },
  { x:'87%', y:'11%', s:4, delay:'0.6s', dur:'3.1s' },
  { x:'76%', y:'80%', s:3, delay:'1.2s', dur:'2.7s' },
  { x:'20%', y:'74%', s:2, delay:'0.3s', dur:'3.4s' },
  { x:'54%', y:'90%', s:3, delay:'1.8s', dur:'2.1s' },
  { x:'93%', y:'44%', s:2, delay:'0.9s', dur:'2.8s' },
]

function DiamondBankCard({ data }: { data: BankCardData }) {
  return (
    <div style={{
      position: 'relative', width: CARD_W, height: CARD_H,
      borderRadius: 15, overflow: 'hidden',
      background: 'linear-gradient(135deg,#030710 0%,#08101e 25%,#060c18 55%,#0c1226 80%,#040810 100%)',
      border: '1px solid rgba(140,210,255,0.28)',
      boxShadow: '0 22px 55px rgba(0,0,0,0.96), 0 0 0 1px rgba(140,210,255,0.12), 0 0 40px rgba(80,180,255,0.1)',
      animation: 'cardIn 0.45s cubic-bezier(0.22,1,0.36,1) forwards',
    }}>
      <div style={{ position: 'absolute', top: -90, left: -60, width: 280, height: 280, borderRadius: '50%', background: 'radial-gradient(circle,rgba(80,160,255,0.09),transparent 62%)', pointerEvents: 'none' }} />
      <div style={{ position: 'absolute', bottom: -70, right: -50, width: 230, height: 230, borderRadius: '50%', background: 'radial-gradient(circle,rgba(180,80,255,0.07),transparent 62%)', pointerEvents: 'none' }} />
      <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', opacity: 0.038, pointerEvents: 'none' }}>
        <defs><pattern id="dmnd" x="0" y="0" width="32" height="32" patternUnits="userSpaceOnUse"><polygon points="16,2 30,16 16,30 2,16" fill="none" stroke="white" strokeWidth="0.7" /></pattern></defs>
        <rect width="100%" height="100%" fill="url(#dmnd)" />
      </svg>
      {(['rgba(80,200,255,0.04)','rgba(200,80,255,0.03)','rgba(0,255,190,0.03)'] as const).map((c, i) => (
        <div key={i} style={{ position: 'absolute', top: 0, bottom: 0, width: '32%', transform: 'skewX(-25deg)', background: `linear-gradient(90deg,transparent,${c},transparent)`, animation: `shimmer ${2.4 + i * 0.7}s ease-in-out ${i * 0.5}s infinite`, pointerEvents: 'none', zIndex: 1 }} />
      ))}
      {SPARKLE_POS.map((sp, i) => (
        <div key={i} style={{ position: 'absolute', left: sp.x, top: sp.y, width: sp.s, height: sp.s, borderRadius: '50%', background: 'white', boxShadow: '0 0 4px 1px rgba(180,240,255,0.8)', pointerEvents: 'none', zIndex: 4, animation: `sparkle ${sp.dur} ease-in-out ${sp.delay} infinite` }} />
      ))}
      <div style={{ position: 'absolute', left: 0, top: 18, bottom: 18, width: 3, background: 'linear-gradient(to bottom,transparent,#22d3ee,#a78bfa,#22d3ee,transparent)', borderRadius: '0 3px 3px 0', boxShadow: '0 0 12px rgba(34,211,238,0.6)' }} />
      <div style={{ position: 'absolute', top: 16, right: 22, zIndex: 5, padding: '2px 10px', borderRadius: 20, background: 'rgba(34,211,238,0.1)', border: '1px solid rgba(140,210,255,0.32)', fontFamily: "'Share Tech Mono',monospace", fontSize: 8, letterSpacing: 3, color: '#67e8f9', boxShadow: '0 0 10px rgba(34,211,238,0.2)' }}>◆ DIAMOND</div>
      <CardBody data={data} textColor="rgba(195,238,255,0.92)" subColor="rgba(100,200,240,0.5)" showAmex />
      {data.iban && <IBANBar iban={data.iban} borderColor="rgba(100,220,255,0.07)" textColor="rgba(80,190,230,0.28)" />}
    </div>
  )
}

export function BankCardComponent({ data }: { data: BankCardData }) {
  switch (data.type) {
    case 'bank_card':         return <ClassicBankCard  data={data} />
    case 'bank_gold_card':    return <GoldBankCard     data={data} />
    case 'bank_diamond_card': return <DiamondBankCard  data={data} />
    default: return null
  }
}
