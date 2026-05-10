import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faShieldHalved } from '@fortawesome/free-solid-svg-icons'

interface ShownByProps {
  name: string
  label: string
}

export function ShownBy({ name, label }: ShownByProps) {
  return (
    <div className="shown-by">
      <span className="shown-by__label">{label}</span>
      <span className="shown-by__badge">
        <FontAwesomeIcon icon={faShieldHalved} />
        {name}
      </span>
    </div>
  )
}
