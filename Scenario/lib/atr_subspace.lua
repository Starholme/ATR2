--CONSTANTS--
local CHANCE_OF_SUBSPACE_PAD = 100 --Chance is 1/this constant, so 1 over 100, or 1 over 1000, etc.

--REQUIRES--
local CONFIG = require("config")

--Holds items that are exported
local exports = {}

local function spawn_subspace_pad(chunk_position)
    local top_left = {x = chunk_position.x * 32, y=chunk_position.y * 32}
    game.print("Making a subspace pad at: "..top_left.x..","..top_left.y)
end

function exports.on_chunk_generated(event)
    if not CONFIG.ENABLE_SUBSPACE then return end

    if math.random(CHANCE_OF_SUBSPACE_PAD) == 1 then
        spawn_subspace_pad(event.position)
    end
end

return exports
