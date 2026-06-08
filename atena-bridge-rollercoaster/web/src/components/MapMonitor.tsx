// Live circuit map. The server pushes car dots at ~6.6Hz (150ms); rendering them raw makes the
// dots STEP along the track. We keep LOCAL float positions, ease them toward the latest server
// position every animation frame (snap on big jumps — teleport/spawn), and update the SVG
// imperatively via refs so the 60Hz interpolation never re-renders React (nui.md §3).
import { useEffect, useRef } from 'react'
import { Monitor } from './parts'
import { type CarDot, type PanelState, type TrackMsg, trainColor } from '../types'

const SVGNS = 'http://www.w3.org/2000/svg'
const SNAP_DIST = 40 // svg units: a jump bigger than this is a respawn, not motion — snap, don't glide

export function MapMonitor({ track, state }: { track: TrackMsg | null; state: PanelState | null }) {
  const carsRef = useRef<SVGGElement>(null)
  const target = useRef<CarDot[]>([])
  const local = useRef<{ x: number; y: number }[]>([])
  const stateRef = useRef<PanelState | null>(null)
  stateRef.current = state
  target.current = state?.cars ?? []

  // 60Hz easing loop — imperative SVG updates only, zero React re-renders.
  useEffect(() => {
    let raf = 0
    let last = 0
    const tick = (now: number) => {
      const dt = last ? (now - last) / 1000 : 0
      last = now
      const g = carsRef.current
      if (g) {
        const tgt = target.current
        // sync circle count
        while (g.children.length < tgt.length) {
          const c = document.createElementNS(SVGNS, 'circle')
          c.setAttribute('r', '3.5')
          g.appendChild(c)
        }
        while (g.children.length > tgt.length) g.removeChild(g.lastChild!)
        const k = Math.min(1, dt * 10) // ease factor: ~100ms to close a 150ms push gap
        tgt.forEach((p, i) => {
          let l = local.current[i]
          const far = !l || Math.hypot(p.x - l.x, p.y - l.y) > SNAP_DIST
          if (far) l = { x: p.x, y: p.y }
          else { l.x += (p.x - l.x) * k; l.y += (p.y - l.y) * k }
          local.current[i] = l
          const c = g.children[i] as SVGCircleElement
          c.setAttribute('cx', String(l.x))
          c.setAttribute('cy', String(l.y))
          const s = stateRef.current
          const t = (s?.trains ?? []).find((x) => x.i === p.t)
          c.setAttribute('fill', t?.held ? '#ff3b30' : trainColor(s, p.t))
        })
        local.current.length = tgt.length
      }
      raf = requestAnimationFrame(tick)
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [])

  const pts = (track?.points ?? []).map((p) => `${p.x},${p.y}`).join(' ')
  return (
    <Monitor kind="map">
      <div className="mon-title">MAPPA CIRCUITO</div>
      <svg className="map" viewBox="0 0 520 188" preserveAspectRatio="xMidYMid meet">
        <polyline fill="none" stroke="#1c7a33" strokeWidth="4" strokeLinejoin="round" strokeLinecap="round" points={pts} />
        <polyline fill="none" stroke="#36d860" strokeWidth="2" strokeLinejoin="round" opacity="0.5" points={pts} />
        {track?.station ? <circle r="5" fill="none" stroke="#a9ffc6" strokeWidth="2" cx={track.station.x} cy={track.station.y} /> : null}
        <g ref={carsRef} id="cars" />
      </svg>
    </Monitor>
  )
}
