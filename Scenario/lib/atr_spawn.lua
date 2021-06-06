--CONSTANTS--

--REQUIRES--
local Utils = require("lib/atr_utils")

--Holds items that are exported
local exports = {}

function exports.Setup()
    Utils.DrawTextLarge("Welcome to ATR!", -20, -6)
end

return exports
