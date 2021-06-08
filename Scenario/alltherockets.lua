-- To keep the scenario more manageable (for myself) I have done the following:
--      1. Keep all event calls here
--      2. Put all config options in config.lua
--      3. Put other stuff into their own files where possible

--REQUIRES--
local CONFIG = require("config")
local spawn = require("lib/atr_spawn")
local utils = require("lib/atr_utils")
local gui = require("lib/atr_gui")

--Holds items that are exported
local exports = {
    events = {},
    on_nth_tick = {}
}

function exports.on_init(event)
    spawn.setup()

    --Does this belong somewhere else?
    game.forces.player.research_queue_enabled = CONFIG.ENABLE_RESEARCH_QUEUE
    game.forces.player.friendly_fire = CONFIG.FRIENDLY_FIRE

end

exports.events[defines.events.on_gui_click] = function (event)
    if not (event and event.element and event.element.valid) then return end

    gui.on_gui_click(event)

end

exports.events[defines.events.on_player_created] = function (event)
    local player = game.players[event.player_index]
    gui.on_player_created(player)
end

exports.on_nth_tick[120] = function (event)
    game.print("Tick 120 fired")
end

return exports
