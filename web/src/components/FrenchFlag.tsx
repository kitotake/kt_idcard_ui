// web/src/components/FrenchFlag.tsx
export function FrenchFlag({ size = 'md' }: { size?: 'sm' | 'md' }) {
  const w = size === 'sm' ? 24 : 32
  const h = size === 'sm' ? 16 : 22
  return (
    <div className="card-flag" style={{ width: w, height: h, display: 'flex', overflow: 'hidden', borderRadius: 2 }}>
      <div style={{ flex: 1, background: '#002395' }} />
      <div style={{ flex: 1, background: '#ffffff' }} />
      <div style={{ flex: 1, background: '#ED2939' }} />
    </div>
  )
}
