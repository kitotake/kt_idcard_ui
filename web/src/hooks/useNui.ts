import { useEffect, useCallback } from 'react'
import type { NuiPayload } from '../types'

function getResourceName(): string {
  return (window as Window & { location: Location }).location.hostname || 'kt_idcard_ui'
}

export function useNuiMessage(handler: (payload: NuiPayload) => void) {
  useEffect(() => {
    const listener = (event: MessageEvent) => {
      const data = event.data as NuiPayload
      if (data && data.action) {
        handler(data)
      }
    }
    window.addEventListener('message', listener)
    return () => window.removeEventListener('message', listener)
  }, [handler])
}

export function useNuiFetch() {
  const fetchNui = useCallback(async (endpoint: string, data: unknown = {}): Promise<void> => {
    const resourceName = getResourceName()
    try {
      await fetch(`https://${resourceName}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      })
    } catch {
      // In dev mode outside FiveM, fetch will fail — that's expected
    }
  }, [])

  return fetchNui
}
