-- To keep the scenario more manageable (for myself) I have done the following:
--      1. Keep all event calls here
--      2. Put all config options in config.lua
--      3. Put other stuff into their own files where possible

--REQUIRES--
local CONFIG = require("config")
local Spawn = require("lib/atr_spawn")
local Utils = require("lib/atr_utils")
local Gui = require("lib/atr_gui")

--Holds items that are exported
local exports = {
    events = {},
    on_nth_tick = {}
}

function exports.on_init(event)
    Spawn.Setup()
end

exports.events[defines.events.on_gui_click] = function (event)
    if not (event and event.element and event.element.valid) then return end

    Gui.OnGuiClick(event)

end

exports.events[defines.events.on_player_created] = function (event)
    local player = game.players[event.player_index]
    Gui.OnPlayerCreated(player)
end

exports.on_nth_tick[120] = function (event)
    game.print("Tick 120 fired")
end

return exports
