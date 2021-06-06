local Utils = require("lib/atr_utils")

local function Setup()
    Utils.DrawTextLarge("Welcome to ATR!", -20, -6)
end

return{
    Setup = Setup
}
