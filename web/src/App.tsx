import { useState, useCallback } from 'react'
import { AnimatePresence } from 'framer-motion'
import type { CardType, NuiPayload } from './types'
import { useNuiMessage, useNuiFetch } from './hooks/useNui'
import { IDCard } from './components/IDCard'
import { ShopMenu } from './components/ShopMenu'
import { ALL_MOCKS } from './data/mockData'
import './styles/main.scss'

const IS_DEV = import.meta.env.DEV

const CARD_TABS: { type: CardType; label: string; group: 'id' | 'bank' }[] = [
  { type: 'identity',          label: '🪪 Identité',   group: 'id'   },
  { type: 'driver',            label: '🚗 Permis',      group: 'id'   },
  { type: 'weapon',            label: '🔫 Arme',        group: 'id'   },
  { type: 'police',            label: '⭐ Police',      group: 'id'   },
  { type: 'mairie',            label: '🏛️ Mairie',      group: 'id'   },
  { type: 'government',        label: '🦅 Gouv.',       group: 'id'   },
  { type: 'ems',               label: '⚕️ EMS',          group: 'id'   },
  { type: 'company',           label: '🏢 Entreprise',  group: 'id'   },
  { type: 'passport',          label: '🌍 Passeport',   group: 'id'   },
  { type: 'bank_card',         label: '💳 Classic',     group: 'bank' },
  { type: 'bank_gold_card',    label: '🥇 Gold',        group: 'bank' },
  { type: 'bank_diamond_card', label: '💎 Diamond',     group: 'bank' },
]

// ─── Types boutique ───────────────────────────────────────────────────────────

interface ShopItem {
  id: string
  label: string
  desc: string
  price: number
  owned: boolean
}

// ─── Payloads NUI étendus ─────────────────────────────────────────────────────

type ExtendedNuiPayload =
  | NuiPayload
  | { action: 'openShop';  items: ShopItem[] }
  | { action: 'closeShop' }

const CLOSE_ENDPOINTS = ['idcard:close', 'bankcard:close'] as const

export function App() {
  const fetchNui = useNuiFetch()

  // ── État carte ──────────────────────────────────────────────────────────────
  const [cardVisible, setCardVisible] = useState(IS_DEV)
  const [activeType,  setActiveType]  = useState<CardType>('identity')
  const [cardData,    setCardData]    = useState<Record<string, unknown>>(ALL_MOCKS)

  // ── État boutique ───────────────────────────────────────────────────────────
  const [shopVisible, setShopVisible] = useState(false)
  const [shopItems,   setShopItems]   = useState<ShopItem[]>([])

  // ─── Fermer la carte ────────────────────────────────────────────────────────
  const handleCardClose = useCallback(() => {
    setCardVisible(false)
    CLOSE_ENDPOINTS.forEach(ep => fetchNui(ep, {}))
  }, [fetchNui])

  // ─── Fermer la boutique ──────────────────────────────────────────────────────
  const handleShopClose = useCallback(() => {
    setShopVisible(false)
    fetchNui('idcard:shop:close', {})
  }, [fetchNui])

  // ─── Acheter un article ──────────────────────────────────────────────────────
  const handleBuy = useCallback((id: string) => {
    fetchNui('idcard:shop:buy', { id })
  }, [fetchNui])

  // ─── Montrer aux proches ─────────────────────────────────────────────────────
  const handleShowNearby = useCallback(() => {
    fetchNui('idcard:showNearby', { cardType: activeType })
  }, [fetchNui, activeType])

  // ─── Messages NUI (cartes + boutique) ────────────────────────────────────────
  const handleNuiMessage = useCallback((payload: ExtendedNuiPayload) => {
    // Boutique
    if (payload.action === 'openShop') {
      setShopItems((payload as { action: 'openShop'; items: ShopItem[] }).items)
      setShopVisible(true)
      setCardVisible(false)
      return
    }
    if (payload.action === 'closeShop') {
      setShopVisible(false)
      return
    }

    // Cartes
    if (payload.action === 'showCard') {
      const p = payload as Extract<NuiPayload, { action: 'showCard' }>
      const type: CardType =
        ('cardType' in p && p.cardType)
          ? p.cardType
          : (p.data as { type: CardType }).type

      setActiveType(type)
      setCardData(prev => ({ ...prev, [type]: p.data }))
      setCardVisible(true)
      setShopVisible(false)
      return
    }
    if (payload.action === 'hideCard') {
      setCardVisible(false)
    }
  }, [])

  useNuiMessage(handleNuiMessage as (p: NuiPayload) => void)

  // ─── ESC ferme ce qui est ouvert ─────────────────────────────────────────────
  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Escape') {
      if (shopVisible)  handleShopClose()
      if (cardVisible)  handleCardClose()
    }
  }, [shopVisible, cardVisible, handleShopClose, handleCardClose])

  const canShowNearby = activeType === 'identity' || activeType === 'driver'
  const isBankCard    = activeType.startsWith('bank_')
  const anyVisible    = cardVisible || shopVisible

  if (!anyVisible) return null

  return (
    <div
      className="overlay visible"
      onKeyDown={handleKeyDown}
      tabIndex={-1}
      style={{ flexDirection: 'column', gap: 12 }}
    >
      {/* ── Dev tab switcher ────────────────────────────────────────────── */}
      {IS_DEV && cardVisible && (
        <div className="tab-bar">
          <div className="tab-group">
            <span className="tab-group__label">IDENTITÉ</span>
            <div className="tab-group__row">
              {CARD_TABS.filter(t => t.group === 'id').map(({ type, label }) => (
                <button
                  key={type}
                  className={`tab-btn ${activeType === type ? 'active' : ''}`}
                  onClick={() => setActiveType(type)}
                >{label}</button>
              ))}
            </div>
          </div>
          <div className="tab-group">
            <span className="tab-group__label">BANQUE</span>
            <div className="tab-group__row">
              {CARD_TABS.filter(t => t.group === 'bank').map(({ type, label }) => (
                <button
                  key={type}
                  className={`tab-btn tab-btn--bank ${activeType === type ? `active active--${type.replace('bank_', '').replace('_card', '')}` : ''}`}
                  onClick={() => setActiveType(type)}
                >{label}</button>
              ))}
            </div>
          </div>
          {/* Bouton dev pour tester la boutique */}
          <div className="tab-group">
            <span className="tab-group__label">DEV</span>
            <div className="tab-group__row">
              <button
                className="tab-btn"
                onClick={() => {
                  setShopItems([
                    { id:'identity_card', label:'🪪 Carte d\'identité nationale', desc:'Document officiel.', price:150, owned:false },
                    { id:'license_A',     label:'🏍️ Permis A — Moto',              desc:'Deux-roues motorisés.', price:800, owned:true },
                    { id:'license_B',     label:'🚗 Permis B — Voiture',            desc:'Véhicules légers.',   price:1200, owned:false },
                    { id:'license_C',     label:'🚛 Permis C — Poids lourd',        desc:'Véhicules lourds.',   price:2500, owned:false },
                  ])
                  setShopVisible(true)
                  setCardVisible(false)
                }}
              >🏪 Shop (test)</button>
            </div>
          </div>
        </div>
      )}

      {/* ── Boutique ────────────────────────────────────────────────────── */}
      <AnimatePresence mode="wait">
        {shopVisible && (
          <ShopMenu
            key="shop"
            items={shopItems}
            onBuy={handleBuy}
            onClose={handleShopClose}
          />
        )}
      </AnimatePresence>

      {/* ── Carte ───────────────────────────────────────────────────────── */}
      <AnimatePresence mode="wait">
        {cardVisible && (
          <IDCard
            key={activeType}
            type={activeType}
            data={cardData[activeType] as Parameters<typeof IDCard>[0]['data']}
            isBankCard={isBankCard}
          />
        )}
      </AnimatePresence>

      {/* ── Barre d'actions (carte uniquement) ──────────────────────────── */}
      {cardVisible && (
        <div className="action-bar">
          {canShowNearby && (
            <button className="action-btn action-btn--show" onClick={handleShowNearby}>
              👁️ Montrer aux proches
            </button>
          )}
          <button className="action-btn action-btn--close" onClick={handleCardClose}>
            ✕ Fermer
          </button>
        </div>
      )}

      <div className="close-hint">[ ESC ] pour fermer</div>
    </div>
  )
}
