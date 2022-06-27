
--Variables and functions should be named lowecase with underscores
--Constants should be all uppercase with underscores

--CONSTANTS--
local SOLAR_MODIFIER = 5
local TICKS_PER_DAY = 3600 --one minutes
--Middle of the day is '0', middle of night is '1'
--Targeted to about half day, very short night
local DAWN = 0.55 --Full bright, Default 0.75
local DUSK = 0.1 --Dimming, Default 0.25
local EVENING = 0.32 --Dark, Default 0.45
local MORNING = 0.33 --Brightening, Default 0.55
local MIN_BRIGHTNESS = 0.15 --Darkest possible? Default 0.15

local FAST_CHUNKS = 4 --How many chunks to give before slowing down
local SECONDS_PER_CHUNK = 240 --How many seconds played to earn a new chunk

--REQUIRES--
local CONFIG = require("config")

--GLOBAL--
--[[
global.atr_void{
  players[
    player_index = {
      candidates[chunk_position,chunk_position,...],
      candidates_count = 0,
      current_chunk = 1024 array of xy's,
      total_chunks = 1,
      surface_name,
      last_test = 0
    },...
  ]
}
--]]

local function test_chunk(surface, chunk_position)
    if not surface.is_chunk_generated(chunk_position) then
        --game.print("test_chunk true: ".. chunk_position.x ..",".. chunk_position.y)
        return true
    end
    local tile = surface.get_tile((chunk_position.x * 32) + 16, (chunk_position.y * 32) + 16)
    if tile.name == "out-of-map" then
        --game.print("test_chunk true: ".. chunk_position.x ..",".. chunk_position.y)
        return true
    end
    --game.print("test_chunk false: ".. chunk_position.x ..",".. chunk_position.y)
    return false
end

local function add_candidates(player_index, chunk_position)
    --Check all four directions from this chunk
    --Add to candidates if required

    local p = global.atr_void.players[player_index]
    local surface = game.surfaces[p.surface_name]

    local up = {x = chunk_position.x, y = chunk_position.y - 1}
    local down = {x = chunk_position.x, y = chunk_position.y + 1}
    local left = {x = chunk_position.x - 1, y = chunk_position.y}
    local right = {x = chunk_position.x + 1, y = chunk_position.y}

    if test_chunk(surface, up) then
        table.insert(p.candidates, up)
        p.candidates_count = p.candidates_count + 1
    end
    if test_chunk(surface, down) then
        table.insert(p.candidates, down)
        p.candidates_count = p.candidates_count + 1
    end
    if test_chunk(surface, left) then
        table.insert(p.candidates, left)
        p.candidates_count = p.candidates_count + 1
    end
    if test_chunk(surface, right) then
        table.insert(p.candidates, right)
        p.candidates_count = p.candidates_count + 1
    end
    --game.print("candidates_count: ".. p.candidates_count)
end

local function create_spawn_area(surface)
    local tiles = {}
    local tile

    local top_left = {x = 0, y = 0}
    -- Create a concrete square
    for x=top_left.x,top_left.x + 31 do
        for y=top_left.y,top_left.y + 31 do
            tile = {name="refined-concrete", position={x,y}}
            if x == top_left.x or x == top_left.x + 31
            or y == top_left.y or y == top_left.y + 31 then
                tile.name = "refined-hazard-concrete-left"
            end
            table.insert(tiles,tile)
        end
    end
    surface.set_tiles(tiles)
    surface.create_entity({name="subspace-item-extractor", position = {top_left.x + 16, top_left.y + 16}, force="player"})
    remote.call("clusterio","reset")
end

local function update_surface_settings(surface)
    surface.show_clouds = false
    surface.solar_power_multiplier = SOLAR_MODIFIER
    --Create a fast day/night cycle
    surface.ticks_per_day = TICKS_PER_DAY
    --Need to double set these to stop crashing...
    surface.evening = 0.32
    surface.morning = 0.33
    surface.dawn = DAWN
    surface.dusk = DUSK
    surface.evening = EVENING
    surface.morning = MORNING
    surface.min_brightness = MIN_BRIGHTNESS
end

local function on_player_created(player)
    --Create new surface that is just void
    local map_gen_settings = {
		default_enable_all_autoplace_controls = false,
		property_expression_names = {cliffiness = 0},
        autoplace_controls = {},
		autoplace_settings = {
            tile = {
                treat_missing_as_default = false
            }
        },
		starting_area = "none",
        peaceful_mode = true,
	}
    local surface_name = "player"..player.index
    local surface = game.create_surface(surface_name, map_gen_settings)

    global.atr_void.players[player.index] = {
        candidates = {},
        candidates_count = 0,
        current_chunk = nil,
        total_chunks = 1,
        surface_name = surface_name,
        last_test = 0
    }

    add_candidates(player.index, {x=0, y = 0})

    --Disable clouds, set brightness, day/night cycle
    update_surface_settings(surface)
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    local surface = game.get_surface("player"..player.index)

    update_surface_settings(surface)

    --Teleport player
    player.teleport({2,2}, surface)
end

local function clear_chunk(event)
    --Spawn area?
    if event.position.x == 0 and event.position.y == 0 then
        create_spawn_area(event.surface)
        return
    end

    local tile_name = "out-of-map"

    local top_left = event.area.left_top
    local bottom_right = event.area.right_bottom
    local tiles = {}
    local tile = {}

    for x=top_left.x,bottom_right.x do
        for y=top_left.y,bottom_right.y do
            tile = {name=tile_name, position={x,y}}
            table.insert(tiles,tile)
        end
    end
    event.surface.set_tiles(tiles)
end

local function fish_chunk(player, p, surface)
    --Is the player holding a fish?
    local stack = player.cursor_stack
    if not stack.valid_for_read then return end
    if not (stack.name == "raw-fish") then return end

    --Take a fish
    stack.count = stack.count - 1
    --Say thanks!
    player.print("eEeEeEeEeEeEeE-click-click(Thanks for all the fish!)")

    --Look for a empty chunk nearby somehow? Search out of map tiles?
    local tiles = surface.find_tiles_filtered({position = player.position, radius = 10, limit = 1, name = "out-of-map"})
    if table_size(tiles) < 1 then return nil end

    local tile = tiles[1]
    --Convert to a chunk position
    local x = math.floor(tile.position.x / 32)
    local y = math.floor(tile.position.y / 32)
    return {x = x, y = y}
end

local function pick_chunk(player, p)
    --Check if player can get a new chunk
    local max_chunks = FAST_CHUNKS + math.floor(player.online_time / (SECONDS_PER_CHUNK * 60))
    --game.print("ticks played:"..player.online_time.." max chunks:"..max_chunks)
    --Return if they are not eligible for a new chunk
    if max_chunks < p.total_chunks then return end
    if p.candidates_count == 0 then return end

    local surface = game.surfaces[p.surface_name]

    local chunk
    --FishChunk?
    chunk = fish_chunk(player, p, surface)

    --Otherwise, pick a random chunk from the eligible chunks
    if not chunk then
        chunk = table.remove(p.candidates, math.random(p.candidates_count))
    end

    p.candidates_count = p.candidates_count - 1
    --game.print("Picked: ".. chunk.x..","..chunk.y)

    --Verify that this chunk is still empty
    if not test_chunk(surface, chunk) then return end
    p.total_chunks = p.total_chunks + 1

    p.current_chunk = {}
    --Generate tile list
    for x = chunk.x * 32, (chunk.x * 32) + 31 do
        for y = chunk.y * 32, (chunk.y * 32) + 31 do
            table.insert(p.current_chunk, {x=x, y=y})
        end
    end
    --Add surrounding chunks to candidate list
    add_candidates(player.index, chunk)
end

local function expand_chunk(player, tick)
    local p = global.atr_void.players[player.index]

    --Check for new chunk, no more than every two seconds
    if not p.current_chunk and tick > p.last_test + 120 then
        --Pick new chunk
        pick_chunk(player, p)
        p.last_test = tick
        return
    end

    if not p.current_chunk then return end

    --Pick a random tile
    local size = table_size(p.current_chunk)
    local tile_pos = table.remove(p.current_chunk, math.random(size))

    --Remove the list if it will be empty now
    if size == 1 then p.current_chunk = nil end

    --Set the tile
    local x = tile_pos.x
    local y = tile_pos.y
    local tile = {name="refined-concrete", position={x,y}}
    if x % 32 == 0 or x % 32 == 31
    or y % 32 == 0 or y % 32 == 31 then
        tile.name = "refined-hazard-concrete-left"
    end
    local tiles = {}
    table.insert(tiles, tile)
    local surface = game.surfaces[p.surface_name]
    surface.set_tiles(tiles)
end

local function on_tick(event)
    --Loop active players
    for key, player in pairs(game.connected_players) do
        expand_chunk(player, event.tick)
    end
end

--Holds items that are exported
local exports = {}
exports.on_init = function ()
    if not CONFIG.ENABLE_VOID then return end

    global.atr_void = {players = {}}
    game.map_settings.pollution.enabled = false
    game.forces.player.recipes["subspace-electricity-extractor"].enabled = false
    game.forces.player.recipes["subspace-electricity-injector"].enabled = false
    game.forces.player.friendly_fire = true --Let there be train kills/nuke oops

    CONFIG.SOFTMOD_TEXT = CONFIG.SOFTMOD_TEXT .. "Void Space - You get your own space station to build on. Expands with time played!\n"
end

exports.on_player_created = function (player)
    if not CONFIG.ENABLE_VOID then return end
    on_player_created(player)
end

exports.on_player_joined_game = function (event)
    if not CONFIG.ENABLE_VOID then return end
    on_player_joined_game(event)
end

exports.on_chunk_generated = function (event)
    if not CONFIG.ENABLE_VOID then return end
    clear_chunk(event)
end

exports.on_tick = function(event)
    if not CONFIG.ENABLE_VOID then return end
    on_tick(event)
end

return exports
