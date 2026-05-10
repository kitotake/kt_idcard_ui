import { useState, useCallback } from 'react'
import { AnimatePresence } from 'framer-motion'
import type { CardType, NuiPayload } from './types'
import { useNuiMessage, useNuiFetch } from './hooks/useNui'
import { IDCard } from './components/IDCard'
import { ALL_MOCKS } from './data/mockData'
import './styles/main.scss'

const IS_DEV = import.meta.env.DEV

const CARD_TYPES: { type: CardType; label: string }[] = [
  { type: 'identity',   label: '🪪 Identité' },
  { type: 'driver',     label: '🚗 Permis' },
  { type: 'weapon',     label: '🔫 Arme' },
  { type: 'police',     label: '⭐ Police' },
  { type: 'mairie',     label: '🏛️ Mairie' },
  { type: 'government', label: '🦅 Gouv.' },
  { type: 'ems',        label: '⚕️ EMS' },
  { type: 'company',    label: '🏢 Entreprise' },
  { type: 'passport',   label: '🌍 Passeport' },
    { type: 'bank_card',         label: '💳 Classic',  activeClass: 'active-classic' },
  { type: 'bank_gold_card',    label: '🥇 Gold',     activeClass: 'active-gold'    },
  { type: 'bank_diamond_card', label: '💎 Diamond',  activeClass: 'active-diamond' },
]

export function App() {
  const fetchNui = useNuiFetch()

  const [visible, setVisible]       = useState(IS_DEV)
  const [activeType, setActiveType] = useState<CardType>('identity')
  const [cardData, setCardData]     = useState(ALL_MOCKS)

  const handleClose = useCallback(() => {
    setVisible(false)
    fetchNui('idcard:close', {})
  }, [fetchNui])

  const handleNuiMessage = useCallback((payload: NuiPayload) => {
    if (payload.action === 'showCard') {
      setActiveType(payload.cardType)
      setCardData(prev => ({ ...prev, [payload.cardType]: payload.data }))
      setVisible(true)
    } else if (payload.action === 'hideCard') {
      setVisible(false)
    }
  }, [])

  useNuiMessage(handleNuiMessage)

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Escape' || e.key === 'e' || e.key === 'E') handleClose()
  }, [handleClose])

  if (!visible) return null

  const currentData = cardData[activeType]

  return (
    <div
      className="overlay visible"
      onKeyDown={handleKeyDown}
      tabIndex={-1}
      style={{ flexDirection: 'column', gap: 16 }}
    >
      {/* Dev tab switcher — hidden in production */}
      {IS_DEV && (
        <div className="tab-bar">
          {CARD_TYPES.map(({ type, label }) => (
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
      )}

      {/* Card with AnimatePresence for smooth transitions */}
      <AnimatePresence mode="wait">
        <IDCard key={activeType} type={activeType} data={currentData} />
      </AnimatePresence>

      <div className="close-hint">
        [ E ] ou [ ESC ] pour fermer
      </div>
    </div>
  )
}
