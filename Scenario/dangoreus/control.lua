---@diagnostic disable: deprecated
--dangOreus, a scenario by Mylon
--MIT Licensed

local CONFIG = require("config")

--These are checked by type and name.
local dangOre_exceptions = {
    ["mining-drill"] = true,
    ["car"] = true,
    ["spider-vehicle"] = true,
    ["locomotive"] = true,
    ["cargo-wagon"] = true,
    ["fluid-wagon"] = true,
    ["artillery-wagon"] = true,
    ["tile-ghost"] = true
}
local dangOre_easy_exceptions = { --Rail and signals and turrets checked seperately (type only)
    ["transport-belt"] = true,
    ["underground-belt"] = true,
    ["splitter"] = true,
    ["electric-pole"] = true,
    ["container"] = true,
    ["logistic-container"] = true,
    ["pipe"] = true,
    ["pipe-to-ground"] = true,
    ["wall"] = true,
    ["gate"] = true,
}

--Settings, these only work on game start and cannot be changed after.
global.STARTING_RADIUS = 40 --settings.global["starting radius"].value
global.EASY_ORE_RADIUS = 60 --settings.global["simple ore radius"].value
global.DANGORE_MODE = "random"--settings.global["dangOre mode"].value
global.SQUARE_MODE = false --settings.global["square mode"].value
global.V_SCALE_FACTOR = 3.0 --settings.global["voronoi scale factor"].value

local perlin = require("perlin") --Perlin Noise.

ORE_SCALING = 0.78 --Exponent for ore amount.
LINEAR_SCALAR = 12 -- For ore amount.
XFER_FACTOR = 3.0 -- ERF() factor, for non-uniform perlin transfer

--
-- some tweakable factors for the voronoi function
--
RING_SIZE = 200.0    -- width of rings
WOBBLE_DEPTH = 40.0  -- depth to "blend" the rings to
WOBBLE_FACTOR = 6.0  -- number of revolutions to use
WOBBLE_SCALE = 0.7   -- how to scale the number of revolutions based on the ring number

local function clamp(min, max, v)
    if v < min then return min end
    if v > max then return max end
    return v
end

--Build the list of ores
local function divOresity_init()
    global.disabled = global.disabled or {}

    -- Migration for pre-1.5.0 saves
    if global.DANGORE_MODE == 1 then global.DANGORE_MODE = "random" end
    if global.DANGORE_MODE == 2 then global.DANGORE_MODE = "perlin" end

    --Some spitballed numbers for vanilla ores.  Temporary hack until I can figure out how to read the new equivalent of autoplace.coverage
    global.coverage = {
        ["iron-ore"] = 1.1,
        ["copper-ore"] = 0.9,
        ["coal"] = 0.6,
        ["stone"] = 0.4,
        ["uranium-ore"] = 0.06,
    }

    --relying on resource_category is unsafe!  Let's build a list out of solid ores.  At this stage, we'll also filter infinite resources because why not.
    global.solid_resources = {}
    for name, entity in pairs(game.get_filtered_entity_prototypes{{filter="type", type="resource"}, {filter="autoplace", mode="and"}}) do
        --log("Inspecting " .. name)
        local add = true
        if entity.infinite_resource then
            add = false
        end
        for _, product in pairs(entity.mineable_properties.products) do
            if product.type == "fluid" then
                add = false
                break
            end
        end
        if add then
            global.solid_resources[name] = true
        end
    end
    --log("Solid resources: " .. serpent.line(global.solid_resources))

    --Each chunk picks a table to generate from.  Each table has either 3 copies of one ore, or 6 copies.
    global.easy_ore_list = {}
	global.diverse_ore_list = {}

    global.ore_chunks = {}

    global.perlin_ore_list = {}
    local rv = {}
    rv[1] = math.random() * 200.0
    rv[2] = math.random() * 200.0
    rv[3] = math.random() * 200.0
    rv[4] = math.random() * 200.0
    rv[5] = math.random() * 50000.0
    global.rand_vecs = rv

    --These are depreciated.
    -- global.easy_ores = {}
    -- global.diverse_ores = {}

	for k,v in pairs(game.entity_prototypes) do
        --if v.type == "resource" and v.resource_category == "basic-solid" and v.autoplace_specification then
        if global.solid_resources[k] then
            table.insert(global.diverse_ore_list, v.name)
            if v.mineable_properties.required_fluid == nil then
                table.insert(global.easy_ore_list, v.name)
            end
        end
	end

    --Check to see if we're playing normal.  Marathon requires more copper.
    if game.difficulty_settings.recipe_difficulty == 0 then
        --This is a hack to make the ratios easier to handle.
        --This hack only makes sense for vanilla ores.
        local vanilla_ores = false
        for k,v in pairs(global.easy_ore_list) do
            if v == "iron-ore" then
                vanilla_ores = true
                break
            end
        end
        if vanilla_ores then
            --1:1:1:1 creates way too much copper, stone.  Coal at least can be liquefied.
            --This changes it to a 3:2:2:1 ratio
            --table.insert(global.diverse_ore_list, "iron-ore")
            table.insert(global.easy_ore_list, "iron-ore")
            table.insert(global.easy_ore_list, "iron-ore")
            table.insert(global.easy_ore_list, "copper-ore")
            table.insert(global.easy_ore_list, "coal")
        end
    end

    --Perlin Ore list generation
    local ore_ranking_raw = {}
    local ore_ranking = {}
    local ore_total = 0

    for k,v in pairs(global.diverse_ore_list) do
        local autoplace = game.surfaces[1].map_gen_settings.autoplace_controls[v]
        local adding
        if autoplace then
            if autoplace.frequency == "none" then
                adding = 0
            else
                adding = autoplace.frequency * autoplace.size
            end
        end
        if not adding then adding = 0 end
        if adding > 0 then
            local amount = adding * (global.coverage[v] or 1) --(game.entity_prototypes[v].autoplace_specification.coverage
            if game.entity_prototypes[v].mineable_properties.required_fluid then
                table.insert(ore_ranking_raw, 1, {name=v, amount=amount})
            else
                table.insert(ore_ranking_raw, {name=v, amount=amount})
            end
            ore_total = ore_total + amount
        end
    end

    --Debug
    --log(serpent.block(ore_ranking_raw))

    --scale ore distribution from 0 to 1.
    local last_key = 0
    --local ore_ranking_size = 0 --Essentially #ore_ranking_raw
    for k,v in pairs(ore_ranking_raw) do
        local key = last_key + v.amount / ore_total
        last_key = key

        if key == 1 then key = 0.9999999 end
        --ore_ranking[key] = v.name
        table.insert(ore_ranking, {v.name, key})
        --ore_ranking_size = ore_ranking_size + 1
        --Debug
        --log("Ore: " .. v.name .. " portion: " .. key)
        --According to this, at this stage, uranium should be 2% of all ore.
    end

    --This next bit requires a lerp
    --Returns x3
    local function lerp(x1, x2, dy, y3)
        return y3 * (x2-x1)/dy + x1
    end

    --Now do a pass to scale these numbers according to perlin.MEASURED distribution
    local last_ranking_key = 0
    last_key = -1
    local previous_iter = -1
    local count = 0
    for k,v in pairs(ore_ranking) do
        --local range = k - last_ranking_key -- This is the percentage that should appear of this ore type
        local range = v[2] - last_ranking_key -- This is the percentage that should appear of this ore type
        last_ranking_key = v[2]
        local measured_sum = 0 -- This is the range that our perlin steps cover, from last_key to n
        --log("For ore " .. v[1] .. " using range " .. range)
        -- count = count + 1 -- This is so we do something special on the last one.  Rounding errors may cause the last ore to not be inserted otherwise.
        --local perlin_key
        --The last ore will never get used.  Let's determine if we're at the end of the table and write the last key there.
        for n, p in pairs(perlin.MEASURED) do
            --Skip keys we've already iterated over
            if n > last_key then
                measured_sum = measured_sum + p
                --if count < ore_ranking_size then
                    if measured_sum > range then
                        --log("measured sum is " .. measured_sum .. " and key range is " .. n - last_key)
                        local x3 = lerp(previous_iter, n, p, range - (measured_sum - p) )
                        table.insert(global.perlin_ore_list, {v[1], x3})
                        --perlin_ore_list[n] = name
                        last_key = n
                        previous_iter = n
                        break
                    end
                --else
                --    perlin_ore_list[0.9999999] = v
                    --game.print(0.88 - n .. "," .. range) --Debug.
                    --break
                --end
                previous_iter = n
            end
        end
    end

    --
    -- Generate a lookup table of 1000 slots, distributed correctly so
    -- they respect the ratios of ore the autoplacer wants to place
    --
    local ore_list = {}
    local f = 0.0
    local j = 1
    for i = 1, 1000 do
        local current = ore_ranking_raw[j]
        table.insert(ore_list, current.name)
        if f > current.amount then
            j = j + 1
            f = f - current.amount
        end
        f = f + ore_total / 1000.0
    end

    global.ORE_LIST = ore_list

    -- perlin_ore_list[math.abs(k)^0.5 * sign] = v
    -- perlin_ore_list[k] = v

    --Pie mode
    --We already have the ore_ranking so let's copy it to our global table.
    global.pie = global.pie or {rotation = math.random() * 2 * math.pi, ores = {}}

    for _, ore in pairs(ore_ranking) do
        table.insert(global.pie.ores, ore)
    end

end

local function voronoi(x, y)
    local function dot(vx, vy, ux, uy)
        return vx * ux + vy * uy
    end

    local function fract(v)
        -- Is there a more sane way to do this?
        local a, b = math.modf(v)
        return b
    end

    local function randAt(px, py)
        local rv = global.rand_vecs
        local a = {dot(px, py, rv[1], rv[2]), dot(px, py, rv[3], rv[4])}
        a[1] = fract(math.sin(a[1]) * rv[5])
        a[2] = fract(math.sin(a[2]) * rv[5])
        return a
    end

    --
    -- transform input coordinate, and determine a scale factor
    --
    local scaleFactor = global.V_SCALE_FACTOR
    local ring = math.floor(math.sqrt(x * x + y * y) / RING_SIZE)
    local ang = math.atan2(x, y)
    local gx = x + math.sin(ang * WOBBLE_FACTOR * (1 + ring * WOBBLE_SCALE)) * WOBBLE_DEPTH -- perturb coords used for actual ring determination
    local gy = y + math.cos(ang * WOBBLE_FACTOR * (1 + ring * WOBBLE_SCALE)) * WOBBLE_DEPTH
    ring = math.floor(math.sqrt(gx * gx + gy * gy) / RING_SIZE)
    local scale = clamp(4.0, 50.0, ring * 10.0) * scaleFactor
    local offx = randAt(scale, 0)[1] * 50.0 -- prevent the same random layout repeating on higher scale sections by shifting it a bit
    x = x / scale + offx
    y = y / scale

    --
    -- cell noise
    --
    local close = {}
    local ix, fx = math.modf(x)
    local iy, fy = math.modf(y)
    local best = 100
    for ny = -1, 1 do
        for nx = -1, 1 do
            local p = randAt(ix + ny, iy + nx)
            local dx = ny + p[1] / 1.8 - fx
            local dy = nx + p[2] / 1.8 - fy
            local d = dx * dx + dy * dy
            if d < best then
                best = d
                close[1] = ix + ny
                close[2] = iy + nx
            end
        end
    end

    --
    -- pick an ore type based on this cell's centroid
    --
    return randAt(close[1], close[2])[1]
end

--Sprinkle ore everywhere
local function gOre(event)
    --Ensure we've done our init
    if not global.perlin_ore_list then divOresity_init() end
    --log(serpent.line(global.perlin_ore_list))

    local oldores = event.surface.find_entities_filtered{type="resource", area=event.area}
    local oils = {}
    for k, v in pairs(oldores) do
        --if v.prototype.resource_category == "basic-solid" then
        --log(k)
        if global.solid_resources[v.name] then
            v.destroy()
        else
			table.insert(oils, v)
		end
    end

    --Generate our random once for the whole chunk.
    local rand = math.random()

    --What kind of chunk are we generating?  Biased, ore, or random?
    --Check our global table of nearby chunks.
    --If any nearby chunks use the biased table, we must use the matching that ore to determine ore type.
    -- chunk_type starts off as a table in case it borders multiple biased patches, then we collapse it after checking neighbors
    local chunk_type = {}
    local biased = false
    local chunkx = event.area.left_top.x
    local chunky = event.area.left_top.y

    local function check_chunk_bias(x,y)
        if global.ore_chunks[x] then
            if global.ore_chunks[x][y] then
                if global.ore_chunks[x][y].biased then
                    table.insert(chunk_type, global.ore_chunks[x][y].type)
                end
            end
        end
    end

    local function check_chunk_type(x,y)
        if global.ore_chunks[x] then
            if global.ore_chunks[x][y] then
                table.insert(chunk_type, global.ore_chunks[x][y].type)
                return
            end
        end
        -- Still here? Insert random.
        table.insert(chunk_type, "random")
    end

    --starting from top, clockwise
    check_chunk_bias(chunkx, chunky-32)
    check_chunk_bias(chunkx+32, chunky)
    check_chunk_bias(chunkx, chunky+32)
    check_chunk_bias(chunkx-32, chunky)

    --Collapse table
    if #chunk_type > 0 then
        chunk_type = chunk_type[math.random(#chunk_type)]
        -- chance this chunk is also biased.
        if math.random() < 0.25 then
            biased = true
        end
    else
        --Repeat process for non-biased chunks
        check_chunk_type(chunkx, chunky-32)
        check_chunk_type(chunkx+32, chunky)
        check_chunk_type(chunkx, chunky+32)
        check_chunk_type(chunkx-32, chunky)

        chunk_type = chunk_type[math.random(#chunk_type)]
        --If type is not random, chance chunk is biased.
        --If type is random, chance chunk type is different.
        if chunk_type == "random" then
            if math.random() < 0.25 then
                --if math.max(math.abs(chunkx), math.abs(chunkx+32))^2 + math.max(math.abs(chunky), math.abs(chunky+32))^2 > global.EASY_ORE_RADIUS^2 then
                if math.max(math.abs(chunkx), math.abs(chunkx+32)^2, math.abs(chunky), math.abs(chunky+32)) > global.EASY_ORE_RADIUS^2 then
                    chunk_type = global.diverse_ore_list[math.random(#global.diverse_ore_list)]
                else
                    chunk_type = global.easy_ore_list[math.random(#global.diverse_ore_list)]
                end
            end
        else
            if math.random() < 0.25 then
                biased = true
            end
        end
    end

    --Set global table with this type/bias
    if not global.ore_chunks[chunkx] then
        global.ore_chunks[chunkx] = {}
    end
    global.ore_chunks[chunkx][chunky] = {type=chunk_type, biased=biased}

    local function transferFunc(f)
        f = math.tanh(2 * XFER_FACTOR * f * (1.0 + 0.08943 * f * f * XFER_FACTOR * XFER_FACTOR) / math.sqrt(3.14159))
        f = (5000.0 + 5000.0 * f) / 10000.0
        f = f - 0.5
        return 2.0 * f
    end

    for x = event.area.left_top.x, event.area.left_top.x + 31 do
        for y = event.area.left_top.y, event.area.left_top.y + 31 do
            local bbox = {{ x, y}, {x+0.5, y+0.5}}
            if not event.surface.get_tile(x,y).collides_with("water-tile") and event.surface.count_entities_filtered{type="cliff", area=bbox} == 0 then
                if global.SQUARE_MODE and ( math.abs(x) >= global.STARTING_RADIUS or math.abs(y) >= global.STARTING_RADIUS ) or (not global.SQUARE_MODE and x^2 + y^2 >= global.STARTING_RADIUS^2) then
                    local type
                    if global.DANGORE_MODE == "random" then
                        --Build the ore list.  Uranium can only appear in uranium chunks.
                        local ore_list = {}
                        for k, v in pairs(global.easy_ore_list) do
                            table.insert(ore_list, v)
                        end
                        if not (chunk_type == "random") then
                            --Build the ore list.  non-baised chunks get 3 instances, biased chunks get 6.  Except uranium, which has no default instance in the table.
                            table.insert(ore_list, chunk_type)
                            --table.insert(ore_list, chunk_type)
                            if biased then
                                table.insert(ore_list, chunk_type)
                                table.insert(ore_list, chunk_type)
                                --table.insert(ore_list, chunk_type)
                            end
                            --game.print(serpent.line(ore_list))
                        end
                        type = ore_list[math.random(#ore_list)]
                    elseif global.DANGORE_MODE == "voronoi" then
                        local noise = voronoi(x, y)
                        local ore_list = global.ORE_LIST
                        type = ore_list[clamp(1, #ore_list, math.floor(#ore_list * (noise / 2 + 0.5)) + 1)]
                    elseif global.DANGORE_MODE == "perlin" then
                        local noise = perlin.noise(x,y)
                        local ore_list = global.ORE_LIST
                        noise = transferFunc(noise)
                        type = ore_list[clamp(1, #ore_list, math.floor(#ore_list * (noise / 2 + 0.5)) + 1)]
                        if not type then
                            local _
                            _, type = next(global.perlin_ore_list)
                        end
                    elseif global.DANGORE_MODE == "pie" then
                        --We need a number from 0 to 1
                        local rad = (math.atan2(y, x) + global.pie.rotation) % (math.pi * 2) / (math.pi * 2)
                        --log(rad)
                        for _, ore in pairs(global.pie.ores) do
                            if rad < ore[2] then
                                type = ore[1]
                                break
                            end
                        end
                        --Default case.  Shouldn't need this!
                        type = type or global.pie.ores[1][1]
                    elseif global.DANGORE_MODE == "spiral" then
                        --We need a number from 0 to 1
                        local rad = (math.atan2(y, x) + global.pie.rotation + (x^2 + y^2)^0.5 / 100) % (math.pi * 2) / (math.pi * 2)
                        --log(rad)
                        for _, ore in pairs(global.pie.ores) do
                            if rad < ore[2] then
                                type = ore[1]
                                break
                            end
                        end
                        --Default case.  Shouldn't need this!
                        type = type or global.pie.ores[1][1]
                    end
                    local amount = ( ( global.SQUARE_MODE and ( math.max(math.abs(x), math.abs(y)) )^2 ) or (x^2 + y^2) )
                        ^ ORE_SCALING / LINEAR_SCALAR * game.surfaces[1].map_gen_settings.autoplace_controls[type].richness
                    amount = math.max(1, amount)
                    event.surface.create_entity{name=type, amount=amount, position={x, y}, enable_tree_removal=false, enable_cliff_removal=false}
                end
            end
        end
    end

    --Ore blocks oil from rendering the resource radius.  Clean up any resources around oil.
    for k, v in pairs(oils) do
        local area = {{v.bounding_box.left_top.x - 1, v.bounding_box.left_top.y - 1}, {v.bounding_box.right_bottom.x + 1, v.bounding_box.right_bottom.y + 1}}
		local overlap = v.surface.find_entities_filtered{type="resource", area=area}
		for n, p in pairs(overlap) do
            --if p.prototype.resource_category == "basic-solid" then
            if global.solid_resources[p] then
				p.destroy()
			end
		end
    end
end



--Auto-destroy non-mining drills.
local function dangOre(event)
    local entity_name, entity_type = event.created_entity.name, event.created_entity.type
    if entity_name == "entity-ghost" then entity_name, entity_type = event.created_entity.ghost_name, event.created_entity.ghost_type end
    if dangOre_exceptions[entity_name] or dangOre_exceptions[entity_type] then return end
    if  (dangOre_easy_exceptions[entity_name] or dangOre_easy_exceptions[entity_type] or --settings.global["easy mode"].value and
        string.find(entity_name, "rail") or
        string.find(entity_name, "turret")) then
        return
    end
    --Some entities have no bounding box area.  Not sure which.
    if event.created_entity.bounding_box.left_top.x == event.created_entity.bounding_box.right_bottom.x or event.created_entity.bounding_box.left_top.y == event.created_entity.bounding_box.right_bottom.y then
        return
    end
    local last_user = event.created_entity.last_user
    local ores = event.created_entity.surface.count_entities_filtered{type="resource", area=event.created_entity.bounding_box}
    if ores > 0 then
        --Need to turn off ghosts left by dead buildings so construction bots won't keep placing buildings and having them blow up.
        local ttl = event.created_entity.force.ghost_time_to_live
        local force = event.created_entity.force
        event.created_entity.force.ghost_time_to_live = 0
        event.created_entity.die()
        force.ghost_time_to_live = ttl
        if last_user then
            last_user.print("Cannot build non-miners on resources!")
        end
    end
end

--Destroying chests causes any contained ore to spill onto the ground.
local function ore_rly(event)
    local items = {"stone", "coal", "iron-ore", "copper-ore", "uranium-ore"}
    if event.entity.type == "container" or event.entity.type == "cargo-wagon" or event.entity.type == "logistic-container" or event.entity.type == "car" then
        --Let's spill all items instead.
        for i = 1, 10 do
            if event.entity.get_inventory(i) then
                for k,v in pairs(event.entity.get_inventory(i).get_contents()) do
                    event.entity.surface.spill_item_stack(event.entity.position, {name=k, count=v})
                end
            end
        end
    end
end

--Limit exploring
local function flOre_is_lava()
    --if not settings.global["floor is lava"].value then return end
    for n, p in pairs(game.connected_players) do
        if p.character and not global.disabled[p.surface.name] then --Spectator or admin
            if math.abs(p.position.x) > global.EASY_ORE_RADIUS or math.abs(p.position.y) > global.EASY_ORE_RADIUS then
                --Check for nearby ore.
                global.flOre = global.flOre or {}
                local distance = global.flOre[p.name] or 1
                local count = p.surface.count_entities_filtered{type="resource", area={{p.position.x-(10*distance), p.position.y-(10*distance)}, {p.position.x+(10*distance), p.position.y+(10*distance)}}}
                if count > (distance * 20) ^2 * 0.80 and distance < 10 then
                    global.flOre[p.name] = distance + 1
                else
                    global.flOre[p.name] = math.max(distance - 1, 1)
                end
                if global.flOre[p.name] > 0 then
                    local target = p.vehicle or p.character
                    p.surface.create_entity{name="acid-stream-worm-medium", target=target, source_position=target.position, position=target.position, duration=30}
                    target.health = target.health - 15 * distance
                    if target.health == 0 then target.die() end
                end
            end
        end
    end
end

--Holds items that are exported
local exports = {
    events = {},
    on_nth_tick = {}
}

exports.on_built_all = function(event)
    if not CONFIG.ENABLE_DANGOREUS then return end
    event.created_entity = event.created_entity or event.entity
    if not global.disabled[event.created_entity.surface.name] then
        dangOre(event)
    end
end

exports.on_chunk_generated = function (event)
    if not CONFIG.ENABLE_DANGOREUS then return end
    if not global.disabled[event.surface.name] then
        gOre(event)
    end
end

exports.on_entity_died = function(event)
    if not CONFIG.ENABLE_DANGOREUS then return end
    if not global.disabled[event.entity.surface.name] then
        ore_rly(event)
    end
end

exports.on_nth_tick120 = function(event)
    if not CONFIG.ENABLE_DANGOREUS then return end
    flOre_is_lava()
end

exports.on_configuration_changed = function(event)
    if not CONFIG.ENABLE_DANGOREUS then return end
    divOresity_init()
end

function exports.on_init(event)
    if not CONFIG.ENABLE_DANGOREUS then return end
    divOresity_init()
    perlin.shuffle()
end

return exports
