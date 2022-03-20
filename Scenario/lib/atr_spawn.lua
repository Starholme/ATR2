--CONSTANTS--
local MAX_STEP = 100

--REQUIRES--
local utils = require("lib/atr_utils")

local step_table = {}
local function build_step_table()

    table.insert(step_table, function (surface)
        utils.draw_text_large("Welcome to ATR!", -20, -10)
    end)

    --Clear entities
    table.insert(step_table, function (surface)
        for _, v in pairs(surface.find_entities({{-50,-50}, {50,50}})) do
            if v.name ~= "character" then
                v.destroy()
            end
        end
    end)

    --concrete under welcome
    table.insert(step_table, function (surface)
        local tiles = {}
        local tile
        for x=-25,25 do
            for y=-10,10 do
                tile = {name="refined-concrete", position={x,y}}
                table.insert(tiles,tile)
            end
        end
        surface.set_tiles(tiles)
    end)

    --10x10 hazard concrete for combinator
    table.insert(step_table, function (surface)
        local tiles = {}
        local tile
        for x=-5,5 do
            for y=0,10 do
                tile = {name="refined-concrete", position={x,y}}
                if x == -5 or x == 5 or y == 0 or y == 10 then
                    tile.name = "refined-hazard-concrete-left"
                end
                table.insert(tiles,tile)
            end
        end
        surface.set_tiles(tiles)
    end)

    --Combinator
    table.insert(step_table, function (surface)
        local combinator = surface.create_entity({name="subspace-resource-combinator", position = {0,5}, force="player"})
        combinator.destructible = false
        combinator.minable = false
    end)
end

--Holds items that are exported
local exports = {}

function exports.setup()
    global.atr_spawn = {step = 0}



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
