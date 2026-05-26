import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'

interface ShopItem {
  id: string
  label: string
  desc: string
  price: number
  owned: boolean
}

interface ShopMenuProps {
  items: ShopItem[]
  onBuy: (id: string) => void
  onClose: () => void
}

export function ShopMenu({ items, onBuy, onClose }: ShopMenuProps) {
  const [confirming, setConfirming] = useState<string | null>(null)
  const [loading,    setLoading]    = useState<string | null>(null)

  function handleBuyClick(item: ShopItem) {
    if (item.owned || loading) return
    setConfirming(item.id)
  }

  function handleConfirm(item: ShopItem) {
    setLoading(item.id)
    setConfirming(null)
    onBuy(item.id)
    // L'état loading sera réinitialisé quand le serveur renvoie le résultat
    // et que le menu se rafraîchit
    setTimeout(() => setLoading(null), 3000)
  }

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.94, y: 20 }}
      animate={{ opacity: 1, scale: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.94, y: 20 }}
      transition={{ type: 'spring', stiffness: 300, damping: 26 }}
      style={{
        width: 440,
        background: 'linear-gradient(160deg, #0d1117 0%, #161b22 60%, #0d1117 100%)',
        border: '1px solid rgba(99,102,241,0.35)',
        borderRadius: 16,
        boxShadow: '0 24px 60px rgba(0,0,0,0.9), 0 0 0 1px rgba(99,102,241,0.15), 0 0 40px rgba(99,102,241,0.08)',
        overflow: 'hidden',
        fontFamily: "'Rajdhani', sans-serif",
      }}
    >
      {/* ── Header ──────────────────────────────────────────────────────── */}
      <div style={{
        padding: '14px 20px',
        background: 'rgba(99,102,241,0.12)',
        borderBottom: '1px solid rgba(99,102,241,0.2)',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ fontSize: 20 }}>📋</span>
          <div>
            <div style={{ fontFamily: 'Share Tech Mono', fontSize: 8, letterSpacing: 2, color: 'rgba(148,163,184,0.7)', textTransform: 'uppercase' }}>
              SERVICES ADMINISTRATIFS
            </div>
            <div style={{ fontFamily: 'Rajdhani', fontSize: 15, fontWeight: 700, color: '#e2e8f0', letterSpacing: 1 }}>
              OFFICIER D'ÉTAT CIVIL
            </div>
          </div>
        </div>
        <button
          onClick={onClose}
          style={{
            background: 'rgba(220,38,38,0.2)', border: '1px solid rgba(220,38,38,0.4)',
            borderRadius: 6, color: '#fca5a5', cursor: 'pointer',
            fontFamily: 'Share Tech Mono', fontSize: 10, padding: '4px 10px',
          }}
        >✕ FERMER</button>
      </div>

      {/* ── Sous-titre ──────────────────────────────────────────────────── */}
      <div style={{
        padding: '8px 20px',
        fontFamily: 'Share Tech Mono', fontSize: 9, letterSpacing: 1,
        color: 'rgba(148,163,184,0.5)',
        borderBottom: '1px solid rgba(255,255,255,0.04)',
      }}>
        Sélectionnez un document à obtenir. Le montant sera prélevé sur votre compte bancaire.
      </div>

      {/* ── Liste des articles ───────────────────────────────────────────── */}
      <div style={{ padding: '10px 14px', display: 'flex', flexDirection: 'column', gap: 6, maxHeight: 380, overflowY: 'auto' }}>
        {items.map(item => (
          <ShopItem
            key={item.id}
            item={item}
            confirming={confirming === item.id}
            loading={loading === item.id}
            onBuyClick={() => handleBuyClick(item)}
            onConfirm={() => handleConfirm(item)}
            onCancel={() => setConfirming(null)}
          />
        ))}
      </div>

      {/* ── Footer ──────────────────────────────────────────────────────── */}
      <div style={{
        padding: '8px 20px',
        borderTop: '1px solid rgba(255,255,255,0.04)',
        fontFamily: 'Share Tech Mono', fontSize: 8, letterSpacing: 1,
        color: 'rgba(148,163,184,0.3)', textAlign: 'center',
      }}>
        MAIRIE DE LOS SANTOS • SERVICE DES DOCUMENTS OFFICIELS
      </div>
    </motion.div>
  )
}

// ─── Ligne d'article ──────────────────────────────────────────────────────────

interface ShopItemProps {
  item: ShopItem
  confirming: boolean
  loading: boolean
  onBuyClick: () => void
  onConfirm: () => void
  onCancel: () => void
}

function ShopItem({ item, confirming, loading, onBuyClick, onConfirm, onCancel }: ShopItemProps) {
  const isDisabled = item.owned || loading

  return (
    <div style={{
      background: item.owned ? 'rgba(22,163,74,0.06)' : 'rgba(255,255,255,0.03)',
      border: `1px solid ${item.owned ? 'rgba(22,163,74,0.25)' : 'rgba(255,255,255,0.07)'}`,
      borderRadius: 10,
      padding: '10px 14px',
      display: 'flex', alignItems: 'center', gap: 12,
      transition: 'all 0.15s',
    }}>
      {/* Infos */}
      <div style={{ flex: 1 }}>
        <div style={{
          fontFamily: 'Rajdhani', fontSize: 14, fontWeight: 600,
          color: item.owned ? '#4ade80' : '#e2e8f0',
          display: 'flex', alignItems: 'center', gap: 6,
        }}>
          {item.label}
          {item.owned && (
            <span style={{
              fontFamily: 'Share Tech Mono', fontSize: 8, padding: '1px 6px',
              background: 'rgba(22,163,74,0.2)', border: '1px solid rgba(22,163,74,0.4)',
              borderRadius: 99, color: '#4ade80', letterSpacing: 1,
            }}>POSSÉDÉ</span>
          )}
        </div>
        <div style={{ fontFamily: 'Share Tech Mono', fontSize: 9, color: 'rgba(148,163,184,0.6)', marginTop: 2 }}>
          {item.desc}
        </div>
      </div>

      {/* Prix + bouton */}
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 5, flexShrink: 0 }}>
        <div style={{
          fontFamily: 'Share Tech Mono', fontSize: 13, fontWeight: 700,
          color: item.owned ? 'rgba(74,222,128,0.5)' : '#fbbf24',
        }}>
          ${item.price.toLocaleString('fr-FR')}
        </div>

        <AnimatePresence mode="wait">
          {confirming ? (
            /* Zone de confirmation */
            <motion.div
              key="confirm"
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              style={{ display: 'flex', gap: 4 }}
            >
              <button
                onClick={onConfirm}
                style={{
                  padding: '4px 10px', borderRadius: 5, cursor: 'pointer',
                  background: 'rgba(22,163,74,0.3)', border: '1px solid rgba(22,163,74,0.6)',
                  color: '#4ade80', fontFamily: 'Share Tech Mono', fontSize: 9, letterSpacing: 1,
                }}
              >✓ OUI</button>
              <button
                onClick={onCancel}
                style={{
                  padding: '4px 10px', borderRadius: 5, cursor: 'pointer',
                  background: 'rgba(220,38,38,0.2)', border: '1px solid rgba(220,38,38,0.4)',
                  color: '#fca5a5', fontFamily: 'Share Tech Mono', fontSize: 9, letterSpacing: 1,
                }}
              >✗ NON</button>
            </motion.div>
          ) : (
            /* Bouton acheter */
            <motion.button
              key="buy"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={onBuyClick}
              disabled={isDisabled}
              style={{
                padding: '5px 14px', borderRadius: 6, cursor: isDisabled ? 'not-allowed' : 'pointer',
                background: item.owned
                  ? 'rgba(22,163,74,0.1)'
                  : loading
                    ? 'rgba(99,102,241,0.2)'
                    : 'rgba(99,102,241,0.25)',
                border: `1px solid ${item.owned ? 'rgba(22,163,74,0.3)' : 'rgba(99,102,241,0.5)'}`,
                color: item.owned ? '#4ade80' : loading ? '#a5b4fc' : '#c7d2fe',
                fontFamily: 'Share Tech Mono', fontSize: 9, letterSpacing: 1,
                opacity: isDisabled && !item.owned ? 0.6 : 1,
                transition: 'all 0.15s',
              }}
            >
              {item.owned ? '✓ OBTENU' : loading ? '...' : 'ACHETER'}
            </motion.button>
          )}
        </AnimatePresence>
      </div>
    </div>
  )
}
