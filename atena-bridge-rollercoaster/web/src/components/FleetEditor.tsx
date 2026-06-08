// FLOTTA page — fleet composition editor (terminal styled, lives on the status monitor).
// Local draft buffer; APPLICA posts the whole draft as the 'setFleet' intent (server validates).
import { type Fleet, type FleetTrain, CAR_PALETTE } from '../types'
import { post } from '../nui'

type Props = {
  fleet: Fleet | null
  draft: FleetTrain[]
  setDraft: React.Dispatch<React.SetStateAction<FleetTrain[]>>
}

export function FleetEditor({ fleet, draft, setDraft }: Props) {
  const liveries = fleet?.liveries?.length ? fleet.liveries : ['classic', 'dlc']
  const maxTrains = fleet?.maxTrains ?? 2
  const maxCarsPerTrain = fleet?.maxCarsPerTrain ?? 4
  const maxTotalCars = fleet?.maxTotalCars ?? 8
  const used = draft.reduce((a, t) => a + t.cars, 0)

  const patch = (i: number, p: Partial<FleetTrain>) =>
    setDraft((d) => d.map((t, k) => (k === i ? { ...t, ...p } : t)))

  return (
    <div className="page" id="page-flotta">
      <div className="fleet-head">
        <span>COMPOSIZIONE</span>
        <span className="budget">
          CARRELLI <b>{used}</b>/<b>{maxTotalCars}</b>
        </span>
      </div>
      <div className="train-list">
        {draft.map((t, i) => (
          <div className="train-row" key={i}>
            <span className="idx">{i + 1}</span>
            <input
              className="tr-color" type="color" title="Colore mappa"
              value={t.color || CAR_PALETTE[i % CAR_PALETTE.length]}
              onChange={(e) => patch(i, { color: e.target.value })}
            />
            <input
              className="tr-label" type="text" maxLength={24} placeholder={t.livery}
              value={t.label ?? ''}
              onChange={(e) => patch(i, { label: e.target.value })}
            />
            <select value={t.livery} onChange={(e) => patch(i, { livery: e.target.value })}>
              {liveries.map((l) => <option key={l} value={l}>{l}</option>)}
            </select>
            <div className="stepper">
              <button onClick={() => { if (t.cars > 1) patch(i, { cars: t.cars - 1 }) }}>−</button>
              <span className="n">{t.cars}</span>
              <button onClick={() => { if (t.cars < maxCarsPerTrain && used < maxTotalCars) patch(i, { cars: t.cars + 1 }) }}>+</button>
            </div>
            <button className="rm" onClick={() => { if (draft.length > 1) setDraft((d) => d.filter((_, k) => k !== i)) }}>✕</button>
          </div>
        ))}
      </div>
      <div className="fleet-actions">
        <button
          disabled={draft.length >= maxTrains || used >= maxTotalCars}
          onClick={() => setDraft((d) => [...d, { livery: liveries[0] ?? 'classic', cars: 1, label: '', color: '' }])}
        >
          + TRENO
        </button>
        <button className="primary" onClick={() => post('setFleet', { trains: draft })}>APPLICA</button>
      </div>
      <div className="hint">Solo a giostra ferma e vuota.</div>
    </div>
  )
}
