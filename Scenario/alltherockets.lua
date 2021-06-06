-- To keep the scenario more manageable (for myself) I have done the following:
--      1. Keep all event calls here
--      2. Put all config options in config.lua
--      3. Put other stuff into their own files where possible

-- Require other modules

-- Event handlers
local function OnInit(event)


    rendering.draw_text{text="Testing1",
                    surface="nauvis",
                    target= {x=-15.5,y=-23},
                    color={0.9, 0.7, 0.3, 0.8},
                    scale=30,
                    --Allowed fonts: default-dialog-button default-game compilatron-message-font default-large default-large-semibold default-large-bold heading-1 compi
                    font="compi",
                    draw_on_ground=true}
end

local function tick120(event)
    game.print("Tick 120 fired")
end

return {
    on_init = OnInit,
    on_nth_tick = {[120] = tick120}
}
