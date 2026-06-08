-- fivem/bridge/rollercoaster/client/ride.lua — coaster boarding PROMPTS + INPUT, hosted by the bridge.
-- EVENT-DRIVEN: rollercoaster fires `rollercoaster:prompt` (a decision-complete spec) ON-CHANGE; the
-- bridge re-renders only then (textUI / hud key-hints / status banner). Per-frame work is ONLY input
-- (engine-polled) + the continuous launch countdown. Pure renderer + forwarder (no gameplay decision).

if GetResourceState('atena') ~= 'started'
   or GetResourceState('atena-std-rollercoaster') ~= 'started' then return end

local C  = CoasterUI or {}
local A  = C.actions or {}
local ST = C.status or {}

-- intent closures (literal exports; the standalone runs the real Ride logic)
local INTENTS = {
    board      = function(seat) exports['atena-std-rollercoaster']:board(seat) end,
    toggleArms = function() exports['atena-std-rollercoaster']:toggleArms() end,
    shiftLeft  = function() exports['atena-std-rollercoaster']:shiftLeft() end,
    shiftRight = function() exports['atena-std-rollercoaster']:shiftRight() end,
    exit       = function() exports['atena-std-rollercoaster']:exit() end,
}

-- on-change senders (atena UI), one per slot
-- CALL-TIME gate (bridge-registration.md): atena restarting mid-session = a window where its
-- exports don't exist → an unguarded call throws "No such export". Skip the send (don't update
-- the last-sent key) so the state re-sends once atena is back.
local function atenaUp() return GetResourceState('atena') == 'started' end

local lastText, lastKeys, lastStatus, lastCD
local function setText(v)
    local k = (type(v) == 'table') and ((v.key or '') .. '|' .. (v.text or '')) or 'off'
    if k ~= lastText and atenaUp() then lastText = k; exports.atena:uiTextUI(v) end
end
local function setKeys(items)
    local k = items and (#items .. '|' .. (items[1] and items[1].key or '')) or 'off'
    if k ~= lastKeys and atenaUp() then lastKeys = k; exports.atena:uiHud('coasterKeys', items and { type = 'keys', items = items } or nil) end
end
local function setStatus(text)
    local k = text or 'off'
    if k ~= lastStatus and atenaUp() then lastStatus = k; exports.atena:uiHud('coasterStatus', text and { type = 'banner', text = text } or nil) end
end
local function setCD(text)
    local k = text or 'off'
    if k ~= lastCD and atenaUp() then lastCD = k; exports.atena:uiHud('coasterCD', text and { type = 'banner', text = text } or nil) end
end

-- ── render: runs ON CHANGE (the prompt event), not per-frame ──────────────────────────────────
local current = { context = 'none' }
local function render(spec)
    current = spec or { context = 'none' }
    local ctx = current.context
    if ctx == 'board' then
        local a = A.board or {}
        setText({ key = a.key, text = a.label }); setKeys(nil); setStatus(nil)
    elseif ctx == 'closed' then
        setText({ text = C.closedText or 'Giostra in corsa' }); setKeys(nil); setStatus(nil)
    elseif ctx == 'ride' then
        setText(false)
        local items = {}
        for _, name in ipairs(current.actions or {}) do
            local a = A[name]; if a then items[#items + 1] = { key = a.key, label = a.label } end
        end
        setKeys(#items > 0 and items or nil)
        setStatus(current.status and ST[current.status] or nil)
    else
        setText(false); setKeys(nil); setStatus(nil)
    end
end

AddEventHandler('atena-std-rollercoaster:prompt', function(spec) render(spec) end)
-- initial sync: direct call (rollercoaster is 'started' per the top guard, so the export is callable).
-- nil → render('none'); the prompt event delivers the real state on the next change. No timing-guess.
render(exports['atena-std-rollercoaster']:currentPrompt())

-- ── per-frame: ONLY input + the continuous countdown (render is event-driven, above) ──────────
local function pressed(ctrl) return IsControlJustPressed(0, ctrl) or IsDisabledControlJustPressed(0, ctrl) end
local function handle(name, seat)
    local a = A[name]; if not a then return end
    if a.controls then
        for i, ctrl in ipairs(a.controls) do
            if pressed(ctrl) then local fn = INTENTS[a.intents[i]]; if fn then fn() end end
        end
    elseif a.control and pressed(a.control) then
        local fn = INTENTS[a.intent]; if fn then fn(seat) end
    end
end

CreateThread(function()
    while true do
        local ctx = current.context
        if not ctx or ctx == 'none' then
            setCD(nil)
            Wait(250)
        else
            if ctx == 'ride' then
                for _, name in ipairs(current.actions or {}) do handle(name) end
                setCD(nil)
            else                                            -- board / closed
                if ctx == 'board' then handle('board', current.seat) end
                local cd = GlobalState.coasterCountdown
                setCD((type(cd) == 'number' and cd >= 0.0)
                    and ('%s %ds'):format(C.countdown or 'Partenza tra', math.ceil(cd)) or nil)
            end
            Wait(0)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and GetResourceState('atena') == 'started' then
        exports.atena:uiTextUI(false)
        exports.atena:uiHud('coasterKeys', nil)
        exports.atena:uiHud('coasterStatus', nil)
        exports.atena:uiHud('coasterCD', nil)
    end
end)
