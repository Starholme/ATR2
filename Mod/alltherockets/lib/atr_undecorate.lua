--CONSTANTS--

--REQUIRES--
--local req = require("whatever")

--Holds items that are exported
local exports = {}

exports.on_tick = function (event)
    local surface = game.get_surface("nauvis")
    local rnd_chunk = surface.get_random_chunk()

    --If 0,0 then no chunks are ready
    if rnd_chunk.x == 0 and rnd_chunk.y == 0 then return end

    --Get all the decoratives in the chunk
    local area = {{x=rnd_chunk.x * 32, y=rnd_chunk.y * 32},{x=(rnd_chunk.x+1) * 32, y=(rnd_chunk.y+1) * 32}}
    local decoratives = surface.find_decoratives_filtered{area = area}

    --Pick one at random
    local count = table_size(decoratives)
    if count == 0 then return end
    local rnd_decorative = decoratives[math.random(count)]

    --Remove this decoration, and any others in the same spot
    local spec_decoratives = surface.find_decoratives_filtered{position = rnd_decorative.position}
    local num = table_size(spec_decoratives)

    local total = global.atr_undecorate or 0
    total = total + num
    global.atr_undecorate = total

    surface.destroy_decoratives{position = rnd_decorative.position}
end
exports.on_tick_modulus = 10

function exports.add_commands()
    commands.add_command("atr_undecorate", nil, function(command)
        game.get_player(command.player_index).print("Decoratives removed:"..global.atr_undecorate)
    end)
end

return exports