-- atena-bridge-rollercoaster — NEON glow control (presentation/integration; the standalone is headless).
-- The coaster's neon sign (sm_22_rcoaster_neon) glows via EMISSIVE TEXTURES (no light entity). We toggle
-- the glow by swapping those textures with a dark "off" runtime texture (AddReplaceTexture) — verified
-- combo in reference/rollercoaster/neon-textures.md. State is server-authoritative (GlobalState
-- .coasterNeonMode: 'auto'|'on'|'off'); 'auto' = day/night from the (synced) game clock. Each client
-- applies locally on-change. A NUI button in atena's debug overlay cycles the mode (staff, admin-gated).
-- ROBUST: no permanent top-guard bail (load-order race kills it for the session). The neon loop is dep-free
-- (textures + a `time`-gated isNight); the debug button registers only when atena is up, re-firing on the
-- reliable hooks below. atena-framework §6.

-- the emissive textures of sm_22_rcoaster_neon (txd = the DRAWABLE name; txn = the DOUBLED CodeWalker
-- name = the real embedded texture). Sign panels + neon tubes + bulbs → the whole glow.
local NEON_TXD  = 'sm_22_rcoaster_neon'
local NEON_TXNS = {
    'sm_22_dc_test_001sm_22_dc_test_001_a',              -- sign panels (emissive/emissivestrong)
    'sm1_22_rsn_dc_neon_0002sm1_22_rsn_dc_neon_0002_a',  -- neon tubes
    'sm1_22_rsn_dc_neon_0003sm1_22_rsn_dc_neon_0003_a',  -- neon tubes (strong)
    'sm1_22_rsn_dc_bulbs_0001sm1_22_rsn_dc_bulbs_0001_a',-- bulbs
}
local RT_TXD, RT_TEX = 'coaster_neon_off', 'off'

-- dark-charcoal "off" runtime texture (built once) — emissive shader renders it as a dead/dim sign,
-- not pure black (invisible). Same neutral grey approved for the tool.
local offReady = false
local function ensureOff()
    if offReady then return end
    local txd = CreateRuntimeTxd(RT_TXD)
    local tex = CreateRuntimeTexture(txd, RT_TEX, 4, 4)
    for x = 0, 3 do for y = 0, 3 do SetRuntimeTexturePixel(tex, x, y, 18, 18, 22, 255) end end
    CommitRuntimeTexture(tex)
    offReady = true
end

local applied                                            -- last applied glow state (nil = unknown → force first apply)
local function applyGlow(on)
    if on == applied then return end                     -- on-change only
    applied = on
    if on then
        for _, txn in ipairs(NEON_TXNS) do RemoveReplaceTexture(NEON_TXD, txn) end
    else
        ensureOff()
        for _, txn in ipairs(NEON_TXNS) do AddReplaceTexture(NEON_TXD, txn, RT_TXD, RT_TEX) end
    end
end

-- prefer the synced `time` resource (shared clock); fall back to the local game clock if it's absent.
local function isNight()
    if GetResourceState('time') == 'started' then
        local ok, n = pcall(function() return exports.time:isNight() end)
        if ok and n ~= nil then return n and true or false end
    end
    local h = GetClockHours(); return h >= 20 or h < 6   -- standalone fallback (night = 20:00–05:59)
end
local function desiredGlow()
    local mode = GlobalState.coasterNeonMode or 'auto'
    if mode == 'on'  then return true end
    if mode == 'off' then return false end
    return isNight()                                     -- 'auto' = day/night
end

-- low-rate loop: mode + clock change slowly; apply is on-change so this is cheap.
CreateThread(function()
    while true do
        applyGlow(desiredGlow())
        Wait(3000)
    end
end)

-- never leave the neon swapped if the bridge stops.
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, txn in ipairs(NEON_TXNS) do RemoveReplaceTexture(NEON_TXD, txn) end
end)

-- ── NUI button (atena debug overlay): cycle auto → on → off (staff; the server gates + broadcasts) ──
local NEON_BTN = 'coaster:neon'
local function cycleMode()
    local m = GlobalState.coasterNeonMode or 'auto'
    local nextMode = (m == 'auto' and 'on') or (m == 'on' and 'off') or 'auto'
    TriggerServerEvent('atena-bridge-rollercoaster:neon:setMode', nextMode)
end
local function registerBtn()
    if GetResourceState('atena') == 'started' then
        -- label carries the CURRENT mode (debugAdd replaces by id → re-registering refreshes it)
        local m = GlobalState.coasterNeonMode or 'auto'
        exports.atena:debugAdd({ id = NEON_BTN, group = 'coaster', label = 'Neon: ' .. m, icon = 'zap' })
    end
end
AddEventHandler('atena:debug:invoke', function(id) if id == NEON_BTN then cycleMode() end end)
CreateThread(function() while GetResourceState('atena') ~= 'started' do Wait(250) end; registerBtn() end)  -- race-proof initial register
AddEventHandler('onResourceStart', function(res) if res == 'atena' then registerBtn() end end)  -- reliable cross-resource hook
AddEventHandler('atena:debug:ready', registerBtn)        -- re-register after `restart atena`
AddEventHandler('atena:debug:refresh', registerBtn)
-- mode changed (server broadcast via GlobalState) → refresh the entry label live (event-driven, no poll)
AddStateBagChangeHandler('coasterNeonMode', 'global', function() registerBtn() end)
