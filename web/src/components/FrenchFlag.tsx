export function FrenchFlag({ size = 'md' }: { size?: 'sm' | 'md' }) {
  const w = size === 'sm' ? 24 : 32
  const h = size === 'sm' ? 16 : 22
  return (
    <div className="card-flag" style={{ width: w, height: h }}>
      <div className="card-flag__b" />
      <div className="card-flag__w" />
      <div className="card-flag__r" />
    </div>
  )
}
