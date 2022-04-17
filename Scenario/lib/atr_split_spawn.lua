--Provide each player it's own place to spawn

--CONSTANTS--
local CHUNKSIZE = 32
local EMPTY_RADIUS_CHUNKS = 10 -- How many chunks need to be open in each direction to consider this spot 'open'
local MAX_CYCLES = 100 -- How many 'rings' around spawn to check before giving up
local SPAWN_SIZE = 96 -- How large is each generated spawn area
local MOAT_WIDTH = 2 -- How many tiles wide is the moat
local TREE_SIZE = 4
local ORE_AMOUNT = 250000

local STATE_NEW = "NEW" --New player, can make own spawn area
local STATE_WAITING = "WAITING" -- Waiting for chunks to generate
local STATE_CLEARING = "CLEARING" -- Clearing automatic entities
local STATE_BUILDING = "BUILDING" -- Creating the spawn area
local STATE_READY = "READY" --Location is prepared, user will be teleported
local STATE_DONE = "DONE" --Nothing needs to be done

--REQUIRES--
local utils = require("lib/atr_utils")
local gui_utils = require("lib/atr_gui_utils")
local CONFIG = require("config")

local atr_gui_ref --Used to keep a handle back to the gui

--GLOBAL--
--global.atr_split_spawn:{
--  player_info:[
--      playerIndex: {x,y,state,
--           sent_invites_to:[otherPlayerIndex:bool]}
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
        --game.print("FOUND x:"..found.x.." y:"..found.y)
        found.x = found.x * CHUNKSIZE
        found.y = found.y * CHUNKSIZE
    else
        game.print("Unable to find spawn point for new player!")
    end

    return found

end

local function check_spawn_charted(center, player_index)
    local player = game.get_player(player_index)
    player.print("Looking for your new home...")
    --game.print("Checking "..center.x..","..center.y)

    local surface = game.get_surface("nauvis")
    local force = game.forces.player

    local size_in_chunks = (SPAWN_SIZE / CHUNKSIZE)
    local center_chunk = {x=center.x/32, y=center.y/32}

    local all_charted = true
    for x = -size_in_chunks, size_in_chunks do
        for y = -size_in_chunks, size_in_chunks do
            local i_chunk = {x = center_chunk.x + x, y = center_chunk.y + y}
            if force.is_chunk_charted(surface, i_chunk) == false then
                all_charted = false
            end
        end
    end

    if all_charted then
        --game.print("All charted "..center.x..","..center.y)
        global.atr_split_spawn.player_info[player_index].state = STATE_CLEARING
    else
        --Chart a slightly larger area than the spawn area
        size_in_chunks = size_in_chunks + 3
        local top_left = {x = center.x - size_in_chunks * CHUNKSIZE, y = center.y - size_in_chunks * CHUNKSIZE}
        local bottom_right = {x = center.x + size_in_chunks * CHUNKSIZE, y = center.y + size_in_chunks * CHUNKSIZE}
        --game.print("Request chart "..center.x..","..center.y)
        force.chart(surface, {top_left, bottom_right})
    end

end

local function clear_spawn_area(center, player_index)
    --game.print("Clearing! "..center.x..","..center.y)
    local player = game.get_player(player_index)
    player.print("Clearing out space for your new home...")

    local surface = game.get_surface("nauvis")
    local size_in_chunks = (SPAWN_SIZE / CHUNKSIZE) + 3
    local top_left = {x = center.x - size_in_chunks * CHUNKSIZE, y = center.y - size_in_chunks * CHUNKSIZE}
    local bottom_right = {x = center.x + size_in_chunks * CHUNKSIZE, y = center.y + size_in_chunks * CHUNKSIZE}
    --Clear area
    for _, v in pairs(surface.find_entities({top_left, bottom_right})) do
        v.destroy()
    end
    --game.print("Cleared! "..top_left.x..","..top_left.y.." "..bottom_right.x..","..bottom_right.y)
    global.atr_split_spawn.player_info[player_index].state = STATE_BUILDING
end

local function build_spawn_area(center, player_index)
    local player = game.get_player(player_index)
    player.print("Building your new home...")

    utils.draw_text_small("Welcome home!", center.x - 7, center.y - 10)
    local surface = game.get_surface("nauvis")
    local top_left = {x = center.x - SPAWN_SIZE / 2, y = center.y - SPAWN_SIZE / 2}
    local bottom_right = {x = center.x + SPAWN_SIZE / 2, y = center.y + SPAWN_SIZE / 2}

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
                --gap in the moat at top
                if y < MOAT_WIDTH and x > (SPAWN_SIZE/2) - 2 and x < (SPAWN_SIZE/2) + 2 then
                    tile.name = "grass-2"
                end
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

local function find_new_player_spawn(player_index)
    --game.print("set new player spawn")

    local player = game.players[player_index]

    local position = find_new_spawn_area()
    if not position then
        return --Failed to find a suitable location
    end

    --Where should they spawn?
    local player_info = global.atr_split_spawn.player_info[player_index]
    player_info.x = position.x
    player_info.y = position.y
    player_info.state = STATE_WAITING
end

local function teleport_home(player_index)
    local player = game.get_player(player_index)
    local player_info = global.atr_split_spawn.player_info[player_index]

    if not player_info then
        return
    end

    if player_info.state ~= STATE_WAITING then
        player.teleport({player_info.x, player_info.y})
    end
end

local function teleport_other_home(player_index, other_player_index)
    local player = game.get_player(player_index)
    local other_player_info = global.atr_split_spawn.player_info[other_player_index]

    if not other_player_info then
        return
    end
    player.teleport({other_player_info.x, other_player_info.y})
end

--Holds items that are exported
local exports = {}

--Variables and functions should be named lowecase with underscores
--Constants should be all uppercase with underscores

function exports.on_init()
    if not CONFIG.ENABLE_SPLIT_SPAWN then return end

    --Ensure the global exists
    global.atr_split_spawn = {}
    global.atr_split_spawn.player_info = {}
end

function exports.on_player_joined_game()
    if not CONFIG.ENABLE_SPLIT_SPAWN then return end

    --Ensure the global exists
    global.atr_split_spawn = global.atr_split_spawn or {}
    global.atr_split_spawn.player_info = global.atr_split_spawn.player_info or {}
    --Migrate existing data to new format
    for key, value in pairs(global.atr_split_spawn.player_info) do
        value.x = value.x or 0
        value.y = value.y or 0
        value.state = value.state or STATE_NEW
        value.sent_invites_to = value.sent_invites_to or {}
    end
end

function exports.on_player_created(player_index)
    if not CONFIG.ENABLE_SPLIT_SPAWN then return end

    --Default spawn is 0,0
    global.atr_split_spawn.player_info[player_index] = {
        x = 0,
        y = 0,
        state = STATE_NEW,
        sent_invites_to = {}
    }
end

function exports.check_spawn_state()
    if not CONFIG.ENABLE_SPLIT_SPAWN then return end

    for player_index, value in pairs(global.atr_split_spawn.player_info) do
        if value.state == STATE_WAITING then
            check_spawn_charted({x=value.x, y=value.y}, player_index)
        elseif value.state == STATE_CLEARING then
            clear_spawn_area({x=value.x, y=value.y}, player_index)
        elseif value.state == STATE_BUILDING then
            build_spawn_area({x=value.x, y=value.y}, player_index)
        elseif value.state == STATE_READY then
            value.state = STATE_DONE
            teleport_home(player_index)
        end
    end
end

function exports.build_tab(tab, player, gui)
    if not CONFIG.ENABLE_SPLIT_SPAWN then return end

    atr_gui_ref = gui --Store a handle so we can call close/refresh/etc.

    local player_info = global.atr_split_spawn.player_info[player.index]

    gui_utils.add_label(tab, "title", "Spawn options?!", gui_utils.STYLES.LABEL_HEADER_STYLE)
    gui_utils.add_spacer_line(tab)

    gui_utils.add_label(tab, "home_info", "My home:"..player_info.x..","..player_info.y, gui_utils.STYLES.MY_LONGER_LABEL_STYLE)

    gui_utils.add_button(tab, "atr_spawn_teleport_home", "Teleport Home")

    if CONFIG.TEST_MODE or player_info.state == STATE_NEW then
        gui_utils.add_button(tab, "atr_spawn_find_new", "I want my own spawn point!")
    end

    gui_utils.add_spacer_line(tab)

    --Players list: Name-Invite/Invited-Teleport to their home
    local invite_table = tab.add{type="table", name="atr_invite_table", column_count=3, draw_horizontal_line_after_headers=true}
    gui_utils.add_label(invite_table, "player_header", "Player ")
    gui_utils.add_label(invite_table, "invite_header", " ")
    gui_utils.add_label(invite_table, "teleport_header", " ")

    for other_player_index,v in pairs(game.players) do
        local other_player_info = global.atr_split_spawn.player_info[other_player_index]
        gui_utils.add_label(invite_table, "player"..other_player_index, v.name)

        local invite_sent = player_info.sent_invites_to[other_player_index] or false
        if invite_sent then
            gui_utils.add_button(invite_table, "atr_spawn_btn_invite_player"..other_player_index, "Cancel Invite")
        else
            gui_utils.add_button(invite_table, "atr_spawn_btn_invite_player"..other_player_index, "Send Invite")
        end

        local invited_by = other_player_info.sent_invites_to[player.index] or false
        if invited_by then
            gui_utils.add_button(invite_table, "atr_spawn_btn_teleport_to_home"..other_player_index, "Teleport to")
        else
            gui_utils.add_label(invite_table, "atr_spawn_btn_teleport_to_home"..other_player_index, " ")
        end
    end

end

local function invite_player_clicked(event)
    local player_info = global.atr_split_spawn.player_info[event.player_index]
    local other_player_index = tonumber(string.sub(event.element.name, 28))
    local invited = player_info.sent_invites_to[other_player_index] or false

    --game.print("invite_player_clicked "..event.player_index.."|"..event.element.name.."|"..other_player_index)
    --Toggle invited state
    if invited then
        player_info.sent_invites_to[other_player_index] = false
        event.element.caption = "Send Invite"
    else
        player_info.sent_invites_to[other_player_index] = true
        event.element.caption = "Cancel Invite"
    end
end

function exports.on_gui_click(event)
    if not CONFIG.ENABLE_SPLIT_SPAWN then return end

    local player = game.players[event.player_index]
    if event.element.name == "atr_spawn_teleport_home" then
        teleport_home(event.player_index)
        atr_gui_ref.hide_gui(player)
    elseif event.element.name == "atr_spawn_find_new" then
        find_new_player_spawn(event.player_index)
        atr_gui_ref.hide_gui(player)
    elseif string.starts_with(event.element.name, "atr_spawn_btn_invite_player") then
        invite_player_clicked(event)
    elseif string.starts_with(event.element.name, "atr_spawn_btn_teleport_to_home") then
        local other_player_index = tonumber(string.sub(event.element.name, 31))
        teleport_other_home(event.player_index, other_player_index)
        atr_gui_ref.hide_gui(player)
    end

end

return exports
