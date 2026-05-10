import { useState, useCallback } from 'react'
import type {
  NuiPayload,
  IdentityPayload,
  LicensesPayload,
  DrivingMenuPayload,
  ViewMode,
} from './types'
import { useNuiMessage, useNuiFetch } from './hooks/useNui'
import { IdentityView } from './components/IdentityView'
import { LicensesView } from './components/LicensesView'
import { DrivingMenuView } from './components/DrivingMenuView'
import './styles/main.scss'

// ─── Dev mock data (shown when running outside FiveM) ────────────────────────

const DEV_MOCK: IdentityPayload = {
  action: 'showIdentity',
  firstname: 'Jean',
  lastname: 'Dupont',
  dateofbirth: '14/07/1990',
  unique_id: 'FR-2847391',
  ped_model: 'mp_m_freemode_01',
  job: 'police',
  job_label: 'Agent de Police',
}

const IS_DEV = import.meta.env.DEV

// ─────────────────────────────────────────────────────────────────────────────

export function App() {
  const fetchNui = useNuiFetch()

  const [visible, setVisible] = useState(IS_DEV)
  const [viewMode, setViewMode] = useState<ViewMode>(IS_DEV ? 'identity' : null)
  const [identityData, setIdentityData] = useState<IdentityPayload | null>(IS_DEV ? DEV_MOCK : null)
  const [licensesData, setLicensesData] = useState<LicensesPayload | null>(null)
  const [drivingData, setDrivingData] = useState<DrivingMenuPayload | null>(null)

  const handleClose = useCallback(() => {
    setVisible(false)
    setViewMode(null)
    fetchNui('idcard:close', {})
  }, [fetchNui])

  const handleNuiMessage = useCallback((payload: NuiPayload) => {
    switch (payload.action) {
      case 'showIdentity':
        setIdentityData(payload)
        setViewMode('identity')
        setVisible(true)
        break

      case 'showLicenses':
        setLicensesData(payload)
        setViewMode('licenses')
        setVisible(true)
        break

      case 'showDrivingMenu':
        setDrivingData(payload)
        setViewMode('driving')
        setVisible(true)
        break

      case 'hideIdentity':
        setVisible(false)
        setViewMode(null)
        break
    }
  }, [])

  useNuiMessage(handleNuiMessage)

  // Close on E key
  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'e' || e.key === 'E') {
      handleClose()
    }
  }, [handleClose])

  return (
    <div
      className={`overlay ${visible ? 'visible' : ''}`}
      onKeyDown={handleKeyDown}
      tabIndex={-1}
    >
      <div className="card-wrapper">
        <div className="card">
          {viewMode === 'identity' && identityData && (
            <IdentityView data={identityData} />
          )}
          {viewMode === 'licenses' && licensesData && (
            <LicensesView data={licensesData} />
          )}
          {viewMode === 'driving' && drivingData && (
            <DrivingMenuView data={drivingData} onClose={handleClose} />
          )}
        </div>
        <div className="close-hint">Appuyez sur [E] pour fermer</div>
      </div>
    </div>
  )
}
