-- fivem/bridge/rollercoaster/atena.server.lua — wire rollercoaster <-> atena (RUNTIME only).
--
-- Bridge doctrine (.claude/rules/atena-framework.md §6): the glue lives HERE, never inside
-- rollercoaster or atena, so both stay pure/standalone. This file is INERT unless BOTH resources
-- are started — no hard `dependencies`, pure runtime detection.

if GetResourceState('atena') ~= 'started'
   or GetResourceState('std-rollercoaster') ~= 'started' then return end

-- NOTE: this closure runs in the BRIDGE's Lua state (FiveM keeps a function ref bound to its origin
-- resource). atena's `Atena.*` globals are NOT visible here — we call atena's PUBLIC exports
-- (atena/server/exports.lua) instead. That is the documented cross-resource seam.

-- ── IN: authorization wrap ────────────────────────────────────────────────────────────────
-- rollercoaster's default policy is OPEN (everyone). Here atena's role system decides who may run
-- privileged actions ('operator' | 'fleet' | 'debug') — DENY-BY-DEFAULT (no role => denied). The
-- perm name is the bare action (matches the seeded roles); namespace per-resource later if needed.
exports['std-rollercoaster']:setAuthorizer(function(src, action)
    return exports.atena:can(src, action)
end)

-- ── IN: inbound-guard wrap ────────────────────────────────────────────────────────────────
-- Route rollercoaster's inbound net validation through atena's centralized guard (arg cap +
-- per-source rate-limit + schema + distance), so every bridged resource shares ONE policy and
-- future global protections (e.g. throttling a flooder) apply everywhere at once.
exports['std-rollercoaster']:setGuard(function(opts, src, args)
    return exports.atena:checkInbound(opts, src, args)
end)

-- ── OUT: notifications ────────────────────────────────────────────────────────────────────
-- atena observes rollercoaster's PUBLIC events (rollercoaster:*) and applies its own logic
-- (logging, economy, ...). rollercoaster keeps emitting them whether or not atena is present.
-- Example — route a boarding into atena's logger (uncomment when wiring real behavior):
--   AddEventHandler('std-rollercoaster:boarded', function(seat)
--       TriggerEvent('atena:log', 'info', 'rollercoaster', ('player %s boarded seat %s'):format(source, seat))
--   end)

if GetResourceState('atena') == 'started' then
    -- one-line boot trace via atena's sink, so the bridge is visible in the server logs
    TriggerEvent('atena:log', 'info', 'bridge', 'rollercoaster<->atena bridge armed (authorizer + guard installed)')
end
