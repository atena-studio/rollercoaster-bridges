// State contract pushed by client/panel.lua (exports.rollercoaster:getPanelState() + 'track').
export type Train = {
  i: number
  cars: number
  seats: number
  riders: number
  phase: 'loading' | 'running' | 'queued' | string
  bars: boolean
  held?: boolean
  atStation?: boolean
  dist?: number
  livery?: string
  label?: string
  color?: string
}
export type FleetTrain = { livery: string; cars: number; label?: string; color?: string }
export type Fleet = {
  trains: FleetTrain[]
  liveries?: string[]
  maxTrains: number
  maxCarsPerTrain: number
  maxTotalCars: number
}
export type CarDot = { t: number; x: number; y: number }
export type PanelState = {
  mode: 'manual' | 'auto'
  operatorPresent?: boolean
  phase: string
  held?: boolean
  bars?: boolean
  canDispatch?: boolean
  countdown: number
  seats: { occupied: number; total: number }
  stationTrain?: number
  trains?: Train[]
  cars?: CarDot[]
  fleet?: Fleet
}
export type TrackMsg = { points?: { x: number; y: number }[]; station?: { x: number; y: number } }

export const CAR_PALETTE = ['#ff5b4d', '#ffe24a', '#4db5ff', '#7dff8a', '#c77dff', '#ff9d4d', '#4dffd0', '#ff6fae']
export const trainColor = (s: PanelState | null, i: number): string => {
  const t = (s?.trains ?? []).find((x) => x.i === i)
  if (t?.color) return t.color
  const n = CAR_PALETTE.length
  return CAR_PALETTE[((((i || 1) - 1) % n) + n) % n]
}
const PHASE_LABEL: Record<string, string> = { loading: 'STAZIONE', running: 'IN CORSA', queued: 'IN CODA' }
export const phaseLabel = (p?: string) => PHASE_LABEL[p ?? ''] ?? (p ?? '').toUpperCase()
