--CONSTANTS--
local BLAST_RADIUS = 3
local BLAST_OBLONGITY = 0
local REPLACE_TILES = 2
local MIN_CRATER_AGE = 60 * 60

--REQUIRES--
--local req = require("whatever")

--Holds items that are exported
local exports = {}

local function fill_crater(surface, tick)
    local craters = global.atr_nuke_crater
    if table_size(craters) == 0 then return end

    --Get the oldest crater
    local crater = craters[1]
    --Check age
    if crater.tick + MIN_CRATER_AGE > tick then return end

    local position = crater.position or {x = 0, y= 0}
    local left = {x = position.x - (BLAST_OBLONGITY + 1), y = position.y}
    local right = {x = position.x + BLAST_OBLONGITY, y = position.y}

    --Look for tiles
    local nuke_tiles = surface.find_tiles_filtered{position = left, name = "nuclear-ground", radius = BLAST_RADIUS}
    local right_tiles = surface.find_tiles_filtered{position = right, name = "nuclear-ground", radius = BLAST_RADIUS}
    --game.print("looking at: "..position.x..":"..position.y)

    --Combine both to get a 'oblong' shape
    for k,v in pairs(right_tiles) do
        table.insert(nuke_tiles, v)
    end

    --Remove some tiles    
    count = table_size(nuke_tiles)

    local tiles = {}
    for i=1,REPLACE_TILES do
        table.insert(tiles, {name="water-shallow", position = table.remove(nuke_tiles, math.random(count)).position})
        count = count - 1
        if count < 1 then break end
    end
    surface.set_tiles(tiles)

    --Remove crater if 'done'
    if (count < 1) then
        table.remove(craters,1)
    end
end

local function look_for_crater(event)
    --game.print("looking for crater")
    local surface = game.surfaces[event.surface_index]
    local tick = event.tick
    local position = event.target_position
    local craters = global.atr_nuke_crater

    --Create a crater and add to the list
    local crater_id = position.x..":"..position.y
    local crater = {tick = tick, crater_id = crater_id, position = position}
    table.insert(craters, crater)
end

exports.on_tick = function (event)
    --Ensure the global exists
    global.atr_nuke_crater = global.atr_nuke_crater or {}

    local surface = game.get_surface("nauvis")

    fill_crater(surface, event.tick)
end
exports.on_tick_modulus = 10

exports.on_script_trigger_effect = function (event)
    --Ensure the global exists
    global.atr_nuke_crater = global.atr_nuke_crater or {}

    game.print(event.effect_id .. event.target_position.x .. event.target_position.y)
    look_for_crater(event)
end

return exports