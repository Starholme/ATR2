--Provide each player it's own place to spawn

--CONSTANTS--
local FREE_CHUNKS_XY = 6 -- How many chunks need to be open in each direction to consider this spot 'open'
local CHUNKSIZE = 32 -- Size of chunks to work with
local MAX_CYCLES = 5 -- How many 'rings' around spawn to check before giving up

--REQUIRES--
--local req = require("whatever")

--GLOBAL--
--global.atr_split_spawn:{
--  player_info:[
--      playerIndex: {x,y}
--  ],
--  last_cycle: {i}
--}

local function testChunk(x,y)
    game.print("x:"..x.." y:"..y)
    if x == 2 and y == 2 then
        return {x = x, y = y}
    end
end

local function find_new_spawn_area(player_index)
    --Find somewhere on the map that has room for a new base

    local surface = game.get_surface("nauvis")

    --How many cycles from the center are we?
    local cycle = global.atr_split_spawn.last_cycle or 1

    local found

    while cycle < 5 do
        local ymin = cycle * -1
        local ymax = cycle
        local xmin = cycle * -1
        local xmax = cycle

        --go right
        for i = xmin,xmax,1 do
            found = testChunk(i, ymin)
            if found then break end
        end
        if found then break end
        --go down
        for i = ymin,ymax,1 do
            found = testChunk(xmax, i)
            if found then break end
        end
        if found then break end
        --go left
        for i = xmax,xmin,-1 do
            found = testChunk(i, ymax)
            if found then break end
        end
        if found then break end
        --go up
        for i = ymax,ymin,-1 do
            found = testChunk(xmin, i)
            if found then break end
        end
        if found then break end
        cycle = cycle + 1
    end

    game.print("cycle:"..cycle)

    game.print("FOUND x:"..found.x.." y:"..found.y)

end

local function set_new_player_spawn(player_index)
    game.print("set new player spawn")

    local player = game.players[player_index]

    --Where should they spawn?
    global.atr_split_spawn.player_info[player_index] = {
        x = player.character.position.x + 100,
        y = player.character.position.y + 100
    }

    game.print("x:" .. player.character.position.x)
    game.print("y:" .. player.character.position.y)

    find_new_spawn_area(player_index)

end

local function build_spawn_area()
    --Clear area
    --Set to grass or whatever
    --Add a moat
    --Add some trees
    --Add ores
end

--Holds items that are exported
local exports = {}

--Variables and functions should be named lowecase with underscores
--Constants should be all uppercase with underscores


function exports.on_player_created(player_index)
    game.print("player created" .. player_index)
    set_new_player_spawn(player_index)
end

function exports.on_init()
    --Ensure the global exists
    global.atr_split_spawn = {}
    global.atr_split_spawn.player_info = {}
end

function exports.on_load()
    --Ensure the global exists
    global.atr_split_spawn = global.atr_split_spawn or {}
    global.atr_split_spawn.player_info = global.atr_split_spawn.player_info or {}
end

return exports
