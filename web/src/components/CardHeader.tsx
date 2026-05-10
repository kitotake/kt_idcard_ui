import { FrenchFlag } from './FrenchFlag'

interface CardHeaderProps {
  typeLabel: string
}

export function CardHeader({ typeLabel }: CardHeaderProps) {
  return (
    <div className="card-header">
      <div className="card-header__country">
        <FrenchFlag />
        <span className="card-header__name">République Française</span>
      </div>
      <span className="card-header__type">{typeLabel}</span>
    </div>
  )
}
