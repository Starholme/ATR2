--CONSTANTS--
local BLAST_RADIUS = 48
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

    --Remove some tiles
    
    --Replace one tile with water
    local nuke_tiles = crater.tiles
    count = table_size(nuke_tiles)

    local tiles = {}
    for i=1,REPLACE_TILES do
        table.insert(tiles, {name="water-shallow", position = table.remove(nuke_tiles, math.random(count))})
        count = count - 1
        if count < 1 then break end
    end
    surface.set_tiles(tiles)

    --Remove crater if 'done'
    if (count < 1) then
        table.remove(craters,1)
    end
end

local function add_crater(tile, tick, surface)
    local craters = global.atr_nuke_crater
    
    --Search for tiles that could be in the blast radius
    local found_tiles = surface.find_tiles_filtered{position = tile, name = "nuclear-ground", radius = BLAST_RADIUS}

    local crater_id = found_tiles[1].position.x..":"..found_tiles[1].position.y
    --Is this a crater that we already know about?
    for k,v in pairs(craters) do
        if crater_id == v.crater_id then 
            game.print("duplicate crater")
            return 
        end
    end

    game.print("new crater:"..crater_id.." tiles:"..table_size(found_tiles))

    local crater = {tick = tick, tiles = {}, crater_id = crater_id}
    for k,v in pairs(found_tiles) do
        table.insert(crater.tiles, v.position)
    end
    --Add to list of craters
    table.insert(craters, crater)
end

local function look_for_crater(surface, tick)
    game.print("looking for crater")
    --Check for 'any' nuke tiles in a random chunk
    local rnd_chunk = surface.get_random_chunk()

    --If 0,0 then no chunks are ready
    if rnd_chunk.x == 0 and rnd_chunk.y == 0 then return end

    local area = {{x=rnd_chunk.x * 32, y=rnd_chunk.y * 32},{x=(rnd_chunk.x+1) * 32, y=(rnd_chunk.y+1) * 32}}
    local found_tiles = surface.find_tiles_filtered{area = area, name="nuclear-ground"}
    local count = table_size(found_tiles)

    --If at least one found, save as a crater
    if count > 0 then
        game.print("found crater")
        add_crater(found_tiles[1].position, tick, surface)
    end

end

exports.on_tick = function (event)
    --Ensure the global exists
    global.atr_nuke_crater = global.atr_nuke_crater or {}

    local surface = game.get_surface("nauvis")
    
    look_for_crater(surface, event.tick)

    fill_crater(surface, event.tick)
end
exports.on_tick_modulus = 10

return exports