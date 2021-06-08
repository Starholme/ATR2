--CONSTANTS--

--REQUIRES--
local utils = require("lib/atr_utils")

--Holds items that are exported
local exports = {}

function exports.setup()
    utils.draw_text_large("Welcome to ATR!", -20, -6)
end

return exports
