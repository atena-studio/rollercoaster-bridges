-- atena-bridge-rollercoaster debug — MENU: registers the launcher entries (DATA only; closures kept HERE keyed
-- by id, atena fires `atena:debug:invoke`), the card toggles (open/close + persist), the FLAGS bool-toggle
-- handling, and the seat-calibration poke. Reads/writes the shared `Dbg` (state + helpers from core).
-- ROBUST: no permanent top-guard bail (load-order race kills the entries forever). reg() stores the closure
-- ALWAYS and only calls atena's export when atena is up; registerAll re-fires on atena:debug:ready/refresh +
-- onResourceStart('atena') (below) → the entries reliably (re)appear. atena-framework §6.

local closures = {}
-- toggle/value: a panel entry is an on/off TOGGLE in the launcher (inline badge, like godmode) —
-- value = whether its card is currently pushed. Plain actions omit them (simple pick).
-- peek = true → the entry hover-previews its card (peekWin = its own window id = fid). Only DATA
-- panels set it; feature/workbench cards (flags/seatcalib) omit it. cards.lua serves the preview.
local function reg(id, label, icon, fn, toggle, value, peek)
    local fid = 'coaster:' .. id
    closures[fid] = fn
    if GetResourceState('atena') == 'started' then
        exports.atena:debugAdd({ id = fid, group = 'coaster', label = label, icon = icon, toggle = toggle, value = value, peekWin = peek and fid or nil })
    end
end
AddEventHandler('atena:debug:invoke', function(id) local fn = closures[id]; if fn then fn() end end)

local function syncBadge(pid)
    if GetResourceState('atena') == 'started' then exports.atena:debugSet(pid, Dbg.panelOn[pid]) end
end
local function togglePanel(pid)
    Dbg.panelOn[pid] = not Dbg.panelOn[pid]
    if Dbg.panelOn[pid] then exports.atena:uiDebugArrange(true)        -- keep the cursor to place the window
    else exports.atena:uiDebugPanel(pid, nil) end                     -- close = remove the card
    Dbg.saveState()
    syncBadge(pid)                                                     -- launcher badge follows the real state
end
-- the card's ✕ button → stop pushing this panel (else the push loop re-adds it next tick).
AddEventHandler('atena:debug:panelClosed', function(pid)
    if Dbg.panelOn[pid] then
        Dbg.panelOn[pid] = false; exports.atena:uiDebugPanel(pid, nil); Dbg.saveState(); syncBadge(pid)
    end
end)

-- Seat calibration: stand where the ped should sit, run this, it logs the car-LOCAL offset for Config.seatLayout.
local function seatCalib()
    local ped = PlayerPedId()
    local pc = GetEntityCoords(ped)
    local n = exports['std-rollercoaster']:carCount() or 0
    local best, bestD, bestI
    for i = 1, n do
        local c = exports['std-rollercoaster']:carEntity(i)
        if c ~= 0 and DoesEntityExist(c) then
            local d = #(pc - GetEntityCoords(c))
            if not bestD or d < bestD then bestD, best, bestI = d, c, i end
        end
    end
    if not best then Dbg.clog('seatcalib', 'no cart nearby'); return end
    local cp  = GetEntityCoords(best)
    local chd = GetEntityHeading(best)
    local loc = GetOffsetFromEntityGivenWorldCoords(best, pc.x, pc.y, pc.z)
    local row, side = (loc.y < 0.0) and 'front' or 'back', (loc.x < 0.0) and 'left' or 'right'
    Dbg.clog('seatcalib', ('car=%s(idx%d) %s-%s local=(%.3f,%.3f,%.3f) cart=(%.3f,%.3f,%.3f) H=%.2f => %s={x=%.3f, y=%.3f, height=0.85}')
        :format(tostring(exports['std-rollercoaster']:carModel(bestI) or '?'), bestI, row, side,
            loc.x, loc.y, loc.z, cp.x, cp.y, cp.z, chd, row, math.abs(loc.x), loc.y))
end

local function registerAll()
    local on = Dbg.panelOn
    reg('train', 'Treno (pannello)',  'train',    function() togglePanel('coaster:train') end, true, on['coaster:train'], true)
    reg('rider', 'Rider (pannello)',  'user',     function() togglePanel('coaster:rider') end, true, on['coaster:rider'], true)
    reg('audio', 'Audio (pannello)',  'volume',   function() togglePanel('coaster:audio') end, true, on['coaster:audio'], true)
    reg('flags', 'Flag (pannello)',   'flag',     function() togglePanel('coaster:flags') end, true, on['coaster:flags'])
    reg('seatcalib', 'Calibra posto (card)', 'wrench', function() Dbg.calibCar = Dbg.calibCar or 1; Dbg.calibSic = Dbg.calibSic or 1; togglePanel('coaster:seatcalib') end, true, on['coaster:seatcalib'])
    reg('calib', 'Calibra posto (log qui)', 'terminal', seatCalib)
end
-- ACTIVE WAIT for atena (race-proof): events (onResourceStart/ready/refresh) may have ALREADY fired before
-- this handler bound (if atena was up before we loaded) → poll until atena is up, then register. This is the
-- reliable initial register; the events handle later atena restarts.
CreateThread(function() while GetResourceState('atena') ~= 'started' do Wait(250) end; registerAll() end)
AddEventHandler('atena:debug:ready', registerAll) -- re-register after `restart atena`
AddEventHandler('atena:debug:refresh', registerAll) -- re-register whenever the overlay opens (unified lifecycle hook)
AddEventHandler('onResourceStart', function(res) if res == 'atena' then registerAll() end end)

-- FLAGS card bool-toggles (atena:debug:action) → flip the REAL marker/log flags on Dbg.on.
AddEventHandler('atena:debug:action', function(panel, key)
    if panel ~= 'coaster:flags' then return end
    local on = Dbg.on
    if key == '*' then
        local v = not on.seats
        on.seats, on.entry, on.nodes, on.operator = v, v, v, v
        if on.sync ~= v then on.sync = v; exports['std-rollercoaster']:setDebug('sync', v) end
        if on.speedlog ~= v then on.speedlog = v; TriggerServerEvent('std-rollercoaster:debug:speedLog', v) end
    elseif key == 'sync' then
        on.sync = not on.sync; exports['std-rollercoaster']:setDebug('sync', on.sync)
    elseif key == 'speedlog' then
        on.speedlog = not on.speedlog; TriggerServerEvent('std-rollercoaster:debug:speedLog', on.speedlog)
    elseif on[key] ~= nil then
        on[key] = not on[key]
    end
    Dbg.saveState()
end)

-- SEAT CALIB card buttons (atena:debug:action) → drive the standalone's REAL calibration hooks. The
-- standalone owns offset/heading + boarding; the bridge only nudges + reads + logs (headless doctrine).
AddEventHandler('atena:debug:action', function(panel, key, value)
    if panel ~= 'coaster:seatcalib' then return end
    Dbg.calibCar = Dbg.calibCar or 1; Dbg.calibSic = Dbg.calibSic or 1
    local R = exports['std-rollercoaster']
    local function watchCart() exports.atena:toolCamWatch(R:carEntity(Dbg.calibCar) or 0) end  -- shared Tool cam → this cart
    local function preview() watchCart(); R:dbgSeatPreview(Dbg.calibCar, Dbg.calibSic) end       -- snap there → nudges visible
    if key == 'car' then                                            -- stepper sends -1 / +1
        local n = R:carCount() or 1; if n < 1 then n = 1 end
        local d = (tonumber(value) or 1) >= 0 and 1 or -1
        Dbg.calibCar = ((Dbg.calibCar - 1 + d) % n) + 1
        preview()
    elseif key == 'seat' then
        local d = (tonumber(value) or 1) >= 0 and 1 or -1
        Dbg.calibSic = ((Dbg.calibSic - 1 + d) % 4) + 1
        preview()
    elseif key == 'x' or key == 'y' or key == 'z' or key == 'heading' then  -- number sends ABSOLUTE
        R:dbgSeatSet(Dbg.calibSic, key, value)
    -- cam = the SHARED Atena.Tool cam; watch the current cart, then toggle / tune via its exports.
    elseif key == 'freecam' then
        watchCart(); exports.atena:toolCam(not (exports.atena:toolCamGet() or {}).on)
    elseif key == 'cam orbit'  then exports.atena:toolCamSet('orbit', value)
    elseif key == 'cam dist'   then exports.atena:toolCamSet('dist', value)
    elseif key == 'cam height' then exports.atena:toolCamSet('height', value)
    elseif key == 'anchor' then R:dbgSetAnchor(not R:dbgGetAnchor())          -- flip the boarding anchor flag
    elseif key == 'anim' then Dbg.calibAnim = tostring(value)                 -- select: which clip to test
    elseif key == 'preview' then preview()
    elseif key == 'reset' then R:dbgSeatReset(Dbg.calibSic); preview()        -- back to original offset/heading
    elseif key == 'play' then
        local base = Dbg.calibAnim or 'enter'
        if base == 'enter' or base == 'exit' then
            R:dbgPlayClip(Dbg.calibCar, Dbg.calibSic, base)                   -- seat-specific climb-in / exit
        else
            local cn = R:dbgClipFor(Dbg.calibSic, base)                       -- in-place clip → the shared Tool
            if cn then exports.atena:toolPlayAnim(cn.dict, cn.clip, (base:find('idle') or base:find('grip')) and 'loop' or 'oneshot') end
        end
    elseif key == 'dump' then
        for sic, g in ipairs(R:dbgSeatDump() or {}) do
            Dbg.clog('seatcalib', ('seat%d (%s): x=%.3f y=%.3f z=%.3f heading=%.1f'):format(sic, g.side, g.x, g.y, g.z, g.heading))
        end
    end
end)
