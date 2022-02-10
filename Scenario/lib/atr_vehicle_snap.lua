-- Very liberally adapted from Vehicle Snap by Zaflis
-- https://mods.factorio.com/mod/VehicleSnap
-- Based on V1.18.4

local SNAPS = 8
local NUM_CHECKS_FOR_STABLE = 7
local MIN_SPEED_TO_SNAP = 0.03

local exports = {}

function exports.on_player_driving_changed_state(event)
    global.atr_vehicle_snap = global.atr_vehicle_snap or {}

    local player_index = event.player_index

    if event.entity ~= nil and event.entity.type == "car" then
        global.atr_vehicle_snap[player_index] = {
            last_orientation = 0, -- orientation of car last time we checked
            stable_checks = 0 -- the orientation has not changed in this many checks
        }
    else
        global.atr_vehicle_snap[player_index] = nil
    end
end

function exports.on_nth_tick()
    if not global.atr_vehicle_snap then
        return
    end

    for player_index, player_data in pairs(global.atr_vehicle_snap) do
        local player = game.players[player_index]

        --Remove if not a valid player, or in a vehicle anymore
        if not player or not player.vehicle then
            global.atr_vehicle_snap[player_index] = nil
        else
            local orientation = player.vehicle.orientation -- float value, direction vehicle is facing
            local stable_checks = player_data.stable_checks

            --Update # of checks that the orientation has been stable
            if math.abs(orientation - player_data.last_orientation)<0.001 then
                stable_checks = stable_checks + 1
            else
                stable_checks = 0
            end
            player_data.last_orientation = orientation
            player_data.stable_checks = stable_checks

            if (stable_checks > NUM_CHECKS_FOR_STABLE) and (math.abs(player.vehicle.speed) > MIN_SPEED_TO_SNAP) then
                local snap_o = math.floor(orientation * SNAPS + 0.5) / SNAPS
                  -- Interpolate with 80% current and 20% target orientation
                  orientation = (orientation * 4.0 + snap_o) * 0.2
                  player.vehicle.orientation = orientation
                  -- Set the last orientation to our updated value, to ignore 'our' changes in the
                  -- stable check
                  player_data.last_orientation = orientation
            end

        end
    end
end

return exports
