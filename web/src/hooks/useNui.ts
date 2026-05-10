import { useEffect, useCallback } from 'react'
import type { NuiPayload } from '../types'

function getResourceName(): string {
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
    } catch { /* dev mode */ }
  }, [])
}
