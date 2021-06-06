-- To keep the scenario more manageable (for myself) I have done the following:
--      1. Keep all event calls here
--      2. Put all config options in config.lua
--      3. Put other stuff into their own files where possible

-- Require other modules
local CONFIG = require("config")
local Spawn = require("lib/atr_spawn")
local Utils = require("lib/atr_utils")
local Gui = require("lib/atr_gui")


-- Event handlers
local function OnInit(event)
    Spawn.Setup()
end

local function OnGuiClick(event)
    if not (event and event.element and event.element.valid) then return end

    Gui.OnGuiClick(event)

end

local function OnPlayerCreated(event)
    local player = game.players[event.player_index]
    Gui.OnPlayerCreated(player)
end

local function tick120(event)
    game.print("Tick 120 fired")
end

return {
    events = {
        [defines.events.on_gui_click] = OnGuiClick,
        [defines.events.on_player_created] = OnPlayerCreated
    },
    on_init = OnInit,
    on_nth_tick = {[120] = tick120}
}
