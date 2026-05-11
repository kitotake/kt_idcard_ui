import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faCar, faMotorcycle, faTruck, faTaxi, faGraduationCap, faIdCard } from '@fortawesome/free-solid-svg-icons'
import type { DrivingMenuPayload } from '../types'
import { FrenchFlag } from './FrenchFlag'
import { GuillochesBg } from './GuillochesBg'
import { useNuiFetch } from '../hooks/useNui'

const FA_MAP: Record<string, typeof faCar> = {
  'fas fa-car':        faCar,
  'fas fa-motorcycle': faMotorcycle,
  'fas fa-truck':      faTruck,
  'fas fa-taxi':       faTaxi,
  'fas fa-id-card':    faIdCard,
}

function resolveIcon(cls: string) {
  return FA_MAP[cls] ?? faGraduationCap
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
    <div className="drv-card">
      <GuillochesBg />

      <div className="drv-header">
        <div className="card-top__left">
          <FrenchFlag size="sm" />
          <span className="card-top__country" style={{ fontSize: 9 }}>République Française</span>
        </div>
        <span className="drv-title">AUTO-ÉCOLE</span>
      </div>

      <div className="drv-list">
        {(data.licenses ?? []).map((lic: typeof data.licenses[number]) => (
          <div
            key={lic.type}
            className={`drv-item ${lic.owned ? 'drv-item--owned' : ''}`}
            onClick={() => !lic.owned && handleSelect(lic.type)}
          >
            <div className="drv-item__icon">
              <FontAwesomeIcon icon={resolveIcon(lic.icon)} />
            </div>
            <div>
              <div className="drv-item__label">{lic.label}</div>
              {lic.owned && <div className="drv-item__tag">✓ Déjà obtenu</div>}
            </div>
          </div>
        ))}
      </div>

      <div className="drv-hint">Cliquez sur un permis pour passer l'examen</div>
    </div>
  )
}
