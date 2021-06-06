local LARGE = 10
local ORANGE = {0.9, 0.7, 0.3, 0.8}

local function DrawText(surface, x, y, scale, color, text)
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

local function DrawTextLarge(text, x, y)
    DrawText("nauvis", x, y, LARGE, ORANGE, text)
end

return {
    DrawTextLarge = DrawTextLarge
}
