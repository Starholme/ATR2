--CONSTANTS--
local MAX_STEP = 100

--REQUIRES--
local utils = require("lib/atr_utils")

local step_table = {}
local function build_step_table()
    --10x10 hazard concrete center
    table.insert(step_table, function (surface)
        local tiles = {}
        local tile
        for x=-5,5 do
            for y=-5,5 do
                tile = {name="refined-hazard-concrete-left", position={x,y}}
                table.insert(tiles,tile)
            end
        end
        surface.set_tiles(tiles)
    end)

    --Combinator
    table.insert(step_table, function (surface)
        local combinator = surface.create_entity({name="constant-combinator", position = {0,0}, force="player"})
        combinator.destructible = false
    end)
end

--Holds items that are exported
local exports = {}

function exports.setup()
    global.atr_spawn = {step = 0}

    utils.draw_text_large("Welcome to ATR!", -20, -6)

    build_step_table()
end

function exports.on_nth_tick()
    local step = global.atr_spawn.step
    if step > MAX_STEP then return end

    step = step + 1
    global.atr_spawn.step = step

    local surface = game.get_surface("nauvis")
    if step_table[step] then
        step_table[step](surface)
    end

end

return exports
