--CONSTANTS--
local CHANCE_OF_SUBSPACE_PAD = 100 --Chance is 1/this constant, so 1 over 100, or 1 over 1000, etc.

--REQUIRES--
local CONFIG = require("config")

--Holds items that are exported
local exports = {}

local function spawn_subspace_pad(chunk_position)
    local top_left = {x = chunk_position.x * 32, y=chunk_position.y * 32}
    game.print("Making a subspace pad at: "..top_left.x..","..top_left.y)

    local surface = game.get_surface("nauvis")
    local tiles = {}
    local tile

    -- Create a concrete square
    for x=top_left.x,top_left.x + 32 do
        for y=top_left.y,top_left.y + 32 do
            tile = {name="refined-concrete", position={x,y}}
            table.insert(tiles,tile)
        end
    end
    surface.set_tiles(tiles)

    --Add the entity
    local rand = math.random(4)
    local name
    game.print("rand:"..rand)
    if rand == 1 then
        name = "subspace-item-injector"
    elseif rand == 2 then
        name = "subspace-item-extractor"
    elseif rand == 3 then
        name = "subspace-fluid-injector"
    else
        name = "subspace-fluid-extractor"
    end
    local entity = surface.create_entity({name=name, position = {top_left.x + 16, top_left.y + 16}, force="player"})
    entity.destructible = false
    entity.minable = false
end

function exports.on_chunk_generated(event)
    if not CONFIG.ENABLE_SUBSPACE then return end

    if math.random(CHANCE_OF_SUBSPACE_PAD) == 1 then
        spawn_subspace_pad(event.position)
    end
end

return exports
