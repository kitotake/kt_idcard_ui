import type { IdentityPayload } from '../types'
import { CardHeader } from './CardHeader'
import { ShownBy } from './ShownBy'

// MRZ helpers
function padMRZ(str: string | undefined, len: number): string {
  return (str ?? '').toUpperCase().replace(/[^A-Z0-9]/g, '<').padEnd(len, '<')
}

function buildMRZ(lastname: string, firstname: string, uniqueId: string): string {
  const ln  = padMRZ(lastname, 13)
  const fn  = padMRZ(firstname, 12)
  const uid = padMRZ(uniqueId, 9).slice(0, 9)
  return `IDFRAX${uid}<<<<<<\n${ln}<<${fn}`
}

// Gender icon – inline SVG to avoid FA dependency on generic person icon
function PersonIcon({ female }: { female: boolean }) {
  return female ? (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.5}>
      <circle cx={12} cy={7} r={4} />
      <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" />
      <path d="M12 17v4M10 19h4" strokeLinecap="round" />
    </svg>
  ) : (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.5}>
      <circle cx={12} cy={7} r={4} />
      <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" />
    </svg>
  )
}

interface Props {
  data: IdentityPayload
}

export function IdentityView({ data }: Props) {
  const isFemale = data.ped_model === 'mp_f_freemode_01'
  const typeLabel = data.is_police_check ? "CONTRÔLE D'IDENTITÉ" : 'CARTE NATIONALE D\'IDENTITÉ'
  const mrz = buildMRZ(data.lastname, data.firstname, data.unique_id)

  return (
    <>
      <CardHeader typeLabel={typeLabel} />

      <div className="card-body">
        <div className="card-photo">
          <PersonIcon female={isFemale} />
        </div>

        <div className="card-info">
          <div className="card-name">
            <span>{(data.lastname ?? '').toUpperCase()}</span>{' '}
            <span className="card-name__first">{data.firstname}</span>
          </div>

          <div className="fields">
            <div className="field">
              <span className="field__label">Date de naissance</span>
              <span className="field__value">{data.dateofbirth || '—'}</span>
            </div>
            <div className="field">
              <span className="field__label">Sexe</span>
              <span className="field__value">{isFemale ? 'F' : 'M'}</span>
            </div>
            <div className="field field--full">
              <span className="field__label">Profession</span>
              <span className="field__value">{data.job_label || data.job || 'Sans emploi'}</span>
            </div>
            <div className="field field--full">
              <span className="field__label">Identifiant unique</span>
              <span className="field__value field__value--mono">{data.unique_id || '—'}</span>
            </div>
          </div>
        </div>
      </div>

      <div className="card-footer">
        <pre className="mrz">{mrz}</pre>
        <div className="chip" />
      </div>

      {data.shown_by && (
        <ShownBy
          name={data.shown_by}
          label={data.is_police_check ? 'Contrôlé par' : 'Présentée par'}
        />
      )}
    </>
  )
}