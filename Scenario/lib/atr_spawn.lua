--CONSTANTS--
local MAX_STEP = 100

--REQUIRES--
local utils = require("lib/atr_utils")

local step_table = {}
local function build_step_table()

    table.insert(step_table, function (surface)
        utils.draw_text_large("Welcome to ATR!", -22, -10)
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
            for y=-10,12 do
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
        for x=-3,3 do
            for y=2,8 do
                tile = {name="refined-concrete", position={x,y}}
                if x == -3 or x == 3 or y == 2 or y == 8 then
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

        remote.call("clusterio","reset")
    end)

    --Instructions box
    table.insert(step_table, function (surface)
        local xmin = -24
        local xmax = -4
        local ymin = -2
        local ymax = 11
        local tiles = {}
        local tile
        for x=xmin,xmax do
            for y=ymin,ymax do
                tile = {name="out-of-map", position={x,y}}
                if x==xmax or x==xmin or y==ymin or y==ymax then
                    tile.name = "tutorial-grid"
                end
                table.insert(tiles,tile)
            end
        end
        surface.set_tiles(tiles)
    end)

    --Instructions
    table.insert(step_table, function (surface)
        utils.draw_text_tiny("This region is rich in hydrocarbons, with little else to offer.", -22, 0)
        utils.draw_text_tiny("One large subspace injector train station has been established,", -22, 1)
        utils.draw_text_tiny("injectors are unable to be placed elsewhere.", -22, 2)
        utils.draw_text_tiny("Expand. Defend. Refine. Repeat.", -22, 3)
    end)

    --Instructions box right
    table.insert(step_table, function (surface)
        local xmin = 4
        local xmax = 24
        local ymin = -2
        local ymax = 11
        local tiles = {}
        local tile
        for x=xmin,xmax do
            for y=ymin,ymax do
                tile = {name="out-of-map", position={x,y}}
                if x==xmax or x==xmin or y==ymin or y==ymax then
                    tile.name = "tutorial-grid"
                end
                table.insert(tiles,tile)
            end
        end
        surface.set_tiles(tiles)
    end)

    --Instructions right
    table.insert(step_table, function (surface)
        utils.draw_text_tiny("The enemy evolves to resist our weapons, but great resistance to", 6, 0)
        utils.draw_text_tiny("one type means weakness to another.", 6, 1) 
        utils.draw_text_tiny("Show them some love and variety.", 6, 2)
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
