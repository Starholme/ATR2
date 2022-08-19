--CONSTANTS--
local ENABLED = settings.global["enable-adaptive-biters"].value
local KILLS_TO_EVOLVE = settings.global["adaptive-biters-kte"].value
local IMMUNE = settings.global["adaptive-biters-immune"].value

local EVOLVE_AMOUNT = 0.05 --How much to decrease damage modifier at once
local EVOLVE_MIN = -0.95 --Lowest possible damage modifier
--REQUIRES--

local function decrement_and_check_modifier(ammo_category, force)
    local modifier = force.get_ammo_damage_modifier(ammo_category)
    --game.print("dec: ".. ammo_category .. " mod: " .. modifier .. " min: " .. EVOLVE_MIN .. " amount: " .. EVOLVE_AMOUNT)
    if modifier - EVOLVE_AMOUNT > EVOLVE_MIN then
        force.set_ammo_damage_modifier(ammo_category, modifier - EVOLVE_AMOUNT)
        return EVOLVE_AMOUNT
    end
    return 0
end

local function increment_modifier(ammo_category, force, amount)
    if IMMUNE then return end
    local modifier = force.get_ammo_damage_modifier(ammo_category)
    modifier = modifier + amount
    force.set_ammo_damage_modifier(ammo_category, modifier)
end

local function adjust_ammo_damage_modifiers(damage_type)
    local force = game.forces["player"]

    --Get the relevant ammo categories
    if damage_type == "explosion" then
        local amount = 0
        amount = amount + decrement_and_check_modifier("artillery-shell", force)
        amount = amount + decrement_and_check_modifier("cannon-shell", force)
        amount = amount + decrement_and_check_modifier("grenade", force)
        amount = amount + decrement_and_check_modifier("landmine", force)
        amount = amount + decrement_and_check_modifier("rocket", force)

        local each = amount / 6
        increment_modifier("artillery-shell", force, each)
        increment_modifier("bullet", force, each)
        increment_modifier("cannon-shell", force, each)
        increment_modifier("flamethrower", force, each)
        increment_modifier("laser", force, each)
        increment_modifier("shotgun-shell", force, each)

    elseif damage_type == "physical" then
        local amount = 0
        amount = amount + decrement_and_check_modifier("artillery-shell", force)
        amount = amount + decrement_and_check_modifier("bullet", force)
        amount = amount + decrement_and_check_modifier("cannon-shell", force)
        amount = amount + decrement_and_check_modifier("shotgun-shell", force)

        local each = amount / 7
        increment_modifier("artillery-shell", force, each)
        increment_modifier("cannon-shell", force, each)
        increment_modifier("flamethrower", force, each)
        increment_modifier("grenade", force, each)
        increment_modifier("landmine", force, each)
        increment_modifier("laser", force, each)
        increment_modifier("rocket", force, each)

    elseif damage_type == "fire" then
        local amount = 0
        amount = amount + decrement_and_check_modifier("flamethrower", force)

        local each = amount / 8
        increment_modifier("artillery-shell", force, each)
        increment_modifier("bullet", force, each)
        increment_modifier("cannon-shell", force, each)
        increment_modifier("grenade", force, each)
        increment_modifier("landmine", force, each)
        increment_modifier("laser", force, each)
        increment_modifier("rocket", force, each)
        increment_modifier("shotgun-shell", force, each)

    elseif damage_type == "laser" then
        local amount = 0
        amount = amount + decrement_and_check_modifier("laser", force)

        local each = amount / 8
        increment_modifier("artillery-shell", force, each)
        increment_modifier("bullet", force, each)
        increment_modifier("cannon-shell", force, each)
        increment_modifier("flamethrower", force, each)
        increment_modifier("grenade", force, each)
        increment_modifier("landmine", force, each)
        increment_modifier("rocket", force, each)
        increment_modifier("shotgun-shell", force, each)        
    end
--[[ ammo-category
artillery-shell - physical, explosion
beam - electric
bullet - physical
cannon-shell - physical, explosion
electric - electric
flamethrower - fire
grenade - explosion
landmine - explosion
laser - laser
melee - physical
rocket - explosion
shotgun-shell - physical
--]]
end

local exports = {}

exports.on_init = function(event)
    if not ENABLED then return end
    global.atr_adaptive_biters = {
        damage_type = {
            electric = 0,
            explosion = 0,
            fire = 0,
            laser = 0,
            physical = 0,
            acid = 0,
            impact = 0,
            poison = 0
        }
    }
end

exports.on_entity_died = function(event)
    if not ENABLED then return end
    --game.print(event.damage_type.name)
    global.atr_adaptive_biters.damage_type[event.damage_type.name] = global.atr_adaptive_biters.damage_type[event.damage_type.name] + 1
end
exports.on_entity_died_filter = {filter = "type", type = "unit"}

exports.on_runtime_mod_setting_changed = function(event)
    ENABLED = settings.global["enable-adaptive-biters"].value
    KILLS_TO_EVOLVE = settings.global["adaptive-biters-kte"].value
    IMMUNE = settings.global["adaptive-biters-immune"].value
end

exports.on_tick = function(event)
    if not ENABLED then return end
    local damage_type = global.atr_adaptive_biters.damage_type
    --Look at the damage type counters
    for k, v in pairs(damage_type) do
        --Check if it needs to be adjusted
        if v > KILLS_TO_EVOLVE then
            --Decrement
            damage_type[k] = v - KILLS_TO_EVOLVE
            --Run adjustment
            adjust_ammo_damage_modifiers(k)
        end
    end
end
exports.on_tick_modulus = 300 --5 seconds

commands.add_command("atr_adaptive_biters", nil, function(command)
    local output = "Adaptive biters enabled: " .. tostring(ENABLED)
    local force = game.forces["player"]
    
    output = output .. "\n artillery-shell:" .. force.get_ammo_damage_modifier("artillery-shell")
    output = output .. "\n beam:" .. force.get_ammo_damage_modifier("beam")
    output = output .. "\n bullet:" .. force.get_ammo_damage_modifier("bullet")
    output = output .. "\n cannon-shell:" .. force.get_ammo_damage_modifier("cannon-shell")
    output = output .. "\n electric:" .. force.get_ammo_damage_modifier("electric")
    output = output .. "\n flamethrower:" .. force.get_ammo_damage_modifier("flamethrower")
    output = output .. "\n grenade:" .. force.get_ammo_damage_modifier("grenade")
    output = output .. "\n landmine:" .. force.get_ammo_damage_modifier("landmine")
    output = output .. "\n laser:" .. force.get_ammo_damage_modifier("laser")
    output = output .. "\n melee:" .. force.get_ammo_damage_modifier("melee")
    output = output .. "\n rocket:" .. force.get_ammo_damage_modifier("rocket")
    output = output .. "\n shotgun-shell:" .. force.get_ammo_damage_modifier("shotgun-shell")
    game.player.print(output)
end)

return exports

--/c game.print(game.forces["player"].get_ammo_damage_modifier("beam"))
--/c game.print(game.forces["player"].set_ammo_damage_modifier("beam", 2.2))
--/c game.forces["player"].research_all_technologies()


--[[ ammo-category
artillery-shell - physical, explosion
beam - electric
biological - Spitters!
bullet - physical
cannon-shell - physical, explosion
capsule
electric - electric
flamethrower - fire
grenade - explosion
landmine - explosion
laser - laser
melee - physical
rocket - explosion
shotgun-shell - physical
*/

/* Damage type
acid
electric
explosion
fire
impact
laser
physical
poison
*/
--]]