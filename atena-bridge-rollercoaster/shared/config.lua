-- Presentation/interaction tunables for the rollercoaster<->atena integration. These live in the
-- BRIDGE (headless: the UI is the bridge's, so are its knobs). The standalone DECIDES which actions
-- are available (gameplay); the bridge only maps each action name -> key + label + intent (here).

CoasterUI = CoasterUI or {}

-- Action map: rollercoaster publishes available action NAMES; the bridge renders the key/label and,
-- on the configured control, fires the intent export. (shift = two directions / two controls.)
CoasterUI.actions = {
    -- key = glyph token(s) for the KeyCap (canonical: 'E' 'SPACE' 'X', multi = space-separated → one
    -- cap each; 'LEFT RIGHT' renders as two arrow glyphs). label = the human description beside it.
    board = { control = 38, key = 'E',          label = 'Sali sulla giostra', intent = 'board' },   -- INPUT_PICKUP
    arms  = { control = 22, key = 'SPACE',      label = 'Braccia',            intent = 'toggleArms' }, -- INPUT_JUMP
    shift = { controls = { 174, 175 }, key = 'LEFT RIGHT', label = 'Cambia posto', intents = { 'shiftLeft', 'shiftRight' } },
    exit  = { control = 73, key = 'X',          label = 'Scendi',             intent = 'exit' },       -- INPUT_VEH_DUCK
}

-- texts the bridge maps published states to.
CoasterUI.closedText = 'Giostra in corsa'                          -- context = 'closed'
CoasterUI.status     = { running = 'In corsa…', barsDown = 'Barre abbassate' }   -- ride status banner
CoasterUI.countdown  = 'Partenza tra'                             -- launch banner prefix

-- control panel third-eye.
CoasterUI.targetRadius = 2.5
CoasterUI.panelOption  = { label = 'Apri quadro comandi', icon = 'settings' }
