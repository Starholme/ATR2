-- To keep the scenario more manageable (for myself) I have done the following:
--      1. Keep all event calls here
--      2. Put all config options in config.lua
--      3. Put other stuff into their own files where possible

--REQUIRES--
local adaptive_biters = require("lib/atr_adaptive_biters")

script.on_init(function(event)
    adaptive_biters.on_init(event)
end)

script.on_event(defines.events.on_entity_died, function(event)
    adaptive_biters.on_entity_died(event)
end,
{adaptive_biters.on_entity_died_filter})

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    adaptive_biters.on_runtime_mod_setting_changed(event)
end)

script.on_event(defines.events.on_tick, function(event)
    if (event.tick % adaptive_biters.on_tick_modulus == 0) then adaptive_biters.on_tick(event) end
end)