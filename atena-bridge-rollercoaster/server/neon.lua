-- atena-bridge-rollercoaster — NEON glow mode (server-authoritative). The client (client/neon.lua) reads
-- GlobalState.coasterNeonMode and applies the texture swap locally; this file OWNS that state: default
-- 'auto' at boot, and a privileged override (NUI button intent + console command), gated by atena's
-- can(src,'debug'). 'auto' = day/night (client decides from the synced clock); 'on'/'off' force it.
if GetResourceState('atena') ~= 'started' or GetResourceState('std-rollercoaster') ~= 'started' then return end

local VALID = { auto = true, on = true, off = true }

local function setMode(mode)
    if not VALID[mode] then return end
    GlobalState.coasterNeonMode = mode                   -- single writer; clients react on-change
end

-- boot: force the default from config (GlobalState survives restarts → don't inherit stale state).
AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then setMode('auto') end
end)

-- NUI button intent (client/neon.lua → here). source is the actor; privileged → can('debug'),
-- schema/range via VALID below. (the net-guard exempt marker must sit on the RegisterNetEvent line itself.)
RegisterNetEvent('atena-bridge-rollercoaster:neon:setMode', function(mode)  -- net-guard: exempt: privileged admin toggle, gated by exports.atena:can(src,'debug') + VALID schema/range
    local src = source
    if type(mode) ~= 'string' or not VALID[mode] then return end          -- schema + range
    if exports.atena:can(src, 'debug') then setMode(mode) end             -- deny-by-default (staff only)
end)

-- console/admin command: neon auto|on|off (src 0 = console always allowed).
RegisterCommand('neon', function(src, args)
    local mode = args[1]
    if type(mode) ~= 'string' or not VALID[mode] then
        print('[atena-bridge-rollercoaster] usage: neon <auto|on|off>')
        return
    end
    if src == 0 or exports.atena:can(src, 'debug') then setMode(mode) end
end, true)
