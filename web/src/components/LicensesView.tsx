import { library } from '@fortawesome/fontawesome-svg-core'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import {
  faCar, faMotorcycle, faTruck, faTaxi, faIdCard,
} from '@fortawesome/free-solid-svg-icons'
import type { LicensesPayload } from '../types'
import { CardHeader } from './CardHeader'
import { ShownBy } from './ShownBy'

library.add(faCar, faMotorcycle, faTruck, faTaxi, faIdCard)

// Map FA class strings like "fas fa-car" to icon names
const FA_MAP: Record<string, typeof faCar> = {
  'fas fa-car':        faCar,
  'fas fa-motorcycle': faMotorcycle,
  'fas fa-truck':      faTruck,
  'fas fa-taxi':       faTaxi,
  'fas fa-id-card':    faIdCard,
}

function resolveIcon(iconClass: string) {
  return FA_MAP[iconClass] ?? faIdCard
}

interface Props {
  data: LicensesPayload
}

export function LicensesView({ data }: Props) {
  const typeLabel = data.checked_by ? 'CONTRÔLE PERMIS' : 'PERMIS DE CONDUIRE'

  return (
    <>
      <CardHeader typeLabel={typeLabel} />

      <div className="license-header">
        <div className="card-name card-name--small">
          <span>{(data.lastname ?? '').toUpperCase()}</span>{' '}
          <span className="card-name__first">{data.firstname}</span>
        </div>
        <div className="license-header__sub">{data.unique_id || '—'}</div>
      </div>

      <div className="license-list">
        {(data.licenses ?? []).map((lic) => (
          <div
            key={lic.type}
            className={`license-item ${lic.valid ? 'license-item--valid' : 'license-item--invalid'}`}
          >
            <div className="license-item__icon">
              <FontAwesomeIcon icon={resolveIcon(lic.icon)} />
            </div>
            <div className="license-item__info">
              <div className="license-item__name">{lic.label}</div>
              <div className="license-item__status">{lic.valid ? 'Valide' : 'Non obtenu'}</div>
            </div>
            <span className="license-item__badge">{lic.valid ? 'VALIDE' : 'ABSENT'}</span>
          </div>
        ))}
      </div>

      {data.checked_by && (
        <ShownBy name={data.checked_by} label="Contrôlé par" />
      )}
    </>
  )
}
