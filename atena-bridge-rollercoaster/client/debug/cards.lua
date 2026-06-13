-- atena-bridge-rollercoaster debug — CARDS: the live inspector cards (TRAIN/RIDER/AUDIO/FLAGS row builders +
-- the throttled push loop). Reads REAL exposed values (GlobalState + exports['std-rollercoaster']) and the shared
-- `Dbg` (open set + flags). The debug observes the actual gameplay, it never replicates it.
-- ROBUST: no permanent top-guard bail (load race). The push loop already gates Dbg.atenaUp(); the row
-- builders read exports['std-rollercoaster'] only while pushing an OPEN panel (deps up by then). atena-framework §6.

local gs = Dbg.gs
local function arr(k, t) local a = gs(k); return type(a) == 'table' and a[t] or nil end
local function boolRow(k, v) return { key = k, value = v and true or false, kind = 'value', tone = v and 'green' or 'dim' } end

-- fleet = array of train descriptors ({cars=…}); format it readable (presentation = bridge), else the
-- raw table reaches the NUI as [object Object],[object Object]…
local function fleetStr()
    local f = gs('coasterFleet')
    if type(f) ~= 'table' then return tostring(f or 1) end
    local cars = {}
    for _, tr in ipairs(f) do cars[#cars + 1] = tostring((type(tr) == 'table' and tr.cars) or tr) end
    return ('%d treni (%s)'):format(#f, table.concat(cars, ','))
end

local function trainRows()
    local t = gs('coasterStationTrain'); if type(t) ~= 'number' or t < 1 then t = 1 end
    local bars = arr('coasterBarsArr', t)
    local phase = arr('coasterTrainPhase', t) or gs('coasterPhase') or '—'
    local cd = gs('coasterCountdown')
    return {
        { key = 'mode',  value = gs('coasterMode') or '—', tone = 'accent' }, { key = 'fleet', value = fleetStr() },
        { key = 'train', value = t }, { key = 'phase', value = phase, tone = 'accent' },
        { key = 'prog',  value = ('%.1f'):format(arr('coasterProg', t) or 0.0) },
        { key = 'speed', value = ('%.2f'):format(arr('coasterSpd', t) or 0.0) },
        boolRow('atStation', arr('coasterAtStation', t)),
        { key = 'bars', value = (bars == false and 'DOWN') or (bars and 'UP') or '—', tone = (bars == false) and 'green' or 'warn' },
        boolRow('onRide', arr('coasterOnRide', t)), boolRow('operator', gs('coasterOperatorPresent')),
        { key = 'countdown', value = (type(cd) == 'number' and cd >= 0.0) and ('%.0f'):format(cd) or '—' },
    }
end

local function riderRows()
    local lp = exports['std-rollercoaster']:localProg() or -1
    local sp = (gs('coasterProg') or {})[1] or -1
    local att, n = exports['std-rollercoaster']:attachedMap() or {}, 0
    for _ in pairs(att) do n = n + 1 end
    local lead = exports['std-rollercoaster']:leadCartCoords()
    return {
        { key = 'seat', value = exports['std-rollercoaster']:mySeat() or '—', tone = 'accent' },
        boolRow('riding', exports['std-rollercoaster']:riding()), { key = 'attached', value = n },
        { key = 'localProg', value = ('%.1f'):format(lp) }, { key = 'serverProg', value = ('%.1f'):format(sp) },
        { key = 'drift', value = ('%.1f'):format(lp - sp), tone = (math.abs(lp - sp) > 2.0) and 'red' or 'dim' },
        { key = 'leadPos', value = lead and ('%.0f,%.0f,%.0f'):format(lead.x, lead.y, lead.z) or '—' },
    }
end

local hasSPT = (GetStreamPlayTime ~= nil)
local function audioRows()
    local nodes = exports['std-rollercoaster']:trackNodes() or {}
    local nn = #nodes
    local prog = (gs('coasterProg') or {})[1] or 0.0
    local node = (nn > 0) and (((nn - math.floor(prog)) % nn) + 1) or 0
    return {
        boolRow('riding', exports['std-rollercoaster']:riding()), { key = 'phase', value = gs('coasterPhase') or '—', tone = 'accent' },
        { key = 'streamMs', value = gs('coasterStreamMs') or '—' },
        { key = 'playTime', value = hasSPT and (GetStreamPlayTime() or -1) or 'n/a' },
        { key = 'node', value = node }, { key = 'z', value = ('%.2f'):format((nodes[node] or {}).z or 0.0) },
        { key = 'speed', value = ('%.2f'):format((gs('coasterSpd') or {})[1] or 0.0) },
    }
end

-- a bool ROW the user flips in arrange → atena fires 'atena:debug:action'; key drives Dbg.on (menu.lua).
local function flag(key, label, v) return { key = key, value = v, kind = 'bool', tone = v and 'green' or 'dim' } end
local function flagsRows()
    local on = Dbg.on
    return {
        flag('seats', 'seats', on.seats), flag('entry', 'entry', on.entry), flag('nodes', 'nodes', on.nodes),
        flag('operator', 'operator', on.operator), flag('sync', 'sync log', on.sync), flag('speedlog', 'speed log', on.speedlog),
        { key = '*', value = false, kind = 'bool', tone = 'accent' },   -- toggle-all
    }
end

-- SEAT CALIBRATION card — read the standalone's REAL seat data (exports['std-rollercoaster']:dbgSeatGet) and
-- expose clickable action-rows (bool rows = buttons; click in arrange fires atena:debug:action → menu.lua
-- nudges the real offset/heading via dbgSeatNudge / boards via dbgTestBoard). The standalone owns the data
-- + behaviour; the bridge is the menu (headless doctrine).
local function calibRows()
    local car = Dbg.calibCar or 1
    local sic = Dbg.calibSic or 1
    local n = exports['std-rollercoaster']:carCount() or 0
    local g = exports['std-rollercoaster']:dbgSeatGet(sic) or {}
    local anchor = exports['std-rollercoaster']:dbgGetAnchor()
    -- free orbit cam = the SHARED Atena.Tool cam (watches the selected cart), not a bridge-local one.
    local cam = exports.atena:toolCamGet() or {}
    local rows = {
        { key = 'freecam', value = cam.on or false, kind = 'toggle', tone = 'warn' },
    }
    if cam.on then
        rows[#rows + 1] = { key = 'cam orbit', value = cam.orbit or 45.0, kind = 'number', step = 15.0 }
        rows[#rows + 1] = { key = 'cam dist',  value = cam.dist or 5.5, kind = 'number', step = 0.5 }
        rows[#rows + 1] = { key = 'cam height', value = cam.height or 2.0, kind = 'number', step = 0.5 }
    end
    for _, r in ipairs({
        { key = 'car',  value = ('%d / %d'):format(car, n), kind = 'stepper', tone = 'accent' },
        { key = 'seat', value = ('%d  (%s)'):format(sic, g.side or '?'), kind = 'stepper', tone = 'accent' },
        { key = 'x', value = g.x or 0.0, kind = 'number', step = 0.01 },
        { key = 'y', value = g.y or 0.0, kind = 'number', step = 0.01 },
        { key = 'z', value = g.z or 0.0, kind = 'number', step = 0.01 },
        { key = 'heading', value = g.heading or 180.0, kind = 'number', step = 5.0 },
        -- boarding anchor flag (collision/placement): player-anchored climb vs seat-anchored snap
        { key = 'anchor', value = anchor and true or false, kind = 'toggle', tone = anchor and 'green' or 'dim' },
        -- pick an animation to test for THIS seat's side (suffix derived from the seat); ▶ play runs it
        { key = 'anim', value = Dbg.calibAnim or 'enter', kind = 'select', options = {
            'enter', 'exit', 'hands_up_enter', 'hands_up_exit',
            'safety_bar_enter', 'safety_bar_exit', 'safety_bar_grip_move_a',
            'idle_a', 'hands_up_idle_a', 'idle_b',
        } },
        { key = 'actions', kind = 'buttons', items = {
            { id = 'preview', label = 'siediti qui', tone = 'accent' },
            { id = 'play', label = '▶ play', tone = 'green' },
            { id = 'reset', label = '↺ reset', tone = 'warn' },
            { id = 'dump', label = 'DUMP', tone = 'warn' },
        } },
    }) do rows[#rows + 1] = r end
    return rows
end

local PANELS = {
    ['coaster:train'] = { title = 'COASTER · TRAIN', rows = trainRows },
    ['coaster:rider'] = { title = 'COASTER · RIDER', rows = riderRows },
    ['coaster:audio'] = { title = 'COASTER · AUDIO', rows = audioRows },
    ['coaster:flags'] = { title = 'COASTER · FLAGS', rows = flagsRows },
    ['coaster:seatcalib'] = { title = 'COASTER · SEAT CALIB', rows = calibRows },
}

-- push the open cards live (throttled). atenaUp guard + pcall the row build (both read code that throws
-- while atena / rollercoaster restart → a throw here would kill this thread and the cards never return).
local failed = {}   -- a broken row builder logs ONCE per open (not 5×/s) — silence here hid real failures
CreateThread(function()
    while true do
        local any = false
        if Dbg.atenaUp() then
            for pid, def in pairs(PANELS) do
                if Dbg.panelOn[pid] then
                    any = true
                    local ok, rows = pcall(def.rows)
                    if ok then
                        failed[pid] = nil
                        exports.atena:uiDebugPanel(pid, { title = def.title, rows = rows })
                    elseif not failed[pid] then
                        failed[pid] = true
                        Dbg.clog('cards', 'row build failed for ' .. pid .. ': ' .. tostring(rows))
                    end
                end
            end
        end
        Wait(any and 200 or 500)
    end
end)

-- hover-PEEK (view-only): preview a DATA card's content WITHOUT opening it (no panelOn, no badge);
-- the push loop above only renders panelOn cards, so peek renders directly and the two never collide.
-- Only the data panels preview — flags (feature) / seatcalib (workbench) declare no peekWin.
local PEEKABLE = { ['coaster:train'] = true, ['coaster:rider'] = true, ['coaster:audio'] = true }
AddEventHandler('atena:debug:peek', function(win)
    local def = PEEKABLE[win] and not Dbg.panelOn[win] and Dbg.atenaUp() and PANELS[win]
    if not def then return end
    local ok, rows = pcall(def.rows)
    if ok then exports.atena:uiDebugPanel(win, { title = def.title, rows = rows }) end
end)
AddEventHandler('atena:debug:peekEnd', function(win)
    if PEEKABLE[win] and not Dbg.panelOn[win] and Dbg.atenaUp() then exports.atena:uiDebugPanel(win, nil) end
end)

-- close any open cards if the bridge stops
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and Dbg.atenaUp() then
        for pid in pairs(PANELS) do exports.atena:uiDebugPanel(pid, nil) end
    end
end)
