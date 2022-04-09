--CONSTANTS--
local CHANCE_OF_SUBSPACE_PAD = 500 --Chance is 1/this constant, so 1 over 100, or 1 over 1000, etc.

--REQUIRES--
local CONFIG = require("config")

--GLOBAL
--global.atr_subspace{
--    last_spawned = "someentity"
--}

--Holds items that are exported
local exports = {}

local function spawn_subspace_pad(chunk_position)
    local top_left = {x = chunk_position.x * 32, y=chunk_position.y * 32}
    --game.print("Making a subspace pad at: "..top_left.x..","..top_left.y)

    local surface = game.get_surface("nauvis")
    local tiles = {}
    local tile

    --Clear any junk
    for _, v in pairs(surface.find_entities({top_left, {top_left.x + 32,top_left.y+32}})) do
        if v.name ~= "character" then
            v.destroy()
        end
    end

    -- Create a concrete square
    for x=top_left.x,top_left.x + 32 do
        for y=top_left.y,top_left.y + 32 do
            tile = {name="refined-concrete", position={x,y}}
            if x == top_left.x or x == top_left.x + 32
            or y == top_left.y or y == top_left.y + 32 then
                tile.name = "refined-hazard-concrete-left"
            end
            table.insert(tiles,tile)
        end
    end
    surface.set_tiles(tiles)

    --Add the entity
    local last_spawned = global.atr_subspace.last_spawned
    local name
    if last_spawned == 3 then
        name = "subspace-item-injector"
        last_spawned = -1
    elseif last_spawned == 0 then
        name = "subspace-item-extractor"
    elseif last_spawned == 1 then
        name = "subspace-fluid-injector"
    elseif last_spawned == 2 then
        name = "subspace-fluid-extractor"
    end
    global.atr_subspace.last_spawned = last_spawned + 1
    local entity = surface.create_entity({name=name, position = {top_left.x + 16, top_left.y + 16}, force="player"})
    entity.destructible = false
    entity.minable = false

    remote.call("clusterio","reset")
end

function exports.on_init()
    global.atr_subspace = {last_spawned = 0}
end

function exports.on_chunk_generated(event)
    if not CONFIG.ENABLE_SUBSPACE then return end

    if math.random(CHANCE_OF_SUBSPACE_PAD) == 1 then
        spawn_subspace_pad(event.position)
    end
end

return exports
