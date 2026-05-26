import { motion } from 'framer-motion'
import type { CardType, CardData, CardTheme, BankCardData } from '../types'
import type {
  IdentityCardData, DriverCardData, WeaponCardData, PoliceCardData,
  MairieCardData, GovernmentCardData, EMSCardData, CompanyCardData, PassportCardData
} from '../types'
import { THEMES } from '../data/themes'
import {
  PhotoPlaceholder, HoloStrip, SecurityOverlay, SecureQR,
  SignatureLine, AccessBadge, StatusBadge, Field, Chip, Barcode, PointsGauge
} from './CardParts'
import { BankCardComponent } from './Bankcardcomponent'

// ─── Tailles adaptées FiveM 1080p ────────────────────────────────────────────
// Avant : width 600px — trop large en jeu
// Après : width 480px max, padding réduit, fontes -15%

const CARD_W = 480

const cardVariants = {
  hidden:  { opacity: 0, y: 24, scale: 0.93, rotateY: -10 },
  visible: {
    opacity: 1, y: 0, scale: 1, rotateY: 0,
    transition: { type: 'spring', stiffness: 280, damping: 24 }
  },
  exit: {
    opacity: 0, y: -16, scale: 0.96,
    transition: { duration: 0.2, ease: 'easeIn' }
  }
}

function CardShell({ type, children }: { type: CardType; children: React.ReactNode }) {
  const t = THEMES[type]
  return (
    <motion.div
      variants={cardVariants}
      initial="hidden" animate="visible" exit="exit"
      style={{
        position: 'relative',
        width: CARD_W,
        borderRadius: 14,
        background: `linear-gradient(135deg, ${t.gradFrom} 0%, ${t.gradVia} 50%, ${t.gradTo} 100%)`,
        border: `1px solid ${t.borderColor}`,
        boxShadow: `0 20px 60px rgba(0,0,0,0.9), 0 0 0 1px ${t.borderColor}, 0 0 30px ${t.accent}28`,
        overflow: 'hidden',
        '--card-accent': t.accent,
        '--card-glow': `${t.accent}40`,
        '--card-glow-alt': `${t.accentAlt}30`,
      } as React.CSSProperties}
    >
      <SecurityOverlay theme={t} />
      <HoloStrip theme={t} />
      {children}
    </motion.div>
  )
}

function CardHeader({ type, rightContent }: { type: CardType; rightContent?: React.ReactNode }) {
  const t = THEMES[type]
  return (
    <div style={{
      padding: '10px 16px 9px',
      background: t.headerBg,
      borderBottom: `1px solid ${t.borderColor}`,
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <span style={{ fontSize: 18 }}>{t.icon}</span>
        <div>
          <div style={{
            fontFamily: 'Share Tech Mono', fontSize: 8, letterSpacing: 2,
            color: t.textSecondary, textTransform: 'uppercase',
          }}>{t.agency}</div>
          <div style={{
            fontFamily: 'Rajdhani', fontSize: 13, fontWeight: 700,
            color: t.textPrimary, letterSpacing: 1.2, textTransform: 'uppercase', marginTop: 1,
          }}>{t.name}</div>
        </div>
      </div>
      {rightContent}
    </div>
  )
}

function PhotoBox({ photo, type, size = 76 }: { photo?: string; type: CardType; size?: number }) {
  const t = THEMES[type]
  return (
    <div style={{
      width: size, height: size * 1.22, borderRadius: 5, overflow: 'hidden', flexShrink: 0,
      border: `2px solid ${t.borderColor}`,
      boxShadow: `0 3px 12px rgba(0,0,0,0.5), inset 0 0 0 1px ${t.accent}20`,
    }}>
      {photo
        ? <img src={photo} alt="ID" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
        : <PhotoPlaceholder theme={t} size={size} />
      }
    </div>
  )
}

function Divider({ theme }: { theme: CardTheme }) {
  return <div style={{ height: 1, background: `linear-gradient(90deg, ${theme.accent}40, transparent)`, margin: '6px 0' }} />
}

// ═══════════════════════════════════════════════════════
// 1. IDENTITÉ
// ═══════════════════════════════════════════════════════
function IdentityCard({ data }: { data: IdentityCardData }) {
  const t = THEMES.identity
  return (
    <CardShell type="identity">
      <CardHeader type="identity" rightContent={<Chip theme={t} />} />
      <div style={{ padding: '14px 16px', display: 'flex', gap: 14 }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'center' }}>
          <PhotoBox photo={data.photo} type="identity" size={76} />
          <SignatureLine name={data.signature ?? data.firstname} theme={t} />
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8 }}>
          <div>
            <div style={{ fontFamily: 'Oswald', fontSize: 21, fontWeight: 600, color: t.textPrimary, lineHeight: 1, letterSpacing: 0.8 }}>
              {data.lastname}
            </div>
            <div style={{ fontFamily: 'Exo 2', fontSize: 15, fontWeight: 300, color: t.accent, letterSpacing: 0.4 }}>
              {data.firstname}
            </div>
          </div>
          <Divider theme={t} />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '6px 12px' }}>
            <Field label="Date de naissance" value={data.dateOfBirth} theme={t} />
            <Field label="Sexe" value={data.gender === 'M' ? 'Masculin' : 'Féminin'} theme={t} />
            <Field label="Taille" value={data.height} theme={t} />
            <Field label="Nationalité" value={data.nationality} theme={t} />
            <Field label="Émission" value={data.issued ?? '—'} theme={t} />
            <Field label="Expiration" value={data.expiry ?? '—'} theme={t} />
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', alignItems: 'flex-end' }}>
          <SecureQR value={`ID:${data.uniqueId ?? data.lastname}`} theme={t} size={46} />
          <Field label="N° Identifiant" value={data.uniqueId ?? '—'} mono theme={t} />
        </div>
      </div>
      <div style={{
        padding: '6px 16px 10px', borderTop: `1px solid ${t.borderColor}`,
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        background: `linear-gradient(90deg, ${t.accent}08, transparent)`,
      }}>
        <Barcode seed={data.uniqueId ?? data.lastname} theme={t} />
        <div style={{ fontFamily: 'Share Tech Mono', fontSize: 8, color: `${t.textSecondary}60`, letterSpacing: 1 }}>
          RÉPUBLIQUE FRANÇAISE • MINISTÈRE DE L'INTÉRIEUR
        </div>
      </div>
    </CardShell>
  )
}

// ═══════════════════════════════════════════════════════
// 2. PERMIS DE CONDUIRE
// ═══════════════════════════════════════════════════════
function DriverCard({ data }: { data: DriverCardData }) {
  const t = THEMES.driver
  return (
    <CardShell type="driver">
      <CardHeader type="driver" rightContent={
        <div style={{ display: 'flex', gap: 3 }}>
          {data.categories.map(c => (
            <div key={c} style={{
              width: 24, height: 24, borderRadius: 3,
              background: t.accent, display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'Rajdhani', fontWeight: 700, fontSize: 12, color: '#fff',
              boxShadow: `0 0 6px ${t.accent}80`,
            }}>{c}</div>
          ))}
        </div>
      } />
      <div style={{ padding: '14px 16px', display: 'flex', gap: 14 }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'center' }}>
          <PhotoBox photo={data.photo} type="driver" size={76} />
          <SignatureLine name={data.signature ?? data.firstname} theme={t} />
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8 }}>
          <div>
            <div style={{ fontFamily: 'Oswald', fontSize: 20, fontWeight: 600, color: t.textPrimary, letterSpacing: 0.8 }}>
              {data.lastname}
            </div>
            <div style={{ fontFamily: 'Exo 2', fontSize: 14, fontWeight: 300, color: t.accent }}>
              {data.firstname}
            </div>
          </div>
          <Divider theme={t} />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '6px 12px' }}>
            <Field label="N° Permis" value={data.licenseNumber} mono theme={t} />
            <Field label="Émission" value={data.issued ?? '—'} theme={t} />
            <Field label="Expiration" value={data.expiry ?? '—'} theme={t} />
          </div>
          <PointsGauge points={data.points} max={data.maxPoints} theme={t} />
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', alignItems: 'flex-end' }}>
          <SecureQR value={`DRV:${data.licenseNumber}`} theme={t} size={44} />
          <div style={{ fontFamily: 'Share Tech Mono', fontSize: 8, color: t.textSecondary, textAlign: 'right' }}>
            {data.categories.join(' • ')}
          </div>
        </div>
      </div>
      <div style={{
        padding: '6px 16px 10px', borderTop: `1px solid ${t.borderColor}`,
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        background: `linear-gradient(90deg, ${t.accent}08, transparent)`,
      }}>
        <Barcode seed={data.licenseNumber} theme={t} />
        <div style={{ fontFamily: 'Share Tech Mono', fontSize: 8, color: `${t.textSecondary}60`, letterSpacing: 1 }}>
          MINISTÈRE DES TRANSPORTS
        </div>
      </div>
    </CardShell>
  )
}

// ═══════════════════════════════════════════════════════
// 3. ARME
// ═══════════════════════════════════════════════════════
function WeaponCard({ data }: { data: WeaponCardData }) {
  const t = THEMES.weapon
  return (
    <CardShell type="weapon">
      <CardHeader type="weapon" rightContent={<StatusBadge status={data.legalStatus} />} />
      <div style={{ padding: '14px 16px', display: 'flex', gap: 14 }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'center' }}>
          <PhotoBox photo={data.photo} type="weapon" size={76} />
          <SignatureLine name={data.signature ?? data.firstname} theme={t} />
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 7 }}>
          <div>
            <div style={{ fontFamily: 'Oswald', fontSize: 20, fontWeight: 600, color: t.textPrimary, letterSpacing: 0.8 }}>{data.lastname}</div>
            <div style={{ fontFamily: 'Exo 2', fontSize: 14, fontWeight: 300, color: t.accent }}>{data.firstname}</div>
          </div>
          <Divider theme={t} />
          <Field label="Type d'autorisation" value={data.authorizationType} theme={t} />
          <AccessBadge level={data.accessLevel} theme={t} />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '5px 12px' }}>
            <Field label="N° Licence" value={data.licenseNumber} mono theme={t} />
            <Field label="Expiration" value={data.expiry ?? '—'} theme={t} />
          </div>
          <div>
            <div style={{ fontFamily: 'Share Tech Mono', fontSize: 7, color: t.textSecondary, letterSpacing: 1, marginBottom: 3 }}>ARMES AUTORISÉES</div>
            <div style={{ display: 'flex', gap: 3, flexWrap: 'wrap' }}>
              {data.allowedWeapons.map(w => (
                <span key={w} style={{
                  padding: '1px 6px', borderRadius: 3,
                  background: `${t.accent}20`, border: `1px solid ${t.accent}40`,
                  fontFamily: 'Rajdhani', fontSize: 9, color: t.textPrimary,
                }}>{w}</span>
              ))}
            </div>
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'flex-start', alignItems: 'flex-end', gap: 8 }}>
          <SecureQR value={`WPN:${data.licenseNumber}`} theme={t} size={44} />
        </div>
      </div>
      <div style={{
        padding: '6px 16px 10px', borderTop: `1px solid ${t.borderColor}`,
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      }}>
        <Barcode seed={data.licenseNumber} theme={t} />
        <div style={{ fontFamily: 'Share Tech Mono', fontSize: 8, color: `${t.textSecondary}60`, letterSpacing: 1 }}>REGISTRE OFFICIEL</div>
      </div>
    </CardShell>
  )
}

// ═══════════════════════════════════════════════════════
// 4. POLICE
// ═══════════════════════════════════════════════════════
function PoliceCard({ data }: { data: PoliceCardData }) {
  const t = THEMES.police
  return (
    <CardShell type="police">
      <div style={{ height: 3, background: `linear-gradient(90deg, ${t.accentAlt}, ${t.accent}, ${t.accentAlt})` }} />
      <CardHeader type="police" rightContent={<StatusBadge status={data.status} />} />
      <div style={{ padding: '12px 16px', display: 'flex', gap: 12 }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'center' }}>
          <PhotoBox photo={data.photo} type="police" size={74} />
          <div style={{ width: 44, height: 44, position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg viewBox="0 0 54 54" fill="none" style={{ position: 'absolute', inset: 0 }}>
              <polygon points="27,2 35,18 52,18 40,30 44,48 27,38 10,48 14,30 2,18 19,18" fill={t.accentAlt} opacity="0.9" />
              <polygon points="27,7 33,19 47,19 37,28 40,43 27,35 14,43 17,28 7,19 21,19" fill={t.accent} opacity="0.7" />
            </svg>
            <span style={{ fontFamily: 'Rajdhani', fontSize: 8, fontWeight: 700, color: '#000', zIndex: 1, textAlign: 'center', lineHeight: 1 }}>
              {data.badgeNumber.split('-')[1] ?? data.badgeNumber}
            </span>
          </div>
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 6 }}>
          <div>
            <div style={{ fontFamily: 'Rajdhani', fontSize: 9, color: t.accentAlt, letterSpacing: 2, textTransform: 'uppercase' }}>{data.rank}</div>
            <div style={{ fontFamily: 'Oswald', fontSize: 20, fontWeight: 600, color: t.textPrimary, letterSpacing: 0.8 }}>{data.lastname}</div>
            <div style={{ fontFamily: 'Exo 2', fontSize: 13, fontWeight: 300, color: t.textSecondary }}>{data.firstname}</div>
          </div>
          <Divider theme={t} />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '5px 12px' }}>
            <Field label="Badge N°" value={data.badgeNumber} mono theme={t} />
            <Field label="Département" value={data.department} theme={t} />
            <Field label="Service" value={data.service} theme={t} />
            <Field label="Expiration" value={data.expiry ?? '—'} theme={t} />
          </div>
          <AccessBadge level={data.accessLevel} theme={t} />
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'flex-end' }}>
          <SecureQR value={`POL:${data.badgeNumber}`} theme={t} size={44} />
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontFamily: 'Share Tech Mono', fontSize: 7, color: t.textSecondary, marginBottom: 3 }}>AUTORISATIONS</div>
            {data.authorizations.slice(0, 3).map(a => (
              <div key={a} style={{ fontFamily: 'Rajdhani', fontSize: 9, color: t.accentAlt }}>• {a}</div>
            ))}
          </div>
        </div>
      </div>
      <div style={{ height: 3, background: `linear-gradient(90deg, ${t.accentAlt}, ${t.accent}, ${t.accentAlt})` }} />
    </CardShell>
  )
}

// ═══════════════════════════════════════════════════════
// 5. MAIRIE
// ═══════════════════════════════════════════════════════
function MairieCard({ data }: { data: MairieCardData }) {
  const t = THEMES.mairie
  return (
    <CardShell type="mairie">
      <CardHeader type="mairie" rightContent={<Chip theme={t} />} />
      <div style={{ padding: '14px 16px', display: 'flex', gap: 14 }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'center' }}>
          <PhotoBox photo={data.photo} type="mairie" size={76} />
          <SignatureLine name={data.signature ?? data.firstname} theme={t} />
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8 }}>
          <div>
            <div style={{ fontFamily: 'Rajdhani', fontSize: 9, color: t.accent, letterSpacing: 2 }}>FONCTIONNAIRE MUNICIPAL</div>
            <div style={{ fontFamily: 'Oswald', fontSize: 20, fontWeight: 600, color: t.textPrimary, letterSpacing: 0.8 }}>{data.lastname}</div>
            <div style={{ fontFamily: 'Exo 2', fontSize: 14, fontWeight: 300, color: t.textSecondary }}>{data.firstname}</div>
          </div>
          <Divider theme={t} />
          <Field label="Fonction" value={data.function} large theme={t} />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '5px 12px' }}>
            <Field label="ID Employé" value={data.employeeId} mono theme={t} />
            <Field label="Émission" value={data.issued ?? '—'} theme={t} />
            <Field label="Expiration" value={data.expiry ?? '—'} theme={t} />
          </div>
          {data.officialSignature && (
            <div style={{ fontFamily: 'Oswald', fontSize: 11, fontStyle: 'italic', color: `${t.accent}90`, letterSpacing: 0.5 }}>
              — {data.officialSignature}
            </div>
          )}
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', alignItems: 'flex-end' }}>
          <SecureQR value={`MRE:${data.employeeId}`} theme={t} size={44} />
        </div>
      </div>
      <div style={{
        padding: '6px 16px 10px', borderTop: `1px solid ${t.borderColor}`,
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      }}>
        <Barcode seed={data.employeeId} theme={t} />
        <div style={{ fontFamily: 'Share Tech Mono', fontSize: 8, color: `${t.textSecondary}60`, letterSpacing: 1 }}>MAIRIE DE LOS SANTOS</div>
      </div>
    </CardShell>
  )
}

// ═══════════════════════════════════════════════════════
// 6. GOUVERNEMENT
// ═══════════════════════════════════════════════════════
function GovernmentCard({ data }: { data: GovernmentCardData }) {
  const t = THEMES.government
  return (
    <CardShell type="government">
      <div style={{ height: 3, background: `linear-gradient(90deg, ${t.stripeColor}, #fff8, ${t.stripeColor})` }} />
      <CardHeader type="government" rightContent={
        <div style={{ padding: '3px 8px', borderRadius: 4, background: `${t.stripeColor}20`, border: `1px solid ${t.stripeColor}50` }}>
          <div style={{ fontFamily: 'Share Tech Mono', fontSize: 7, color: t.stripeColor, letterSpacing: 1 }}>CLEARANCE</div>
          <div style={{ fontFamily: 'Rajdhani', fontSize: 15, fontWeight: 700, color: t.stripeColor, lineHeight: 1 }}>LEVEL {data.securityLevel}</div>
        </div>
      } />
      <div style={{ padding: '12px 16px', display: 'flex', gap: 12 }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'center' }}>
          <PhotoBox photo={data.photo} type="government" size={74} />
          <SignatureLine name={data.signature ?? data.firstname} theme={t} />
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 7 }}>
          <div>
            <div style={{ fontFamily: 'Share Tech Mono', fontSize: 8, color: t.stripeColor, letterSpacing: 2 }}>{data.function.toUpperCase()}</div>
            <div style={{ fontFamily: 'Oswald', fontSize: 20, fontWeight: 600, color: t.textPrimary, letterSpacing: 0.8 }}>{data.lastname}</div>
            <div style={{ fontFamily: 'Exo 2', fontSize: 13, fontWeight: 300, color: t.textSecondary }}>{data.firstname}</div>
          </div>
          <Divider theme={t} />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '5px 12px' }}>
            <Field label="ID Gouvernemental" value={data.govId} mono theme={t} />
            <Field label="Département" value={data.nationalDepartment} theme={t} />
            <Field label="Émission" value={data.issued ?? '—'} theme={t} />
            <Field label="Expiration" value={data.expiry ?? '—'} theme={t} />
          </div>
          <div style={{ display: 'flex', gap: 3, flexWrap: 'wrap' }}>
            {data.specialAuthorizations.map(a => (
              <span key={a} style={{ padding: '1px 6px', borderRadius: 3, background: `${t.stripeColor}18`, border: `1px solid ${t.stripeColor}40`, fontFamily: 'Share Tech Mono', fontSize: 8, color: t.stripeColor }}>{a}</span>
            ))}
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', alignItems: 'flex-end' }}>
          <SecureQR value={`GOV:${data.govId}`} theme={t} size={44} />
          <AccessBadge level={data.securityLevel} theme={t} />
        </div>
      </div>
      <div style={{ height: 3, background: `linear-gradient(90deg, ${t.stripeColor}, #fff8, ${t.stripeColor})` }} />
    </CardShell>
  )
}

// ═══════════════════════════════════════════════════════
// 7. EMS
// ═══════════════════════════════════════════════════════
function EMSCard({ data }: { data: EMSCardData }) {
  const t = THEMES.ems
  return (
    <CardShell type="ems">
      <div style={{ height: 3, background: `linear-gradient(90deg, ${t.accent}, #22d3ee, ${t.accent})` }} />
      <CardHeader type="ems" rightContent={<StatusBadge status={data.status} />} />
      <div style={{ padding: '12px 16px', display: 'flex', gap: 12 }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'center' }}>
          <PhotoBox photo={data.photo} type="ems" size={74} />
          <div style={{ padding: '3px 10px', borderRadius: 5, background: '#7f1d1d', border: '1px solid #f87171', fontFamily: 'Rajdhani', fontSize: 15, fontWeight: 700, color: '#fca5a5', letterSpacing: 1, textAlign: 'center' }}>
            {data.bloodGroup}
          </div>
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 6 }}>
          <div>
            <div style={{ fontFamily: 'Share Tech Mono', fontSize: 8, color: t.accent, letterSpacing: 2 }}>{data.medicalRank.toUpperCase()}</div>
            <div style={{ fontFamily: 'Oswald', fontSize: 20, fontWeight: 600, color: t.textPrimary, letterSpacing: 0.8 }}>{data.lastname}</div>
            <div style={{ fontFamily: 'Exo 2', fontSize: 13, fontWeight: 300, color: t.textSecondary }}>{data.firstname}</div>
          </div>
          <Divider theme={t} />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '5px 12px' }}>
            <Field label="N° EMS" value={data.emsNumber} mono theme={t} />
            <Field label="Département" value={data.department} theme={t} />
            <Field label="Groupe sanguin" value={data.bloodGroup} theme={t} />
            <Field label="Expiration" value={data.expiry ?? '—'} theme={t} />
          </div>
          <div style={{ display: 'flex', gap: 3, flexWrap: 'wrap' }}>
            {data.medicalAuthorizations.map(a => (
              <span key={a} style={{ padding: '1px 6px', borderRadius: 3, background: `${t.accent}20`, border: `1px solid ${t.accent}40`, fontFamily: 'Rajdhani', fontSize: 9, color: t.textPrimary }}>{a}</span>
            ))}
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', alignItems: 'flex-end' }}>
          <SecureQR value={`EMS:${data.emsNumber}`} theme={t} size={44} />
          <SignatureLine name={data.signature ?? data.firstname} theme={t} />
        </div>
      </div>
      <div style={{ height: 3, background: `linear-gradient(90deg, ${t.accent}, #22d3ee, ${t.accent})` }} />
    </CardShell>
  )
}

// ═══════════════════════════════════════════════════════
// 8. ENTREPRISE
// ═══════════════════════════════════════════════════════
function CompanyCard({ data }: { data: CompanyCardData }) {
  const t = THEMES.company
  return (
    <CardShell type="company">
      <CardHeader type="company" rightContent={<div style={{ fontSize: 26 }}>{data.companyLogo ?? '🏢'}</div>} />
      <div style={{ padding: '14px 16px', display: 'flex', gap: 12 }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'center' }}>
          <PhotoBox photo={data.photo} type="company" size={74} />
          <SignatureLine name={data.signature ?? data.firstname} theme={t} />
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 7 }}>
          <div>
            <div style={{ fontFamily: 'Share Tech Mono', fontSize: 9, color: t.stripeColor, letterSpacing: 2, textTransform: 'uppercase' }}>{data.company}</div>
            <div style={{ fontFamily: 'Oswald', fontSize: 20, fontWeight: 600, color: t.textPrimary, letterSpacing: 0.8 }}>{data.lastname}</div>
            <div style={{ fontFamily: 'Exo 2', fontSize: 13, fontWeight: 300, color: t.textSecondary }}>{data.firstname}</div>
          </div>
          <Divider theme={t} />
          <Field label="Poste" value={data.position} large theme={t} />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '5px 12px' }}>
            <Field label="Département" value={data.companyDepartment} theme={t} />
            <Field label="ID Employé" value={data.employeeId} mono theme={t} />
            <Field label="Émission" value={data.issued ?? '—'} theme={t} />
            <Field label="Expiration" value={data.expiry ?? '—'} theme={t} />
          </div>
          <AccessBadge level={data.accessLevel} theme={t} />
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', alignItems: 'flex-end' }}>
          <SecureQR value={`EMP:${data.employeeId}`} theme={t} size={44} />
        </div>
      </div>
      <div style={{
        padding: '6px 16px 10px', borderTop: `1px solid ${t.borderColor}`,
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      }}>
        <Barcode seed={data.employeeId} theme={t} />
        <div style={{ fontFamily: 'Share Tech Mono', fontSize: 8, color: `${t.textSecondary}60`, letterSpacing: 1 }}>{data.company.toUpperCase()} • EMPLOYEE BADGE</div>
      </div>
    </CardShell>
  )
}

// ═══════════════════════════════════════════════════════
// 9. PASSEPORT
// ═══════════════════════════════════════════════════════
function PassportCard({ data }: { data: PassportCardData }) {
  const t = THEMES.passport
  return (
    <CardShell type="passport">
      <div style={{ height: 3, background: `linear-gradient(90deg, ${t.accent}, #60a5fa, ${t.accent})` }} />
      <CardHeader type="passport" rightContent={
        <div style={{ textAlign: 'right' }}>
          <div style={{ fontFamily: 'Share Tech Mono', fontSize: 8, color: t.textSecondary, letterSpacing: 1 }}>N° PASSEPORT</div>
          <div style={{ fontFamily: 'Share Tech Mono', fontSize: 12, color: t.textPrimary, letterSpacing: 2 }}>{data.passportNumber}</div>
        </div>
      } />
      <div style={{ padding: '12px 16px', display: 'flex', gap: 14 }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'center' }}>
          <PhotoBox photo={data.photo} type="passport" size={78} />
          <SignatureLine name={data.signature ?? data.firstname} theme={t} />
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 7 }}>
          <div>
            <div style={{ fontFamily: 'Share Tech Mono', fontSize: 8, color: t.accent, letterSpacing: 2 }}>{data.issuingCountry}</div>
            <div style={{ fontFamily: 'Oswald', fontSize: 21, fontWeight: 600, color: t.textPrimary, letterSpacing: 0.8 }}>{data.lastname}</div>
            <div style={{ fontFamily: 'Exo 2', fontSize: 14, fontWeight: 300, color: t.textSecondary }}>{data.firstname}</div>
          </div>
          <Divider theme={t} />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '5px 12px' }}>
            <Field label="Nationalité" value={data.nationality} theme={t} />
            <Field label="Date de naissance" value={data.dateOfBirth} theme={t} />
            <Field label="Sexe" value={data.gender === 'M' ? 'M — Masculin' : 'F — Féminin'} theme={t} />
            <Field label="Pays émetteur" value={data.issuingCountry} theme={t} />
            <Field label="Émission" value={data.issued ?? '—'} theme={t} />
            <Field label="Expiration" value={data.expiry ?? '—'} theme={t} />
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', alignItems: 'flex-end' }}>
          <SecureQR value={`PASP:${data.passportNumber}`} theme={t} size={46} />
        </div>
      </div>
      <div style={{ background: 'rgba(0,0,0,0.45)', borderTop: `1px solid ${t.borderColor}`, padding: '6px 16px 10px' }}>
        <div style={{ fontFamily: 'Share Tech Mono', fontSize: 7, color: t.textSecondary, letterSpacing: 1, marginBottom: 3 }}>MRZ — MACHINE READABLE ZONE</div>
        {data.mrz.split('\n').map((line, i) => (
          <div key={i} style={{ fontFamily: 'Share Tech Mono', fontSize: 9, color: `${t.textPrimary}80`, letterSpacing: 1.5, lineHeight: 1.6, wordBreak: 'break-all' }}>{line}</div>
        ))}
      </div>
    </CardShell>
  )
}

// ═══════════════════════════════════════════════════════
// EXPORT PRINCIPAL
// ═══════════════════════════════════════════════════════

interface IDCardProps {
  type: CardType
  data: CardData
  isBankCard?: boolean
}

export function IDCard({ type, data, isBankCard }: IDCardProps) {
  switch (type) {
    case 'identity':   return <IdentityCard   data={data as IdentityCardData} />
    case 'driver':     return <DriverCard     data={data as DriverCardData} />
    case 'weapon':     return <WeaponCard     data={data as WeaponCardData} />
    case 'police':     return <PoliceCard     data={data as PoliceCardData} />
    case 'mairie':     return <MairieCard     data={data as MairieCardData} />
    case 'government': return <GovernmentCard data={data as GovernmentCardData} />
    case 'ems':        return <EMSCard        data={data as EMSCardData} />
    case 'company':    return <CompanyCard    data={data as CompanyCardData} />
    case 'passport':   return <PassportCard   data={data as PassportCardData} />
    case 'bank_card':
    case 'bank_gold_card':
    case 'bank_diamond_card':
      return <BankCardComponent data={data as BankCardData} />
    default: return null
  }
}
