local resource_autoplace = require("resource-autoplace")

--Force oil (and other fluids) to appear in spawn.
for k, v in pairs(data.raw.resource) do
    if v.category == "basic-fluid" and v.autoplace then
        v.autoplace = resource_autoplace.resource_autoplace_settings{
            name = k,
            order = "a", -- Other resources are "b"; oil won't get placed if something else is already there.
            base_density = 8.2,
            base_spots_per_km2 = 7.2,
            random_probability = 1/48,
            random_spot_size_minimum = 3,
            random_spot_size_maximum = 6,
            additional_richness = 220000, -- this increases the total everywhere, so base_density needs to be decreased to compensate
            has_starting_area_placement = true,
            -- resource_index = resource_autoplace.resource_indexes[k],
            regular_rq_factor_multiplier = 1
          },
        log("Updating autoplace for " .. k)
    end
end

--passthrough resource.coverage to runtime stage.
-- for k, v in pairs(data.raw.resource) do
--     if not v.infinite and v.autoplace then
--         local add = true
--         if v.minable.results then
--             for _, product in pairs(v.minable.results) do
--                 if product.type == "fluid" then
--                     add = false
--                     break
--                 end
--             end
--         elseif v.minable.result and v.minable.result.type == "fluid" then
--             add = false
--         end
--         if add then
--             local recipe = {
--                 type = "recipe",
--                 name = "dangOreus-" .. v.name,
--                 energy_required = v.autoplace.base_density,
--                 enabled = false,
--                 ingredients = {},
--                 results = {},
--                 icon = v.icon,
--                 icons = v.icons,
--                 icon_size = v.icon_size,
--                 subgroup = "raw-material"
--                 }
--             data:extend{recipe}
--         end
--     end
-- end
