data:extend({
    {
        type = "bool-setting",
        name = "enable-adaptive-biters",
        setting_type = "runtime-global",
        default_value = true
    },
    {
        type = "bool-setting",
        name = "adaptive-biters-immune",
        setting_type = "runtime-global",
        default_value = false
    },
    {
        type = "int-setting",
        name = "adaptive-biters-kte",
        setting_type = "runtime-global",
        default_value = 100,
        minimum_value = 1,
        maximum_value = 1000
    }
    
})