// Generates a pseudo-random barcode from a string seed
export function Barcode({ seed = 'default' }: { seed?: string }) {
  const bars: { width: number; height: number }[] = []
  let hash = 0
  for (let i = 0; i < seed.length; i++) {
    hash = (hash * 31 + seed.charCodeAt(i)) & 0xffffffff
  }

  for (let i = 0; i < 48; i++) {
    hash = ((hash * 1664525 + 1013904223) & 0xffffffff) >>> 0
    const w = (hash % 3) === 0 ? 3 : (hash % 5) === 0 ? 2 : 1
    const h = 20 + (hash % 12)
    bars.push({ width: w, height: h })
  }

  return (
    <div className="card-barcode">
      {bars.map((b, i) => (
        <div
          key={i}
          className="card-barcode__bar"
          style={{ width: b.width, height: b.height }}
        />
      ))}
    </div>
  )
}

// SVG guillochis/rosette pattern for the holographic background
export function GuillochesBg() {
  return (
    <div className="card-guilloches">
      <svg viewBox="0 0 520 260" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMid slice">
        {/* Circular wave patterns */}
        {[0, 1, 2, 3, 4].map(i => (
          <circle
            key={`c${i}`}
            cx={60 + i * 100}
            cy={130}
            r={80 + i * 10}
            fill="none"
            stroke="#1a4a8a"
            strokeWidth="0.4"
            opacity="0.6"
          />
        ))}
        {/* Fine line hatching */}
        {Array.from({ length: 30 }, (_, i) => (
          <line
            key={`h${i}`}
            x1={0} y1={i * 9}
            x2={520} y2={i * 9}
            stroke="#1a4a8a" strokeWidth="0.3" opacity="0.3"
          />
        ))}
        {/* Diagonal lines */}
        {Array.from({ length: 20 }, (_, i) => (
          <line
            key={`d${i}`}
            x1={-100 + i * 36} y1={0}
            x2={-100 + i * 36 + 200} y2={260}
            stroke="#1a4a8a" strokeWidth="0.3" opacity="0.25"
          />
        ))}
        {/* Rosette at top-left */}
        {Array.from({ length: 12 }, (_, i) => (
          <ellipse
            key={`r${i}`}
            cx={50} cy={30}
            rx={25} ry={10}
            fill="none"
            stroke="#1a4a8a" strokeWidth="0.35" opacity="0.5"
            transform={`rotate(${i * 30} 50 30)`}
          />
        ))}
        {/* Rosette at bottom-right */}
        {Array.from({ length: 12 }, (_, i) => (
          <ellipse
            key={`rr${i}`}
            cx={470} cy={230}
            rx={25} ry={10}
            fill="none"
            stroke="#1a4a8a" strokeWidth="0.35" opacity="0.5"
            transform={`rotate(${i * 30} 470 230)`}
          />
        ))}
        {/* Wave lines across middle */}
        {Array.from({ length: 6 }, (_, i) => {
          const y = 80 + i * 20
          const pts = Array.from({ length: 53 }, (__, j) =>
            `${j * 10},${y + Math.sin(j * 0.5 + i) * 8}`
          ).join(' ')
          return (
            <polyline
              key={`w${i}`}
              points={pts}
              fill="none"
              stroke="#1a4a8a" strokeWidth="0.35" opacity="0.4"
            />
          )
        })}
      </svg>
    </div>
  )
}
