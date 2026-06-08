// Status monitor: on-screen pages STATO (readout + read-only queue) / FLOTTA (fleet editor).
// Tabs live INSIDE the monitor (the screens are the only place "pages" exist — no web chrome).
import { useState } from 'react'
import clsx from 'clsx'
import { Monitor } from './parts'
import { FleetEditor } from './FleetEditor'
import { type FleetTrain, type PanelState, type Train, phaseLabel, trainColor } from '../types'

// queue ordered by remaining distance to the station (monotonic -> no thrash): front pinned,
// platform trains above circulating ones, nearest-to-berth first.
function queueOrder(s: PanelState): Train[] {
  const front = s.stationTrain ?? 0
  return (s.trains ?? []).slice().sort((a, b) => {
    if (a.i === front) return -1
    if (b.i === front) return 1
    const aAt = a.atStation ? 0 : 1
    const bAt = b.atStation ? 0 : 1
    if (aAt !== bAt) return aAt - bAt
    return ((a.dist ?? 0) - (b.dist ?? 0)) || (a.i - b.i)
  })
}

type Props = {
  state: PanelState | null
  draft: FleetTrain[]
  setDraft: React.Dispatch<React.SetStateAction<FleetTrain[]>>
  setEditing: (v: boolean) => void   // App skips draft re-seeding from live pushes while editing
}

export function StatusMonitor({ state, draft, setDraft, setEditing }: Props) {
  const [page, setPage] = useState<'stato' | 'flotta'>('stato')
  const s = state

  const openPage = (p: 'stato' | 'flotta') => {
    setPage(p)
    setEditing(p === 'flotta')
    if (p === 'flotta' && s?.fleet) {
      // (re)seed the draft from the live fleet on entering the editor
      setDraft((s.fleet.trains ?? []).map((t) => ({ livery: t.livery, cars: t.cars, label: t.label ?? '', color: t.color ?? '' })))
    }
  }

  return (
    <Monitor kind="status">
      <div className="mon-tabs">
        <button className={clsx('mtab', page === 'stato' && 'active')} onClick={() => openPage('stato')}>STATO</button>
        <button className={clsx('mtab', page === 'flotta' && 'active')} onClick={() => openPage('flotta')}>FLOTTA</button>
      </div>

      {page === 'stato' ? (
        <div className="page" id="page-stato">
          <div className="readout">
            <div className="ro"><span>STATO</span><b>{s ? (s.held ? 'HOLD' : phaseLabel(s.phase)) : '—'}</b></div>
            <div className="ro"><span>POSTI</span><b>{s ? `${s.seats.occupied}/${s.seats.total}` : '0/0'}</b></div>
            <div className="ro"><span>PARTENZA</span><b>{s && s.countdown >= 0 ? `${Math.ceil(s.countdown)}s` : '—'}</b></div>
          </div>
          <div className="loglabel">CODA TRENI</div>
          <div className="train-status">
            {s ? queueOrder(s).map((t) => (
              <div key={t.i} className={clsx('tr-row', t.i === (s.stationTrain ?? 0) && 'front', t.held && 'held')}>
                <span className="tr-i">{t.i}</span>
                <span className="tr-dot" style={{ background: trainColor(s, t.i) }} />
                <span className="tr-live">{(t.label || t.livery || '')} ·{t.cars}</span>
                <span className="tr-ph">{t.held ? 'FERMO' : phaseLabel(t.phase)}</span>
                <span className="tr-bars">{t.bars ? 'barre giù' : 'barre su'}</span>
                <span className="tr-rid">{t.riders}/{t.seats}</span>
              </div>
            )) : null}
          </div>
        </div>
      ) : (
        <FleetEditor fleet={s?.fleet ?? null} draft={draft} setDraft={setDraft} />
      )}
    </Monitor>
  )
}
