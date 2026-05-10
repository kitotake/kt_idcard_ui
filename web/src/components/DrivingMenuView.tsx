import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import {
  faCar, faMotorcycle, faTruck, faTaxi, faGraduationCap, faIdCard,
} from '@fortawesome/free-solid-svg-icons'
import type { DrivingMenuPayload } from '../types'
import { CardHeader } from './CardHeader'
import { useNuiFetch } from '../hooks/useNui'

const FA_MAP: Record<string, typeof faCar> = {
  'fas fa-car':        faCar,
  'fas fa-motorcycle': faMotorcycle,
  'fas fa-truck':      faTruck,
  'fas fa-taxi':       faTaxi,
  'fas fa-id-card':    faIdCard,
}

function resolveIcon(iconClass: string) {
  return FA_MAP[iconClass] ?? faGraduationCap
}

interface Props {
  data: DrivingMenuPayload
  onClose: () => void
}

export function DrivingMenuView({ data, onClose }: Props) {
  const fetchNui = useNuiFetch()

  function handleSelect(licType: string) {
    fetchNui('idcard:selectLicense', { type: licType })
    onClose()
  }

  return (
    <>
      <CardHeader typeLabel="AUTO-ÉCOLE" />

      <div className="driving-header">
        <div className="driving-header__title">Choisissez votre permis</div>
        <div className="driving-header__sub">Auto-école officielle</div>
      </div>

      <div className="driving-list">
        {(data.licenses ?? []).map((lic) => (
          <div
            key={lic.type}
            className={`driving-item ${lic.owned ? 'driving-item--owned' : ''}`}
            onClick={() => !lic.owned && handleSelect(lic.type)}
          >
            <div className="driving-item__icon">
              <FontAwesomeIcon icon={resolveIcon(lic.icon)} />
            </div>
            <div>
              <div className="driving-item__label">{lic.label}</div>
              {lic.owned && <div className="driving-item__owned-tag">✓ Déjà obtenu</div>}
            </div>
          </div>
        ))}
      </div>

      <div className="driving-hint">Cliquez sur un permis pour passer l'examen</div>
    </>
  )
}
