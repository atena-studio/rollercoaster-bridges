-- atena-bridge-rollercoaster — the rollercoaster <-> atena integration (bridge doctrine, atena-framework §6).
-- A bridge resource is EXEMPT from the anti-bias rule: calling exports['std-rollercoaster']:* / Atena.* is its
-- nature (the glue). Each file self-guards with GetResourceState(...) so this stays INERT unless both
-- the standalone and atena are started. Lives under the fivem/[bridge]/ CONTAINER, versioned WITH the
-- rollercoaster repo (the glue evolves with its standalone).

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'atena-bridge-rollercoaster'
author 'SirTheo'
description 'Bridge: rollercoaster <-> atena (control panel CEF, boarding prompts, debug tooling)'
version '0.0.1'

-- No escrow_ignore: a bridge is INTEGRATION GLUE (atena-framework §6), not a protected product. It ships
-- in cleartext WITH its standalone and is never escrowed/obfuscated/name-locked (escrow-protection rule).

shared_scripts {
    'shared/config.lua',        -- CoasterUI: presentation/interaction tunables (bridge-owned)
}

server_scripts {
    'server/auth.lua',          -- rollercoaster <-> atena: authorizer + inbound-guard seams
    'server/neon.lua',          -- neon glow mode (GlobalState, server-authoritative; admin override)
}

client_scripts {
    'client/panel.lua',         -- coaster control panel (CEF + intents)
    'client/ride.lua',          -- coaster boarding prompts + input (renders rollercoaster's state)
    'client/neon.lua',          -- neon glow day/night auto + manual override (texture swap) + NUI button
    -- debug split by concern (atena-framework §11): core first (shared Dbg), api/menu, then the loops.
    'client/debug/core.lua',    -- shared Dbg state + helpers (gs/atenaUp/clog/saveState) + restore
    'client/debug/menu.lua',    -- launcher entries + card toggles + FLAGS bool-handling + seat calib
    'client/debug/cards.lua',   -- TRAIN/RIDER/AUDIO/FLAGS row builders + throttled push loop
    'client/debug/markers.lua', -- native 3D world markers (seats/entry/nodes/operator box)
    'client/debug/synclog.lua', -- cross-client rider-divergence log (Dbg.on.sync)
    -- free orbit cam + anim tester are now the SHARED Atena.Tool (atena/modules/tool) — the calib card
    -- drives it via exports.atena:toolCam*/toolPlayAnim (refactor-first: one tester, every bridge reuses it).
}

-- This bridge OWNS the coaster control-desk CEF (headless doctrine: the standalone ships no UI). Each
-- bridge resource can now carry its OWN ui_page (no more single-bridge one-ui_page limit).
ui_page 'nui/index.html'

-- nui/ is the COMPILED output; the SOURCE lives in the PRIVATE std-rollercoaster/web/ (Vite+React+Tailwind).
-- Build with `.\.claude\bin\build-nui.ps1 rollercoaster` (std/web -> bridge/nui). Hashed asset names =>
-- recreate the dev container after a rebuild (txAdmin can't `refresh`).
files {
    'nui/index.html',
    'nui/assets/**',
}
