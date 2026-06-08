// Coaster operator control DESK (React port of the vanilla nui/app.js — same NUI contract).
// Physical controls (throw levers + a mode toggle) act on the train AT THE STATION; the screens
// only DISPLAY (map + status + read-only queue). Lua side (client/panel.lua) is unchanged:
// pushes { action: 'open'|'close'|'track'|'state' }, receives the same callback names.
import { useEffect, useState } from 'react'
import clsx from 'clsx'
import { MapMonitor } from './components/MapMonitor'
import { StatusMonitor } from './components/StatusMonitor'
import { Deck, FootBadge } from './components/Deck'
import { type FleetTrain, type PanelState, type TrackMsg } from './types'
import { post } from './nui'
import { useNuiEvent } from './hooks'

export default function App() {
  const [open, setOpen] = useState(false)
  const [prewarm, setPrewarm] = useState(true)
  const [track, setTrack] = useState<TrackMsg | null>(null)
  const [state, setState] = useState<PanelState | null>(null)
  const [draft, setDraft] = useState<FleetTrain[]>([])
  const [editing, setEditing] = useState(false)

  useNuiEvent('open', () => setOpen(true))
  useNuiEvent('close', () => setOpen(false))
  useNuiEvent<TrackMsg>('track', (d) => setTrack(d))
  useNuiEvent<PanelState & { action: string }>('state', (d) => {
    setState(d)
    // live pushes re-seed the fleet draft ONLY while not editing (don't clobber typing)
    if (!editing && d.fleet) {
      setDraft((d.fleet.trains ?? []).map((t) => ({ livery: t.livery, cars: t.cars, label: t.label ?? '', color: t.color ?? '' })))
    }
  })

  // ESC closes (Lua releases focus on the 'close' callback)
  useEffect(() => {
    if (!open) return
    const k = (e: KeyboardEvent) => {
      if (e.key === 'Escape') { setOpen(false); post('close', {}) }
    }
    window.addEventListener('keyup', k)
    return () => window.removeEventListener('keyup', k)
  }, [open])

  // Prewarm: the cabinet uses expensive SVG-noise textures + blur/shadow filters whose first
  // rasterization is what makes the first [E] feel slow. Paint the panel once (fully transparent,
  // non-interactive) at load so CEF caches those textures (nui.md §4).
  useEffect(() => {
    let r2 = 0
    const r1 = requestAnimationFrame(() => { r2 = requestAnimationFrame(() => setPrewarm(false)) })
    return () => { cancelAnimationFrame(r1); cancelAnimationFrame(r2) }
  }, [])

  const visible = open || prewarm
  const ghost = prewarm && !open ? ({ opacity: 0, pointerEvents: 'none' } as const) : undefined
  return (
    <>
      <div id="scene">
        <div id="panel" className={clsx(!visible && 'hidden')} style={ghost}>
          <div className="cabinet">
            <span className="tex tex-case" aria-hidden="true" />
            <span className="softbox" aria-hidden="true" />

            {/* engraved brand strip + cast screws (no UI chrome / hints) */}
            <div className="brandbar">
              <span className="brand">DEL PERRO · COASTER CONTROL</span>
              <span className="serial">UNIT 04 / REV C</span>
              <i className="screw tl" /><i className="screw tr" />
            </div>

            <div className="monitors">
              <MapMonitor track={track} state={state} />
              <StatusMonitor state={state} draft={draft} setDraft={setDraft} setEditing={setEditing} />
            </div>

            <Deck s={state} />
            <FootBadge s={state} />
          </div>
        </div>
      </div>

      {/* global post-processing (the lens) — ONLY while the desk is up: a permanently mounted
          vignette/grain would tint the player's screen with the panel closed (and paint for
          nothing). Prewarmed transparent with the panel so its texture is cached too. */}
      {visible ? (
        <div id="post" aria-hidden="true" style={ghost}>
          <span className="grain" />
          <span className="vignette" />
        </div>
      ) : null}
    </>
  )
}
