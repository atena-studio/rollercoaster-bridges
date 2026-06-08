// Physical control deck: indicator lamps + three throw levers + the mode toggle.
// Levers act on the train AT THE STATION (server resolves the front); feedback (denials)
// is NOT shown here — the bridge routes it to atena's notifications.
import { useState } from 'react'
import { Led, Lever, ModeToggle } from './parts'
import { type PanelState } from '../types'
import { post } from '../nui'

export function Deck({ s }: { s: PanelState | null }) {
  const [pulled, setPulled] = useState(false)
  if (!s) return null

  const auto = s.mode === 'auto'
  const present = !!s.operatorPresent
  const npcRunning = auto && present // NPC has the desk -> manual controls locked
  const atStation = (s.stationTrain ?? 0) !== 0
  const canDispatch = !!s.canDispatch && !npcRunning && !s.held

  const pullDispatch = () => {
    setPulled(true)
    window.setTimeout(() => setPulled(false), 220)
    post('dispatch', {})
  }

  return (
    <div className="deck">
      <span className="tex tex-deck" aria-hidden="true" />

      <div className="leds">
        <Led color="red" on={s.phase === 'running' && !s.held} label="CORSA" />
        <Led color="grn" on={s.phase === 'loading'} label="STAZIONE" />
        <Led color="amber" on={!!s.bars} label="BARRE" />
        <Led color="red" on={!!s.held} label="HOLD" />
      </div>

      <div className="controls">
        <Lever
          down={!!s.bars} lit={!!s.bars}
          disabled={npcRunning || !atStation || !!s.held}
          plate="BARRE"
          onPull={() => post('bars', { down: !s.bars })}
        />
        <Lever
          role="go"
          blink={canDispatch} lit={s.phase === 'running'} pulled={pulled}
          disabled={!canDispatch}
          plate="PARTENZA"
          onPull={pullDispatch}
        />
        <Lever
          role="stop"
          down={!!s.held} blink={!!s.held}
          disabled={npcRunning}
          plate={s.held ? 'RIPRENDI' : 'EMERGENZA'}
          onPull={() => post('estop', {})}
        />
        <ModeToggle
          auto={auto}
          busy={auto && !present}
          note={!auto ? 'manuale' : present ? 'auto' : 'in arrivo…'}
          onFlip={() => post(auto ? 'dismissOperator' : 'callOperator', {})}
        />
      </div>
    </div>
  )
}

export function FootBadge({ s }: { s: PanelState | null }) {
  if (!s) return null
  const auto = s.mode === 'auto'
  const present = !!s.operatorPresent
  const npcRunning = auto && present
  return (
    <div className="foot">
      <span className={npcRunning ? 'mode-auto' : 'mode-manual'} id="mode-badge">
        {auto ? (present ? 'AUTO' : 'AUTO · assente') : 'MANUALE'}
      </span>
    </div>
  )
}
