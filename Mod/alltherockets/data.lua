--atr_nuke_crater
table.insert(
    data.raw["projectile"]["atomic-rocket"]["action"]["action_delivery"]["target_effects"], 
    {
        type="script",
        effect_id = "atomic-rocket"
    })