// web/src/hooks/useNui.ts
// Bridge FiveM NUI ↔ React
//
// En production FiveM : window.location.hostname retourne le nom de la resource
// En dev Vite (localhost) : les fetch échouent silencieusement (catch vide),
// ce qui est intentionnel — seule la partie visuelle est testée en dev.

import { useEffect, useCallback } from 'react'
import type { NuiPayload } from '../types'

function getResourceName(): string {
  // FiveM injecte le nom de la resource comme hostname de la page NUI.
  // En développement local (Vite), hostname = "localhost".
  return window.location.hostname || 'kt_idcard_ui'
}

export function useNuiMessage(handler: (p: NuiPayload) => void) {
  useEffect(() => {
    const fn = (e: MessageEvent) => {
      const d = e.data as NuiPayload
      if (d?.action) handler(d)
    }
    window.addEventListener('message', fn)
    return () => window.removeEventListener('message', fn)
  }, [handler])
}

export function useNuiFetch() {
  return useCallback(async (endpoint: string, data: unknown = {}) => {
    try {
      await fetch(`https://${getResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      })
    } catch {
      // Échec silencieux en dev (localhost ne répond pas au NUI fetch).
      // En production FiveM ce bloc ne devrait jamais s'exécuter.
    }
  }, [])
}
