--CONSTANTS--
local LARGE = 10
local SMALL = 5
local ORANGE = {0.9, 0.7, 0.3, 0.8}

--REQUIRES--

--Holds items that are exported
local exports = {}

local function draw_text(surface, x, y, scale, color, text)
    rendering.draw_text{
        text=text,
        surface=surface,
        target={x,y},
        color=color,
        scale=scale,
        --Allowed fonts: default-dialog-button default-game compilatron-message-font default-large default-large-semibold default-large-bold heading-1 compi
        font="compi",
        draw_on_ground=true
    }
end

function exports.draw_text_large(text, x, y)
    draw_text("nauvis", x, y, LARGE, ORANGE, text)
end

function exports.draw_text_small(text, x, y)
    draw_text("nauvis", x, y, SMALL, ORANGE, text)
end

function exports.spawn_ore_blob(name, amount, x_position, y_position, surface)
    --ie: spawn_ore_blob("iron-ore", 10000, -50, -50, game.get_surface("nauvis"))
    local tile_to_amount_ratio = 10000
    local tiles  = amount / tile_to_amount_ratio

    local biases = {[0] = {[0] = 1}}
    local t = 1

    local function grow(grid,t2)
        local old = {}
        local new_count = 0
        for x,_  in pairs(grid) do
            for y,__ in pairs(_) do
                table.insert(old,{x,y})
            end
        end
        for _,pos in pairs(old) do
            local x,y = pos[1],pos[2]
            for dx=-1,1,1 do
                for dy=-1,1,1 do
                    local a,b = x+dx, y+dy
                    if math.random() > 0.9 then
                        grid[a] = grid[a] or {}
                        if not grid[a][b] then
                            grid[a][b] = 1 - (t2/tiles)
                            new_count = new_count + 1
                            if (new_count+t2) == tiles then return new_count end
                        end
                    end
                end
            end
        end
        return new_count
    end

    repeat
        t = t + grow(biases,t)
    until t >= tiles

    local total_bias = 0
    for x,_ in pairs(biases) do
        for y,bias in pairs(_) do
            total_bias = total_bias + bias
        end
    end

    for x,_ in pairs(biases) do
        for y,bias in pairs(_) do
        surface.create_entity{
            name = name,
            amount = amount * (bias/total_bias),
            force = 'neutral',
            position = {x_position+x,y_position+y},
            }
        end
    end
end

return exports
