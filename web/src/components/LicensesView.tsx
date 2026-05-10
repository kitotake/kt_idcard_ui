import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faCar, faMotorcycle, faTruck, faTaxi, faIdCard, faShieldHalved } from '@fortawesome/free-solid-svg-icons'
import type { LicensesPayload } from '../types'
import { FrenchFlag } from './FrenchFlag'
import { GuillochesBg } from './GuillochesBg'

const FA_MAP: Record<string, typeof faCar> = {
  'fas fa-car':        faCar,
  'fas fa-motorcycle': faMotorcycle,
  'fas fa-truck':      faTruck,
  'fas fa-taxi':       faTaxi,
  'fas fa-id-card':    faIdCard,
}

function resolveIcon(cls: string) {
  return FA_MAP[cls] ?? faIdCard
}

function PersonPlaceholder() {
  return (
    <svg viewBox="0 0 52 62" fill="none" style={{ width: '100%', height: '100%' }}>
      <rect width="52" height="62" fill="rgba(30,80,140,0.08)" />
      <circle cx="26" cy="20" r="12" fill="rgba(30,80,140,0.25)" />
      <path d="M4 58 C4 42 48 42 48 58" fill="rgba(30,80,140,0.25)" />
    </svg>
  )
}

interface Props {
  data: LicensesPayload
  capturedPhoto: string | null
}

export function LicensesView({ data, capturedPhoto }: Props) {
  const displayPhoto = capturedPhoto ?? data.photo ?? null

  return (
    <div className="lic-card">
      <GuillochesBg />

      <div className="lic-header">
        <div className="card-top__left">
          <FrenchFlag size="sm" />
          <span className="card-top__country" style={{ fontSize: 9 }}>République Française</span>
        </div>
        <span className="lic-title">PERMIS DE CONDUIRE</span>
      </div>

      {/* Owner strip */}
      <div className="lic-owner">
        <div className="lic-owner-photo">
          {displayPhoto
            ? <img src={displayPhoto} alt="" />
            : <div className="lic-owner-photo__placeholder"><PersonPlaceholder /></div>
          }
        </div>
        <div className="lic-owner-info">
          <div className="lic-owner-info__name">
            {(data.lastname ?? '').toUpperCase()} {data.firstname}
          </div>
          <div className="lic-owner-info__uid">{data.unique_id}</div>
        </div>
      </div>

      <div className="lic-list">
        {(data.licenses ?? []).map(lic => (
          <div key={lic.type} className={`lic-item ${lic.valid ? 'lic-item--valid' : 'lic-item--invalid'}`}>
            <div className="lic-item__icon">
              <FontAwesomeIcon icon={resolveIcon(lic.icon)} />
            </div>
            <div className="lic-item__info">
              <div className="lic-item__name">{lic.label}</div>
              <div className="lic-item__status">{lic.valid ? 'Valide' : 'Non obtenu'}</div>
            </div>
            <span className="lic-item__badge">{lic.valid ? 'VALIDE' : 'ABSENT'}</span>
          </div>
        ))}
      </div>

      {data.checked_by && (
        <div className="police-banner">
          <FontAwesomeIcon icon={faShieldHalved} />
          <span>Contrôlé par —</span>
          <span className="police-banner__name">{data.checked_by}</span>
        </div>
      )}
    </div>
  )
}
