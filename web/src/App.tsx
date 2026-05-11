import { useState, useCallback } from 'react'
import { AnimatePresence } from 'framer-motion'
import type { CardType, NuiPayload } from './types'
import { useNuiMessage, useNuiFetch } from './hooks/useNui'
import { IDCard } from './components/IDCard'
import { ALL_MOCKS } from './data/mockData'
import './styles/main.scss'

const IS_DEV = import.meta.env.DEV

// ─── Tab definitions ──────────────────────────────────────────────────────────
// Toutes les cartes : 9 cartes identité + 3 cartes bancaires
const CARD_TABS: { type: CardType; label: string; group: 'id' | 'bank' }[] = [
  { type: 'identity',         label: '🪪 Identité',   group: 'id'   },
  { type: 'driver',           label: '🚗 Permis',      group: 'id'   },
  { type: 'weapon',           label: '🔫 Arme',        group: 'id'   },
  { type: 'police',           label: '⭐ Police',      group: 'id'   },
  { type: 'mairie',           label: '🏛️ Mairie',      group: 'id'   },
  { type: 'government',       label: '🦅 Gouv.',       group: 'id'   },
  { type: 'ems',              label: '⚕️ EMS',          group: 'id'   },
  { type: 'company',          label: '🏢 Entreprise',  group: 'id'   },
  { type: 'passport',         label: '🌍 Passeport',   group: 'id'   },
  { type: 'bank_card',        label: '💳 Classic',     group: 'bank' },
  { type: 'bank_gold_card',   label: '🥇 Gold',        group: 'bank' },
  { type: 'bank_diamond_card',label: '💎 Diamond',     group: 'bank' },
]

// ─── NUI close endpoint : commun aux deux anciens systèmes ────────────────────
// On envoie les deux pour compatibilité ascendante si jamais le serveur écoute encore les deux
const CLOSE_ENDPOINTS = ['idcard:close', 'bankcard:close'] as const

export function App() {
  const fetchNui = useNuiFetch()

  const [visible,    setVisible]    = useState(IS_DEV)
  const [activeType, setActiveType] = useState<CardType>('identity')
  const [cardData,   setCardData]   = useState<Record<string, unknown>>(ALL_MOCKS)

  // ─── Close handler ──────────────────────────────────────────────────────────
  const handleClose = useCallback(() => {
    setVisible(false)
    // Notifie les deux endpoints pour compatibilité
    CLOSE_ENDPOINTS.forEach(ep => fetchNui(ep, {}))
  }, [fetchNui])

  // ─── NUI message handler ────────────────────────────────────────────────────
  // Compatible avec les payloads des deux anciens systèmes :
  //   kt_idcard_ui  → { action: 'showCard', cardType, data }
  //   kt_bankcard_ui → { action: 'showCard', data: { type, ... } }
  const handleNuiMessage = useCallback((payload: NuiPayload) => {
    if (payload.action === 'showCard') {
      // Détermine le type selon la source du payload
      const type: CardType =
        ('cardType' in payload && payload.cardType)
          ? payload.cardType
          // Fallback : le type est dans data.type (format bankcard)
          : (payload.data as { type: CardType }).type

      setActiveType(type)
      setCardData(prev => ({ ...prev, [type]: payload.data }))
      setVisible(true)
    } else if (payload.action === 'hideCard') {
      setVisible(false)
    }
  }, [])

  useNuiMessage(handleNuiMessage)

  // ─── Keyboard close ────────────────────────────────────────────────────────
  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Escape' || e.key === 'e' || e.key === 'E') handleClose()
  }, [handleClose])

  if (!visible) return null

  const isBankCard = activeType.startsWith('bank_')

  return (
    <div
      className="overlay visible"
      onKeyDown={handleKeyDown}
      tabIndex={-1}
      style={{ flexDirection: 'column', gap: 16 }}
    >
      {/* ── Dev tab switcher (DEV uniquement) ─────────────────────────────── */}
      {IS_DEV && (
        <div className="tab-bar">
          {/* Groupe identité */}
          <div className="tab-group">
            <span className="tab-group__label">IDENTITÉ</span>
            <div className="tab-group__row">
              {CARD_TABS.filter(t => t.group === 'id').map(({ type, label }) => (
                <button
                  key={type}
                  className={`tab-btn ${activeType === type ? 'active' : ''}`}
                  onClick={() => setActiveType(type)}
                  style={{ '--card-accent': '#2563eb' } as React.CSSProperties}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>
          {/* Groupe banque */}
          <div className="tab-group">
            <span className="tab-group__label">BANQUE</span>
            <div className="tab-group__row">
              {CARD_TABS.filter(t => t.group === 'bank').map(({ type, label }) => (
                <button
                  key={type}
                  className={`tab-btn tab-btn--bank ${activeType === type ? `active active--${type.replace('bank_', '').replace('_card', '')}` : ''}`}
                  onClick={() => setActiveType(type)}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* ── Card ──────────────────────────────────────────────────────────── */}
      <AnimatePresence mode="wait">
        <IDCard
          key={activeType}
          type={activeType}
          data={cardData[activeType] as Parameters<typeof IDCard>[0]['data']}
          isBankCard={isBankCard}
        />
      </AnimatePresence>

      <div className="close-hint">[ E ] ou [ ESC ] pour fermer</div>
    </div>
  )
}