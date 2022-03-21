--CONSTANTS--
local KIT = {
    {name="infinity-chest", count = 50},
    {name="infinity-pipe", count = 50},
    {name="electric-energy-interface", count = 50},
    {name="express-loader", count = 50},
    {name="express-transport-belt", count = 50},
}

--REQUIRES--
--local req = require("whatever")

--Holds items that are exported
local exports = {}

function exports.on_player_created(player)
    player.insert{name="power-armor-mk2", count = 1}
    player.character_running_speed_modifier = 2

    if player and player.get_inventory(defines.inventory.character_armor) ~= nil and player.get_inventory(defines.inventory.character_armor)[1] ~= nil then
        local p_armor = player.get_inventory(defines.inventory.character_armor)[1].grid
            if p_armor ~= nil then
                p_armor.put({name = "fusion-reactor-equipment"})
                p_armor.put({name = "fusion-reactor-equipment"})
                p_armor.put({name = "exoskeleton-equipment"})
                p_armor.put({name = "exoskeleton-equipment"})
                p_armor.put({name = "exoskeleton-equipment"})
                p_armor.put({name = "exoskeleton-equipment"})
                p_armor.put({name = "exoskeleton-equipment"})
                p_armor.put({name = "energy-shield-mk2-equipment"})
                p_armor.put({name = "personal-laser-defense-equipment"})
                p_armor.put({name = "personal-laser-defense-equipment"})
                p_armor.put({name = "personal-laser-defense-equipment"})
                p_armor.put({name = "personal-laser-defense-equipment"})
                p_armor.put({name = "personal-roboport-mk2-equipment"})
                p_armor.put({name = "battery-mk2-equipment"})
                p_armor.put({name = "battery-mk2-equipment"})
            end
        player.insert{name="construction-robot", count = 100}
    end

    for _,item in pairs(KIT) do
        player.insert(item)
    end

end

return exports
