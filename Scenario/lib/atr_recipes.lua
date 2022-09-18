
local function disable_all(recipes)
    for k,v in pairs(recipes) do
        v.enabled = false
    end
end

local function toggle(command)
    local param = command.parameter
    local player = game.players[command.player_index]
    local recipes = player.force.recipes

    if param == "all" then 
        disable_all(recipes) 
        player.print("All recipes disabled")
    else
        --Is it a valid recipe passed in?
        if not recipes[param] then
            player.print("Recipe not found: " .. param)
            return
        end
        recipes[param].enabled = not recipes[param].enabled
        local enabled = "disabled"
        if recipes[param].enabled then enabled = "enabled" end
        player.print("Recipe ".. enabled ..": "..param)
    end

end

local exports = {}

exports.add_commands = function()
    commands.add_command("atr_recipe",
        "/c atr_recipe recipe - Toggle the recipe"
        ,function(command)
            toggle(command)
        end)
end

return exports