-- atena-bridge-rollercoaster debug — SYNCLOG: cross-client rider-divergence log (a 2nd client can't be shown in
-- one card, so this logs to the server console to compare two clients). Gated on Dbg.on.sync.
-- ROBUST: no permanent top-guard bail (load race). The loop reads exports['std-rollercoaster'] only when
-- Dbg.on.sync is enabled (default OFF) → deps up by then. atena-framework §6.

local gs = Dbg.gs

CreateThread(function()
    while true do
        if not Dbg.on.sync then
            Wait(400)
        else
            local lead = exports['std-rollercoaster']:leadCartCoords()
            if lead then
                Dbg.clog('cartpos', ('localProg=%.1f serverProg=%.1f cart1=(%.2f,%.2f,%.2f) phase=%s'):format(
                    exports['std-rollercoaster']:localProg() or -1, (gs('coasterProg') or {})[1] or -1,
                    lead.x, lead.y, lead.z, gs('coasterPhase') or '?'))
            end
            if (gs('coasterPhase') or '') == 'running' then
                local localId = GetPlayerServerId(PlayerId())
                for srv, seat in pairs(exports['std-rollercoaster']:attachedMap() or {}) do
                    if srv ~= localId then
                        local plyr = GetPlayerFromServerId(srv)
                        local ped = (plyr ~= -1) and GetPlayerPed(plyr) or 0
                        if ped ~= 0 then
                            local pp = GetEntityCoords(ped)
                            local car = exports['std-rollercoaster']:carEntity(exports['std-rollercoaster']:carOf(seat))
                            local att = car ~= 0 and DoesEntityExist(car) and IsEntityAttachedToEntity(ped, car)
                            local cp = (car ~= 0 and DoesEntityExist(car)) and GetEntityCoords(car) or vector3(0.0, 0.0, 0.0)
                            Dbg.clog('riderdiv', ('srv=%d seat=%d att=%s ped=(%.2f,%.2f,%.2f) cart=(%.2f,%.2f,%.2f)'):format(
                                srv, seat, tostring(att), pp.x, pp.y, pp.z, cp.x, cp.y, cp.z))
                        end
                    end
                end
            end
            Wait(1000)
        end
    end
end)
