--Provide each player it's own place to spawn

--CONSTANTS--
local CHUNKSIZE = 32
local EMPTY_RADIUS_CHUNKS = 4 -- How many chunks need to be open in each direction to consider this spot 'open'
local MAX_CYCLES = 10 -- How many 'rings' around spawn to check before giving up
local SPAWN_SIZE = 96 -- How large is each generated spawn area
local MOAT_WIDTH = 2 -- How many tiles wide is the moat
local TREE_SIZE = 4
local ORE_AMOUNT = 250000

local STATE_WAITING = "WAITING"
local STATE_READY = "READY"
local STATE_DONE = "DONE"

--REQUIRES--
local utils = require("lib/atr_utils")
local CONFIG = require("config")

--GLOBAL--
--global.atr_split_spawn:{
--  player_info:[
--      playerIndex: {x,y,state}
--  ],
--  last_cycle: {i}
--}

local function test_chunk(x, y, surface)
    --Ensure no player entities nearby
    --Count entities within a radius
    local radius = EMPTY_RADIUS_CHUNKS * CHUNKSIZE
    local position = {x = x * CHUNKSIZE, y = y * CHUNKSIZE}
    local count = surface.count_entities_filtered({
        position = position,
        radius = radius,
        force = "player",
        limit = 10
    })

    --game.print("test_chunk: x:"..x.." y:"..y.." entities: "..count)
    if count == 0 then
        return {x = x, y = y}
    end
end

local function find_new_spawn_area()
    --Find somewhere on the map that has room for a new base

    local surface = game.get_surface("nauvis")

    --How many cycles from the center are we?
    local cycle = global.atr_split_spawn.last_cycle or 1

    local found

    while cycle < MAX_CYCLES do
        local ymin = cycle * -1
        local ymax = cycle
        local xmin = cycle * -1
        local xmax = cycle

        --go right
        for i = xmin,xmax,1 do
            found = test_chunk(i, ymin, surface)
            if found then break end
        end
        if found then break end
        --go down
        for i = ymin,ymax,1 do
            found = test_chunk(xmax, i, surface)
            if found then break end
        end
        if found then break end
        --go left
        for i = xmax,xmin,-1 do
            found = test_chunk(i, ymax, surface)
            if found then break end
        end
        if found then break end
        --go up
        for i = ymax,ymin,-1 do
            found = test_chunk(xmin, i, surface)
            if found then break end
        end
        if found then break end
        cycle = cycle + 1
    end

    if found then
        game.print("FOUND x:"..found.x.." y:"..found.y)
        found.x = found.x * CHUNKSIZE
        found.y = found.y * CHUNKSIZE
    else
        game.print("Unable to find spawn point for new player!")
    end

    return found

end

local function build_spawn_area(center, player_index)
    utils.draw_text_small("Welcome home!", center.x - 7, center.y - 10)
    local surface = game.get_surface("nauvis")
    local top_left = {x = center.x - SPAWN_SIZE / 2, y = center.y - SPAWN_SIZE / 2}
    local bottom_right = {x = center.x + SPAWN_SIZE / 2, y = center.y + SPAWN_SIZE / 2}
    --Ensure area is generated
    surface.request_to_generate_chunks(center, 3)

    --Clear area
    for _, v in pairs(surface.find_entities({top_left, bottom_right})) do
        v.destroy()
    end

    --Add a moat, fill center with grass
    local tiles = {}
    local tile
    for x = 0, SPAWN_SIZE do
        for y = 0, SPAWN_SIZE do
            --Default to grass
            tile = {name = "grass-1", position = {top_left.x + x, top_left.y + y}}

            --Add a moat
            if x < MOAT_WIDTH or x > SPAWN_SIZE - MOAT_WIDTH or
                y < MOAT_WIDTH or y > SPAWN_SIZE - MOAT_WIDTH
            then
                tile.name = "water"
            end
            --gap in the moat at top
            if x > center.x-2 and x < center.x+2 then
                tile.name = "grass-2"
            end

            table.insert(tiles, tile)
        end
    end
    surface.set_tiles(tiles)

    --Add some trees
    local tree_position = {x=center.x, y=top_left.y}
    for x = 0, TREE_SIZE do
        for y = 0, TREE_SIZE do
            surface.create_entity({name="tree-01", position = {tree_position.x + x, tree_position.y + y}})
        end
    end

    --Add ores
    utils.spawn_ore_blob("iron-ore", ORE_AMOUNT, top_left.x + 10, top_left.y + 10, surface)
    utils.spawn_ore_blob("copper-ore", ORE_AMOUNT, top_left.x + 10, bottom_right.y - 10, surface)
    utils.spawn_ore_blob("stone", ORE_AMOUNT / 5, bottom_right.x - 10, bottom_right.y - 10, surface)
    utils.spawn_ore_blob("coal", ORE_AMOUNT / 2, bottom_right.x - 10, top_left.y + 10, surface)

    global.atr_split_spawn.player_info[player_index].state = STATE_READY
end

local function set_new_player_spawn(player_index)
    --game.print("set new player spawn")

    local player = game.players[player_index]

    local position = find_new_spawn_area()
    if not position then
        return --Failed to find a suitable location
    end

    --Where should they spawn?
    global.atr_split_spawn.player_info[player_index] = {
        x = position.x,
        y = position.y,
        state = STATE_WAITING
    }
end

local function teleport_home(player_index)
    local player = game.get_player(player_index)
    local player_info = global.atr_split_spawn.player_info[player_index]

    if player_info.state == STATE_READY or player_info.state == STATE_DONE then
        player.teleport({player_info.x, player_info.y})
        --game.print("TELEPORT HOME: "..player_info.x..","..player_info.y)
    end

end

--Holds items that are exported
local exports = {}

--Variables and functions should be named lowecase with underscores
--Constants should be all uppercase with underscores


function exports.on_player_created(player_index)
    if not CONFIG.ENABLE_SPLIT_SPAWN then return end

    game.print("player created" .. player_index)
    set_new_player_spawn(player_index)
end

function exports.on_init()
    if not CONFIG.ENABLE_SPLIT_SPAWN then return end

    --Ensure the global exists
    global.atr_split_spawn = {}
    global.atr_split_spawn.player_info = {}
end

function exports.on_load()
    if not CONFIG.ENABLE_SPLIT_SPAWN then return end

    --Ensure the global exists
    global.atr_split_spawn = global.atr_split_spawn or {}
    global.atr_split_spawn.player_info = global.atr_split_spawn.player_info or {}
end

function exports.check_spawn_state()
    if not CONFIG.ENABLE_SPLIT_SPAWN then return end

    for player_index, value in pairs(global.atr_split_spawn.player_info) do
        if value.state == STATE_WAITING then
            build_spawn_area({x=value.x, y=value.y}, player_index)
        elseif value.state == STATE_READY then
            value.state = STATE_DONE
            teleport_home(player_index)
        end
    end
end

return exports
