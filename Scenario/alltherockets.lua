-- To keep the scenario more manageable (for myself) I have done the following:
--      1. Keep all event calls here
--      2. Put all config options in config.lua
--      3. Put other stuff into their own files where possible

--REQUIRES--
local CONFIG = require("config")
local gui = require("lib/atr_gui")
local spawn = require("lib/atr_spawn")
local split_spawn = require("lib/atr_split_spawn")
local subspace = require("lib/atr_subspace")
local test_mode = require("lib/atr_test_mode")
local vehicle_snap = require("lib/atr_vehicle_snap")


--Holds items that are exported
local exports = {
    events = {},
    on_nth_tick = {}
}

function exports.on_init(event)
    spawn.setup()
    split_spawn.on_init()
    subspace.on_init()

    --Does this belong somewhere else?
    game.forces.player.research_queue_enabled = CONFIG.ENABLE_RESEARCH_QUEUE
    game.forces.player.friendly_fire = CONFIG.FRIENDLY_FIRE

end

exports.events[defines.events.on_chunk_generated] = function (event)
    subspace.on_chunk_generated(event)
end

exports.events[defines.events.on_gui_click] = function (event)
    if not (event and event.element and event.element.valid) then return end

    gui.on_gui_click(event)

    split_spawn.on_gui_click(event)

end

exports.events[defines.events.on_player_created] = function (event)
    local player = game.players[event.player_index]
    gui.on_player_created(player)
    split_spawn.on_player_created(event.player_index)

    if (CONFIG.TEST_MODE) then
        test_mode.on_player_created(player)
    end

end

exports.events[defines.events.on_player_joined_game] = function (event)
    split_spawn.on_player_joined_game()
end

exports.events[defines.events.on_player_driving_changed_state] = function (event)
    vehicle_snap.on_player_driving_changed_state(event)
end

exports.on_nth_tick[6] = function (event)
    vehicle_snap.on_nth_tick()
    spawn.on_nth_tick()
end

exports.on_nth_tick[120] = function (event)
    split_spawn.check_spawn_state()
end

exports.on_nth_tick[600] = function (event)
    if (CONFIG.TEST_MODE) then
        game.print("TEST MODE ACTIVE!")
    end
end

return exports
