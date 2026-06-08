-- atena-bridge-rollercoaster debug — MARKERS: native 3D world markers (seats/entry/nodes/operator box) — the
-- SPATIAL debug, not cards. Reads REAL exposed values (seatPositions/trackNodes/getInteractables) + the
-- shared `Dbg.on` flags (flipped from the FLAGS card). opBox/C/constants are local (only this file uses them).
-- ROBUST: no permanent top-guard bail (load race). The draw loop only reads exports['atena-std-rollercoaster'] when a
-- Dbg.on flag is enabled (default OFF, set only after the deps-gated restore) → deps up by then. §6.

local C = CoasterUI or {}
local MARK_DIST, LINE_DIST, Z = 140.0, 320.0, 0.55
local opBox  -- cached operator box coords (from rollercoaster's interactables)

local function drawOverlays(pc)
    local on = Dbg.on
    if on.operator and opBox and #(pc - opBox) < MARK_DIST then
        local dia = 2.0 * ((C.targetRadius or 2.5))
        DrawMarker(1, opBox.x, opBox.y, opBox.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, dia, dia, 1.6, 0, 220, 255, 150, false, false, 2, false, nil, nil, false)
    end
    if on.seats or on.entry then
        for _, p in ipairs(exports['atena-std-rollercoaster']:seatPositions() or {}) do
            if on.seats and p.world then
                local w = vector3(p.world.x, p.world.y, p.world.z)
                if #(pc - w) < MARK_DIST then
                    DrawMarker(28, w.x, w.y, w.z + 0.25, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25,
                        p.occ and 220 or 40, p.occ and 40 or 220, 40, 150, false, false, 2, false, nil, nil, false)
                end
            end
            if on.entry and p.entry then
                local e = vector3(p.entry.x, p.entry.y, p.entry.z)
                if #(pc - e) < MARK_DIST then
                    DrawMarker(1, e.x, e.y, e.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.2, 1.2, 1.6, 40, 220, 255, 120, false, false, 2, false, nil, nil, false)
                end
            end
        end
    end
    if on.nodes then
        local nodes = exports['atena-std-rollercoaster']:trackNodes() or {}
        local n = #nodes
        for i = 1, n do
            local a = nodes[i]
            local da = #(pc - vector3(a.x, a.y, a.z + Z))
            if da < LINE_DIST then
                local b = nodes[(i % n) + 1]
                local hot = math.floor(((a.z - 16.0) / 15.0) * 255.0)
                if hot < 0 then hot = 0 elseif hot > 255 then hot = 255 end
                DrawLine(a.x, a.y, a.z + Z, b.x, b.y, b.z + Z, hot, 60, 255 - hot, 200)
                if da < MARK_DIST then
                    DrawMarker(28, a.x, a.y, a.z + Z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.30, 0.30, 0.30, hot, 60, 255 - hot, 170, false, false, 2, false, nil, nil, false)
                end
            end
        end
    end
end

CreateThread(function()
    for _ = 1, 20 do                                  -- cache the operator box position
        local list = exports['atena-std-rollercoaster']:getInteractables()
        if list then
            for _, it in ipairs(list) do
                if it.id == 'operatorBox' and it.coords then opBox = vector3(it.coords.x, it.coords.y, it.coords.z) end
            end
            break
        end
        Wait(250)
    end
    while true do
        local on = Dbg.on
        if not (on.seats or on.entry or on.nodes or on.operator) then
            Wait(300)
        else
            local ped = PlayerPedId()
            if ped ~= 0 then drawOverlays(GetEntityCoords(ped)) end
            Wait(0)
        end
    end
end)
