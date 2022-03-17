--CONSTANTS--
local LARGE = 10
local SMALL = 5
local ORANGE = {0.9, 0.7, 0.3, 0.8}

--REQUIRES--

--Holds items that are exported
local exports = {}

local function draw_text(surface, x, y, scale, color, text)
    rendering.draw_text{
        text=text,
        surface=surface,
        target={x,y},
        color=color,
        scale=scale,
        --Allowed fonts: default-dialog-button default-game compilatron-message-font default-large default-large-semibold default-large-bold heading-1 compi
        font="compi",
        draw_on_ground=true
    }
end

function exports.draw_text_large(text, x, y)
    draw_text("nauvis", x, y, LARGE, ORANGE, text)
end

function exports.draw_text_small(text, x, y)
    draw_text("nauvis", x, y, SMALL, ORANGE, text)
end

return exports
