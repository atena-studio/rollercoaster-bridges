-- atena-bridge-rollercoaster debug — CORE: shared state + helpers (atena-framework §11). Separate Lua files in
-- one resource don't share upvalues → the cross-file state/helpers live on a resource-global `Dbg`.
-- Loaded FIRST. Headless (standalone §11): rollercoaster ships NO debug; the bridge renders its REAL
-- exposed values as atena debug cards + native markers, reading them — never replicating.
-- ROBUST: do NOT bail permanently at load if a dep isn't 'started' yet (load-order race → the whole debug
-- chain dies for the session). Define the shared state ALWAYS; gate the runtime export calls (Dbg.atenaUp /
-- the deferred restore below). atena-framework §6 / dev-server gotcha (ensure is async, no 'started' barrier).
Dbg = Dbg or {}
Dbg.on = { seats = false, entry = false, nodes = false, operator = false, sync = false, speedlog = false }  -- marker/log flags
Dbg.panelOn = {}                                                      -- which inspector cards are open

function Dbg.gs(k) return GlobalState[k] end                          -- shared GlobalState read shorthand
-- atena may be UNAVAILABLE while it restarts → calling its export then throws and would kill a loop thread.
function Dbg.atenaUp() return GetResourceState('atena') == 'started' end
function Dbg.clog(tag, detail) if Dbg.atenaUp() then exports.atena:log('info', tag, tostring(detail or '')) end end

-- persist open cards + flags across a BRIDGE restart (KVP via atena, no DB; an atena-restart is covered by
-- the persistent push loop). Saved on every toggle.
function Dbg.saveState()
    local p = {}
    for pid, v in pairs(Dbg.panelOn) do if v then p[#p + 1] = pid end end
    exports.atena:uiRemember('coaster:dbg', { panels = p, flags = Dbg.on })
end

-- restore at OUR boot (covers a bridge restart; runs once, not on atena-restart). Wait for both deps to be
-- 'started' first (robust to load-order: the bridge may load before atena/rollercoaster are ready).
CreateThread(function()
    while GetResourceState('atena') ~= 'started' or GetResourceState('std-rollercoaster') ~= 'started' do Wait(250) end
    local st = exports.atena:uiRecall('coaster:dbg')
    if type(st) ~= 'table' then return end
    if type(st.flags) == 'table' then
        for k, v in pairs(st.flags) do if Dbg.on[k] ~= nil then Dbg.on[k] = v and true or false end end
        if Dbg.on.sync then exports['std-rollercoaster']:setDebug('sync', true) end
        if Dbg.on.speedlog then TriggerServerEvent('std-rollercoaster:debug:speedLog', true) end
    end
    for _, pid in ipairs(st.panels or {}) do Dbg.panelOn[pid] = true end
end)
