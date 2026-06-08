-- fivem/bridge/rollercoaster/atena.client.lua — the coaster control panel, HOSTED BY THE BRIDGE
-- (headless doctrine: rollercoaster exposes data + intents, the bridge owns ALL presentation). The
-- CEF (rollercoaster/nui/*) is the bridge's ui_page; it reads rollercoaster's exported state and
-- fires rollercoaster's intents. INERT unless both resources are started.

if GetResourceState('atena') ~= 'started'
   or GetResourceState('std-rollercoaster') ~= 'started' then return end

local panelOpen = false

-- ── panel lifecycle ─────────────────────────────────────────────────────────────────────────
local function pushState()
    local s = exports['std-rollercoaster']:getPanelState()
    if s then s.action = 'state'; SendNUIMessage(s) end
end

local function openPanel()
    if panelOpen then return end
    panelOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    local tr = exports['std-rollercoaster']:getTrackSchematic()
    if tr then SendNUIMessage({ action = 'track', points = tr.points, station = tr.station }) end
    pushState()
    CreateThread(function()
        while panelOpen do pushState(); Wait(150) end     -- moderate push while open (nui.md §3)
    end)
end

local function closePanel()
    if not panelOpen then return end
    panelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- ── NUI callbacks -> rollercoaster intents (literal names; the bridge is anti-bias exempt) ───
RegisterNUICallback('bars', function(data, cb)
    TriggerServerEvent('std-rollercoaster:op:bars', data and data.down and true or false, data and data.train); cb('ok')
end)
RegisterNUICallback('dispatch', function(data, cb)
    TriggerServerEvent('std-rollercoaster:op:dispatch', data and data.train); cb('ok')
end)
RegisterNUICallback('estop', function(data, cb)
    TriggerServerEvent('std-rollercoaster:op:estop', data and data.train); cb('ok')
end)
RegisterNUICallback('setFleet', function(data, cb)
    TriggerServerEvent('std-rollercoaster:op:setFleet', (data and data.trains) or {}); cb('ok')
end)
RegisterNUICallback('callOperator', function(_, cb)
    TriggerServerEvent('std-rollercoaster:op:callOperator'); cb('ok')
end)
RegisterNUICallback('dismissOperator', function(_, cb)
    TriggerServerEvent('std-rollercoaster:op:dismissOperator'); cb('ok')
end)
RegisterNUICallback('close', function(_, cb) closePanel(); cb('ok') end)

-- ── rollercoaster notifications -> atena notifications (NOT the panel) ───────────────────────
-- The panel keeps only controls + live display; feedback (denials, fleet applied) goes through
-- atena's shared notifications (the bridge translates the coded reasons). Global (not panel-gated).
local REASONS = {
    too_far = 'Allontanato dal quadro', npc_busy = "L'operatore NPC è al comando",
    no_train = 'Nessun treno in banchina', not_front = 'Solo il treno di testa può partire',
    bars_up = 'Abbassa prima le barre', in_corsa = 'Giostra in corsa', riders_aboard = 'Passeggeri a bordo',
    auto_mode = 'Modalità automatica attiva', invalid = 'Dati non validi', in_coda = 'Treno in coda',
}
local function reasonText(r) return REASONS[r] or tostring(r) end

RegisterNetEvent('std-rollercoaster:op:denied', function(reason)
    exports.atena:uiNotify({ title = 'Giostra', description = reasonText(reason), type = 'error' })
end)
RegisterNetEvent('std-rollercoaster:op:fleetDenied', function(reason)
    exports.atena:uiNotify({ title = 'Flotta', description = 'Negato: ' .. reasonText(reason), type = 'error' })
end)
RegisterNetEvent('std-rollercoaster:op:fleetOk', function(trains, cars)
    exports.atena:uiNotify({ title = 'Flotta',
        description = ('Applicato: %s treno/i, %s vagoni'):format(tostring(trains), tostring(cars)), type = 'success' })
end)

-- ── open the panel from the control box, via atena's third-eye (Atena.Target) ────────────────
-- rollercoaster exposes the box as an interactable (data); the bridge wires it to the third-eye.
CreateThread(function()
    local list
    for _ = 1, 20 do
        list = exports['std-rollercoaster']:getInteractables()
        if list then break end
        Wait(250)
    end
    local C = CoasterUI or {}
    local po = C.panelOption or { label = 'Apri quadro comandi', icon = 'settings' }
    local reach = C.targetRadius or 2.5
    for _, it in ipairs(list or {}) do
        if it.kind == 'sphere' and it.coords then
            local opts = {}
            for _, o in ipairs(it.options or {}) do
                if o.name == 'openPanel' then
                    -- presentation (label/icon) is the BRIDGE's (config.lua), not the standalone's.
                    -- `id` (not a closure): a function can't cross the export -> atena fires
                    -- 'atena:target:invoke' with this id and we open the panel below.
                    opts[#opts + 1] = { label = po.label, icon = po.icon, distance = reach, id = 'coaster:openPanel' }
                end
            end
            if #opts > 0 then
                exports.atena:targetAddSphereZone({
                    coords  = vector3(it.coords.x, it.coords.y, it.coords.z),
                    radius  = reach,
                    options = opts,
                })
            end
        end
    end
end)

-- atena fires this when the box's third-eye option is picked (id-based — no closure across the export)
AddEventHandler('atena:target:invoke', function(id)
    if id == 'coaster:openPanel' then openPanel() end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and panelOpen then SetNuiFocus(false, false) end
end)
