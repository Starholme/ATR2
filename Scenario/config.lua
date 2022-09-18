return {
    --Common across all servers--
    VERSION = "V1.9.0",
    SCENARIO_TEXT =
    "ATR is a cooperative game that is intended to provide some continuity across map resets. \n" ..
    "Rules: Be polite. Ask before changing other player's stuff. Have fun!",
    MOD_TEXT = "Mods:\n"..
    "Clusterio Library - Used to communicate with the cluster\n"..
    "Subspace Storage - Allows storing items and fluids in a limitless space, shared across the cluster"..
    "All The Rockets - Scenario components:\n"..
    "   Adaptive biters - Biters evolve to resist the weapons you use"
    ,
    SOFTMOD_TEXT = "Soft Mods:\n"..
    "Global Chat - Chat text is shared across all servers in the cluster\n"..
    "Server Select - Jump directly between servers in the cluster\n"..
    "Vehicle Snap - Cars are easier to drive on roads, they snap to one of 8 directions\n",
    DISCORD = "https://discord.gg/6dq2CbJ3Gx",
    CONTACT_TEXT = "See stats and server info at https://AllTheRockets.duckdns.org | Discord:Starholme#3744",

    --Specific to this instance--
    SERVER_TEXT = "Nauvis Ghawar",
    MAP_INFO = "Ghawar is an oil field located in Saudi Arabia, covering some 8400 sq.km, producing 3.8 million barrels of oil and 57 million cubic meters of gas per day",

    TEST_MODE = true,
    ENABLE_RESEARCH_QUEUE = true,
    FRIENDLY_FIRE = false,

    ENABLE_SPLIT_SPAWN = false,
    ENABLE_SUBSPACE = false,
    ENABLE_VOID = false, --You probably want to blacklist steam/water and subspace electrical injector/extractors
    ENABLE_DANGOREUS = false
}
